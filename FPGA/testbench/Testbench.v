`timescale 1ns / 1ps

module Testbench( );
    
    // reg reset;
    // reg clk;
    // reg uart_rx;
    // wire uart_tx;

    // initial begin
    //     reset = 1;
    //     clk = 1;
    //     uart_rx = 1;
    //     #200;
    //     reset = 0;
    // end
    // always #5 clk = ~clk;

    StarshipFPGATop top(
        .clock(),
        .reset(),
        .resetctrl_hartIsInReset_0(), 
        .debug_clock(), 
        .debug_reset(), 
        .debug_systemjtag_jtag_TCK(), 
        .debug_systemjtag_jtag_TMS(), 
        .debug_systemjtag_jtag_TDI(), 
        .debug_systemjtag_jtag_TDO_data(), 
        .debug_systemjtag_jtag_TDO_driven(), 
        .debug_systemjtag_reset(), 
        .debug_systemjtag_mfr_id(), 
        .debug_systemjtag_part_number(), 
        .debug_systemjtag_version(), 
        .debug_ndreset(), 
        .debug_dmactive(), 
        .debug_dmactiveAck(), 
        .uart_0_txd(), 
        .uart_0_rxd(), 
        .spi_0_sck(), 
        .spi_0_dq_0_i(), 
        .spi_0_dq_0_o(), 
        .spi_0_dq_0_ie(), 
        .spi_0_dq_0_oe(), 
        .spi_0_dq_1_i(), 
        .spi_0_dq_1_o(), 
        .spi_0_dq_1_ie(), 
        .spi_0_dq_1_oe(), 
        .spi_0_dq_2_i(), 
        .spi_0_dq_2_o(), 
        .spi_0_dq_2_ie(), 
        .spi_0_dq_2_oe(), 
        .spi_0_dq_3_i(), 
        .spi_0_dq_3_o(), 
        .spi_0_dq_3_ie(), 
        .spi_0_dq_3_oe(), 
        .spi_0_cs_0(), 
        .xilinxvc707mig_ddr3_addr(), 
        .xilinxvc707mig_ddr3_ba(), 
        .xilinxvc707mig_ddr3_ras_n(), 
        .xilinxvc707mig_ddr3_cas_n(), 
        .xilinxvc707mig_ddr3_we_n(), 
        .xilinxvc707mig_ddr3_reset_n(), 
        .xilinxvc707mig_ddr3_ck_p(), 
        .xilinxvc707mig_ddr3_ck_n(), 
        .xilinxvc707mig_ddr3_cke(), 
        .xilinxvc707mig_ddr3_cs_n(), 
        .xilinxvc707mig_ddr3_dm(), 
        .xilinxvc707mig_ddr3_odt(), 
        .xilinxvc707mig_ddr3_dq(), 
        .xilinxvc707mig_ddr3_dqs_n(), 
        .xilinxvc707mig_ddr3_dqs_p(), 
        .xilinxvc707mig_sys_clk_i(), 
        .xilinxvc707mig_ui_clk(), 
        .xilinxvc707mig_ui_clk_sync_rst(), 
        .xilinxvc707mig_mmcm_locked(), 
        .xilinxvc707mig_aresetn(), 
        .xilinxvc707mig_init_calib_complete(), 
        .xilinxvc707mig_sys_rst(), 
        .io_covSum(),
        .metaReset()
    );
        
endmodule
