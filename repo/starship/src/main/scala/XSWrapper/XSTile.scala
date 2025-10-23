package starship.xiangshan

import chisel3._
import chisel3.util._
import chisel3.experimental.{IntParam, StringParam}

import scala.collection.mutable.{ListBuffer}

import org.chipsalliance.cde.config._
import freechips.rocketchip.subsystem._
import freechips.rocketchip.devices.tilelink._
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.rocket._
import freechips.rocketchip.subsystem.{RocketCrossingParams}
import freechips.rocketchip.tilelink._
import freechips.rocketchip.interrupts._
import freechips.rocketchip.util._
import freechips.rocketchip.tile._
import freechips.rocketchip.amba.axi4._
import freechips.rocketchip.prci._

case class XSCoreParams(
    xLen: Int = 64,
    bootFreqHz: BigInt = BigInt(1_000_000_000),
) extends CoreParams {
  val useVM: Boolean = true
  val useHypervisor: Boolean = false
  val useUser: Boolean = true
  val useSupervisor: Boolean = true
  val useDebug: Boolean = true
  val useAtomics: Boolean = true
  val useAtomicsOnlyForIO: Boolean = false
  val useCompressed: Boolean = true
  val useBitManip: Boolean = false
  val useBitManipCrypto: Boolean = false
  // val useVector: Boolean = false
  val useCryptoNIST: Boolean = false
  val useCryptoSM: Boolean = false
  val useRVE: Boolean = false
  val useConditionalZero: Boolean = false
  val mulDiv: Option[MulDivParams] = Some(MulDivParams())
  val fpu: Option[FPUParams] = Some(FPUParams())
  val fetchWidth: Int = 4
  val decodeWidth: Int = 2
  val retireWidth: Int = 2
  val instBits: Int = if (useCompressed) 16 else 32
  val nLocalInterrupts: Int = 0
  val useNMI: Boolean = false
  val nPMPs: Int = 8
  val pmpGranularity: Int = 4
  val nBreakpoints: Int = 0
  val useBPWatch: Boolean = false
  val mcontextWidth: Int = 0
  val scontextWidth: Int = 0
  val nPerfCounters: Int = 0
  val haveBasicCounters: Boolean = true
  val haveFSDirty: Boolean = true
  val misaWritable: Boolean = false
  val haveCFlush: Boolean = false
  val nL2TLBEntries: Int = 4
  val nL2TLBWays: Int = 4
  val nPTECacheEntries: Int = 4
  val mtvecInit: Option[BigInt] = Some(BigInt(0))
  val mtvecWritable: Boolean = true
  val traceHasWdata: Boolean = false
  val lrscCycles: Int = 64
  val useZba: Boolean = false
  val useZbb: Boolean = false
  val useZbs: Boolean = false
  val pgLevels = 4
}

case class XSTileAttachParams(
  tileParams: XSTileParams,
  crossingParams: RocketCrossingParams
) extends CanAttachTile {
  type TileType = XSTile
  val lookup = PriorityMuxHartIdFromSeq(Seq(tileParams))
}

case class XSTileParams(
  core: XSCoreParams = XSCoreParams(),
  name: Option[String] = Some("xiangshan_tile"),
  tileId: Int = 0,
  tlSizeWidth: Int = 3,
  tlAddrWidth: Int = 36,
  tlMemDataWidth: Int = 256,
  tlMemSourceWidth: Int = 9,
  tlMemSinkWidth: Int = 4,
  tlMMIODataWidth: Int = 64,
  tlMMIOSourceWidth: Int = 3,
  tlMMIOSinkWidth: Int = 1,
) extends InstantiableTileParams[XSTile]
{
  val icache: Option[ICacheParams] = None
  val dcache: Option[DCacheParams] = None
  val btb: Option[BTBParams] = None
  val beuAddr: Option[BigInt] = None
  val blockerCtrlAddr: Option[BigInt] = None
  val boundaryBuffers: Boolean = false
  val clockSinkParams: ClockSinkParameters = ClockSinkParameters()

  def instantiate(crossing: HierarchicalElementCrossingParamsLike, lookup: LookupByHartIdImpl)(implicit p: Parameters): XSTile = {
    new XSTile(this, crossing, lookup)
  }
  val baseName = name.getOrElse("ibex_tile")
  val uniqueName = s"${baseName}_$tileId"
}

// case object DirtyKey extends ControlKey[Bool](name = "blockisdirty")
// case class DirtyField() extends BundleField[Bool](DirtyKey, Output(Bool()), _ := false.B)

