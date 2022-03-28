module Probe_StarshipASICTop #(parameter WIDTH)
(
  input clock,
  input reset,
  input finish,
  input [WIDTH - 1:0] state
);

  reg [WIDTH - 1:0] prev_state;
  integer i, ones;
  int map[longint];
  wire [WIDTH - 1:0] toggle = prev_state ^ state;

  integer heatMapFile;
  initial begin
    heatMapFile = $fopen("./heat.map", "w");
  end

  always @(posedge clock) begin
    if (reset) begin
      prev_state <= 0;
    end else begin
      prev_state <= state;
      ones = $countones(toggle);
      $fdisplay(heatMapFile, "%b", toggle) ;
    end
    // $display("result is %x", toggle);

  end
endmodule

module Probe_TestHarness #(parameter WIDTH)
(
  input clock,
  input reset,
  input finish,
  input [WIDTH - 1:0] state
);

endmodule