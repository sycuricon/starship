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
import sifive.fpgashells.shell.xilinx.nexysa7shell._
import sifive.fpgashells.devices.xilinx.digilentnexysa7mig._
import sifive.blocks.devices.uart._

class StarshipFPGATopA7(implicit p: Parameters) extends StarshipSystem
  with HasPeripheryUART
  with HasPeripherySPI
  with HasMemoryDigilentNexysA7MIG
{

  val chosen = new DeviceSnippet {
    def describe() = Description("chosen", Map(
      "bootargs" -> Seq(ResourceString("nokaslr"))
    ))
  }
  
  val mmc = new MMCDevice(tlSpiNodes.head.device) 
  ResourceBinding {
    Resource(mmc, "reg").bind(ResourceAddress(0))
  }

  override lazy val module = new StarshipFPGATopModuleImpA7(this)
}

class StarshipFPGATopModuleImpA7[+L <: StarshipFPGATopA7](_outer: L) extends StarshipSystemModuleImp(_outer)
  with HasPeripheryUARTModuleImp
  with HasPeripherySPIModuleImp
  with HasMemoryDigilentNexysA7MIGModuleImp
  with DontTouch

// VC707 shell has SPI to SDIO
// Arty A7 100T has different memory interface with VC707
class TestHarnessA7(override implicit val p: Parameters) extends NexysA7Shell
    with HasDDR2 {


  dut_clock := (p(FPGAFrequencyKey) match {
    case 50   => clk50
    case 200  => clk200
  })

  withClockAndReset(dut_clock, dut_reset) {
    val dut = Module(LazyModule(new StarshipFPGATopA7).module)
    
    connectSPI      (dut)
    connectUART     (dut)
    connectMIG      (dut)

    dut.tieOffInterrupts()
    dut.dontTouchPorts()
  }
}
