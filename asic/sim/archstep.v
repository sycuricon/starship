module ArchStepBB(
    input clock,
    input reset,
    input valid,
    input [63:0] pc,
    input [31:0] inst,
    input [63:0] data
);
  always @(posedge clock) begin
    if (!reset) begin
      if (valid && Testbench.verbose) 
        $display("%t pc 0x%x inst 0x%x data 0x%x", $time, pc, inst, data);
    end
  end
endmodule

module MemMorpherBB(
  input clock,
  input reset,
  input valid,
  input valid_taint_0,
  input [63:0] addr,
  input [63:0] addr_taint_0,
  input [255:0] data_in,
  input [255:0] data_in_taint_0,
  output [255:0] data_out,
  output [255:0] data_out_taint_0,
  output [31:0] taint_sum
);
  reg [255:0] data_reg;
  byte unsigned is_variant;

	initial begin
		is_variant = {is_variant_hierachy($sformatf("%m"))};
	end

  always @(negedge clock) begin
    if (valid) begin
      data_reg[7:0]     = testbench_memory_read_byte(is_variant, addr[30:0] + 31'h0);
      data_reg[15:8]    = testbench_memory_read_byte(is_variant, addr[30:0] + 31'h1);
      data_reg[23:16]   = testbench_memory_read_byte(is_variant, addr[30:0] + 31'h2);
      data_reg[31:24]   = testbench_memory_read_byte(is_variant, addr[30:0] + 31'h3);
      data_reg[39:32]   = testbench_memory_read_byte(is_variant, addr[30:0] + 31'h4);
      data_reg[47:40]   = testbench_memory_read_byte(is_variant, addr[30:0] + 31'h5);
      data_reg[55:48]   = testbench_memory_read_byte(is_variant, addr[30:0] + 31'h6);
      data_reg[63:56]   = testbench_memory_read_byte(is_variant, addr[30:0] + 31'h7);
      data_reg[71:64]   = testbench_memory_read_byte(is_variant, addr[30:0] + 31'h8);
      data_reg[79:72]   = testbench_memory_read_byte(is_variant, addr[30:0] + 31'h9);
      data_reg[87:80]   = testbench_memory_read_byte(is_variant, addr[30:0] + 31'hA);
      data_reg[95:88]   = testbench_memory_read_byte(is_variant, addr[30:0] + 31'hB);
      data_reg[103:96]  = testbench_memory_read_byte(is_variant, addr[30:0] + 31'hC);
      data_reg[111:104] = testbench_memory_read_byte(is_variant, addr[30:0] + 31'hD);
      data_reg[119:112] = testbench_memory_read_byte(is_variant, addr[30:0] + 31'hE);
      data_reg[127:120] = testbench_memory_read_byte(is_variant, addr[30:0] + 31'hF);
      data_reg[135:128] = testbench_memory_read_byte(is_variant, addr[30:0] + 31'h10);
      data_reg[143:136] = testbench_memory_read_byte(is_variant, addr[30:0] + 31'h11);
      data_reg[151:144] = testbench_memory_read_byte(is_variant, addr[30:0] + 31'h12);
      data_reg[159:152] = testbench_memory_read_byte(is_variant, addr[30:0] + 31'h13);
      data_reg[167:160] = testbench_memory_read_byte(is_variant, addr[30:0] + 31'h14);
      data_reg[175:168] = testbench_memory_read_byte(is_variant, addr[30:0] + 31'h15);
      data_reg[183:176] = testbench_memory_read_byte(is_variant, addr[30:0] + 31'h16);
      data_reg[191:184] = testbench_memory_read_byte(is_variant, addr[30:0] + 31'h17);
      data_reg[199:192] = testbench_memory_read_byte(is_variant, addr[30:0] + 31'h18);
      data_reg[207:200] = testbench_memory_read_byte(is_variant, addr[30:0] + 31'h19);
      data_reg[215:208] = testbench_memory_read_byte(is_variant, addr[30:0] + 31'h1A);
      data_reg[223:216] = testbench_memory_read_byte(is_variant, addr[30:0] + 31'h1B);
      data_reg[231:224] = testbench_memory_read_byte(is_variant, addr[30:0] + 31'h1C);
      data_reg[239:232] = testbench_memory_read_byte(is_variant, addr[30:0] + 31'h1D);
      data_reg[247:240] = testbench_memory_read_byte(is_variant, addr[30:0] + 31'h1E);
      data_reg[255:248] = testbench_memory_read_byte(is_variant, addr[30:0] + 31'h1F);
    end  
  end

  assign data_out = data_reg;
  assign data_out_taint_0 = data_in_taint_0;
  assign taint_sum = 0;

endmodule
