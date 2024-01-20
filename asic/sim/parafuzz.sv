import "DPI-C" function void parafuzz_probebuff_tick (longint unsigned data);
import "DPI-C" function byte is_variant(string hierarchy);

module ProbeBufferBB (
    input clock,
    input reset,
    input [63:0] write,
    input wen,
    output [63:0] read
);

   always @(negedge clock) begin
        if (!reset) begin
            if (wen && !is_variant($sformatf("%m"))) begin
                parafuzz_probebuff_tick(write);
            end
        end
   end

  assign read = 0;

endmodule

// module TaintSource (
//   input         clock,
//   input         reset,
//   input         mem_axi4_0_ar_ready,
//   input         mem_axi4_0_ar_valid,
//   input  [3:0]  mem_axi4_0_ar_bits_id,
//   input  [31:0] mem_axi4_0_ar_bits_addr,
//   input         mem_axi4_0_r_ready,
//   input         mem_axi4_0_r_valid,
//   input  [3:0]  mem_axi4_0_r_bits_id,
//   output [63:0] mem_axi4_0_r_bits_data_taint_0
// );

//     reg [31:0] last_addr;
//     reg [3:0] last_id;
//     always @(posedge clock) begin
//         if (reset) begin
//             last_addr <= 0;
//             last_id <= 0;
//         end else begin
//             if (mem_axi4_0_ar_valid && mem_axi4_0_ar_ready) begin
//                 last_addr <= mem_axi4_0_ar_bits_addr;
//                 last_id <= mem_axi4_0_ar_bits_id;
//             end
//         end
//     end

//     reg [63:0] taint_source;
//     always @(*) begin
//         taint_source = 0;
//         if (mem_axi4_0_r_valid && mem_axi4_0_r_ready) begin
//             if (mem_axi4_0_r_bits_id == last_id && 
//                 last_addr >= 32'h80004000 &&
//                 last_addr < 32'h80005000) begin
//                 taint_source = -1;
//             end
//         end
//     end

//     assign mem_axi4_0_r_bits_data_taint_0 = taint_source;

// endmodule
