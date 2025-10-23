package starship.asic

import java.nio.charset.StandardCharsets
import java.nio.file.{Files, Paths}

import chisel3._
import chisel3.util._
import freechips.rocketchip.util._
import org.chipsalliance.cde.config._
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.regmapper._
import freechips.rocketchip.tilelink._
import freechips.rocketchip.subsystem._

 
case class MagicParams(
  baseAddress: BigInt = 0x2000,
  width: Int = 64) {
  def address = AddressSet(baseAddress, 0xFFF)
}

case object MagicKey extends Field[Option[MagicParams]](None)

case class MagicAttachParams(
  slaveWhere: TLBusWrapperLocation = CBUS
)

case object MagicAttachKey extends Field(MagicAttachParams())

class MagicIO(val w: Int) extends Bundle {
  val clock = Input(Clock())
  val reset = Input(Bool())
  val read_select = Input(UInt(12.W))
  val read_ready = Input(Bool())
  val read_valid = Output(Bool())
  val read_data = Output(UInt(w.W))
}

class MagicDeviceBlackbox(val w: Int) extends BlackBox {
    val io = IO(new MagicIO(w))
}

class MagicDevice(params: MagicParams, beatBytes: Int)(implicit p: Parameters) 
  extends LazyModule {
  
  val device = new SimpleDevice("magic", Seq("sycuricon,risc-free,magic-device"))

  val node: TLRegisterNode = TLRegisterNode(
    address   = Seq(params.address),
    device    = device,
    beatBytes = beatBytes)

  lazy val module = new Imp
  class Imp extends LazyModuleImp(this) {   
    val field_name = List("random", "rdm_word", "rdm_float", "rdm_double", "rdm_text_addr", "rdm_data_addr", "mepc_next", "sepc_next", "rdm_pte")
    val field_offset = field_name.zipWithIndex.map((_._2*8))
    val field_header = "#ifndef _SYCURICON_MAGIC_DEVICE_H\n" + "#define _SYCURICON_MAGIC_DEVICE_H\n" +
                       field_name.zip(field_offset).map(pair => "#define MAGIC_" + pair._1.toUpperCase + " 0x0" + pair._2.toHexString + "\n").mkString +
                       "#define MAX_MAGIC_SPACE " + "0x0" + (field_name.size*8).toHexString + "\n" +
                       "#endif\n"
    Files.write(Paths.get("./build/rocket-chip/magic_device.h"), field_header.getBytes(StandardCharsets.UTF_8))

    val field_wire = field_offset.map(_ => Wire(new DecoupledIO(UInt(params.width.W))))
    node.regmap(field_offset.zip(field_wire).map{
      case (offset, wire) => offset -> Seq(RegField.r(params.width, wire, RegFieldDesc(f"rdm_$offset", "", reset=Some(0), volatile=true)))
    }:_*)

    val impl = Module(new MagicDeviceBlackbox(params.width))
    impl.io.clock := clock
    impl.io.reset := reset.asBool
    impl.io.read_select := 0.U

    field_wire.zip(field_offset).foreach{ case (io, offset) =>
      io.bits := impl.io.read_data
      io.valid := impl.io.read_valid
      when(io.ready) {
        impl.io.read_select := offset.U(12.W)
      }
    }

    impl.io.read_ready := field_wire.foldLeft(false.B)((res, io) => res || io.ready)
  }
}

trait CanHavePeripheryMagicDevice { this: BaseSubsystem =>
  val MagicOpt = p(MagicKey).map { params =>
    val tlbus = locateTLBusWrapper(p(MagicAttachKey).slaveWhere)
    val magic = LazyModule(new MagicDevice(params, tlbus.beatBytes))
    magic.node := tlbus.coupleTo("magic") { TLFragmenter(tlbus) := _ }
    magic
  }
}
