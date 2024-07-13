`define INFO_VCTM_START     32'h00002013
`define INFO_VCTM_END       32'h00102013
`define INFO_DELAY_START    32'h00202013
`define INFO_DELAY_END      32'h00302013
`define INFO_TEXE_START     32'h00402013
`define INFO_TEXE_END       32'h00502013
`define INFO_LEAK_START     32'h00602013
`define INFO_LEAK_END       32'h00702013
`define INFO_INIT_START     32'h00802013
`define INFO_INIT_END       32'h00902013
`define INFO_BIM_START      32'h00a02013
`define INFO_BIM_END        32'h00b02013
`define INFO_TRAIN_START    32'h00c02013
`define INFO_TRAIN_END      32'h00d02013

module SyncMonitor (
  input clock,
  input reset
);

  string log_name = "default";
  int taint_fd;
  int event_fd;
  int cov_fd;
  int live_fd;

  initial begin
    $timeformat(-9, 0, "", 20);
    $value$plusargs("label=%s", log_name);
    taint_fd = $fopen({`TOP_DIR, "/wave/", log_name, ".taint.csv"}, "w");
    event_fd = $fopen({`TOP_DIR, "/wave/", log_name, ".taint.log"}, "w");
    cov_fd = $fopen({`TOP_DIR, "/wave/", log_name, ".taint.cov"}, "w");
    live_fd = $fopen({`TOP_DIR, "/wave/", log_name, ".taint.live"}, "w");

`ifdef HASVARIANT
    $fwrite(taint_fd,"time,dut,vnt\n");
`else
    $fwrite(taint_fd,"time,dut\n");
`endif
  end

  always @(posedge clock) begin
    if (!reset) begin
  `ifdef HASVARIANT
      $fwrite(taint_fd, "%t, %d, %d\n", $time, `DUT_SOC_TOP.taint_sum, `VNT_SOC_TOP.taint_sum);
  `elsif HASTAINT
      $fwrite(taint_fd, "%t, %d\n", $time, `DUT_SOC_TOP.taint_sum);
  `endif
    end
  end

  function void event_handler;
    input valid;
    input [31:0] inst;
    input string suffix;
    input int id;
    input int is_dut;

    if (valid) begin
      case (inst)
        `INFO_VCTM_START: begin
          $fwrite(event_fd, "%t, VCTM_START_%s, %d, %d\n", $time, suffix, id, is_dut);
          $display("VCTM_START_%s", suffix);
        end
        `INFO_VCTM_END: begin
          $fwrite(event_fd, "%t, VCTM_END_%s, %d, %d\n", $time, suffix, id, is_dut);
          $display("VCTM_END_%s", suffix);
          if(is_dut && suffix=="DEQ")begin
            $finish;
          end
        end
        `INFO_DELAY_START: begin
          $fwrite(event_fd, "%t, DELAY_START_%s, %d, %d\n", $time, suffix, id, is_dut);
          $display("DELAY_START_%s", suffix);
        end
        `INFO_DELAY_END: begin
          $fwrite(event_fd, "%t, DELAY_END_%s, %d, %d\n", $time, suffix, id, is_dut);
          $display("DELAY_END_%s", suffix);
        end
        `INFO_TEXE_START: begin
          $fwrite(event_fd, "%t, TEXE_START_%s, %d, %d\n", $time, suffix, id, is_dut);
          $display("TEXE_START_%s", suffix);
          if(is_dut && suffix=="DEQ")begin
            $finish;
          end
        end
        `INFO_TEXE_END: begin
          $fwrite(event_fd, "%t, TEXE_END_%s, %d, %d\n", $time, suffix, id, is_dut);
          $display("TEXE_END_%s", suffix);
        end
        `INFO_LEAK_START: begin
          $fwrite(event_fd, "%t, LEAK_START_%s, %d, %d\n", $time, suffix, id, is_dut);
          $display("LEAK_START_%s", suffix);
        end
        `INFO_LEAK_END: begin
          $fwrite(event_fd, "%t, LEAK_END_%s, %d, %d\n", $time, suffix, id, is_dut);
          $display("LEAK_END_%s", suffix);
        end
        `INFO_INIT_START: begin
          $fwrite(event_fd, "%t, INIT_START_%s, %d, %d\n", $time, suffix, id, is_dut);
          $display("INIT_START_%s", suffix);
        end
        `INFO_INIT_END: begin
          $fwrite(event_fd, "%t, INIT_END_%s, %d, %d\n", $time, suffix, id, is_dut);
          $display("INIT_END_%s", suffix);
        end
        `INFO_BIM_START: begin
          $fwrite(event_fd, "%t, BIM_START_%s, %d, %d\n", $time, suffix, id, is_dut);
          $display("BIM_START_%s", suffix);
        end
        `INFO_BIM_END: begin
          $fwrite(event_fd, "%t, BIM_END_%s, %d, %d\n", $time, suffix, id, is_dut);
          $display("VCTM_END_%s", suffix);
        end
        `INFO_TRAIN_START: begin
          $fwrite(event_fd, "%t, TRAIN_START_%s, %d, %d\n", $time, suffix, id, is_dut);
          $display("TRAIN_START_%s", suffix);
        end
        `INFO_TRAIN_END: begin
          $fwrite(event_fd, "%t, TRAIN_END_%s, %d, %d\n", $time, suffix, id, is_dut);
          $display("TRAIN_END_%s", suffix);
        end
      endcase
    end
  endfunction

  `ifdef TARGET_BOOM
    `include "variant/rob_sync.boom.v"
  `else // TARGET_XiangShan
    `include "variant/rob_sync.xiangshan.v"
  `endif

endmodule
