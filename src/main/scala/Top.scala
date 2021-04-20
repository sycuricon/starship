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

import sifive.blocks.devices.spi._
import sifive.blocks.devices.uart._

case object BuildTop extends Field[Parameters => LazyModule]((p: Parameters) => new StarshipTop()(p))

class StarshipSystem(implicit p: Parameters) extends RocketSubsystem
  with HasAsyncExtInterrupts
  with CanHaveMasterAXI4MemPort
  with CanHaveMasterAXI4MMIOPort
  with CanHaveSlaveAXI4Port
{
  val bootROM  = p(BootROMLocated(location)).map { BootROM.attach(_, this, CBUS) }
  val maskROMs = p(MaskROMLocated(location)).map { MaskROM.attach(_, this, CBUS) }

  override lazy val module = new StarshipSystemModuleImp(this)
}

class StarshipSystemModuleImp[+L <: StarshipSystem](_outer: L) extends RocketSubsystemModuleImp(_outer)
  with HasRTCModuleImp
  with HasExtInterruptsModuleImp
  with DontTouch


class StarshipTop(implicit p: Parameters) extends StarshipSystem
  with HasPeripheryUART
  // with HasPeripherySPI
{
  override lazy val module = new StarshipTopModuleImp(this)
}

class StarshipTopModuleImp[+L <: StarshipTop](_outer: L) extends StarshipSystemModuleImp(_outer)
  with HasPeripheryUARTModuleImp
  // with HasPeripherySPIModuleImp
  with DontTouch