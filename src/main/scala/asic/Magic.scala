package starship.asic

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

class MagicBlackbox(val w: Int) extends BlackBox {
    val io = IO(new MagicIO(w))
}

trait MagicModule extends HasRegMap {
  implicit val p: Parameters
  def params: MagicParams
  val clock: Clock
  val reset: Reset

  val random          = Wire(new DecoupledIO(UInt(params.width.W)))
  val rdm_word        = Wire(new DecoupledIO(UInt(params.width.W)))
  val rdm_float       = Wire(new DecoupledIO(UInt(params.width.W)))
  val rdm_double      = Wire(new DecoupledIO(UInt(params.width.W)))
  val rdm_fuzz_addr   = Wire(new DecoupledIO(UInt(params.width.W)))
  val next_fuzz_addr  = Wire(new DecoupledIO(UInt(params.width.W)))

  val impl = Module(new MagicBlackbox(params.width))

  impl.io.clock := clock
  impl.io.reset := reset.asBool

  random.bits := impl.io.read_data
  rdm_word.bits := impl.io.read_data
  rdm_float.bits := impl.io.read_data
  rdm_double.bits := impl.io.read_data
  rdm_fuzz_addr.bits := impl.io.read_data
  next_fuzz_addr.bits := impl.io.read_data

  random.valid := impl.io.read_valid
  rdm_word.valid := impl.io.read_valid
  rdm_float.valid := impl.io.read_valid
  rdm_double.valid := impl.io.read_valid
  rdm_fuzz_addr.valid := impl.io.read_valid 
  next_fuzz_addr.valid := impl.io.read_valid

  impl.io.read_select:= Cat(random.ready, rdm_word.ready, rdm_float.ready, rdm_double.ready, rdm_fuzz_addr.ready, next_fuzz_addr.ready)
  impl.io.read_ready := random.ready || rdm_word.ready || rdm_float.ready || rdm_double.ready || rdm_fuzz_addr.ready || next_fuzz_addr.ready

  val lut = Map(
    "random" -> 0x00,
    "rdm_word" -> 0x08,
    "rdm_float" -> 0x10,
    "rdm_double" -> 0x18,
    "rdm_addr" -> 0x20,
    "is_mepc_in_fuzz" -> 0x28)
  regmap(
    0x00    -> Seq(RegField.r(params.width, random)),
    0x08    -> Seq(RegField.r(params.width, rdm_word)),
    0x10    -> Seq(RegField.r(params.width, rdm_float)),
    0x18    -> Seq(RegField.r(params.width, rdm_double)),
    0x20    -> Seq(RegField.r(params.width, rdm_fuzz_addr)),
    0x28    -> Seq(RegField.r(params.width, next_fuzz_addr))
  )
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