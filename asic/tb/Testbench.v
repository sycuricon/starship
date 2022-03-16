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


module Testbench;

  reg clock = 1'b0;
  reg reset = 1'b1;

  always #(`CLOCK_PERIOD/2.0) clock = ~clock;
  initial #(`RESET_DELAY) reset = 0;

  int unsigned rand_value;
  string testcase;
  
  reg [255:0] reason = "";
  reg failure = 1'b0;
  reg verbose = 1'b0;
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

`ifdef DEBUG
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


    if (dump_start == 0) begin
      // Start dumping before first clock edge to capture reset sequence in waveform
      `WAVE_ON
    end

    // Memory Initialize
    #(`RESET_DELAY/2.0) 
    if ($value$plusargs("testcase=%s", testcase)) begin
        $display("Load testcase: %s", testcase);
        $readmemh(testcase, `MEM_RPL.ram);
    end
    $system("date +%s%N");

  end

  always @(posedge clock) begin

    trace_count = trace_count + 1;


    if (trace_count == dump_start) begin
    `WAVE_ON
    end


    if (!reset) begin
      if (max_cycles > 0 && trace_count > max_cycles) begin
        reason = " (timeout)";
        failure = 1'b1;
      end

      if (failure) begin
        $fdisplay(32'h80000002, "*** FAILED ***%s after %d simulation cycles", reason, trace_count);
        `WAVE_CLOSE
        $fatal;
      end

      if (finish) begin
        $fdisplay(32'h80000002, "*** PASSED *** Completed after %d simulation cycles", trace_count);
        `WAVE_CLOSE
        $display("Finish time: %t", $realtime);
        $system("date +%s%N");
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

  RTLFUZZ_dromajo dromajo (
    .clock(clock),
    .reset(reset),
    .valid(`PIPELINE.csr_io_trace_0_valid),
    .hartid(`PIPELINE.io_hartid),
    .pc(`PIPELINE.csr_io_trace_0_iaddr),
    .inst(`PIPELINE.csr_io_trace_0_insn),
    .wdata(`PIPELINE.rf_wdata[63:0]),
    .mstatus(),
    .finish(finish));

  tty #(115200, 0) u0_tty(
   .STX(uart_rx),
   .SRX(uart_tx),
   .reset(reset)
  );

endmodule


//  Copyright (c) by Ando Ki.
module tty #(parameter BAUD_RATE  = 115200, LOOPBACK=1)
(
   output  reg   STX,
   input   wire  SRX,
   input   wire  reset
);
   integer uart_file_desc;
   reg tick = 0;

   initial begin
     uart_file_desc = $fopen({`TOP_DIR, "/log/tty.log"}, "w");
   end

   localparam INTERVAL = (100000000/BAUD_RATE); // nsec

   reg [7:0] data  = 0;
   initial begin STX = 1'b1; end

   always @ (negedge SRX) begin
      if (!reset) begin
        tick = 1;
        #(100) tick = 0;
        receive(data);
        $write("%c", data); 
        $fflush();
        $fdisplay(uart_file_desc, "%c", data) ;
        $fflush();
        if (LOOPBACK) send(data);
      end
   end

   task receive;
        output [7:0] value;
        integer      x;
   begin
          #(INTERVAL*1.5 - 100);
          for (x=0; x<8; x=x+1) begin // LSB comes first
                  tick = 1;
                  #(100) tick = 0;
                  value[x] = SRX;
                  #(INTERVAL-100);
          end
   end
   endtask

   task send;
        input [7:0] value;
        integer     y;
   begin
        STX = 1'b0;
        #(INTERVAL);
        for (y=0; y<8; y=y+1) begin // LSB goes first
           STX = value[y];
           #(INTERVAL);
        end
        STX = 1'b1;
        #(INTERVAL);
   end
   endtask
endmodule