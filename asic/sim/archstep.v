module ArchStepBB(
    input clock,
    input reset,
    input valid,
    input [63:0] pc,
    input [31:0] inst
);
  always @(posedge clock) begin
    if (!reset) begin
      if (valid && Testbench.verbose) 
        $display("%t pc 0x%x inst 0x%x", $time, pc, inst);
    end
  end
endmodule
