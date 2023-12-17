(* blackbox *)
(* pift_wire_instrumented *)
(* pift_cell_instrumented *)
(* pift_port_instrumented *)
(* pift_ignore_module *)
module MagicDeviceBlackbox (
  input clock,
  input reset,
  input [11:0] read_select,
  input read_ready,
  output read_valid,
  output [63:0] read_data
);

endmodule

(* blackbox *)
(* pift_wire_instrumented *)
(* pift_cell_instrumented *)
(* pift_port_instrumented *)
(* pift_ignore_module *)
module plusarg_reader #(
   parameter FORMAT="borked=%d",
   parameter WIDTH=1,
   parameter [WIDTH-1:0] DEFAULT=0
) (
   output [WIDTH-1:0] out
);

endmodule

(* blackbox *)
(* pift_wire_instrumented *)
(* pift_cell_instrumented *)
(* pift_port_instrumented *)
(* pift_ignore_module *)
module StarshipROM(
  input clock,
  input oe,
  input me,
  input [10:0] address,
  output [31:0] q
);

endmodule

// (* blackbox *)
// (* pift_wire_instrumented *)
// (* pift_cell_instrumented *)
// (* pift_port_instrumented *)
// (* pift_ignore_module *)
// module tag_array_ext(
//   input RW0_clk,
//   input [5:0] RW0_addr,
//   input RW0_en,
//   input RW0_wmode,
//   input [3:0] RW0_wmask,
//   input [87:0] RW0_wdata,
//   output [87:0] RW0_rdata
// );

// endmodule

// (* blackbox *)
// (* pift_wire_instrumented *)
// (* pift_cell_instrumented *)
// (* pift_port_instrumented *)
// (* pift_ignore_module *)
// module array_0_0_ext(
//   input W0_clk,
//   input [8:0] W0_addr,
//   input W0_en,
//   input [63:0] W0_data,
//   input [0:0] W0_mask,
//   input R0_clk,
//   input [8:0] R0_addr,
//   input R0_en,
//   output [63:0] R0_data
// );

// endmodule

// (* blackbox *)
// (* pift_wire_instrumented *)
// (* pift_cell_instrumented *)
// (* pift_port_instrumented *)
// (* pift_ignore_module *)
// module tag_array_0_ext(
//   input RW0_clk,
//   input [5:0] RW0_addr,
//   input RW0_en,
//   input RW0_wmode,
//   input [3:0] RW0_wmask,
//   input [79:0] RW0_wdata,
//   output [79:0] RW0_rdata
// );

// endmodule

// (* blackbox *)
// (* pift_wire_instrumented *)
// (* pift_cell_instrumented *)
// (* pift_port_instrumented *)
// (* pift_ignore_module *)
// module dataArrayWay_0_ext(
//   input RW0_clk,
//   input [8:0] RW0_addr,
//   input RW0_en,
//   input RW0_wmode,
//   input [63:0] RW0_wdata,
//   output [63:0] RW0_rdata
// );

// endmodule

// (* blackbox *)
// (* pift_wire_instrumented *)
// (* pift_cell_instrumented *)
// (* pift_port_instrumented *)
// (* pift_ignore_module *)
// module hi_us_ext(
//   input W0_clk,
//   input [6:0] W0_addr,
//   input W0_en,
//   input [3:0] W0_data,
//   input [3:0] W0_mask,
//   input R0_clk,
//   input [6:0] R0_addr,
//   input R0_en,
//   output [3:0] R0_data
// );

// endmodule

// (* blackbox *)
// (* pift_wire_instrumented *)
// (* pift_cell_instrumented *)
// (* pift_port_instrumented *)
// (* pift_ignore_module *)
// module table_ext(
//   input W0_clk,
//   input [6:0] W0_addr,
//   input W0_en,
//   input [43:0] W0_data,
//   input [3:0] W0_mask,
//   input R0_clk,
//   input [6:0] R0_addr,
//   input R0_en,
//   output [43:0] R0_data
// );

// endmodule

// (* blackbox *)
// (* pift_wire_instrumented *)
// (* pift_cell_instrumented *)
// (* pift_port_instrumented *)
// (* pift_ignore_module *)
// module hi_us_0_ext(
//   input W0_clk,
//   input [7:0] W0_addr,
//   input W0_en,
//   input [3:0] W0_data,
//   input [3:0] W0_mask,
//   input R0_clk,
//   input [7:0] R0_addr,
//   input R0_en,
//   output [3:0] R0_data
// );

// endmodule

// (* blackbox *)
// (* pift_wire_instrumented *)
// (* pift_cell_instrumented *)
// (* pift_port_instrumented *)
// (* pift_ignore_module *)
// (* pift_ignore_module *)
// module table_0_ext(
//   input W0_clk,
//   input [7:0] W0_addr,
//   input W0_en,
//   input [47:0] W0_data,
//   input [3:0] W0_mask,
//   input R0_clk,
//   input [7:0] R0_addr,
//   input R0_en,
//   output [47:0] R0_data
// );

