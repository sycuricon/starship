yosys read_verilog -sv build/rocket-chip/BOOM.$::env(YOSYS_TOP).$::env(YOSYS_CONFIG).top.v
yosys read_verilog -sv asic/yosys/blackbox.v
yosys read_verilog -sv build/rocket-chip/BOOM.$::env(YOSYS_TOP).$::env(YOSYS_CONFIG).behav_srams.top.v

yosys hierarchy -top $::env(YOSYS_TOP)

yosys proc
yosys pmuxtree
yosys bmuxmap
yosys opt -purge

yosys write_verilog -simple-lhs build/rocket-chip/BOOM.$::env(YOSYS_TOP).$::env(YOSYS_CONFIG).top.opt.v
