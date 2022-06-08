// commit stage
if (`PIPELINE.wb_valid) begin
    if (cosim_commit(0, $signed(`PIPELINE.csr_io_trace_0_iaddr), `PIPELINE.csr_io_trace_0_insn) != 0) begin
        $display("[CJ] Commit Failed");
        #10 $fatal;
    end
end

// judge stage
if (`PIPELINE.wb_wen && !`PIPELINE.wb_set_sboard) begin
    if (cosim_judge(0, "int", `PIPELINE.rf_waddr, `PIPELINE.rf_wdata) != 0) begin
        $display("[CJ] integer register Judge Failed");
        #10 $fatal;
    end
end

if (`PIPELINE.ll_wen) begin
    if (cosim_judge(0, "int", `PIPELINE.rf_waddr, `PIPELINE.rf_wdata) != 0) begin
        $display("[CJ] integer register Judge Failed");
        #10 $fatal;
    end
end

if (`CPU_TOP.fpuOpt.rtlFuzz_fregWriteEnable & ~reset) begin
    if (cosim_judge(0, "float", `CPU_TOP.fpuOpt.waddr, `CPU_TOP.fpuOpt.rtlFuzz_fregWriteData) != 0) begin
        $display("[CJ] float register write Judge Failed");
        #10 $fatal;
    end
end

if (`CPU_TOP.fpuOpt.load_wb & ~reset) begin
    if (cosim_judge(0, "float", `CPU_TOP.fpuOpt.load_wb_tag, `CPU_TOP.fpuOpt.rtlFuzz_fregLoadData) != 0) begin
        $display("[CJ] float register load Judge Failed");
        #10 $fatal;
    end
end

// exception & interrupt
if (`PIPELINE.csr.io_trace_0_interrupt) begin
    cosim_raise_trap(0, `PIPELINE.csr.io_trace_0_cause[63:0]);
end
