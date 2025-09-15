package starship.fpga

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
import sifive.fpgashells.shell._
import sifive.fpgashells.clocks._
import sifive.blocks.devices.spi._
import sifive.blocks.devices.uart._
import sifive.fpgashells.ip.xilinx._
import sifive.fpgashells.shell.xilinx.vc707shell._
import sifive.fpgashells.devices.xilinx.xilinxvc707mig._
import sifive.blocks.devices.uart._

class StarshipFPGATop(implicit p: Parameters) extends StarshipSystem
  with HasPeripheryUART
  with HasPeripherySPI
  with HasPeripheryDebug
  with HasMemoryXilinxVC707MIG
{

  val chosen = new DeviceSnippet {
    def describe() = Description("chosen", Map(
      "bootargs" -> Seq(ResourceString("console=ttyS0 earlycon nokaslr"))
    ))
  }
  
  val mmc = new MMCDevice(tlSpiNodes.head.device) 
  ResourceBinding {
    Resource(mmc, "reg").bind(ResourceAddress(0))
  }

  override lazy val module = new StarshipFPGATopModuleImp(this)
}

class StarshipFPGATopModuleImp[+L <: StarshipFPGATop](_outer: L) extends StarshipSystemModuleImp(_outer)
  with HasPeripheryUARTModuleImp
  with HasPeripherySPIModuleImp
  with HasPeripheryDebugModuleImp
  with HasMemoryXilinxVC707MIGModuleImp
  with DontTouch

class TestHarness(override implicit val p: Parameters) extends VC707Shell
    with HasDDR3
    with HasDebugJTAG 
  {


  dut_clock := (p(FPGAFrequencyKey) match {
    case 25 => clk25
    case 50 => clk50
    case 100 => clk100
    case 150 => clk150
  })

  withClockAndReset(dut_clock, dut_reset) {
    val dut = Module(LazyModule(new StarshipFPGATop).module)
    
    connectSPI      (dut)
    connectUART     (dut)
    connectDebugJTAG(dut)
    connectMIG      (dut)

    val childReset = dut_reset.asBool | dut.debug.map(_.ndreset).getOrElse(false.B)
    dut.reset := childReset

    led(0) := jtag_TCK.asBool
    led(1) := jtag_TDI.asBool
    led(2) := jtag_TDO.asBool
    led(3) := jtag_TMS.asBool
    led(4) := false.B
    led(5) := true.B
    led(6) := false.B
    led(7) := true.B

    dut_ndreset := 0.U

    dut.tieOffInterrupts()
    dut.dontTouchPorts()

    dut.resetctrl.foreach { rc =>
      rc.hartIsInReset.foreach { _ := childReset }
    }
    Debug.connectDebugClockAndReset(dut.debug, dut_clock)
  }
}
