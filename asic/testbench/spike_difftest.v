import "DPI-C" function int cosim_commit (
    input int unsigned hartid, 
    input longint unsigned dut_pc, 
    input int unsigned dut_insn
);

import "DPI-C" function int cosim_judge (
    input int unsigned hartid, 
    input string which,
    input int unsigned dut_waddr, 
    input longint unsigned dut_wdata
);
import "DPI-C" function void cosim_raise_trap (
    input int unsigned hartid, 
    input longint unsigned cause
);

import "DPI-C" function void cosim_init(
    input string testcase,
    input reg verbose
);

import "DPI-C" function longint cosim_finish();

module CJ #(parameter harts=1, commits=2) (
    input clock,
    input reset,
    output finish
);
    string testcase;
    reg verbose = 1'b0;
    reg [63:0] tohost;

    initial begin
        if (!$value$plusargs("testcase=%s", testcase)) begin
            $write("%c[1;31m",27);
            $display("At least one testcase is required for CJ");
            $write("%c[0m",27);
            $fatal;
        end
        verbose = $test$plusargs("verbose");
        cosim_init(testcase, verbose);
    end

    always @(posedge clock) begin
        if (!reset) begin

            `include "spike_difftest.rocket.v"
            // `include "spike_difftest.cva6.v"
            // `include "spike_difftest.boom.v"

            tohost = cosim_finish();
        end
    end

    assign finish = tohost & 1'b1;

endmodule



import "DPI-C" function longint unsigned cosim_randomizer_insn (
    input longint unsigned in,
    input longint unsigned pc
);

module MCBlackbox (
  input en,
  input [63:0] in,
  input [63:0] pc,
  output [63:0] out
);
  reg [63:0] insn_back;

  always @(*) begin
    if (en)
      insn_back = cosim_randomizer_insn(in, pc);
  end
  
  assign out = insn_back;

endmodule

import "DPI-C" function longint unsigned cosim_randomizer_data (
    input int unsigned read_select
);

module MagicBlackbox (
  input clock,
  input reset,
  input [4:0] read_select,
  input read_ready,
  output read_valid,
  output [63:0] read_data
);
  reg [63:0] data_back;

   always @(negedge clock) begin
      if (!reset) begin
        if (read_valid && read_ready)
          data_back = cosim_randomizer_data(read_select);
      end
   end
  
  assign read_valid = 1'b1;
  assign read_data = data_back;

endmodule