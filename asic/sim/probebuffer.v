import "DPI-C" function void parafuzz_probebuff_tick (longint unsigned data);
import "DPI-C" function byte is_variant_hierachy(string hierarchy);

module ProbeBufferBB (
    input clock,
    input reset,
    input [63:0] write,
    input wen,
    output [63:0] read
);

   always @(negedge clock) begin
        if (!reset) begin
            if (wen && !is_variant_hierachy($sformatf("%m"))) begin
                parafuzz_probebuff_tick(write);
            end
        end
   end

  assign read = 0;

endmodule
