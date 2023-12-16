package starship.asic

import starship._
import chisel3._
import chisel3.experimental.{annotate, ChiselAnnotation}
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

class StarshipSimTop(implicit p: Parameters) extends StarshipSystem
    with CanHaveMasterAXI4MemPort
    with CanHaveSlaveAXI4Port
    with HasAsyncExtInterrupts
    with HasPeripheryUART
//    with HasPeripheryDebug
//    with CanHavePeripheryMagicDevice
    with CanHavePeripheryResetManager
{
  val chosen = new DeviceSnippet {
    def describe() = Description("chosen", Map(
      "bootargs" -> Seq(ResourceString("nokaslr"))
    ))
  }

  override lazy val module = new StarshipSimTopModuleImp(this)
}

class StarshipSimTopModuleImp[+L <: StarshipSimTop](_outer: L) extends StarshipSystemModuleImp(_outer)
    with HasRTCModuleImp
    with HasExtInterruptsModuleImp
    with HasPeripheryUARTModuleImp
    with CanHavePeripheryResetManagerImp
    with DontTouch
    with HasDummyTaintPort

trait HasDummyTaintPort {
  val tainted = collection.mutable.Map[String, Data]()
  tainted.update("uart_0_rxd_taint_0", IO(Flipped(UInt(1.W))).suggestName("uart_0_rxd_taint_0"))
  tainted.update("reset_manager_reset_in_taint_0", IO(Flipped(UInt(1.W))).suggestName("reset_manager_reset_in_taint_0"))

  val outer: StarshipSimTop
  outer.l2_frontend_bus_axi4.zipWithIndex.foreach {
    case (port, index) =>
      port.elements.foreach {
        case (channel, bundle) =>
          bundle.getElements.foreach {
            field => {
              if (chisel3.reflect.DataMirror.directionOf(field) == chisel3.ActualDirection.Input) {
                val name =
                  if (Seq("ready", "valid").contains(field.name)) s"l2_frontend_bus_axi4_${index}_${channel}_${field.name}_taint_0"
                  else s"l2_frontend_bus_axi4_${index}_${channel}_bits_${field.name}_taint_0"
                tainted.update(name, IO(Flipped(field.cloneType)).suggestName(name))
              }
            }
          }
      }
  }

  outer.mem_axi4.zipWithIndex.foreach {
    case (port, index) =>
      port.elements.foreach {
        case (channel, bundle) =>
          bundle.getElements.foreach {
            field => {
              if (chisel3.reflect.DataMirror.directionOf(field) == chisel3.ActualDirection.Input) {
                val name =
                  if (Seq("ready", "valid").contains(field.name)) s"mem_axi4_${index}_${channel}_${field.name}_taint_0"
                  else s"mem_axi4_${index}_${channel}_bits_${field.name}_taint_0"

                tainted.update(name, IO(Flipped(field.cloneType)).suggestName(name))
              }
            }
          }
      }
  }
}

class TaintSource() extends Module {
  val io = IO(new Bundle{
    val mem_axi4_0_ar_ready = Input(Bool())
    val mem_axi4_0_ar_valid = Input(Bool())
    val mem_axi4_0_ar_bits_id = Input(UInt(4.W))
    val mem_axi4_0_ar_bits_addr = Input(UInt(32.W))
    val mem_axi4_0_r_ready = Input(Bool())
    val mem_axi4_0_r_valid = Input(Bool())
    val mem_axi4_0_r_bits_id = Input(UInt(4.W))
    val mem_axi4_0_r_bits_data_taint_0 = Output(UInt(64.W))
  })

  val reg_last_addr = RegInit(0.U(32.W))
  val reg_last_id = RegInit(0.U(32.W))

  val secret_addr = PlusArg("secret_addr", 0x80004000L, "Secret Section Start Address", 64)
  val secret_size = PlusArg("secret_size", 0x00001000, "Secret Section Length")

  when (io.mem_axi4_0_ar_ready & io.mem_axi4_0_ar_valid) {
    reg_last_addr := io.mem_axi4_0_ar_bits_addr
    reg_last_id := io.mem_axi4_0_ar_bits_id
  }

  io.mem_axi4_0_r_bits_data_taint_0 := 0.U
  when ((io.mem_axi4_0_r_ready & io.mem_axi4_0_r_valid) &&
    (reg_last_addr >= secret_addr && reg_last_addr < (secret_addr + secret_size)) &&
    (reg_last_id === io.mem_axi4_0_r_bits_id)
  ) {
    io.mem_axi4_0_r_bits_data_taint_0 := -1.S(64.W).asUInt
  }
}

class TestHarness()(implicit p: Parameters) extends Module {
  
  val io = IO(new Bundle {
    val uart_tx = Output(Bool())
    val uart_rx = Input(Bool())
  })

  val ldut = LazyModule(new StarshipSimTop)
  val dut = Module(ldut.module)



  dut.reset_manager.map (_.reset_in := reset.asBool)
  // Allow the debug ndreset to reset the dut, but not until the initial reset has completed
  dut.reset := (reset.asBool |
                ldut.debug.map { debug => AsyncResetReg(debug.ndreset) }.getOrElse(false.B) |
                dut.reset_manager.map { _.reset_out }.getOrElse(false.B)).asBool

  dut.dontTouchPorts()
  dut.tieOffInterrupts()
  SimAXIMem.connectMem(ldut)

  ldut.l2_frontend_bus_axi4.foreach(
    p => {
      p.ar.valid := false.B
      p.ar.bits := DontCare
      p.aw.valid := false.B
      p.aw.bits := DontCare
      p.w.valid := false.B
      p.w.bits := DontCare
      p.r.ready := false.B
      p.b.ready := false.B
    }
  )

  dut.tainted.foreach {
    case (key, io) =>
      io := 0.U
      annotate(new ChiselAnnotation {
        override def toFirrtl = firrtl.AttributeAnnotation(
          io.toTarget, "pift_taint_wire = 1")
      })
  }

  val tsrc = Module(new TaintSource())
  tsrc.io.mem_axi4_0_ar_ready := ldut.mem_axi4(0).ar.ready
  tsrc.io.mem_axi4_0_ar_valid := ldut.mem_axi4(0).ar.valid
  tsrc.io.mem_axi4_0_ar_bits_id := ldut.mem_axi4(0).ar.bits.id
  tsrc.io.mem_axi4_0_ar_bits_addr := ldut.mem_axi4(0).ar.bits.addr
  tsrc.io.mem_axi4_0_r_ready := ldut.mem_axi4(0).r.ready
  tsrc.io.mem_axi4_0_r_valid := ldut.mem_axi4(0).r.valid
  tsrc.io.mem_axi4_0_r_bits_id := ldut.mem_axi4(0).r.bits.id
  dut.tainted.get("mem_axi4_0_r_bits_data_taint_0").get := tsrc.io.mem_axi4_0_r_bits_data_taint_0

  dut.uart.headOption.foreach(uart => {
      uart.rxd := SyncResetSynchronizerShiftReg(io.uart_rx, 2, init = true.B, name=Some("uart_rxd_sync"))
      io.uart_tx  := uart.txd
    }
  )

  Debug.connectDebug(ldut.debug, ldut.resetctrl, ldut.psd, clock, reset.asBool, WireInit(false.B))
}
