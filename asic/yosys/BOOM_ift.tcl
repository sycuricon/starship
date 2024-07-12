yosys read_verilog -sv build/rocket-chip/BOOM.$::env(YOSYS_TOP).$::env(YOSYS_CONFIG).top.opt.v
yosys read_verilog -sv asic/yosys/blackbox.v

yosys hierarchy -top $::env(YOSYS_TOP)

yosys proc
yosys memory_collect
yosys opt -purge

# yosys tee -o build/rocket-chip/sink_summary.log tsink --verbose --top $::env(YOSYS_TOP)

yosys tee -o build/rocket-chip/boom_ift.log     pift --verbose --liveness --ignore-ports clock,reset --vec_anno build/rocket-chip/BOOM.$::env(YOSYS_TOP).$::env(YOSYS_CONFIG).vec
yosys tee -o build/rocket-chip/boom_sram.log    anno_chisel_sram --verbose
yosys tee -o build/rocket-chip/boom_sram.log    tcov --verbose
yosys tsum --verbose

yosys opt -purge

yosys thook

yosys write_verilog -simple-lhs build/rocket-chip/BOOM.$::env(YOSYS_TOP).$::env(YOSYS_CONFIG).top.ift.v
