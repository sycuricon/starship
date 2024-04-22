import "DPI-C" function void swap_memory_write_byte(byte idx, longint addr, byte data);
import "DPI-C" function byte swap_memory_read_byte(byte idx, longint addr);
import "DPI-C" function void swap_memory_initial(byte idx, string origin_dist, string variant_dist);

module mem_ext(
  input W0_clk,
  input [ADDR_WIDTH-1:0] W0_addr,
  input W0_en,
  input [DATA_WIDTH-1:0] W0_data,
  input [MASK_WIDTH-1:0] W0_mask,
  
  input R0_clk,
  input [ADDR_WIDTH-1:0] R0_addr,
  input R0_en,
  output [DATA_WIDTH-1:0] R0_data
);

  reg [7:0] idx;
  string origin_dist, variant_dist;
  initial begin
    idx = {is_variant_hierachy($sformatf("%m"))};
    void'($value$plusargs("origin_dist=%s", origin_dist));
    void'($value$plusargs("variant_dist=%s", variant_dist));
    swap_memory_initial(idx, origin_dist, variant_dist);
  end

  reg [DATA_WIDTH-1:0] R0_tmp_data;
  assign R0_data = R0_tmp_data;

  always @(posedge R0_clk)begin
    if (R0_en) begin
      R0_tmp_data[7:0]   <= swap_memory_read_byte(idx, {(64-ADDR_WIDTH-3)'h0 ,R0_addr, 3'h0});
      R0_tmp_data[15:8]  <= swap_memory_read_byte(idx, {(64-ADDR_WIDTH-3)'h0 ,R0_addr, 3'h1});
      R0_tmp_data[23:16] <= swap_memory_read_byte(idx, {(64-ADDR_WIDTH-3)'h0 ,R0_addr, 3'h2});
      R0_tmp_data[31:24] <= swap_memory_read_byte(idx, {(64-ADDR_WIDTH-3)'h0 ,R0_addr, 3'h3});
      R0_tmp_data[39:32] <= swap_memory_read_byte(idx, {(64-ADDR_WIDTH-3)'h0 ,R0_addr, 3'h4});
      R0_tmp_data[47:40] <= swap_memory_read_byte(idx, {(64-ADDR_WIDTH-3)'h0 ,R0_addr, 3'h5});
      R0_tmp_data[55:48] <= swap_memory_read_byte(idx, {(64-ADDR_WIDTH-3)'h0 ,R0_addr, 3'h6});
      R0_tmp_data[63:56] <= swap_memory_read_byte(idx, {(64-ADDR_WIDTH-3)'h0 ,R0_addr, 3'h7});
    end
  end

  always @(posedge W0_clk)begin
    if (W0_en) begin
      if (W0_mask[0]) swap_memory_write_byte(idx, {(64-ADDR_WIDTH-3)'h0 ,W0_addr, 3'h0}, W0_data[7:0]);
      if (W0_mask[1]) swap_memory_write_byte(idx, {(64-ADDR_WIDTH-3)'h0 ,W0_addr, 3'h1}, W0_data[15:8]);
      if (W0_mask[2]) swap_memory_write_byte(idx, {(64-ADDR_WIDTH-3)'h0 ,W0_addr, 3'h2}, W0_data[23:16]);
      if (W0_mask[3]) swap_memory_write_byte(idx, {(64-ADDR_WIDTH-3)'h0 ,W0_addr, 3'h3}, W0_data[31:24]);
      if (W0_mask[4]) swap_memory_write_byte(idx, {(64-ADDR_WIDTH-3)'h0 ,W0_addr, 3'h4}, W0_data[39:32]);
      if (W0_mask[5]) swap_memory_write_byte(idx, {(64-ADDR_WIDTH-3)'h0 ,W0_addr, 3'h5}, W0_data[47:40]);
      if (W0_mask[6]) swap_memory_write_byte(idx, {(64-ADDR_WIDTH-3)'h0 ,W0_addr, 3'h6}, W0_data[55:48]);
      if (W0_mask[7]) swap_memory_write_byte(idx, {(64-ADDR_WIDTH-3)'h0 ,W0_addr, 3'h7}, W0_data[63:56]);
    end
  end

endmodule
