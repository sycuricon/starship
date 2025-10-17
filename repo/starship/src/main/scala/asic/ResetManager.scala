package starship.asic

import chisel3._
import chisel3.util._
import freechips.rocketchip.util._
import org.chipsalliance.cde.config._
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.regmapper._
import freechips.rocketchip.tilelink._
import freechips.rocketchip.subsystem._

 
case class ResetManagerParams(
  baseAddress: BigInt = 0x4000,
  width: Int = 64) {
  def address = AddressSet(baseAddress, 0xFFF)
}

case object ResetManagerKey extends Field[Option[ResetManagerParams]](None)

case class ResetManagerAttachParams(
  slaveWhere: TLBusWrapperLocation = CBUS
)

case object ResetManagerAttachKey extends Field(ResetManagerAttachParams())

class ResetManagerIO() extends Bundle {
  val reset_out = Output(Bool())
  val reset_in = Input(Reset())
}

class ResetManager(params: ResetManagerParams, beatBytes: Int)(implicit p: Parameters)
  extends LazyModule {
  
  val device = new SimpleDevice("reset_manager", Seq("sycuricon,risc-free,reset-manager"))

  val node: TLRegisterNode = TLRegisterNode(
    address   = Seq(params.address),
    device    = device,
    beatBytes = beatBytes)

  val ioNode = BundleBridgeSource(() => new ResetManagerIO().cloneType)

  lazy val module = new Imp
  class Imp extends LazyModuleImp(this) {
    Annotated.params(this, params)

    val field_name = List("state", "counter")
    val field_offset = field_name.zipWithIndex.map(_._2 * params.width / 8)

    val reg_state = withReset(ioNode.bundle.reset_in) { RegInit(0.U(params.width.W)) }
    val reg_counter = withReset(ioNode.bundle.reset_in) { RegInit(0.U(params.width.W)) }
    def read_counter(ready: Bool): (Bool, UInt) = {
      (true.B, reg_counter)
    }
    def write_counter(valid: Bool, bits: UInt): Bool = {
      when (valid) { reg_counter := bits }
      true.B
    }
    reg_counter := Mux(reg_counter === 0.U, 0.U, reg_counter - 1.U)
    ioNode.bundle.reset_out := reg_counter =/= 0.U

    node.regmap(
      field_offset(0) -> Seq(RegField(params.width, reg_state)),
      field_offset(1) -> Seq(RegField(params.width, read_counter(_), write_counter(_, _)))
    )
  }
}

trait CanHavePeripheryResetManager { this: BaseSubsystem =>
  val reset_ctrls = p(ResetManagerKey).map { params =>
    val tlbus = locateTLBusWrapper(p(ResetManagerAttachKey).slaveWhere)
    val lreset_manage = LazyModule(new ResetManager(params, cbus.beatBytes))
    tlbus.coupleTo("reset-manager") { lreset_manage.node := TLFragmenter(tlbus) := _ }
    lreset_manage
  }

  val reset_ionodes = reset_ctrls.map(_.ioNode.makeSink())
}

trait CanHavePeripheryResetManagerImp extends LazyModuleImp {
  val outer: CanHavePeripheryResetManager
  val reset_manager = outer.reset_ionodes.map { _.makeIO() }
}
