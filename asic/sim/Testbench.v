//VCS coverage exclude_file
`timescale 1ns / 10ps

`ifndef RESET_DELAY
 `define RESET_DELAY 7.7
`endif

`define SOC_TOP  Testbench.testHarness.ldut
`define TILE_TOP `SOC_TOP.tile_prci_domain

`define SOC_TOP_VNT  Testbench.testHarness_variant.ldut

`define MEM_TOP  Testbench.testHarness.mem.srams.mem
`define MEM_REG  `MEM_TOP.mem_ext

`define MEM_TOP_VNT  Testbench.testHarness_variant.mem.srams.mem
`define MEM_REG_VNT  `MEM_TOP_VNT.mem_ext

`ifdef TARGET_BOOM
  `define CPU_TOP  `TILE_TOP.tile_reset_domain_boom_tile
  `define PIPELINE `CPU_TOP.core
`elsif TARGET_CVA6
  `define CPU_TOP  `TILE_TOP.tile_reset_domain_cva6_tile
  `define PIPELINE `CPU_TOP.core.i_ariane.i_cva6
`else
  `define CPU_TOP  `TILE_TOP.tile_reset_domain_tile
  `define PIPELINE `CPU_TOP.core
`endif

`ifdef COVERAGE_SUMMARY
  `define COVERAGE_PROBE Testbench.testHarness.ldut.io_covSum
