package starship

import starship.fpga._

import chisel3._

import freechips.rocketchip.system._
import freechips.rocketchip.config._

import freechips.rocketchip.subsystem._

import sifive.fpgashells.shell._
import sifive.fpgashells.clocks._
import sifive.fpgashells.ip.xilinx._
import sifive.fpgashells.shell.xilinx._

import sifive.blocks.devices.uart._
class WithUART(baudrate: BigInt = 115200) extends Config((site, here, up) => {
  case PeripheryUARTKey => Seq(
    UARTParams(
      address = 0x54000000L, 
      nTxEntries = 256, 
      nRxEntries = 256, 
      initBaudRate = baudrate))
})

class WithFrequency(MHz: Double) extends Config((site, here, up) => {
  case FPGAFrequencyKey => MHz
})

class StarshipBaseConfig extends Config(
  new WithBootROMFile("bootrom/bootrom.img") ++
  new WithExtMemSize(0x80000000L) ++
  new WithNExtTopInterrupts(0) ++
  new WithDTS("zjv,starship", Nil) ++
  new WithEdgeDataBits(64) ++
  new WithCoherentBusTopology ++
  new WithoutTLMonitors ++
  new BaseConfig)

class StarshipDefaultConfig extends Config(
  new WithUART ++
  new WithFrequency(50) ++
  new WithNBigCores(1)    ++
  new StarshipBaseConfig)
