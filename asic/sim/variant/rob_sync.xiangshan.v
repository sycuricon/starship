`define DUT_ROB_ENQ_EN_0        `DUT_SOC_TOP.tile_prci_domain.tile_reset_domain_xiangshan_tile.core.core.backend.ctrlBlock.rob.io_enq_req_0_valid
`define DUT_ROB_ENQ_INST_0      `DUT_SOC_TOP.tile_prci_domain.tile_reset_domain_xiangshan_tile.core.core.backend.ctrlBlock.rob.io_enq_req_0_bits_cf_instr
`define DUT_ROB_ENQ_PC_0        `DUT_SOC_TOP.tile_prci_domain.tile_reset_domain_xiangshan_tile.core.core.backend.ctrlBlock.rob.io_enq_req_0_bits_cf_pc
`define DUT_ROB_ENQ_EN_1        `DUT_SOC_TOP.tile_prci_domain.tile_reset_domain_xiangshan_tile.core.core.backend.ctrlBlock.rob.io_enq_req_1_valid
`define DUT_ROB_ENQ_INST_1      `DUT_SOC_TOP.tile_prci_domain.tile_reset_domain_xiangshan_tile.core.core.backend.ctrlBlock.rob.io_enq_req_1_bits_cf_instr
`define DUT_ROB_ENQ_PC_1        `DUT_SOC_TOP.tile_prci_domain.tile_reset_domain_xiangshan_tile.core.core.backend.ctrlBlock.rob.io_enq_req_1_bits_cf_pc
`define DUT_ROB_ENQ_READY       `DUT_SOC_TOP.tile_prci_domain.tile_reset_domain_xiangshan_tile.core.core.backend.ctrlBlock.rob.io_enq_canAccept

`define DUT_ROB_DEQ_EN_0        `DUT_SOC_TOP.tile_prci_domain.tile_reset_domain_xiangshan_tile.core.core.backend.ctrlBlock.rob.arch_step.valid
`define DUT_ROB_DEQ_INST_0      `DUT_SOC_TOP.tile_prci_domain.tile_reset_domain_xiangshan_tile.core.core.backend.ctrlBlock.rob.arch_step.inst
`define DUT_ROB_DEQ_PC_0        `DUT_SOC_TOP.tile_prci_domain.tile_reset_domain_xiangshan_tile.core.core.backend.ctrlBlock.rob.arch_step.pc
`define DUT_ROB_DEQ_DATA_0      `DUT_SOC_TOP.tile_prci_domain.tile_reset_domain_xiangshan_tile.core.core.backend.ctrlBlock.rob.arch_step.data
`define DUT_ROB_DEQ_EN_1        `DUT_SOC_TOP.tile_prci_domain.tile_reset_domain_xiangshan_tile.core.core.backend.ctrlBlock.rob.arch_step_1.valid
`define DUT_ROB_DEQ_INST_1      `DUT_SOC_TOP.tile_prci_domain.tile_reset_domain_xiangshan_tile.core.core.backend.ctrlBlock.rob.arch_step_1.inst
`define DUT_ROB_DEQ_PC_1        `DUT_SOC_TOP.tile_prci_domain.tile_reset_domain_xiangshan_tile.core.core.backend.ctrlBlock.rob.arch_step_1.pc
`define DUT_ROB_DEQ_DATA_1      `DUT_SOC_TOP.tile_prci_domain.tile_reset_domain_xiangshan_tile.core.core.backend.ctrlBlock.rob.arch_step_1.data

`define VNT_ROB_ENQ_EN_0        `VNT_SOC_TOP.tile_prci_domain.tile_reset_domain_xiangshan_tile.core.core.backend.ctrlBlock.rob.io_enq_req_0_valid
`define VNT_ROB_ENQ_INST_0      `VNT_SOC_TOP.tile_prci_domain.tile_reset_domain_xiangshan_tile.core.core.backend.ctrlBlock.rob.io_enq_req_0_bits_cf_instr
`define VNT_ROB_ENQ_EN_1        `VNT_SOC_TOP.tile_prci_domain.tile_reset_domain_xiangshan_tile.core.core.backend.ctrlBlock.rob.io_enq_req_1_valid
`define VNT_ROB_ENQ_INST_1      `VNT_SOC_TOP.tile_prci_domain.tile_reset_domain_xiangshan_tile.core.core.backend.ctrlBlock.rob.io_enq_req_1_bits_cf_instr
`define VNT_ROB_ENQ_READY       `VNT_SOC_TOP.tile_prci_domain.tile_reset_domain_xiangshan_tile.core.core.backend.ctrlBlock.rob.io_enq_canAccept