// endmodule

// (* blackbox *)
// (* pift_wire_instrumented *)
// (* pift_cell_instrumented *)
// (* pift_port_instrumented *)
// (* pift_ignore_module *)
// module table_1_ext(
//   input W0_clk,
//   input [6:0] W0_addr,
//   input W0_en,
//   input [51:0] W0_data,
//   input [3:0] W0_mask,
//   input R0_clk,
//   input [6:0] R0_addr,
//   input R0_en,
//   output [51:0] R0_data
// );

// endmodule

// (* blackbox *)
// (* pift_wire_instrumented *)
// (* pift_cell_instrumented *)
// (* pift_port_instrumented *)
// (* pift_ignore_module *)
// module meta_0_ext(
//   input W0_clk,
//   input [6:0] W0_addr,
//   input W0_en,
//   input [123:0] W0_data,
//   input [3:0] W0_mask,
//   input R0_clk,
//   input [6:0] R0_addr,
//   input R0_en,
//   output [123:0] R0_data
// );

// endmodule

// (* blackbox *)
// (* pift_wire_instrumented *)
// (* pift_cell_instrumented *)
// (* pift_port_instrumented *)
// (* pift_ignore_module *)
// module btb_0_ext(
//   input W0_clk,
//   input [6:0] W0_addr,
//   input W0_en,
//   input [55:0] W0_data,
//   input [3:0] W0_mask,
//   input R0_clk,
//   input [6:0] R0_addr,
//   input R0_en,
//   output [55:0] R0_data
// );

// endmodule

// (* blackbox *)
// (* pift_wire_instrumented *)
// (* pift_cell_instrumented *)
// (* pift_port_instrumented *)
// (* pift_ignore_module *)
// module ebtb_ext(
//   input W0_clk,
//   input [6:0] W0_addr,
//   input W0_en,
//   input [39:0] W0_data,
//   input R0_clk,
//   input [6:0] R0_addr,
//   input R0_en,
//   output [39:0] R0_data
// );

// endmodule

// (* blackbox *)
// (* pift_wire_instrumented *)
// (* pift_cell_instrumented *)
// (* pift_port_instrumented *)
// (* pift_ignore_module *)
// module data_ext(
//   input W0_clk,
//   input [10:0] W0_addr,
//   input W0_en,
//   input [7:0] W0_data,
//   input [3:0] W0_mask,
//   input R0_clk,
//   input [10:0] R0_addr,
//   input R0_en,
//   output [7:0] R0_data
// );

// endmodule

// (* blackbox *)
// (* pift_wire_instrumented *)
// (* pift_cell_instrumented *)
// (* pift_port_instrumented *)
// (* pift_ignore_module *)
// module meta_ext(
//   input W0_clk,
//   input [3:0] W0_addr,
//   input W0_en,
//   input [119:0] W0_data,
//   input R0_clk,
//   input [3:0] R0_addr,
//   input R0_en,
//   output [119:0] R0_data
// );

// endmodule

// (* blackbox *)
// (* pift_wire_instrumented *)
// (* pift_cell_instrumented *)
// (* pift_port_instrumented *)
// (* pift_ignore_module *)
// module ghist_0_ext(
//   input W0_clk,
//   input [3:0] W0_addr,
//   input W0_en,
//   input [71:0] W0_data,
//   input R0_clk,
//   input [3:0] R0_addr,
//   input R0_en,
//   output [71:0] R0_data
// );

// endmodule

// (* blackbox *)
// (* pift_wire_instrumented *)
// (* pift_cell_instrumented *)
// (* pift_port_instrumented *)
// (* pift_ignore_module *)
// module rob_debug_inst_mem_ext(
//   input W0_clk,
//   input [4:0] W0_addr,
//   input W0_en,
//   input [31:0] W0_data,
//   input [0:0] W0_mask,
//   input R0_clk,
//   input [4:0] R0_addr,
//   input R0_en,
//   output [31:0] R0_data
// );

// endmodule

// (* blackbox *)
// (* pift_wire_instrumented *)
// (* pift_cell_instrumented *)
// (* pift_port_instrumented *)
// (* pift_ignore_module *)
// module l2_tlb_ram_ext(
//   input RW0_clk,
//   input [8:0] RW0_addr,
//   input RW0_en,
//   input RW0_wmode,
//   input [44:0] RW0_wdata,
//   output [44:0] RW0_rdata
// );

// endmodule


(* blackbox *)
(* pift_wire_instrumented *)
(* pift_cell_instrumented *)
(* pift_port_instrumented *)
(* pift_ignore_module *)
module ProbeBufferBB(
    input clock,
    input reset,
    input [63:0] write,
    input wen,
    output [63:0] read
);

endmodule
