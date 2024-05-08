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

(* keep *)
(* blackbox *)
module ProbeBufferBB(
    input clock,
    input reset,
    input [63:0] write,
    input wen,
    output [63:0] read
);

endmodule

(* keep *)
(* blackbox *)
(* pift_wire_instrumented *)
(* pift_cell_instrumented *)
(* pift_port_instrumented *)
(* pift_ignore_module *)
module ArchStepBB(
    input clock,
    input reset,
    input valid,
    input [63:0] pc,
    input [31:0] inst,
    input [63:0] data
);

endmodule

(* keep *)
(* blackbox *)
module MemMorpherBB(
  input clock,
  input reset,
  input valid,
  input [63:0] addr,
  output [255:0] data_in,
  output [255:0] data_out
);

endmodule
