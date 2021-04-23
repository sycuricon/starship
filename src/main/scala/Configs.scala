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


class StarshipBaseConfig extends Config(
  new WithBootROMFile("repo/rocket-chip/bootrom/bootrom.img") ++
  new WithExtMemSize(0x80000000L) ++
  new WithNExtTopInterrupts(0) ++
  new WithDTS("zjv,starship", Nil) ++
  new WithEdgeDataBits(64) ++
  new WithCoherentBusTopology ++
  new WithoutTLMonitors ++
  new BaseConfig)