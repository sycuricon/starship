`define DUT_ROB_ENQ_EN_0        `DUT_SOC_TOP.tile_prci_domain.tile_reset_domain_boom_tile.core.rob.io_enq_valids_0
`define DUT_ROB_ENQ_INST_0      `DUT_SOC_TOP.tile_prci_domain.tile_reset_domain_boom_tile.core.rob.io_enq_uops_0_debug_inst
`define DUT_ROB_DEQ_EN_0        `DUT_SOC_TOP.tile_prci_domain.tile_reset_domain_boom_tile.core.rob.io_commit_valids_0
`define DUT_ROB_DEQ_INST_0      `DUT_SOC_TOP.tile_prci_domain.tile_reset_domain_boom_tile.core.rob.io_commit_uops_0_debug_inst

`define VNT_ROB_ENQ_EN_0        `VNT_SOC_TOP.tile_prci_domain.tile_reset_domain_boom_tile.core.rob.io_enq_valids_0
`define VNT_ROB_ENQ_INST_0      `VNT_SOC_TOP.tile_prci_domain.tile_reset_domain_boom_tile.core.rob.io_enq_uops_0_debug_inst
`define VNT_ROB_DEQ_EN_0        `VNT_SOC_TOP.tile_prci_domain.tile_reset_domain_boom_tile.core.rob.io_commit_valids_0
`define VNT_ROB_DEQ_INST_0      `VNT_SOC_TOP.tile_prci_domain.tile_reset_domain_boom_tile.core.rob.io_commit_uops_0_debug_inst

`define IS_DUT 1
`define IS_VNT 0

always @(posedge clock) begin
  if (!reset) begin
    event_handler(`DUT_ROB_ENQ_EN_0, `DUT_ROB_ENQ_INST_0, "ENQ", 0, `IS_DUT);
    event_handler(`DUT_ROB_DEQ_EN_0, `DUT_ROB_DEQ_INST_0, "DEQ", 0, `IS_DUT);

    `ifdef HASVARIANT
      event_handler(`VNT_ROB_ENQ_EN_0, `VNT_ROB_ENQ_INST_0, "ENQ", 0, `IS_VNT);
      event_handler(`VNT_ROB_DEQ_EN_0, `VNT_ROB_DEQ_INST_0, "DEQ", 0, `IS_VNT);
    `endif
  end
end

`ifdef HASVARIANT
always @(posedge clock) begin
  if (reset) begin
    sync <= 1'b1;
  end
  else begin
    if (`DUT_ROB_ENQ_EN_0 != `VNT_ROB_ENQ_EN_0) begin
      sync <= 1'b0;
    end
    else begin
      if (`DUT_ROB_ENQ_INST_0 != `VNT_ROB_ENQ_INST_0) begin
        sync <= 1'b0;
      end
    end
  end
end

always @(negedge clock) begin
  if (reset) begin
    victim_done <= 1'b0;
  end
  if (!sync) begin
    if (`DUT_ROB_DEQ_EN_0 && (`DUT_ROB_DEQ_INST_0 == `INFO_DELAY_END)) begin
      victim_done <= 1;
    end
    if (`VNT_ROB_DEQ_EN_0 && (`VNT_ROB_DEQ_INST_0 == `INFO_DELAY_END)) begin
      victim_done <= 1;
    end
  end
end
`endif
