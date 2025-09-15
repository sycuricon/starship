// commit & judge stage
// 0
if (`PIPELINE.rob.io_commit_arch_valids_0) begin
    if (cosim_commit(0, $signed(`PIPELINE.rob.io_commit_uops_0_debug_pc), 
        `PIPELINE.rob.io_commit_uops_0_is_rvc ? `PIPELINE.rob.io_commit_uops_0_debug_inst[15:0]
            : `PIPELINE.rob.io_commit_uops_0_debug_inst
        ) != 0) begin
        $display("[CJ] %d Commit Failed", 0);
        #10 $fatal;
    end

    if (`PIPELINE.rob.io_commit_uops_0_dst_rtype == 2'b00) begin
        if (cosim_judge(0, "int", `PIPELINE.rob.io_commit_uops_0_ldst, `PIPELINE.rob.io_commit_debug_wdata_0) != 0) begin
            $display("[CJ] %d integer register Judge Failed", 0);
            #10 $fatal;
        end
    end

    if (`PIPELINE.rob.io_commit_uops_0_dst_rtype == 2'b01) begin
        if (cosim_judge(0, "float", `PIPELINE.rob.io_commit_uops_0_ldst, `PIPELINE.rob.io_commit_debug_wdata_0) != 0) begin
            $display("[CJ] %d float register write Judge Failed", 0);
            #10 $fatal;
        end
    end

end

// 1
if (`PIPELINE.rob.io_commit_arch_valids_1) begin
    if (cosim_commit(0, $signed(`PIPELINE.rob.io_commit_uops_1_debug_pc), 
        `PIPELINE.rob.io_commit_uops_1_is_rvc ? `PIPELINE.rob.io_commit_uops_1_debug_inst[15:0]
            : `PIPELINE.rob.io_commit_uops_1_debug_inst) != 0) begin
        $display("[CJ] %d Commit Failed", 1);
        #10 $fatal;
    end

    if (`PIPELINE.rob.io_commit_uops_1_dst_rtype == 2'b00) begin
        if (cosim_judge(0, "int", `PIPELINE.rob.io_commit_uops_1_ldst, `PIPELINE.rob.io_commit_debug_wdata_1) != 0) begin
            $display("[CJ] %d integer register Judge Failed", 1);
            #10 $fatal;
        end
    end

    if (`PIPELINE.rob.io_commit_uops_1_dst_rtype == 2'b01) begin
        if (cosim_judge(0, "float", `PIPELINE.rob.io_commit_uops_1_ldst, `PIPELINE.rob.io_commit_debug_wdata_1) != 0) begin
            $display("[CJ] %d float register write Judge Failed", 1);
            #10 $fatal;
        end
    end

end

// 2
if (`PIPELINE.rob.io_commit_arch_valids_2) begin
    if (cosim_commit(0, $signed(`PIPELINE.rob.io_commit_uops_2_debug_pc), 
        `PIPELINE.rob.io_commit_uops_2_is_rvc ? `PIPELINE.rob.io_commit_uops_2_debug_inst[15:0]
            : `PIPELINE.rob.io_commit_uops_2_debug_inst) != 0) begin
        $display("[CJ] %d Commit Failed", 2);
        #10 $fatal;
    end

    if (`PIPELINE.rob.io_commit_uops_2_dst_rtype == 2'b00) begin
        if (cosim_judge(0, "int", `PIPELINE.rob.io_commit_uops_2_ldst, `PIPELINE.rob.io_commit_debug_wdata_2) != 0) begin
            $display("[CJ] %d integer register Judge Failed", 2);
            #10 $fatal;
        end
    end

    if (`PIPELINE.rob.io_commit_uops_2_dst_rtype == 2'b01) begin
        if (cosim_judge(0, "float", `PIPELINE.rob.io_commit_uops_2_ldst, `PIPELINE.rob.io_commit_debug_wdata_2) != 0) begin
            $display("[CJ] %d float register write Judge Failed", 2);
            #10 $fatal;
        end
    end

end

// exception & interrupt
for (int i = 0; i < commits; i++) begin
    if (`PIPELINE.rob.io_com_xcpt_valid & `PIPELINE.rob.io_com_xcpt_bits_cause[63]) begin
        cosim_raise_trap(0, `PIPELINE.rob.io_com_xcpt_bits_cause);
    end
end