class XSTile private(
  val xsParams: XSTileParams,
  crossing: ClockCrossingType,
  lookup: LookupByHartIdImpl,
  q: Parameters)
  extends BaseTile(xsParams, crossing, lookup, q)
  with SinksExternalInterrupts
  with SourcesExternalNotifications {

  def this(params: XSTileParams, crossing: HierarchicalElementCrossingParamsLike, lookup: LookupByHartIdImpl)(implicit p: Parameters) =
    this(params, crossing.crossingType, lookup, p)

  val intOutwardNode = Some(IntIdentityNode())
  val masterNode = visibilityNode
  val slaveNode = TLIdentityNode()

  tlOtherMastersNode := tlMasterXbar.node
  masterNode :=* tlOtherMastersNode
  DisableMonitors { implicit p => tlSlaveXbar.node :*= slaveNode }

  val cpuDevice: SimpleDevice = new SimpleDevice("cpu", Seq("sycuricon,xiangshan", "riscv")) {
    override def parent = Some(ResourceAnchors.cpus)
    override def describe(resources: ResourceBindings): Description = {
      val Description(name, mapping) = super.describe(resources)
      Description(name, mapping ++
                        cpuProperties ++
                        nextLevelCacheProperty ++
                        tileProperties)
    }
  }

  ResourceBinding {
    Resource(cpuDevice, "reg").bind(ResourceAddress(tileId))
  }

  val mem_node = TLClientNode(
    Seq(TLMasterPortParameters.v1(
      clients = Seq(TLMasterParameters.v1(
        name = "xs_mem_port",
        sourceId = IdRange(0, 1 << xsParams.tlMemSourceWidth),
        supportsProbe = TransferSizes(64)
      )),
      // echoFields = Seq(DirtyField())
    )))

  val mmio_node = TLClientNode(
    Seq(TLMasterPortParameters.v1(
      clients = Seq(TLMasterParameters.v1(
        name = "xs_mmio_port",
        sourceId = IdRange(0, 1 << xsParams.tlMMIOSourceWidth)))
    )))

  tlMasterXbar.node := mem_node
  tlMasterXbar.node := mmio_node

  def connectXSInterrupts(debug_0: Bool, clint_0: Bool, clint_1: Bool, plic_0: Bool, plic_1: Bool) {
    val (interrupts, _) = intSinkNode.in(0)
    debug_0 := interrupts(0)
    clint_0 := interrupts(1)
    clint_1 := interrupts(2)
    plic_0  := interrupts(3)
    plic_1  := interrupts(4)
  }

  override lazy val module = new XSTileModuleImp(this)
}

class XSTileModuleImp(outer: XSTile) extends BaseTileModuleImp(outer) {
  val core = Module(new XS_XSTile)
  core.io.clock := clock
  core.io.reset := reset
  core.io.io_hartId := outer.hartIdSinkNode.bundle
  core.io.io_reset_vector := BigInt(0x80000000L).U

  val (mem, _) = outer.mem_node.out(0)
  // A channel
  core.io.auto_l2top_memory_port_out_a_ready := mem.a.ready
  mem.a.valid := core.io.auto_l2top_memory_port_out_a_valid
  mem.a.bits.opcode := core.io.auto_l2top_memory_port_out_a_bits_opcode
  mem.a.bits.param := core.io.auto_l2top_memory_port_out_a_bits_param
  mem.a.bits.size := core.io.auto_l2top_memory_port_out_a_bits_size
  mem.a.bits.source := core.io.auto_l2top_memory_port_out_a_bits_source
  mem.a.bits.address := core.io.auto_l2top_memory_port_out_a_bits_address
  // mem.a.bits.echo(DirtyKey) := core.io.auto_l2top_memory_port_out_a_bits_echo_blockisdirty
  mem.a.bits.mask := core.io.auto_l2top_memory_port_out_a_bits_mask
  mem.a.bits.data := core.io.auto_l2top_memory_port_out_a_bits_data
  // mem.a.bits.corrupt := core.io.auto_l2top_memory_port_out_a_bits_corrupt
  
  // B channel
  mem.b.ready := core.io.auto_l2top_memory_port_out_bready
  core.io.auto_l2top_memory_port_out_bvalid := mem.b.valid
  core.io.auto_l2top_memory_port_out_bopcode := mem.b.bits.opcode
  core.io.auto_l2top_memory_port_out_bparam := mem.b.bits.param
  core.io.auto_l2top_memory_port_out_bsize := mem.b.bits.size
  core.io.auto_l2top_memory_port_out_baddress := mem.b.bits.address
  core.io.auto_l2top_memory_port_out_bmask := mem.b.bits.mask
  core.io.auto_l2top_memory_port_out_bdata := mem.b.bits.data
  core.io.auto_l2top_memory_port_out_bcorrupt := mem.b.bits.corrupt

