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

module CJ #(parameter harts=1) (
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
            // $display("\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
            if (`PIPELINE.wb_valid) begin
                if (cosim_commit(0, $signed(`PIPELINE.csr_io_trace_0_iaddr), `PIPELINE.csr_io_trace_0_insn) != 0) begin
                    $display("[CJ] Commit Failed");
                    #100 $fatal;
                end
            end
            
            if (`PIPELINE.wb_wen && !`PIPELINE.wb_set_sboard) begin
                if (cosim_judge(0, "int", `PIPELINE.rf_waddr, `PIPELINE.rf_wdata) != 0) begin
                    $display("[CJ] integer register Judge Failed");
                    #100 $fatal;
                end
            end

            if (`PIPELINE.ll_wen) begin
                if (cosim_judge(0, "int", `PIPELINE.rf_waddr, `PIPELINE.rf_wdata) != 0) begin
                    $display("[CJ] integer register Judge Failed");
                    #100 $fatal;
                end
            end

            if (`CPU_TOP.fpuOpt.rtlFuzz_fregWriteEnable & `CPU_TOP.fpuOpt._T_2) begin
                if (cosim_judge(0, "float", `CPU_TOP.fpuOpt.waddr, `CPU_TOP.fpuOpt.rtlFuzz_fregWriteData) != 0) begin
                    $display("[CJ] float register write Judge Failed");
                    #100 $fatal;
                end
            end

            if (`CPU_TOP.fpuOpt.load_wb & `CPU_TOP.fpuOpt._T_2) begin
                if (cosim_judge(0, "float", `CPU_TOP.fpuOpt.load_wb_tag, `CPU_TOP.fpuOpt.rtlFuzz_fregLoadData) != 0) begin
                    $display("[CJ] float register load Judge Failed");
                    #100 $fatal;
                end
            end

            if (`PIPELINE.csr.io_trace_0_interrupt) begin
                cosim_raise_trap(0, `PIPELINE.csr.io_trace_0_cause[63:0]);
            end
            // $display("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n\n");
            tohost = cosim_finish();
        end
    end

    assign finish = tohost & 1'b1;

endmodule
