// commit & judge stage
for (int i = 0; i < commits; i++) begin
    if (`DUT_PIPELINE.commit_ack[i] && !`DUT_PIPELINE.commit_instr_id_commit[i].ex.valid) begin
        if (cosim_commit(0, $signed(`DUT_PIPELINE.commit_instr_id_commit[i].pc), `DUT_PIPELINE.commit_instr_id_commit[i].ex.tval) != 0) begin
            $display("[CJ] %d Commit Failed", i);
            #10 $fatal;
        end

        if (`DUT_PIPELINE.we_gpr_commit_id[i]) begin
            if (cosim_judge(0, "int", `DUT_PIPELINE.waddr_commit_id[i], `DUT_PIPELINE.wdata_commit_id[i]) != 0) begin
                $display("[CJ] %d integer register Judge Failed", i);
                #10 $fatal;
            end
        end

        if (`DUT_PIPELINE.we_fpr_commit_id[i]) begin
            if (cosim_judge(0, "float", `DUT_PIPELINE.waddr_commit_id[i], `DUT_PIPELINE.wdata_commit_id[i]) != 0) begin
                $display("[CJ] %d float register write Judge Failed", i);
                #10 $fatal;
            end
        end

    end
end

// exception & interrupt
for (int i = 0; i < commits; i++) begin
    if (`DUT_PIPELINE.commit_ack[i] & `DUT_PIPELINE.commit_instr_id_commit[i].ex.valid & `DUT_PIPELINE.commit_instr_id_commit[i].ex.cause[63]) begin
        cosim_raise_trap(0, `DUT_PIPELINE.commit_instr_id_commit[i].ex.cause);
    end
end
