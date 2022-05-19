            // commit & judge stage
            for (int i = 0; i < commits; i++) begin
                if (`CVA6_PIPELINE.commit_ack[i] && !`CVA6_PIPELINE.commit_instr_id_commit[i].ex.valid) begin
                    if (cosim_commit(0, $signed(`CVA6_PIPELINE.commit_instr_id_commit[i].pc), `CVA6_PIPELINE.commit_instr_id_commit[i].ex.tval) != 0) begin
                        $display("[CJ] %d Commit Failed", i);
                        #10 $fatal;
                    end

                    if (`CVA6_PIPELINE.we_gpr_commit_id[i]) begin
                        if (cosim_judge(0, "int", `CVA6_PIPELINE.waddr_commit_id[i], `CVA6_PIPELINE.wdata_commit_id[i]) != 0) begin
                            $display("[CJ] %d integer register Judge Failed", i);
                            #10 $fatal;
                        end
                    end

                    if (`CVA6_PIPELINE.we_fpr_commit_id[i]) begin
                        if (cosim_judge(0, "float", `CVA6_PIPELINE.waddr_commit_id[i], `CVA6_PIPELINE.wdata_commit_id[i]) != 0) begin
                            $display("[CJ] %d float register write Judge Failed", i);
                            #10 $fatal;
                        end
                    end
            
                end
            end

            // exception & interrupt
            for (int i = 0; i < commits; i++) begin
                if (`CVA6_PIPELINE.commit_ack[i] & `CVA6_PIPELINE.commit_instr_id_commit[i].ex.valid & `CVA6_PIPELINE.commit_instr_id_commit[i].ex.cause[63]) begin
                    cosim_raise_trap(0, `CVA6_PIPELINE.commit_instr_id_commit[i].ex.cause);
                end
            end            