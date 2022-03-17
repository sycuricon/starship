module Probe_StarshipASICTop #(parameter WIDTH)
(
  input clock,
  input reset,
  input finish,
  input [WIDTH - 1:0] state
);

  // always @(posedge clock) begin
  //   if (!reset) begin
  //     if (max_cycles > 0 && trace_count > max_cycles) begin
  //       reason = " (timeout)";
  //       failure = 1'b1;
  //     end

  //     if (failure) begin
  //       $fdisplay(32'h80000002, "*** FAILED ***%s after %d simulation cycles", reason, trace_count);
  //       `WAVE_CLOSE
  //       $fatal;
  //     end

  //     if (finish) begin
  //       $fdisplay(32'h80000002, "*** PASSED *** Completed after %d simulation cycles", trace_count);
  //       `WAVE_CLOSE
  //       $display("Finish time: %t", $realtime);
  //       $system("date +%s%N");
  //       $finish;
  //     end
  //   end
  // end

endmodule

module Probe_TestHarness #(parameter WIDTH)
(
  input clock,
  input reset,
  input finish,
  input [WIDTH - 1:0] state
);

endmodule