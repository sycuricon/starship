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

  reg victim_done = 0;
  reg sync = 1'b1;

  string taintlog = "default";
  int taint_fd;
  int event_fd;

  initial begin
    $timeformat(-9, 0, "", 20);
    $value$plusargs("taintlog=%s", taintlog);
    taint_fd = $fopen({`TOP_DIR, "/wave/", taintlog, ".taint.csv"}, "w");
    $fwrite(taint_fd,"time,base,variant\n");
    event_fd = $fopen({`TOP_DIR, "/wave/", taintlog, ".taint.log"}, "w");
  end

  function void event_handler;
    input valid;
    input [31:0] inst;
    input string suffix;
    input int id;

    if (valid) begin
      case (inst)
        `INFO_VCTM_START: begin
          $fwrite(event_fd, "%t, VCTM_START_%s, %d\n", $time, suffix, id);
          $system("echo -e \"\033[31m[>] victim_start `date +%s.%3N` \033[0m\"");
        end
        `INFO_VCTM_END: begin
          $fwrite(event_fd, "%t, VCTM_END_%s, %d\n", $time, suffix, id);
        end
        `INFO_DELAY_START: begin
          $fwrite(event_fd, "%t, DELAY_START_%s, %d\n", $time, suffix, id);
          $system("echo -e \"\033[31m[>] delay_start `date +%s.%3N` \033[0m\"");
        end
        `INFO_DELAY_END: begin
          $fwrite(event_fd, "%t, DELAY_END_%s, %d\n", $time, suffix, id);
        end
        `INFO_TEXE_START: begin
          $fwrite(event_fd, "%t, TEXE_START_%s, %d\n", $time, suffix, id);
          $system("echo -e \"\033[31m[>] texe_start `date +%s.%3N` \033[0m\"");
        end
        `INFO_TEXE_END: begin
          $fwrite(event_fd, "%t, TEXE_END_%s, %d\n", $time, suffix, id);
        end
        `INFO_LEAK_START: begin
          $fwrite(event_fd, "%t, LEAK_START_%s, %d\n", $time, suffix, id);
          $system("echo -e \"\033[31m[>] leak_end `date +%s.%3N` \033[0m\"");
        end
        `INFO_LEAK_END: begin
          $fwrite(event_fd, "%t, LEAK_END_%s, %d\n", $time, suffix, id);
        end
        `INFO_INIT_START: begin
          $fwrite(event_fd, "%t, INIT_START_%s, %d\n", $time, suffix, id);
          $system("echo -e \"\033[31m[>] init_start `date +%s.%3N` \033[0m\"");
        end
        `INFO_INIT_END: begin
          $fwrite(event_fd, "%t, INIT_END_%s, %d\n", $time, suffix, id);
        end
        `INFO_BIM_START: begin
          $fwrite(event_fd, "%t, BIM_START_%s, %d\n", $time, suffix, id);
          $system("echo -e \"\033[31m[>] bim_start `date +%s.%3N` \033[0m\"");
        end
        `INFO_BIM_END: begin
          $fwrite(event_fd, "%t, BIM_END_%s, %d\n", $time, suffix, id);
        end
        `INFO_TRAIN_START: begin
          $fwrite(event_fd, "%t, TRAIN_START_%s, %d\n", $time, suffix, id);
          $system("echo -e \"\033[31m[>] train_start `date +%s.%3N` \033[0m\"");
        end
        `INFO_TRAIN_END: begin
          $fwrite(event_fd, "%t, TRAIN_END_%s, %d\n", $time, suffix, id);
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
