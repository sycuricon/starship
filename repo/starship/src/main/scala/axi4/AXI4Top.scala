package starship.axi4

import starship._
import chisel3._
import freechips.rocketchip.tile._
import freechips.rocketchip.util._
import freechips.rocketchip.prci._
import org.chipsalliance.cde.config._
import freechips.rocketchip.system._
import freechips.rocketchip.tilelink._
import freechips.rocketchip.subsystem._
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.devices.debug._
import freechips.rocketchip.devices.tilelink._
import sifive.blocks.devices.uart._
import sifive.fpgashells.ip.xilinx._

class StarshipAxi4Top(implicit p: Parameters) extends StarshipSystem
    with CanHaveMasterAXI4MemPort
    with CanHaveMasterAXI4MMIOPort
    with HasPeripheryDebug
{
  val chosen = new DeviceSnippet {
    def describe() = Description("chosen", Map(
      "bootargs" -> Seq(ResourceString("nokaslr"))
    ))
  }

  override lazy val module = new StarshipAxi4TopModuleImp(this)
}

class StarshipAxi4TopModuleImp[+L <: StarshipAxi4Top](_outer: L) extends StarshipSystemModuleImp(_outer)
    with DontTouch


class TestHarness()(implicit p: Parameters) extends Module {
  
  val io = IO(new Bundle {
    val jtag_TCK             = Input(Clock())
    val jtag_TMS             = Input(Bool())
    val jtag_TDI             = Input(Bool())
    val jtag_TDO             = Output(Bool())
  })

  val ldut = LazyModule(new StarshipAxi4Top)
  val dut = Module(ldut.module)

  // Allow the debug ndreset to reset the dut, but not until the initial reset has completed
  dut.reset := (reset.asBool | ldut.debug.map { debug => AsyncResetReg(debug.ndreset) }.getOrElse(false.B)).asBool

  dut.dontTouchPorts()
  dut.tieOffInterrupts()
  SimAXIMem.connectMem(ldut)
  SimAXIMem.connectMMIO(ldut)

  val djtag     = ldut.debug.get.systemjtag.get

  djtag.jtag.TCK := io.jtag_TCK
  djtag.jtag.TMS := io.jtag_TMS
  djtag.jtag.TDI := io.jtag_TDI
  io.jtag_TDO    := djtag.jtag.TDO.data

  djtag.mfr_id   := p(JtagDTMKey).idcodeManufId.U(11.W)
  djtag.part_number := p(JtagDTMKey).idcodePartNum.U(16.W)
  djtag.version  := p(JtagDTMKey).idcodeVersion.U(4.W)

  djtag.reset    := PowerOnResetFPGAOnly(clock)

  ldut.resetctrl.foreach { rc =>
    rc.hartIsInReset.foreach { _ := dut.reset }
  }
  Debug.connectDebugClockAndReset(ldut.debug, clock)
}
