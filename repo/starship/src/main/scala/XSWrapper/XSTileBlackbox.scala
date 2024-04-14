package starship.xiangshan

import chisel3._
import chisel3.util._

// make verilog CONFIG=MinimalConfig MFC=1 WITH_CONSTANTIN=0 NO_ZSTD_COMPRESSION=1 IMAGE_GZ_COMPRESS=0 WITH_CHISELDB=0 EMU_TRACE=vcd NO_DIFF=1 XSTOP_PREFIX=XS_ RELEASE=1

class XS_XSTile(
  tlSizeWidth: Int = 3,
  tlAddrWidth: Int = 36,
  tlMemDataWidth: Int = 256,
  tlMemSourceWidth: Int = 9,
  tlMemSinkWidth: Int = 4,
  tlMMIODataWidth: Int = 64,
  tlMMIOSourceWidth: Int = 3,
  tlMMIOSinkWidth: Int = 1,
) extends BlackBox with HasBlackBoxPath {
  val io = IO(new Bundle {
    // clock and reset
    val clock = Input(Clock())
    val reset = Input(Bool())
    
    // design specific
    val io_hartId = Input(UInt(64.W))
    val io_reset_vector = Input(UInt(tlAddrWidth.W))
    val io_cpu_halt = Output(Bool())

    // interrupt
    val auto_l2top_beu_int_out_0 = Output(Bool())
    val auto_l2top_plic_int_in_1_0 = Input(Bool())
    val auto_l2top_plic_int_in_0_0 = Input(Bool())
    val auto_l2top_debug_int_in_0 = Input(Bool())
    val auto_l2top_clint_int_in_0 = Input(Bool())
    val auto_l2top_clint_int_in_1 = Input(Bool())

    // mmio A channel
    val auto_l2top_mmio_port_out_a_ready = Input(Bool())
    val auto_l2top_mmio_port_out_a_valid = Output(Bool())
    val auto_l2top_mmio_port_out_a_bits_opcode = Output(UInt(3.W))
    val auto_l2top_mmio_port_out_a_bits_param = Output(UInt(3.W))
    val auto_l2top_mmio_port_out_a_bits_size = Output(UInt(tlSizeWidth.W))
    val auto_l2top_mmio_port_out_a_bits_source = Output(UInt(tlMMIOSourceWidth.W))
    val auto_l2top_mmio_port_out_a_bits_address = Output(UInt(tlAddrWidth.W))
    val auto_l2top_mmio_port_out_a_bits_mask = Output(UInt((tlMMIODataWidth/8).W))
    val auto_l2top_mmio_port_out_a_bits_data = Output(UInt(tlMMIODataWidth.W))
    val auto_l2top_mmio_port_out_a_bits_corrupt = Output(Bool())

    // mmio D channel
    val auto_l2top_mmio_port_out_d_ready = Output(Bool())
    val auto_l2top_mmio_port_out_d_valid = Input(Bool())
    val auto_l2top_mmio_port_out_d_bits_opcode = Input(UInt(3.W))
    val auto_l2top_mmio_port_out_d_bits_param = Input(UInt(2.W))
    val auto_l2top_mmio_port_out_d_bits_size = Input(UInt(tlSizeWidth.W))
    val auto_l2top_mmio_port_out_d_bits_source = Input(UInt(tlMMIOSourceWidth.W))
    val auto_l2top_mmio_port_out_d_bits_sink = Input(UInt(tlMMIOSinkWidth.W))
    val auto_l2top_mmio_port_out_d_bits_denied = Input(Bool())
    val auto_l2top_mmio_port_out_d_bits_data = Input(UInt(tlMMIODataWidth.W))
    val auto_l2top_mmio_port_out_d_bits_corrupt = Input(Bool())

    // memory A channel
    val auto_l2top_memory_port_out_a_ready = Input(Bool())
    val auto_l2top_memory_port_out_a_valid = Output(Bool())
    val auto_l2top_memory_port_out_a_bits_opcode = Output(UInt(3.W))
    val auto_l2top_memory_port_out_a_bits_param = Output(UInt(3.W))
    val auto_l2top_memory_port_out_a_bits_size = Output(UInt(tlSizeWidth.W))
    val auto_l2top_memory_port_out_a_bits_source = Output(UInt(tlMemSourceWidth.W))
    val auto_l2top_memory_port_out_a_bits_address = Output(UInt(tlAddrWidth.W))
    val auto_l2top_memory_port_out_a_bits_echo_blockisdirty = Output(Bool())
    val auto_l2top_memory_port_out_a_bits_mask = Output(UInt((tlMemDataWidth/8).W))
    val auto_l2top_memory_port_out_a_bits_data = Output(UInt(tlMemDataWidth.W))
    val auto_l2top_memory_port_out_a_bits_corrupt = Output(Bool())

    // memory B channel
    val auto_l2top_memory_port_out_bready = Output(Bool())
    val auto_l2top_memory_port_out_bvalid = Input(Bool())
    val auto_l2top_memory_port_out_bopcode = Input(UInt(3.W))
    val auto_l2top_memory_port_out_bparam = Input(UInt(3.W))  // 2?
    val auto_l2top_memory_port_out_bsize = Input(UInt(tlSizeWidth.W))
    val auto_l2top_memory_port_out_baddress = Input(UInt(tlAddrWidth.W))
    val auto_l2top_memory_port_out_bmask = Input(UInt((tlMemDataWidth/8).W))
    val auto_l2top_memory_port_out_bdata = Input(UInt(tlMemDataWidth.W))
    val auto_l2top_memory_port_out_bcorrupt = Input(Bool())

    // memory C channel
    val auto_l2top_memory_port_out_c_ready = Input(Bool())
    val auto_l2top_memory_port_out_c_valid = Output(Bool())
    val auto_l2top_memory_port_out_c_bits_opcode = Output(UInt(3.W))
    val auto_l2top_memory_port_out_c_bits_param = Output(UInt(3.W))
    val auto_l2top_memory_port_out_c_bits_size = Output(UInt(tlSizeWidth.W))
    val auto_l2top_memory_port_out_c_bits_source = Output(UInt(tlMemSourceWidth.W))
    val auto_l2top_memory_port_out_c_bits_address = Output(UInt(tlAddrWidth.W))
    val auto_l2top_memory_port_out_c_bits_echo_blockisdirty = Output(Bool())
    val auto_l2top_memory_port_out_c_bits_data = Output(UInt(tlMemDataWidth.W))
    val auto_l2top_memory_port_out_c_bits_corrupt = Output(Bool())

    // memory D channel
    val auto_l2top_memory_port_out_d_ready = Output(Bool())
    val auto_l2top_memory_port_out_d_valid = Input(Bool())
    val auto_l2top_memory_port_out_d_bits_opcode = Input(UInt(3.W))
    val auto_l2top_memory_port_out_d_bits_param = Input(UInt(2.W))
    val auto_l2top_memory_port_out_d_bits_size = Input(UInt(tlSizeWidth.W))
    val auto_l2top_memory_port_out_d_bits_source = Input(UInt(tlMemSourceWidth.W))
    val auto_l2top_memory_port_out_d_bits_sink = Input(UInt(tlMemSinkWidth.W))
    val auto_l2top_memory_port_out_d_bits_denied = Input(Bool())
    val auto_l2top_memory_port_out_d_bits_echo_blockisdirty = Input(Bool())
    val auto_l2top_memory_port_out_d_bits_data = Input(UInt(tlMemDataWidth.W))
    val auto_l2top_memory_port_out_d_bits_corrupt = Input(Bool())

    // memory E channel
    val auto_l2top_memory_port_out_e_ready = Input(Bool())
    val auto_l2top_memory_port_out_e_valid = Output(Bool())
    val auto_l2top_memory_port_out_e_bits_sink = Output(UInt(tlMemSinkWidth.W))
  })

  val root = System.getProperty("user.dir")
  addPath(s"$root/repo/starship/src/main/resources/vsrc/XSList.f")
}
