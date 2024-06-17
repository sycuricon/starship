yosys read_verilog -sv build/rocket-chip/XiangShan.$::env(YOSYS_TOP).$::env(YOSYS_CONFIG).top.opt.v
yosys read_verilog -sv asic/yosys/blackbox.v

yosys hierarchy -top $::env(YOSYS_TOP)

yosys proc
yosys memory_collect
yosys opt -purge

# yosys tee -o build/rocket-chip/sink_summary.log tsink --verbose --top $::env(YOSYS_TOP)

yosys tee -o build/rocket-chip/xiangshan_ift.log pift --verbose --ignore-ports clock,reset --vec_anno build/rocket-chip/XiangShan.$::env(YOSYS_TOP).$::env(YOSYS_CONFIG).vec
yosys anno_chisel_sram --verbose
yosys tcov --verbose
yosys opt -purge

yosys tsink --verbose --output build/rocket-chip/XiangShan.$::env(YOSYS_TOP).$::env(YOSYS_CONFIG).sink

yosys write_verilog -simple-lhs build/rocket-chip/XiangShan.$::env(YOSYS_TOP).$::env(YOSYS_CONFIG).top.ift.v
