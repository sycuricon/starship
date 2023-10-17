package starship.playyard.diplomacy

import chisel3._
import chisel3.stage._
import chisel3.util.random._
import chisel3.internal.sourceinfo._
import freechips.rocketchip.diplomacy._
import org.chipsalliance.cde.config._

class Leaf(implicit p: Parameters) extends LazyModule {
  val input = BundleBridgeSink[Bool]()
  val output = BundleBridgeSource[Bool](() => Bool())

  lazy val module = new LazyModuleImp(this) {
    output.bundle := input.bundle
  }
}

class A(implicit p: Parameters) extends LazyModule {
  val b = LazyModule(new Leaf)
  val c = LazyModule(new Leaf)

  val input = b.input
  val output = c.output

  val bOutput = b.output.makeSink
  val cInput = BundleBridgeSource[Bool](() => Bool())
  c.input := cInput

  lazy val module = new LazyModuleImp(this) {
    cInput.bundle := bOutput.bundle
  }
}

class Foo(implicit p: Parameters) extends SimpleLazyModule {
  val bar = LazyModule(new A)

  val input = bar.input
  val output = bar.output
}

class demo2TestHarness(implicit p: Parameters) extends LazyModule {
  val a = LazyModule(new A)
  val foo = LazyModule(new Foo)

  val aInput = BundleBridgeSource[Bool](() => Bool())
  a.input := aInput

  val aOutput = a.output.makeSink

  val fooInput = BundleBridgeSource[Bool](() => Bool())
  foo.input := fooInput

  val fooOutput = foo.output.makeSink

  lazy val module = new LazyModuleImp(this) {
    aInput.makeIO
    fooOutput.makeIO
    fooInput.bundle := aOutput.bundle
  }

  override lazy val desiredName = "Top"
}

class LeafHarness(implicit p: Parameters) extends LazyModule {
  val leaf = LazyModule(new Leaf)

  val leafInput = BundleBridgeSource[Bool](() => Bool())
  leaf.input := leafInput

  val leafOutput = leaf.output.makeSink
  
  lazy val module = new LazyModuleImp(this) {
    leafInput.makeIO
    leafOutput.makeIO

    val op = IO {
      new Bundle {
        val in = Input(Bool())
      }
    }
  }

   override lazy val desiredName = "LeafTest"
}

object diplomacyDemo2 {
  def main(args: Array[String]) {
    val verilog = (new ChiselStage).emitVerilog(
      LazyModule(new LeafHarness()(Parameters.empty)).module,
      Array("-td", "build/playyard")
    )

    print(verilog)
  }
}