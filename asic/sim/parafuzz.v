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

  reg dut_done = 0;
  reg vnt_done = 0;
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

    if (valid) begin
      case (inst)
        `INFO_VCTM_START: begin
          $fwrite(event_fd, "VCTM_START_%s, %t\n", suffix, $time);
          $system("echo -e \"\033[31m[>] victim_start `date +%s.%3N` \033[0m\"");
        end
        `INFO_VCTM_END:     $fwrite(event_fd, "VCTM_END_%s, %t\n", suffix, $time);
        `INFO_DELAY_START: begin
          $fwrite(event_fd, "DELAY_START_%s, %t\n", suffix, $time);
          $system("echo -e \"\033[31m[>] delay_start `date +%s.%3N` \033[0m\"");
        end
        `INFO_DELAY_END:    $fwrite(event_fd, "DELAY_END_%s, %t\n", suffix, $time);
        `INFO_TEXE_START: begin
          $fwrite(event_fd, "TEXE_START_%s, %t\n", suffix, $time);
          $system("echo -e \"\033[31m[>] texe_start `date +%s.%3N` \033[0m\"");
        end
        `INFO_TEXE_END:     $fwrite(event_fd, "TEXE_END_%s, %t\n", suffix, $time);
        `INFO_LEAK_START: begin
          $fwrite(event_fd, "LEAK_START_%s, %t\n", suffix, $time);
          $system("echo -e \"\033[31m[>] leak_end `date +%s.%3N` \033[0m\"");
        end
        `INFO_LEAK_END:     $fwrite(event_fd, "LEAK_END_%s, %t\n", suffix, $time);
        `INFO_INIT_START: begin
          $fwrite(event_fd, "INIT_START_%s, %t\n", suffix, $time);
          $system("echo -e \"\033[31m[>] init_start `date +%s.%3N` \033[0m\"");
        end
        `INFO_INIT_END:     $fwrite(event_fd, "INIT_END_%s, %t\n", suffix, $time);
        `INFO_BIM_START: begin
          $fwrite(event_fd, "BIM_START_%s, %t\n", suffix, $time);
          $system("echo -e \"\033[31m[>] bim_start `date +%s.%3N` \033[0m\"");
        end
        `INFO_BIM_END:      $fwrite(event_fd, "BIM_END_%s, %t\n", suffix, $time);
        `INFO_TRAIN_START: begin
          $fwrite(event_fd, "TRAIN_START_%s, %t\n", suffix, $time);
          $system("echo -e \"\033[31m[>] train_start `date +%s.%3N` \033[0m\"");
        end
        `INFO_TRAIN_END:    $fwrite(event_fd, "TRAIN_END_%s, %t\n", suffix, $time);
      endcase
    end
  endfunction

  function void arch_step;
    input string id;
    input valid;
    input [63:0] pc;
    input [31:0] inst;

    if (valid) 
      $display("%s %t pc 0x%x inst 0x%x", id, $time, pc, inst);
  endfunction

  `ifdef TARGET_BOOM
    `include "variant/rob_sync.boom.v"
  `else // TARGET_XiangShan
    `include "variant/rob_sync.xiangshan.v"
  `endif

endmodule
