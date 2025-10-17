`define DUT_SOC_TOP     Testbench.testHarness.ldut
`define DUT_TILE_TOP    `DUT_SOC_TOP.tile_prci_domain
`define DUT_MEM_TOP     Testbench.testHarness.mem.srams.mem
`define DUT_MEM_REG     `DUT_MEM_TOP.mem_ext

`define VNT_SOC_TOP     Testbench.testHarness_variant.ldut

`ifdef TARGET_BOOM
  `define DUT_CPU_TOP   `DUT_TILE_TOP.tile_reset_domain_boom_tile
  `define DUT_PIPELINE  `DUT_CPU_TOP.core
  `define DUT_INTERRUPT `DUT_PIPELINE.io_interrupts_msip
`elsif TARGET_CVA6
  `define DUT_CPU_TOP   `DUT_TILE_TOP.tile_reset_domain_cva6_tile
  `define DUT_PIPELINE  `DUT_CPU_TOP.core.i_ariane.i_cva6
  `define DUT_INTERRUPT `DUT_PIPELINE.ipi_i
`elsif TARGET_XiangShan
  `define DUT_CPU_TOP   `DUT_TILE_TOP.tile_reset_domain_xiangshan_tile.core.core
  `define DUT_PIPELINE  `DUT_CPU_TOP.backend
  `define DUT_INTERRUPT `DUT_PIPELINE.io_externalInterrupt_msip
`else // TARGET_ROCKET
  `define DUT_CPU_TOP   `DUT_TILE_TOP.tile_reset_domain_tile
  `define DUT_PIPELINE  `DUT_CPU_TOP.core
  `define DUT_INTERRUPT `DUT_PIPELINE.io_interrupts_msip
`endif
