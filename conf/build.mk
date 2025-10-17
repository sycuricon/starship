# SoC Configuration
##################################

STARSHIP_CORE	?= BOOM
STARSHIP_FREQ	?= 100
STARSHIP_TH 	?= starship.asic.TestHarness
STARSHIP_TOP	?= starship.asic.StarshipSimTop
STARSHIP_CONFIG	?= starship.asic.StarshipSimMiniConfig


# FPGA Configuration
####################

STARSHIP_BOARD	?= vc707


# Simulation Configuration
##########################

SIMULATION_MODE		?= variant
SIMULATION_LABEL	?= $(notdir $(STARSHIP_TESTCASE))
EXTRA_SIM_ARGS		?=

STARSHIP_TESTCASE	?=


# Out of Project Configuration
##############################

XS_REPO_DIR		?=
CVA6_REPO_DIR	?=

$(BUILD)/starship-dummy-testcase:
	mkdir -p $(BUILD)
	wget https://github.com/sycuricon/riscv-tests/releases/download/dummy/rv64ui-p-simple -O $@
