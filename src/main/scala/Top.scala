package starship

import chisel3._

import freechips.rocketchip.tile._
import freechips.rocketchip.util._
import freechips.rocketchip.prci._
import freechips.rocketchip.config._
import freechips.rocketchip.system._
import freechips.rocketchip.subsystem._
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.devices.debug._
import freechips.rocketchip.devices.tilelink._
import sifive.fpgashells.devices.xilinx.xilinxvc707mig._

import sifive.blocks.devices.spi._
import sifive.blocks.devices.uart._

class StarshipSystem(implicit p: Parameters) extends RocketSubsystem
  with HasAsyncExtInterrupts
{
  val bootROM  = p(BootROMLocated(location)).map { BootROM.attach(_, this, CBUS) }
  val maskROMs = p(MaskROMLocated(location)).map { MaskROM.attach(_, this, CBUS) }

  override lazy val module = new StarshipSystemModuleImp(this)
}

class StarshipSystemModuleImp[+L <: StarshipSystem](_outer: L) extends RocketSubsystemModuleImp(_outer)
  with HasRTCModuleImp
  with HasExtInterruptsModuleImp
  with DontTouch