import "DPI-C" function int dromajo_init(
    input string config_file
);

import "DPI-C" function int dromajo_step(
    input int     hartid,
    input longint dut_pc,
    input int     dut_insn,
    input longint dut_wdata,
    input longint mstatus,
    input bit     check
);

import "DPI-C" function void dromajo_raise_trap(
    input int     hartid,
    input longint cause
);

import "DPI-C" function longint dromajo_finish();

import "DPI-C" function int dromajo_check_sboard(
    input int     hartid,
    input int     dut_waddr,
    input longint dut_wdata
);

module RTLFUZZ_dromajo #(parameter COMMIT_WIDTH=1, XLEN=64, INST_BITS=32, HARTID_LEN=1) (
    input clock,
    input reset,

    input [          (COMMIT_WIDTH) - 1:0] valid,
    input [            (HARTID_LEN) - 1:0] hartid,
    input [     (XLEN*COMMIT_WIDTH) - 1:0] pc,
    input [(INST_BITS*COMMIT_WIDTH) - 1:0] inst,
    input [     (XLEN*COMMIT_WIDTH) - 1:0] wdata,
    input [     (XLEN*COMMIT_WIDTH) - 1:0] mstatus,
    input [          (COMMIT_WIDTH) - 1:0] check,

    input           int_xcpt,
    input [XLEN - 1:0] cause,
    output          finish
);
    string config_file;
    int step_result, ll_check_result;
    reg [63:0] tohost;

    initial begin
        if (!$value$plusargs("dromajo_config=%s", config_file)) begin
            $write("%c[1;31m",27);
            $display("FAIL: Dromajo Configuration File is Required");
            $write("%c[0m",27);
            $fatal;
        end
        if (dromajo_init(config_file) != 0) begin
            $write("%c[1;31m",27);
            $display("FAIL: Dromajo Co-Simulation Start Failed");
            $write("%c[0m",27);
            $fatal;
        end
    end

    always @(posedge clock) begin
        if (!reset) begin
            for (int i =0; i < COMMIT_WIDTH; i = i +1) begin
                if (valid[i]) begin
                    step_result = dromajo_step(hartid, 
                        pc[((i+1)*XLEN - 1)-:XLEN], inst[((i+1)*INST_BITS - 1)-:INST_BITS],
                        wdata[((i+1)*XLEN - 1)-:XLEN], mstatus[((i+1)*XLEN - 1)-:XLEN],
                        check[i]);
                    if (step_result != 0) begin
                        $display("FAIL: Dromajo Simulation Failed with exit code: %d", step_result);
                        #10 $fatal;
                    end
                end
                
                if (mstatus[1 + i*XLEN]) begin
                    ll_check_result = dromajo_check_sboard(hartid, 
                        mstatus[6 + i*XLEN -: 5], wdata[((i+1)*XLEN - 1)-:XLEN]);
                    if (ll_check_result != 0) begin
                        $display("FAIL: Dromajo Simulation Failed with exit code: %d", ll_check_result);
                        #100 $fatal;
                    end
                end
            end

            if (int_xcpt) begin
                dromajo_raise_trap(hartid, cause);
            end

            tohost = dromajo_finish();
        end
    end

    assign finish = tohost & 1'b1;

endmodule
