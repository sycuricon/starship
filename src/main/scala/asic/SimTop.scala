package starship.asic

import starship._
import chisel3._
import freechips.rocketchip.tile._
import freechips.rocketchip.util._
import freechips.rocketchip.prci._
import freechips.rocketchip.config._
import freechips.rocketchip.system._
import freechips.rocketchip.tilelink._
import freechips.rocketchip.subsystem._
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.devices.debug._
import freechips.rocketchip.devices.tilelink._
import sifive.blocks.devices.uart._

class StarshipASICTop(implicit p: Parameters) extends StarshipSystem
    with CanHaveMasterAXI4MemPort
    with CanHaveSlaveAXI4Port
    with HasAsyncExtInterrupts
    with HasPeripheryUART
    with CanHavePeripheryMagic
{
  val chosen = new DeviceSnippet {
    def describe() = Description("chosen", Map(
      "bootargs" -> Seq(ResourceString("nokaslr"))
    ))
  }

  override lazy val module = new StarshipASICTopModuleImp(this)
}

class StarshipASICTopModuleImp[+L <: StarshipASICTop](_outer: L) extends StarshipSystemModuleImp(_outer)
    with HasRTCModuleImp
    with HasExtInterruptsModuleImp
    with HasPeripheryUARTModuleImp
    with DontTouch


class TestHarness()(implicit p: Parameters) extends Module {
  val io = IO(new Bundle {
    val uart_tx = Output(Bool())
    val uart_rx = Input(Bool())
  })

  val ldut = LazyModule(new StarshipASICTop)
  val dut = Module(ldut.module)

  // Allow the debug ndreset to reset the dut, but not until the initial reset has completed
  dut.reset := (reset.asBool | dut.debug.map { debug => AsyncResetReg(debug.ndreset) }.getOrElse(false.B)).asBool

  dut.dontTouchPorts()
  dut.tieOffInterrupts()
  SimAXIMem.connectMem(ldut)

  ldut.l2_frontend_bus_axi4.foreach(_.tieoff)
  dut.uart.headOption.foreach(uart => {
      uart.rxd := SyncResetSynchronizerShiftReg(io.uart_rx, 2, init = true.B, name=Some("uart_rxd_sync"))
      io.uart_tx  := uart.txd
    }
  )
}
