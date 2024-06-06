import "DPI-C" function longint unsigned parafuzz_probebuff_tick(byte unsigned is_variant, longint unsigned data);
import "DPI-C" function byte unsigned is_variant_hierachy(string hierarchy);

`define CMD_GIVE_ME_SECRET 64'hAF1B_608E_883D_0000

module ProbeBufferBB (
    input clock,
    input reset,
    input wen,
    input wen_taint_0,
    input [63:0] write,
    input [63:0] write_taint_0,
    output reg [63:0] read,
    output reg [63:0] read_taint_0,
    output [31:0] taint_sum
);

    byte unsigned is_variant;
    initial begin
        is_variant = is_variant_hierachy($sformatf("%m"));
    end

    always @(negedge clock) begin
        if (!reset) begin
            if (wen) begin
                read <= parafuzz_probebuff_tick(is_variant, write);
                if (write == `CMD_GIVE_ME_SECRET) begin
                    read_taint_0 <= {64{1'b1}};
                end
                else begin
                    read_taint_0 <= {64{1'b0}};
                end
            end
        end
    end

  assign taint_sum = 0;

endmodule
