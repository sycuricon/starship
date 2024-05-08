// commit stage
if (`DUT_PIPELINE.wb_valid) begin
    if (cosim_commit(0, $signed(`DUT_PIPELINE.csr_io_trace_0_iaddr), `DUT_PIPELINE.csr_io_trace_0_insn) != 0) begin
        $display("[CJ] Commit Failed");
        #10 $fatal;
    end
end

// judge stage
if (`DUT_PIPELINE.wb_wen && !`DUT_PIPELINE.wb_set_sboard) begin
    if (cosim_judge(0, "int", `DUT_PIPELINE.rf_waddr, `DUT_PIPELINE.rf_wdata) != 0) begin
        $display("[CJ] integer register Judge Failed");
        #10 $fatal;
    end
end

if (`DUT_PIPELINE.ll_wen) begin
    if (cosim_judge(0, "int", `DUT_PIPELINE.rf_waddr, `DUT_PIPELINE.rf_wdata) != 0) begin
        $display("[CJ] integer register Judge Failed");
        #10 $fatal;
    end
end

if (`DUT_CPU_TOP.fpuOpt.rtlFuzz_fregWriteEnable & ~reset) begin
    if (cosim_judge(0, "float", `DUT_CPU_TOP.fpuOpt.waddr, `DUT_CPU_TOP.fpuOpt.rtlFuzz_fregWriteData) != 0) begin
        $display("[CJ] float register write Judge Failed");
        #10 $fatal;
    end
end

if (`DUT_CPU_TOP.fpuOpt.load_wb & ~reset) begin
    if (cosim_judge(0, "float", `DUT_CPU_TOP.fpuOpt.load_wb_tag, `DUT_CPU_TOP.fpuOpt.rtlFuzz_fregLoadData) != 0) begin
        $display("[CJ] float register load Judge Failed");
        #10 $fatal;
    end
end

// exception & interrupt
if (`DUT_PIPELINE.csr.io_trace_0_interrupt) begin
    cosim_raise_trap(0, `DUT_PIPELINE.csr.io_trace_0_cause[63:0]);
end