`endif

import "DPI-C" function longint timer_stop();
import "DPI-C" function int coverage_collector(
  input longint unsigned dut_cov
);
import "DPI-C" function void cosim_reinit(
    input string testcase,
    input reg verbose
);
import "DPI-C" function void cosim_set_tohost(input longint unsigned value);

module Testbench;
  
  reg clock = 1'b0;
  reg reset = 1'b1;

  wire interrupt;

  always #(`CLOCK_PERIOD/2.0) clock = ~clock;
  initial #(`RESET_DELAY) reset = 0;

  `ifdef VCS
    `ifdef COVERAGE_SUMMARY
      assign `SOC_TOP.metaReset = reset;
    `endif
  `endif

  initial begin
    $system("echo -e \"\033[31m[>] vcs start `date +%s.%3N` \033[0m\"");
    `ifdef VCS
      force `PIPELINE.io_interrupts_msip = interrupt;
    `endif
  end 

  int unsigned rand_value;
  string testcase;
  string taintlog = "default";
  longint timer_result;
  
  reg [255:0] reason = "";
  reg failure = 1'b0;
  reg verbose = 1'b0;
  reg fuzz = 1'b0;
  reg dump_wave = 1'b0;
  reg jtag_rbb_enable = 1'b0;
  reg [63:0] max_cycles = 0;
  reg [63:0] dump_start = 0;
  reg [63:0] trace_count = 0;
  reg [2047:0] fsdbfile = 0;
  reg [2047:0] vcdplusfile = 0;
  reg [2047:0] vcdfile = 0;

  int taint_fd;
  int event_fd;

  wire [63:0] tohost;
  wire printf_cond = verbose && !reset;
  wire uart_rx, uart_tx;

  initial begin
    void'($value$plusargs("max-cycles=%d", max_cycles));
    void'($value$plusargs("dump-start=%d", dump_start));
    void'($value$plusargs("jtag_rbb_enable=%d", jtag_rbb_enable));
    verbose = $test$plusargs("verbose");
    fuzz = $test$plusargs("fuzzing");
    dump_wave = $test$plusargs("dump");

    // fixed for diffuzzRTL, CJ should not timeout
    max_cycles = 2000000000;

    // $urandom is seeded via cmdline (+ntb_random_seed in VCS) but that doesn't seed $random.
    rand_value = $urandom;
    rand_value = $random(rand_value);
    if (verbose) begin
      `ifdef VCS
        $fdisplay(32'h80000002, "testing $random %0x seed %d", rand_value, unsigned'($get_initial_random_seed));
      `endif
    end

    if (dump_wave) begin
      `ifdef DEBUG_FSDB
        `define WAVE_ON     $fsdbDumpon;
        `define WAVE_CLOSE  $fsdbDumpoff;
        $fsdbDumpfile({`TOP_DIR, "/wave/starship.fsdb"});
        $fsdbDumpvars(0, "+all");
      `elsif DEBUG_VCD
        `define WAVE_ON     $dumpon;
        `define WAVE_CLOSE  $dumpoff;
        $dumpfile({`TOP_DIR, "/wave/starship.vcd"});
        $dumpvars(0, Testbench);
      `else
        `define WAVE_ON     ;
        `define WAVE_CLOSE  ;
      `endif
    end

    if (dump_start == 0) begin
      // Start dumping before first clock edge to capture reset sequence in waveform
      if (dump_wave) begin
        `WAVE_ON
      end
    end

    // Memory Initialize
    #(`RESET_DELAY/2.0)
    if ($value$plusargs("testcase=%s", testcase)) begin
      $display("TestHarness Memory Load Testcase: %s", {testcase, ".hex"});
      $readmemh({testcase, ".hex"}, `MEM_REG.ram);
      $readmemh({testcase, ".variant.hex"}, `MEM_REG_VNT.ram);
    end
    $system("echo -e \"\033[31m[>] vcs init `date +%s.%3N` \033[0m\"");

    // taint
    $timeformat(-9,0,"",20);
    $value$plusargs("taintlog=%s", taintlog);
    taint_fd = $fopen({`TOP_DIR, "/wave/", taintlog, ".taint.csv"}, "w");
    $fwrite(taint_fd,"time,base,variant\n");
    event_fd = $fopen({`TOP_DIR, "/wave/", taintlog, ".taint.log"}, "w");
  end

  always @(posedge clock) begin
    if (!reset) begin
      $fwrite(taint_fd,"%t, %d, %d\n", $time, `SOC_TOP.taint_sum, `SOC_TOP_VNT.taint_sum);

      `define BOOM_ROB_ENQ_ENABLE Testbench.testHarness.ldut.tile_prci_domain.tile_reset_domain_boom_tile.core.rob.io_enq_valids_0
      `define BOOM_ROB_DEQ_ENABLE Testbench.testHarness.ldut.tile_prci_domain.tile_reset_domain_boom_tile.core.rob.io_commit_valids_0
      `define BOOM_ROB_ENQ_INST   Testbench.testHarness.ldut.tile_prci_domain.tile_reset_domain_boom_tile.core.rob.io_enq_uops_0_debug_inst
      `define BOOM_ROB_DEQ_INST   Testbench.testHarness.ldut.tile_prci_domain.tile_reset_domain_boom_tile.core.rob.io_commit_uops_0_debug_inst
      if (`BOOM_ROB_ENQ_ENABLE) begin
        case (`BOOM_ROB_ENQ_INST)
          32'h00002013: $fwrite(event_fd, "INFO_VCTM_START, %t\n", $time);
          32'h00102013: $fwrite(event_fd, "INFO_VCTM_END, %t\n", $time);
          32'h00202013: $fwrite(event_fd, "INFO_DELAY_START, %t\n", $time);
          32'h00302013: $fwrite(event_fd, "INFO_DELAY_END, %t\n", $time);
          32'h00402013: $fwrite(event_fd, "INFO_TEXE_START, %t\n", $time);
          32'h00502013: $fwrite(event_fd, "INFO_TEXE_END, %t\n", $time);
          32'h00602013: $fwrite(event_fd, "INFO_LEAK_START, %t\n", $time);
          32'h00702013: $fwrite(event_fd, "INFO_LEAK_END, %t\n", $time);
        endcase
      end
      if (`BOOM_ROB_DEQ_ENABLE) begin
        case (`BOOM_ROB_DEQ_INST)
          32'h00002013: $fwrite(event_fd, "INFO_VCTM_START_COMMIT, %t\n", $time);
          32'h00102013: $fwrite(event_fd, "INFO_VCTM_END_COMMIT, %t\n", $time);
          32'h00202013: $fwrite(event_fd, "INFO_DELAY_START_COMMIT, %t\n", $time);
          32'h00302013: $fwrite(event_fd, "INFO_DELAY_END_COMMIT, %t\n", $time);
          32'h00402013: $fwrite(event_fd, "INFO_TEXE_START_COMMIT, %t\n", $time);
          32'h00502013: $fwrite(event_fd, "INFO_TEXE_END_COMMIT, %t\n", $time);
          32'h00602013: $fwrite(event_fd, "INFO_LEAK_START_COMMIT, %t\n", $time);
          32'h00702013: $fwrite(event_fd, "INFO_LEAK_END_COMMIT, %t\n", $time);
        endcase
      end
    end
  end

  always @(negedge clock) begin
    if(!jtag_rbb_enable) begin
      trace_count = trace_count + 1;
      if (trace_count == dump_start) begin
        if (dump_wave) begin
          `WAVE_ON
        end
      end

      if (!reset) begin
        if (max_cycles > 0 && trace_count > max_cycles) begin
          reason = " (timeout)";
          failure = 1'b1;
        end

        if (failure) begin
          $fdisplay(32'h80000002, "*** FAILED ***%s after %d simulation cycles", reason, trace_count);
          trace_count = 0;
          failure = 0;
          if (fuzz) begin
            $system("echo -e \"\033[31m[>] round timeout `date +%s.%3N` \033[0m\"");
            cosim_set_tohost(5);
            fuzz_manager();
          end else begin
            if (dump_wave) begin
              `WAVE_CLOSE
            end
            $fatal;
          end
        end
        if (tohost & 1'b1) begin
          $fdisplay(32'h80000002, "*** PASSED *** Completed after %d simulation cycles", trace_count);
          trace_count = 0;
          if (fuzz) begin
            $system("echo -e \"\033[31m[>] round finish `date +%s.%3N` \033[0m\"");
            fuzz_manager();
          end else begin
            if (dump_wave) begin
              `WAVE_CLOSE
            end
            $system("echo -e \"\033[31m[>] vcs stop `date +%s.%3N` \033[0m\"");
            `ifdef COVERAGE_SUMMARY
            $display("[CJ] coverage sum = %d", `COVERAGE_PROBE);
            `endif
            $finish;
          end

        end
      end
    end
  end

  SyncMonitor smon(
    .clock(clock),
    .reset(reset)    
  );

  TestHarness testHarness(
    .clock(clock),
    .reset(reset),
    .io_uart_tx(),
    .io_uart_rx(1'b0)
  // .io_uart_tx(uart_tx),
  // .io_uart_rx(uart_rx)
  );

  TestHarness testHarness_variant(
    .clock(clock),
    .reset(reset),
    .io_uart_tx(),
    .io_uart_rx(1'b0)
  // .io_uart_tx(uart_tx),
  // .io_uart_rx(uart_rx)
  );

`ifdef COSIMULATION
  CJ rtlfuzz (
    .clock(clock),
    .reset(reset|jtag_rbb_enable),
    .tohost(tohost)
  );
`endif

  // tty #(115200, 0) u0_tty(
  //  .STX(uart_rx),
  //  .SRX(uart_tx),
  //  .reset(reset)
  // );

`ifdef COVERAGE_SUMMARY
  coverage_monitor mon(
    .clock(clock),
    .reset(reset),
    .cov(`COVERAGE_PROBE),
    .tohost(tohost),
    .interrupt(interrupt)
  );
`endif

  task fuzz_manager;
  begin
    force clock = 0;
    #50;
    `ifdef COVERAGE_SUMMARY
    if (coverage_collector(`COVERAGE_PROBE)) begin
      reset = 1;
      $readmemh("./testcase.hex", `MEM_REG.ram);
      cosim_reinit("./testcase.elf", verbose);
      $system("echo -e \"\033[31m[>] round start `date +%s.%3N` \033[0m\"");
    end
    `endif
    release clock;
    #10 reset = 0;
  end
  endtask

endmodule


`define MAX_WAIT_CYCLE  1000

module coverage_monitor(
  input clock,
  input reset,
  input [29:0] cov,
  input [63:0] tohost,
  output interrupt
);

  reg [63:0] count = 0;
  reg [63:0] watch_dog = 0;
  reg [29:0] pre_cov = 0;

  always @(negedge clock) begin
    if (!reset) begin
      if (cov != pre_cov) begin
        pre_cov <= cov;
        count <= 0;
      end else begin
        count <= count + 1;
      end
      if (tohost & 1) begin
        count <= 0;
        watch_dog <= 0;
      end else begin
        watch_dog <= watch_dog + 1;
      end
    end else begin
      count <= 0;
      watch_dog <= 0;
    end
  end

  assign interrupt = (count >= (`MAX_WAIT_CYCLE * ((cov >> 19)+1) )) || (watch_dog >= 50000);
endmodule
