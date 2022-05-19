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


`define CVA6_CPU_TOP  `SOC_TOP.tile_prci_domain.tile_reset_domain_cva6_tile
`define CVA6_PIPELINE `CVA6_CPU_TOP.core.i_ariane.i_cva6



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

            // `include "spike_difftest.rocket.v"
            `include "spike_difftest.cva6.v"

            tohost = cosim_finish();
        end
    end

    assign finish = tohost & 1'b1;

endmodule
