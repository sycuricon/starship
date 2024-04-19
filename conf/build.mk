# Verilog Generation Configuration
##################################

STARSHIP_CORE	?= XiangShan
STARSHIP_FREQ	?= 100
STARSHIP_TH 	?= starship.asic.TestHarness
STARSHIP_TOP	?= starship.asic.StarshipSimTop
STARSHIP_CONFIG	?= starship.asic.StarshipSimConfig


# FPGA Configuration
####################

STARSHIP_BOARD	?= vc707


# Simulation Configuration
##########################

SIMULATION_MODE		:= variant
EXTRA_SIM_ARGS		?=

STARSHIP_TESTCASE	?= /home/phantom/work/InstGenerator/build/Testbench

# Out of Project Configuration

XS_REPO_DIR		?= /home/phantom/work/XiangShan
CVA6_REPO_DIR	?=

export XS_REPO_DIR CVA6_REPO_DIR

$(BUILD)/starship-dummy-testcase:
	mkdir -p $(BUILD)
	wget https://github.com/sycuricon/riscv-tests/releases/download/dummy/rv64ui-p-simple -O $@
