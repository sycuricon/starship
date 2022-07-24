package starship.asic

import java.nio.charset.StandardCharsets
import java.nio.file.{Files, Paths}

import chisel3._
import chisel3.util._
import freechips.rocketchip.config._
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.regmapper._
import freechips.rocketchip.tilelink._
import freechips.rocketchip.subsystem._

 
case class MagicParams(
  address: BigInt = 0x2000,
  width: Int = 64)

case object MagicKey extends Field[Option[MagicParams]](None)

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

trait MagicModule extends HasRegMap {
  implicit val p: Parameters
  def params: MagicParams
  val clock: Clock
  val reset: Reset


  val field_name = List("random", "rdm_word", "rdm_float", "rdm_double", "rdm_text_addr", "rdm_data_addr", "epc_next", "epc_map", "rdm_pte")
  val field_offset = field_name.zipWithIndex.map((_._2*8))
  val field_header = "#ifndef _ZJV_MAGIC_DEVICE_H\n" + "#define _ZJV_MAGIC_DEVICE_H\n" +
                     field_name.zip(field_offset).map(pair => "#define MAGIC_" + pair._1.toUpperCase + " 0x0" + pair._2.toHexString + "\n").mkString +
                     "#define MAX_MAGIC_SPACE " + "0x0" + (field_name.size*8).toHexString + "\n" +
                     "#endif\n"
  Files.write(Paths.get("./build/rocket-chip/magic_device.h"), field_header.getBytes(StandardCharsets.UTF_8))

  val field_wire = field_offset.map(_ => Wire(new DecoupledIO(UInt(params.width.W))))
  val field_regmap = field_offset.zip(field_wire).map{case (offset, wire) => offset -> Seq(RegField.r(params.width, wire))}

  val impl = Module(new MagicDeviceBlackbox(params.width))

  impl.io.clock := clock
  impl.io.reset := reset.asBool

  field_wire.zip(field_offset).foreach{ case (io, offset) =>
    io.bits := impl.io.read_data
    io.valid := impl.io.read_valid
    when(io.ready) {
      impl.io.read_select := offset.U(12.W)
    }
  }

  impl.io.read_ready := field_wire.foldLeft(false.B)((res, io) => res || io.ready)
  regmap(field_regmap:_*)
}

class MagicTL(params: MagicParams, beatBytes: Int)(implicit p: Parameters)
  extends TLRegisterRouter(
    params.address, "magic", Seq("zjv,starship,fuzz-magic"), beatBytes = beatBytes)(
      new TLRegBundle(params, _))(
      new TLRegModule(params, _, _) with MagicModule)

trait CanHavePeripheryMagic { this: BaseSubsystem =>
  private val portName = "magic"

  val magic = p(MagicKey) match {
    case Some(params) => {
        val magic = LazyModule(new MagicTL(params, pbus.beatBytes)(p))
        pbus.toVariableWidthSlave(Some(portName)) { magic.node }
        Some(magic)
    }
    case None => None
  }
}