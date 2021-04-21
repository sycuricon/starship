package starship

import starship.fpga._

import chisel3._

import freechips.rocketchip.system._
import freechips.rocketchip.config._
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.devices.debug._

import freechips.rocketchip.subsystem._

import sifive.fpgashells.shell._
import sifive.fpgashells.clocks._
import sifive.fpgashells.ip.xilinx._
import sifive.fpgashells.shell.xilinx._
import sifive.fpgashells.devices.xilinx.xilinxvc707mig._

import sifive.blocks.devices.uart._
import sifive.blocks.devices.spi._


class WithPeripherals extends Config((site, here, up) => {
  case PeripheryUARTKey => List(
    UARTParams(address = BigInt(0x64000000L)))
  case PeripherySPIKey => List(
    SPIParams(rAddress = BigInt(0x64001000L)))
})

class WithFrequency(MHz: Double) extends Config((site, here, up) => {
  case FPGAFrequencyKey => MHz
})

class StarshipBaseConfig extends Config(
  new WithBootROMFile("bootrom/bootrom.img") ++
  new WithExtMemSize(0x40000000L) ++
  new WithNExtTopInterrupts(0) ++
  new WithDTS("zjv,starship", Nil) ++
  new WithEdgeDataBits(64) ++
  new WithCoherentBusTopology ++
  new WithoutTLMonitors ++
  new BaseConfig)

class StarshipDefaultConfig extends Config(
  new WithPeripherals ++
  new WithFrequency(50) ++
  new WithNBigCores(1)    ++
  new StarshipBaseConfig().alter((site,here,up) => {
    case PeripheryBusKey => up(PeripheryBusKey, site).copy(dtsFrequency = Some(BigInt(50000000))) // 50 MHz hperiphery
    case MemoryXilinxDDRKey => XilinxVC707MIGParams(address = Seq(AddressSet(0x80000000L,0x40000000L-1))) //1GB
    case DTSTimebase => BigInt(1000000)
    case DebugModuleKey => None
  })
)