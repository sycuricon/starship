`define BOOM_CPU_TOP  `SOC_TOP.tile_prci_domain.tile_reset_domain_boom_tile
`define BOOM_PIPELINE `BOOM_CPU_TOP.core

// commit & judge stage
// 0
if (`BOOM_PIPELINE.rob_io_commit_arch_valids_0) begin
    if (cosim_commit(0, $signed(`BOOM_PIPELINE._T_205), 
        `BOOM_PIPELINE.rob_io_commit_uops_0_is_rvc ? `BOOM_PIPELINE.rob_io_commit_uops_0_debug_inst[15:0]
            : `BOOM_PIPELINE.rob_io_commit_uops_0_debug_inst
        ) != 0) begin
        $display("[CJ] %d Commit Failed", 0);
        #10 $fatal;
    end

    if (`BOOM_PIPELINE._T_215) begin
        if (cosim_judge(0, "int", `BOOM_PIPELINE.rob_io_commit_uops_0_ldst, `BOOM_PIPELINE.rob_io_commit_debug_wdata_0) != 0) begin
            $display("[CJ] %d integer register Judge Failed", 0);
            #10 $fatal;
        end
    end

    if (~`BOOM_PIPELINE._T_215 & `BOOM_PIPELINE._T_218) begin
        if (cosim_judge(0, "float", `BOOM_PIPELINE.rob_io_commit_uops_0_ldst, `BOOM_PIPELINE.rob_io_commit_debug_wdata_0) != 0) begin
            $display("[CJ] %d float register write Judge Failed", 0);
            #10 $fatal;
        end
    end

end

// 1
if (`BOOM_PIPELINE.rob_io_commit_arch_valids_1) begin
    if (cosim_commit(0, $signed(`BOOM_PIPELINE._T_227), 
        `BOOM_PIPELINE.rob_io_commit_uops_1_is_rvc ? `BOOM_PIPELINE.rob_io_commit_uops_1_debug_inst[15:0]
            : `BOOM_PIPELINE.rob_io_commit_uops_1_debug_inst) != 0) begin
        $display("[CJ] %d Commit Failed", 1);
        #10 $fatal;
    end

    if (`BOOM_PIPELINE._T_237) begin
        if (cosim_judge(0, "int", `BOOM_PIPELINE.rob_io_commit_uops_1_ldst, `BOOM_PIPELINE.rob_io_commit_debug_wdata_1) != 0) begin
            $display("[CJ] %d integer register Judge Failed", 1);
            #10 $fatal;
        end
    end

    if (~`BOOM_PIPELINE._T_237 & `BOOM_PIPELINE._T_240) begin
        if (cosim_judge(0, "float", `BOOM_PIPELINE.rob_io_commit_uops_1_ldst, `BOOM_PIPELINE.rob_io_commit_debug_wdata_1) != 0) begin
            $display("[CJ] %d float register write Judge Failed", 1);
            #10 $fatal;
        end
    end

end

// 2
if (`BOOM_PIPELINE.rob_io_commit_arch_valids_2) begin
    if (cosim_commit(0, $signed(`BOOM_PIPELINE._T_249), 
        `BOOM_PIPELINE.rob_io_commit_uops_2_is_rvc ? `BOOM_PIPELINE.rob_io_commit_uops_2_debug_inst[15:0]
            : `BOOM_PIPELINE.rob_io_commit_uops_2_debug_inst) != 0) begin
        $display("[CJ] %d Commit Failed", 2);
        #10 $fatal;
    end

    if (`BOOM_PIPELINE._T_259) begin
        if (cosim_judge(0, "int", `BOOM_PIPELINE.rob_io_commit_uops_2_ldst, `BOOM_PIPELINE.rob_io_commit_debug_wdata_2) != 0) begin
            $display("[CJ] %d integer register Judge Failed", 2);
            #10 $fatal;
        end
    end

    if (~`BOOM_PIPELINE._T_259 & `BOOM_PIPELINE._T_262) begin
        if (cosim_judge(0, "float", `BOOM_PIPELINE.rob_io_commit_uops_2_ldst, `BOOM_PIPELINE.rob_io_commit_debug_wdata_2) != 0) begin
            $display("[CJ] %d float register write Judge Failed", 2);
            #10 $fatal;
        end
    end

end

// exception & interrupt
for (int i = 0; i < commits; i++) begin
    if (`BOOM_PIPELINE.rob_io_com_xcpt_valid & `BOOM_PIPELINE.rob_io_com_xcpt_bits_cause[63]) begin
        cosim_raise_trap(0, `BOOM_PIPELINE.rob_io_com_xcpt_bits_cause);
    end
end