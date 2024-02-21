# Verilog Generation Configuration
##################################

STARSHIP_CORE	?= BOOM
STARSHIP_FREQ	?= 100
STARSHIP_TH 	?= starship.asic.TestHarness
STARSHIP_TOP	?= starship.asic.StarshipSimTop
STARSHIP_CONFIG	?= starship.asic.StarshipSimConfig


# FPGA Configuration
####################

STARSHIP_BOARD	?= vc707


# Simulation Configuration
##########################

STARSHIP_TESTCASE	?= $(BUILD)/fuzz_code/Testbench
# STARSHIP_TESTCASE	?= $(TOP)/riscv-tests-parafuzz/build/benchmarks/spectre-v1.guess101.riscv

EXTRA_SIM_ARGS		?= 

$(BUILD)/starship-dummy-testcase:
	mkdir -p $(BUILD)
	wget https://github.com/sycuricon/riscv-tests/releases/download/dummy/rv64ui-p-simple -O $@
