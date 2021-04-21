package starship.fpga

import starship._

import chisel3._

import freechips.rocketchip.util._
import freechips.rocketchip.config._
import freechips.rocketchip.tilelink._
import freechips.rocketchip.diplomacy._

import sifive.fpgashells.shell._
import sifive.fpgashells.clocks._
import sifive.fpgashells.ip.xilinx._
import sifive.fpgashells.shell.xilinx.vc707shell._


import sifive.blocks.devices.uart._

class TestHarness(override implicit val p: Parameters) extends VC707Shell
    with HasDDR3 {

  dut_clock := clk50
  withClockAndReset(dut_clock, dut_reset) {
    val dut = Module(LazyModule(new StarshipTop).module)
    
    connectSPI      (dut)
    connectUART     (dut)
    connectMIG      (dut)

    dut.tieOffInterrupts()
    dut.dontTouchPorts()
  }
}
