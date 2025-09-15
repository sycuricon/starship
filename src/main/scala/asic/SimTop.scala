package starship.asic

import starship._
import chisel3._
import firrtl.FirrtlProtos.Firrtl.BigInt
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

class StarshipSimTop(implicit p: Parameters) extends StarshipSystem
  with HasPeripheryUART
  with CanHaveMasterAXI4MemPort
{

  val chosen = new DeviceSnippet {
    def describe() = Description("chosen", Map(
      "bootargs" -> Seq(ResourceString("console=ttyS0 earlycon nokaslr"))
    ))
  }

  override lazy val module = new StarshipSimTopModuleImp(this)
}

class StarshipSimTopModuleImp[+L <: StarshipSimTop](_outer: L) extends StarshipSystemModuleImp(_outer)
  with HasPeripheryUARTModuleImp
  with DontTouch

class TestHarness(implicit val p: Parameters) extends Module
  {

  val io = IO(new Bundle {
    val uart_tx = Output(Bool())
    val uart_rx = Input(Bool())
  })

  val ldut = LazyModule(new StarshipSimTop)
  val dut = Module(ldut.module)

  dut.reset := reset.asBool
  dut.tieOffInterrupts()
  dut.dontTouchPorts()
  SimAXIMem.connectMem(ldut)

  dut.uart.headOption.foreach(uart => {
      uart.rxd := SyncResetSynchronizerShiftReg(io.uart_rx, 2, init = true.B, name=Some("uart_rxd_sync"))
      io.uart_tx  := uart.txd
    }
  )

}