`define VNT_ROB_DEQ_EN_0        `VNT_SOC_TOP.tile_prci_domain.tile_reset_domain_xiangshan_tile.core.core.backend.ctrlBlock.rob.arch_step.valid
`define VNT_ROB_DEQ_INST_0      `VNT_SOC_TOP.tile_prci_domain.tile_reset_domain_xiangshan_tile.core.core.backend.ctrlBlock.rob.arch_step.inst
`define VNT_ROB_DEQ_PC_0        `VNT_SOC_TOP.tile_prci_domain.tile_reset_domain_xiangshan_tile.core.core.backend.ctrlBlock.rob.arch_step.pc
`define VNT_ROB_DEQ_DATA_0      `VNT_SOC_TOP.tile_prci_domain.tile_reset_domain_xiangshan_tile.core.core.backend.ctrlBlock.rob.arch_step.data
`define VNT_ROB_DEQ_EN_1        `VNT_SOC_TOP.tile_prci_domain.tile_reset_domain_xiangshan_tile.core.core.backend.ctrlBlock.rob.arch_step_1.valid
`define VNT_ROB_DEQ_INST_1      `VNT_SOC_TOP.tile_prci_domain.tile_reset_domain_xiangshan_tile.core.core.backend.ctrlBlock.rob.arch_step_1.inst
`define VNT_ROB_DEQ_PC_1        `VNT_SOC_TOP.tile_prci_domain.tile_reset_domain_xiangshan_tile.core.core.backend.ctrlBlock.rob.arch_step_1.pc
`define VNT_ROB_DEQ_DATA_1      `VNT_SOC_TOP.tile_prci_domain.tile_reset_domain_xiangshan_tile.core.core.backend.ctrlBlock.rob.arch_step_1.data


always @(posedge clock) begin
  if (!reset) begin
`ifdef HASVARIANT
    $fwrite(taint_fd, "%t, %d, %d\n", $time, `DUT_SOC_TOP.taint_sum, `VNT_SOC_TOP.taint_sum);
`endif
    event_handler(`DUT_ROB_ENQ_EN_0 && `DUT_ROB_ENQ_READY, `DUT_ROB_ENQ_INST_0, "ENQ", 0);
    event_handler(`DUT_ROB_ENQ_EN_1 && `DUT_ROB_ENQ_READY, `DUT_ROB_ENQ_INST_1, "ENQ", 1);
    event_handler(`DUT_ROB_DEQ_EN_0, `DUT_ROB_DEQ_INST_0, "DEQ", 0);
    event_handler(`DUT_ROB_DEQ_EN_1, `DUT_ROB_DEQ_INST_1, "DEQ", 1);
  end
end

`ifdef HASVARIANT
always @(posedge clock) begin
  if (reset) begin
    sync <= 1'b1;
  end
  else begin
    if (
      (`DUT_ROB_ENQ_EN_0 != `VNT_ROB_ENQ_EN_0) ||
      (`DUT_ROB_ENQ_EN_1 != `VNT_ROB_ENQ_EN_1)
    ) begin
      sync <= 1'b0;
    end
    else begin
      if (
        ((`DUT_ROB_ENQ_EN_0 == `VNT_ROB_ENQ_EN_0) && (`DUT_ROB_ENQ_INST_0 != `VNT_ROB_ENQ_INST_0)) ||
        ((`DUT_ROB_ENQ_EN_1 == `VNT_ROB_ENQ_EN_1) && (`DUT_ROB_ENQ_INST_1 != `VNT_ROB_ENQ_INST_1))
      ) begin
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
    if (
      (`DUT_ROB_DEQ_EN_0 && (`DUT_ROB_DEQ_INST_0 == `INFO_DELAY_END)) ||
      (`DUT_ROB_DEQ_EN_1 && (`DUT_ROB_DEQ_INST_1 == `INFO_DELAY_END))
    ) begin
      victim_done <= 1;
    end
    if (
      (`VNT_ROB_DEQ_EN_0 && (`VNT_ROB_DEQ_INST_0 == `INFO_DELAY_END)) ||
      (`VNT_ROB_DEQ_EN_1 && (`VNT_ROB_DEQ_INST_1 == `INFO_DELAY_END))
    ) begin
      victim_done <= 1;
    end
  end
end
`endif
