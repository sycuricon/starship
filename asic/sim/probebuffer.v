import "DPI-C" function void parafuzz_probebuff_tick(byte unsigned is_variant, longint unsigned data);
import "DPI-C" function byte unsigned is_variant_hierachy(string hierarchy);

module ProbeBufferBB (
    input clock,
    input reset,
    input wen,
    input wen_taint_0,
    input [63:0] write,
    input [63:0] write_taint_0,
    output [63:0] read,
    output [63:0] read_taint_0,
    output [31:0] taint_sum
);

    byte unsigned is_variant;
    initial begin
        is_variant = is_variant_hierachy($sformatf("%m"));
    end

    always @(negedge clock) begin
        if (!reset) begin
            if (wen) begin
                parafuzz_probebuff_tick(is_variant ,write);
            end
        end
    end

  assign read = is_variant ? 0 : -1;
  assign read_taint_0 = -1;
  assign taint_sum = 0;

endmodule
