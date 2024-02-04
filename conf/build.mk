# Verilog Generation Configuration
##################################

STARSHIP_CORE	?= BOOM
STARSHIP_FREQ	?= 100
STARSHIP_TH 	?= starship.asic.TestHarness
STARSHIP_TOP	?= starship.asic.StarshipSimTop
STARSHIP_CONFIG	?= starship.asic.StarshipStateInitConfig


# FPGA Configuration
####################

STARSHIP_BOARD	?= vc707


# Simulation Configuration
##########################

STARSHIP_TESTCASE	?= $(BUILD)/starship-dummy-testcase

EXTRA_SIM_ARGS		?= +maskromhex=$(BUILD)/firmware/rvsnap/default.hex

$(BUILD)/starship-dummy-testcase:
	mkdir -p $(BUILD)
	wget https://github.com/sycuricon/riscv-tests/releases/download/dummy/rv64ui-p-simple -O $@
