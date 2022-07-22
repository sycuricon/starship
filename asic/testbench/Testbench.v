//VCS coverage exclude_file
`timescale 1ns / 10ps

`ifndef RESET_DELAY
 `define RESET_DELAY 7.7
`endif

`ifndef MODEL
 `define MODEL TestHarness
`endif

`define SOC_TOP  Testbench.testHarness.ldut
`define CPU_TOP  `SOC_TOP.tile_prci_domain.tile_reset_domain_tile
`define PIPELINE `CPU_TOP.core
`define MEM_TOP  Testbench.testHarness.mem.srams.mem
`define MEM_RPL  `MEM_TOP.mem_ext

import "DPI-C" function void timer_start();
import "DPI-C" function longint timer_stop();
import "DPI-C" function int coverage_collector(
  input longint unsigned dut_cov
);
import "DPI-C" function void cosim_reinit(
    input string testcase,
    input reg verbose
);

module Testbench;
  
  reg clock = 1'b0;
  reg reset = 1'b1;

  wire interrupt;

  always #(`CLOCK_PERIOD/2.0) clock = ~clock;
  initial #(`RESET_DELAY) reset = 0;

  assign Testbench.testHarness.ldut.metaReset = reset;

  initial begin
    $system("echo -e \"\033[31m vcs start `date +%s.%3N` \033[0m\"");
    force `PIPELINE.io_interrupts_msip = interrupt;
    if ($test$plusargs("interrupt")) begin
      // #(`RESET_DELAY * 2)
      // forever @(posedge clock) begin
      //   force `PIPELINE.io_interrupts_mtip = 1'b0;
      //   force `PIPELINE.io_interrupts_msip = 1'b0;
      //   force `PIPELINE.io_interrupts_meip = 1'b0;
      //   force `PIPELINE.io_interrupts_seip = 1'b0;
      //   #200;
      //   force `PIPELINE.io_interrupts_mtip = 1'b1;
      //   force `PIPELINE.io_interrupts_msip = 1'b1;
      //   force `PIPELINE.io_interrupts_meip = 1'b1;
      //   force `PIPELINE.io_interrupts_seip = 1'b1;
      //   #1000;
      // end
    end  
  end 

  int unsigned rand_value;
  string testcase;
  longint timer_result;
  
  reg [255:0] reason = "";
  reg failure = 1'b0;
  reg verbose = 1'b0;
  reg fuzz = 1'b0;
  reg dump_wave = 1'b0;
  reg [63:0] max_cycles = 0;
  reg [63:0] dump_start = 0;
  reg [63:0] trace_count = 0;
  reg [2047:0] fsdbfile = 0;
  reg [2047:0] vcdplusfile = 0;
  reg [2047:0] vcdfile = 0;

  wire [63:0] tohost;
  wire printf_cond = verbose && !reset;
  wire uart_rx, uart_tx;

  initial begin
    void'($value$plusargs("max-cycles=%d", max_cycles));
    void'($value$plusargs("dump-start=%d", dump_start));
    verbose = $test$plusargs("verbose");
    fuzz = $test$plusargs("fuzzing");
    dump_wave = $test$plusargs("dump");

    // $urandom is seeded via cmdline (+ntb_random_seed in VCS) but that doesn't seed $random.
    rand_value = $urandom;
    rand_value = $random(rand_value);
    if (verbose) begin
      $fdisplay(32'h80000002, "testing $random %0x seed %d", rand_value, unsigned'($get_initial_random_seed));
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
        $dumpvars(0, testHarness);
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
      $readmemh({testcase, ".hex"}, `MEM_RPL.ram);
    end
    $system("echo -e \"\033[31m vcs init `date +%s.%3N` \033[0m\"");
    timer_start();
  end

  always @(negedge clock) begin
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
        if (dump_wave) begin
          `WAVE_CLOSE
        end
        $fatal;
      end
      if (tohost & 1'b1) begin
        $fdisplay(32'h80000002, "*** PASSED *** Completed after %d simulation cycles", trace_count);
        if (fuzz) begin
          fuzz_manager();
        end
        else begin
          if (dump_wave) begin
            `WAVE_CLOSE
          end
          $system("echo -e \"\033[31m vcs stop `date +%s.%3N` \033[0m\"");
          timer_result = timer_stop();
          $display("Finish time: %d ns", timer_result);
          $display("[CJ] coverage sum = %d", Testbench.testHarness.ldut.io_covSum);
          // $writememh("test.hex", Testbench.testHarness.ldut.tile_prci_domain.tile_reset_domain_tile.frontend.tlb.r_need_gpa);
          $finish;
        end

      end
    end
  end

  `MODEL testHarness(
    .clock(clock),
    .reset(reset),
    .io_uart_tx(1'b0),
    .io_uart_rx(1'b0)
  // .io_uart_tx(uart_tx),
  // .io_uart_rx(uart_rx)
  );

  CJ rtlfuzz (
    .clock(clock),
    .reset(reset),
    .tohost(tohost));

  tty #(115200, 0) u0_tty(
   .STX(uart_rx),
   .SRX(uart_tx),
   .reset(reset)
  );

  coverage_monitor mon(
    .clock(clock),
    .reset(reset),
    .cov(Testbench.testHarness.ldut.io_covSum),
    .tohost(tohost),
    .interrupt(interrupt)
  );

  task fuzz_manager;
  begin
    // force tohost = 0;
    force clock = 0;
    #50;
    if (coverage_collector(Testbench.testHarness.ldut.io_covSum)) begin
      reset = 1;
      $readmemh("./testcase.hex", `MEM_RPL.ram);
      cosim_reinit("./testcase.elf", verbose);
    end
    release clock;
    #10 reset = 0;
    // release tohost;
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

  assign interrupt = (count >= `MAX_WAIT_CYCLE) || (watch_dog >= 10000) ;
endmodule