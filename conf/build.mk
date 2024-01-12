# Verilog Generation Configuration
##################################

STARSHIP_CORE	?= Rocket
STARSHIP_FREQ	?= 100
STARSHIP_TH 	?= starship.fpga.TestHarness
STARSHIP_TOP	?= starship.fpga.StarshipFPGATop
STARSHIP_CONFIG	?= starship.fpga.StarshipFPGADebugConfig


# FPGA Configuration
##################### Verilog Generation Configuration
##################################

STARSHIP_CORE	?= Rocket
STARSHIP_FREQ	?= 100
STARSHIP_TH 	?= starship.axi4.TestHarness
STARSHIP_TOP	?= starship.axi4.StarshipAxi4Top
STARSHIP_CONFIG	?= starship.axi4.StarshipAxi4DebugConfig



# FPGA Configuration
####################

STARSHIP_BOARD	?= vc707


# Simulation Configuration
##########################

STARSHIP_TESTCASE	?= $(BUILD)/starship-dummy-testcase

$(BUILD)/starship-dummy-testcase:
	mkdir -p $(BUILD)
	wget https://github.com/sycuricon/riscv-tests/releases/download/dummy/rv64ui-p-simple -O $@


STARSHIP_BOARD	?= vc707


# Simulation Configuration
##########################

STARSHIP_TESTCASE	?= $(BUILD)/starship-dummy-testcase

$(BUILD)/starship-dummy-testcase:
	mkdir -p $(BUILD)
	wget https://github.com/sycuricon/riscv-tests/releases/download/dummy/rv64ui-p-simple -O $@
