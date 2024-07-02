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

`define IS_DUT 1
`define IS_VNT 0

always @(posedge clock) begin
  if (!reset) begin
    event_handler(`DUT_ROB_ENQ_EN_0 && `DUT_ROB_ENQ_READY, `DUT_ROB_ENQ_INST_0, "ENQ", 0, `IS_DUT);
    event_handler(`DUT_ROB_ENQ_EN_1 && `DUT_ROB_ENQ_READY, `DUT_ROB_ENQ_INST_1, "ENQ", 1, `IS_DUT);
    event_handler(`DUT_ROB_DEQ_EN_0, `DUT_ROB_DEQ_INST_0, "DEQ", 0, `IS_DUT);
    event_handler(`DUT_ROB_DEQ_EN_1, `DUT_ROB_DEQ_INST_1, "DEQ", 1, `IS_DUT);

    `ifdef HASVARIANT
      event_handler(`VNT_ROB_ENQ_EN_0 && `VNT_ROB_ENQ_READY, `VNT_ROB_ENQ_INST_0, "ENQ", 0, `IS_VNT);
      event_handler(`VNT_ROB_ENQ_EN_1 && `VNT_ROB_ENQ_READY, `VNT_ROB_ENQ_INST_1, "ENQ", 1, `IS_VNT);
      event_handler(`VNT_ROB_DEQ_EN_0, `VNT_ROB_DEQ_INST_0, "DEQ", 0, `IS_VNT);
      event_handler(`VNT_ROB_DEQ_EN_1, `VNT_ROB_DEQ_INST_1, "DEQ", 1, `IS_VNT);
    `endif
  end
end
