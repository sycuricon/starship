//VCS coverage exclude_file
`timescale 1ns / 10ps

`ifndef RESET_DELAY
 `define RESET_DELAY 7.7
`endif

`ifndef MODEL
 `define MODEL TestHarness
`endif

`define SOC_TOP  testHarness.ldut
`define CPU_TOP  `SOC_TOP.tile_prci_domain.tile_reset_domain_tile
`define PIPELINE `CPU_TOP.core
`define MEM_TOP  testHarness.mem.srams.mem
`define MEM_RPL  `MEM_TOP.mem_ext

import "DPI-C" function void timer_start();
import "DPI-C" function longint timer_stop();

module Testbench;
  
  reg clock = 1'b0;
  reg reset = 1'b1;

  always #(`CLOCK_PERIOD/2.0) clock = ~clock;
  initial #(`RESET_DELAY) reset = 0;

  int unsigned rand_value;
  string testcase;
  longint timer_result;
  
  reg [255:0] reason = "";
  reg failure = 1'b0;
  reg verbose = 1'b0;
  reg dump_wave = 1'b0;
  reg [63:0] max_cycles = 0;
  reg [63:0] dump_start = 0;
  reg [63:0] trace_count = 0;
  reg [2047:0] fsdbfile = 0;
  reg [2047:0] vcdplusfile = 0;
  reg [2047:0] vcdfile = 0;

  wire finish;
  wire printf_cond = verbose && !reset;
  wire uart_rx, uart_tx;

  initial begin
    void'($value$plusargs("max-cycles=%d", max_cycles));
    void'($value$plusargs("dump-start=%d", dump_start));
    verbose = $test$plusargs("verbose");
    dump_wave = $test$plusargs("dump");

    // do not delete the lines below.
    // $random function needs to be called with the seed once to affect all
    // the downstream $random functions within the Chisel-generated Verilog
    // code.
    // $urandom is seeded via cmdline (+ntb_random_seed in VCS) but that
    // doesn't seed $random.
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
        $display("Load testcase: %s", testcase);
        $readmemh(testcase, `MEM_RPL.ram);
    end
    timer_start();
  end

  always @(posedge clock) begin
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
      if (finish) begin
        $fdisplay(32'h80000002, "*** PASSED *** Completed after %d simulation cycles", trace_count);
        if (dump_wave) begin
          `WAVE_CLOSE
        end
        timer_result = timer_stop();
        $display("Finish time: %d ns", timer_result);
        // $writememh("test.hex", Testbench.testHarness.ldut.tile_prci_domain.tile_reset_domain_tile.frontend.tlb.r_need_gpa);
        $finish;
      end
    end
  end

  `MODEL testHarness(
    .clock(clock),
    .reset(reset),
    .io_uart_tx(uart_tx),
    .io_uart_rx(uart_rx)
  );

  wire [63:0] wdata;
  assign wdata = `PIPELINE.wb_ctrl_wfd ? `CPU_TOP.fpuOpt._T_42[63:0] : `PIPELINE.rf_wdata[63:0];

  RTLFUZZ_dromajo dromajo (
    .clock(clock),
    .reset(reset),
    .valid(`PIPELINE.csr_io_trace_0_valid),
    .hartid(`PIPELINE.io_hartid),
    .pc(`PIPELINE.csr_io_trace_0_iaddr),
    .inst(`PIPELINE.csr_io_trace_0_insn),
    .wdata(wdata),
    .mstatus({`PIPELINE.ll_waddr[4:0], `PIPELINE.ll_wen,!`PIPELINE.has_data}),
    .finish(finish));

  tty #(115200, 0) u0_tty(
   .STX(uart_rx),
   .SRX(uart_tx),
   .reset(reset)
  );

  // `include "StarshipASICTop.vh"
  // `include "TestHarness.vh"

endmodule