  // C channel
   core.io.auto_l2top_memory_port_out_c_ready := mem.c.ready
  mem.c.valid := core.io.auto_l2top_memory_port_out_c_valid
  mem.c.bits.opcode := core.io.auto_l2top_memory_port_out_c_bits_opcode
  mem.c.bits.param := core.io.auto_l2top_memory_port_out_c_bits_param
  mem.c.bits.size := core.io.auto_l2top_memory_port_out_c_bits_size
  mem.c.bits.source := core.io.auto_l2top_memory_port_out_c_bits_source
  mem.c.bits.address := core.io.auto_l2top_memory_port_out_c_bits_address
  // mem.c.bits.echo(DirtyKey) := core.io.auto_l2top_memory_port_out_c_bits_echo_blockisdirty
  mem.c.bits.data := core.io.auto_l2top_memory_port_out_c_bits_data
  // mem.c.bits.corrupt := core.io.auto_l2top_memory_port_out_c_bits_corrupt

  // D channel
  mem.d.ready := core.io.auto_l2top_memory_port_out_d_ready
  core.io.auto_l2top_memory_port_out_d_valid := mem.d.valid
  core.io.auto_l2top_memory_port_out_d_bits_opcode := mem.d.bits.opcode
  core.io.auto_l2top_memory_port_out_d_bits_param := mem.d.bits.param
  core.io.auto_l2top_memory_port_out_d_bits_size := mem.d.bits.size
  core.io.auto_l2top_memory_port_out_d_bits_source := mem.d.bits.source
  core.io.auto_l2top_memory_port_out_d_bits_sink := mem.d.bits.sink
  core.io.auto_l2top_memory_port_out_d_bits_denied := mem.d.bits.denied
  // core.io.auto_l2top_memory_port_out_d_bits_echo_blockisdirty := mem.d.bits.echo(DirtyKey)
    core.io.auto_l2top_memory_port_out_d_bits_echo_blockisdirty := false.B
  core.io.auto_l2top_memory_port_out_d_bits_data := mem.d.bits.data
  core.io.auto_l2top_memory_port_out_d_bits_corrupt := mem.d.bits.corrupt

  // E channel
   core.io.auto_l2top_memory_port_out_e_ready := mem.e.ready
  mem.e.valid := core.io.auto_l2top_memory_port_out_e_valid
  mem.e.bits.sink := core.io.auto_l2top_memory_port_out_e_bits_sink

  val (mmio, _) = outer.mmio_node.out(0)
  
  // A channel
  core.io.auto_l2top_mmio_port_out_a_ready := mmio.a.ready
  mmio.a.valid := core.io.auto_l2top_mmio_port_out_a_valid
  mmio.a.bits.opcode := core.io.auto_l2top_mmio_port_out_a_bits_opcode
  // mmio.a.bits.param := core.io.auto_l2top_mmio_port_out_a_bits_param
  mmio.a.bits.size := core.io.auto_l2top_mmio_port_out_a_bits_size
  mmio.a.bits.source := core.io.auto_l2top_mmio_port_out_a_bits_source
  mmio.a.bits.address := core.io.auto_l2top_mmio_port_out_a_bits_address
  mmio.a.bits.mask := core.io.auto_l2top_mmio_port_out_a_bits_mask
  mmio.a.bits.data := core.io.auto_l2top_mmio_port_out_a_bits_data
  // mmio.a.bits.corrupt := core.io.auto_l2top_mmio_port_out_a_bits_corrupt

  // D channel
  mmio.d.ready := core.io.auto_l2top_mmio_port_out_d_ready
  core.io.auto_l2top_mmio_port_out_d_valid := mmio.d.valid

  core.io.auto_l2top_mmio_port_out_d_bits_opcode := mmio.d.bits.opcode
  // core.io.auto_l2top_mmio_port_out_d_bits_param := mmio.d.bits.param
  core.io.auto_l2top_mmio_port_out_d_bits_size := mmio.d.bits.size
  core.io.auto_l2top_mmio_port_out_d_bits_source := mmio.d.bits.source
  // core.io.auto_l2top_mmio_port_out_d_bits_sink := mmio.d.bits.sink
  // core.io.auto_l2top_mmio_port_out_d_bits_denied := mmio.d.bits.denied
  core.io.auto_l2top_mmio_port_out_d_bits_data := mmio.d.bits.data
  // core.io.auto_l2top_mmio_port_out_d_bits_corrupt := mmio.d.bits.corrupt

  outer.connectXSInterrupts(
    core.io.auto_l2top_debug_int_in_0, 
    core.io.auto_l2top_clint_int_in_0, 
    core.io.auto_l2top_clint_int_in_1,
    core.io.auto_l2top_plic_int_in_1_0, 
    core.io.auto_l2top_plic_int_in_0_0,
  )
}
