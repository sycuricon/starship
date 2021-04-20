package starship.fpga

import starship._

import chisel3._
import chisel3.experimental._

import freechips.rocketchip.util._
import freechips.rocketchip.config._
import freechips.rocketchip.tilelink._
import freechips.rocketchip.diplomacy._

import sifive.fpgashells.shell._
import sifive.fpgashells.clocks._
import sifive.fpgashells.ip.xilinx._
import sifive.fpgashells.shell.xilinx._

import sifive.blocks.devices.uart._

class TestHarness(override implicit val p: Parameters) extends VC707Shell {

  val uart = Overlay(UARTOverlayKey, new UARTVC707ShellPlacer(this, UARTShellInput()))
  val topDesign = LazyModule(p(BuildTop)(designParameters)).suggestName("starship")
  
  val io_uart_bb = BundleBridgeSource(() => (new UARTPortIO(designParameters(PeripheryUARTKey).head)))
  designParameters(UARTOverlayKey).head.place(UARTDesignInput(io_uart_bb))

  override lazy val module = new LazyRawModuleImp(this) {
    val reset = IO(Input(Bool()))
    xdc.addBoardPin(reset, "reset")

    val reset_ibuf = Module(new IBUF)
    reset_ibuf.io.I := reset

    // val sysclk: Clock = sys_clock.get() match {
    //   case Some(x: SysClockVC707PlacedOverlay) => x.clock
    // }
    // val powerOnReset = PowerOnResetFPGAOnly(sysclk)
    // sdc.addAsyncPath(Seq(powerOnReset))

    val ereset: Bool = chiplink.get() match {
      case Some(x: ChipLinkVCU118PlacedOverlay) => !x.ereset_n
      case _ => false.B
    }
    pllReset :=
      reset_ibuf.io.O  || ereset
  }
}
