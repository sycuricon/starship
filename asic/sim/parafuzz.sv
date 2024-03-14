import "DPI-C" function void parafuzz_probebuff_tick (longint unsigned data);
import "DPI-C" function byte is_variant_hierachy(string hierarchy);

module ProbeBufferBB (
    input clock,
    input reset,
    input [63:0] write,
    input wen,
    output [63:0] read
);

   always @(negedge clock) begin
        if (!reset) begin
            if (wen && !is_variant_hierachy($sformatf("%m"))) begin
                parafuzz_probebuff_tick(write);
            end
        end
   end

  assign read = 0;

endmodule

module SyncMonitor (
    input clock,
    input reset
);

    `define DUT_ROB_ENQ_ENABLE Testbench.testHarness.ldut.tile_prci_domain.tile_reset_domain_boom_tile.core.rob.io_enq_valids_0
    `define DUT_ROB_ENQ_INST   Testbench.testHarness.ldut.tile_prci_domain.tile_reset_domain_boom_tile.core.rob.io_enq_uops_0_debug_inst
    `define VNT_ROB_ENQ_ENABLE Testbench.testHarness_variant.ldut.tile_prci_domain.tile_reset_domain_boom_tile.core.rob.io_enq_valids_0
    `define VNT_ROB_ENQ_INST   Testbench.testHarness_variant.ldut.tile_prci_domain.tile_reset_domain_boom_tile.core.rob.io_enq_uops_0_debug_inst

    `define DUT_ROB_DEQ_ENABLE Testbench.testHarness.ldut.tile_prci_domain.tile_reset_domain_boom_tile.core.rob.io_commit_valids_0
    `define DUT_ROB_DEQ_INST   Testbench.testHarness.ldut.tile_prci_domain.tile_reset_domain_boom_tile.core.rob.io_commit_uops_0_debug_inst
    `define VNT_ROB_DEQ_ENABLE Testbench.testHarness_variant.ldut.tile_prci_domain.tile_reset_domain_boom_tile.core.rob.io_commit_valids_0
    `define VNT_ROB_DEQ_INST   Testbench.testHarness_variant.ldut.tile_prci_domain.tile_reset_domain_boom_tile.core.rob.io_commit_uops_0_debug_inst

    reg dut_done = 0;
    reg vnt_done = 0;
    reg sync = 1'b1;

    always @(posedge clock) begin
        if (reset) begin
            sync <= 1'b1;
        end else begin
            if (`DUT_ROB_ENQ_ENABLE != `VNT_ROB_ENQ_ENABLE) begin
                sync <= 1'b0;
            end else begin
                if (`DUT_ROB_ENQ_INST != `VNT_ROB_ENQ_INST) begin
                    sync <= 1'b0;
                end
            end
        end
    end

    always @(negedge clock) begin
        if (reset) begin
            dut_done <= 0;
            vnt_done <= 0;
        end

        if (!sync) begin
            if (`DUT_ROB_DEQ_ENABLE) begin
                if (`DUT_ROB_DEQ_INST == 32'h00302013) begin
                    dut_done <= 1;
                end
            end
            if (`VNT_ROB_DEQ_ENABLE) begin
                if (`VNT_ROB_DEQ_INST == 32'h00302013) begin
                    vnt_done <= 1;
                end
            end        
        end
    end
endmodule
