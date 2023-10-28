package starship.fpga

import starship._

import chisel3._

import freechips.rocketchip.system._
import org.chipsalliance.cde.config._
import freechips.rocketchip.subsystem._
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.devices.debug._
import freechips.rocketchip.devices.tilelink._

import sifive.fpgashells.shell._
import sifive.fpgashells.clocks._
import sifive.fpgashells.ip.xilinx._
import sifive.fpgashells.shell.xilinx._
import sifive.fpgashells.devices.xilinx.xilinxvc707mig._

import sifive.blocks.devices.spi._
import sifive.blocks.devices.uart._


case object VCU707DDRSizeKey extends Field[BigInt](0x40000000L) // 1 GB

class WithPeripherals extends Config((site, here, up) => {
  case PeripheryUARTKey => List(
    UARTParams(address = BigInt(0x64000000L)))
  case PeripherySPIKey => List(
    SPIParams(rAddress = BigInt(0x64001000L)))
  case MaskROMLocated(x) => List(
    MaskROMParams(BigInt(0x20000L), "StarshipROM")
  )
})

class StarshipFPGAConfig extends Config(
  new WithPeripherals ++
  new StarshipBaseConfig().alter((site,here,up) => {
    case DebugModuleKey => None
    case PeripheryBusKey => up(PeripheryBusKey, site).copy(dtsFrequency = Some(site(FrequencyKey).toInt * 1000000))
    /* timebase-frequency = 1 MHz */
    case DTSTimebase => BigInt(1000000L)
    /* memory-size = 1 GB */
    case MemoryXilinxDDRKey => XilinxVC707MIGParams(address = Seq(AddressSet(0x80000000L,site(VCU707DDRSizeKey)-1)))
    case ExtMem => up(ExtMem, site).map(x => 
      x.copy(master = x.master.copy(size = site(VCU707DDRSizeKey))))
  })
)

class StarshipFPGADebugConfig extends Config(
  new WithPeripherals ++
  new WithJtagDTM ++
  new StarshipBaseConfig().alter((site,here,up) => {
    //case DebugModuleKey => None
    case PeripheryBusKey => up(PeripheryBusKey, site).copy(dtsFrequency = Some(site(FrequencyKey).toInt * 1000000))
    /* timebase-frequency = 1 MHz */
    case DTSTimebase => BigInt(1000000L)
    /* memory-size = 1 GB */
    case MemoryXilinxDDRKey => XilinxVC707MIGParams(address = Seq(AddressSet(0x80000000L,site(VCU707DDRSizeKey)-1)))
    case ExtMem => up(ExtMem, site).map(x => 
      x.copy(master = x.master.copy(size = site(VCU707DDRSizeKey))))
  })
)