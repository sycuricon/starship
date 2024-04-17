yosys read_verilog -sv build/rocket-chip/BOOM.$::env(YOSYS_TOP).$::env(YOSYS_CONFIG).top.v.untainted
yosys read_verilog -sv asic/ift/blackbox.v
yosys read_verilog -sv build/rocket-chip/BOOM.$::env(YOSYS_TOP).$::env(YOSYS_CONFIG).behav_srams.top.v

yosys hierarchy -top $::env(YOSYS_TOP)

yosys proc
yosys opt
yosys pmuxtree
yosys bmuxmap
yosys opt
yosys memory_collect
yosys opt

yosys tee -o build/rocket-chip/sink_summary.log tsink --verbose --top $::env(YOSYS_TOP)

yosys pift --ignore-ports clock,reset --verbose
yosys opt -purge
yosys tcov --verbose

yosys write_verilog build/rocket-chip/BOOM.$::env(YOSYS_TOP).$::env(YOSYS_CONFIG).top.v
