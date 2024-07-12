//VCS coverage exclude_file
`timescale 1ns / 10ps

`ifndef RESET_DELAY
  `define RESET_DELAY 15.7
`endif

`include "xref_common.vh"


module Testbench;
  
  reg clock = 1'b0;
  reg reset = 1'b1;

  wire interrupt;

  always #(`CLOCK_PERIOD/2.0) clock = ~clock;
  initial #(`RESET_DELAY) reset = 0;

  int unsigned rand_value;
  string test_name = "starship";

  reg [255:0] reason = "";
  reg failure = 1'b0;
  reg verbose = 1'b0;
  reg dump_wave = 1'b0;
  reg jtag_rbb_enable = 1'b0;
  reg [63:0] max_cycles = 0;
  reg [63:0] dump_start = 0;
  reg [63:0] trace_count = 0;
  reg [2047:0] fsdbfile = 0;
  reg [2047:0] vcdplusfile = 0;
  reg [2047:0] vcdfile = 0;

  wire [63:0] tohost = 0;
  wire printf_cond = verbose && !reset;
  wire uart_rx, uart_tx;

  initial begin
    void'($value$plusargs("label=%s", test_name));
    void'($value$plusargs("max-cycles=%d", max_cycles));
    void'($value$plusargs("dump-start=%d", dump_start));
    void'($value$plusargs("jtag_rbb_enable=%d", jtag_rbb_enable));
    verbose = $test$plusargs("verbose");
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
        $fsdbDumpfile({`TOP_DIR, "/wave/", test_name, ".fsdb"});
        $fsdbDumpvars(0, "+all");
      `elsif DEBUG_VCD
        `define WAVE_ON     $dumpon;
        `define WAVE_CLOSE  $dumpoff;
        $dumpfile({`TOP_DIR, "/wave/", test_name, ".vcd"});
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
          if (dump_wave) begin
            `WAVE_CLOSE
          end
          $fatal;
        end
        if (tohost & 1'b1) begin
          $fdisplay(32'h80000002, "*** PASSED *** Completed after %d simulation cycles", trace_count);
          trace_count = 0;
          if (dump_wave) begin
            `WAVE_CLOSE
          end
          $system("echo -e \"\033[31m[>] vcs done `date +%s.%3N` \033[0m\"");
          $finish;
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

`ifdef HASVARIANT
  TestHarness testHarness_variant(
    .clock(clock),
    .reset(reset),
    .io_uart_tx(),
    .io_uart_rx(1'b0)
  // .io_uart_tx(uart_tx),
  // .io_uart_rx(uart_rx)
  );

  defparam `DUT_SOC_TOP.IFT_RULE = "data";
  defparam `DUT_CPU_TOP.IFT_RULE = "diva";
`endif

  // tty #(115200, 0) u0_tty(
  //  .STX(uart_rx),
  //  .SRX(uart_tx),
  //  .reset(reset)
  // );

endmodule
