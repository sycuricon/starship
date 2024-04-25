import "DPI-C" function void parafuzz_probebuff_tick(byte unsigned is_variant, longint unsigned data);
import "DPI-C" function byte unsigned is_variant_hierachy(string hierarchy);

module ProbeBufferBB (
    input clock,
    input reset,
    input [63:0] write,
    input wen,
    output [63:0] read
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

  assign read = 0;

endmodule
