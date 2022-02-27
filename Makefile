# Starship Project
# Copyright (C) 2021 by phantom
# Email: phantom@zju.edu.cn
# This file is under MIT License, see https://www.phvntom.tech/LICENSE.txt

TOP			:= $(CURDIR)
SRC			:= $(TOP)/repo
BUILD		:= $(TOP)/build
CONFIG		:= $(TOP)/conf
SBT_BUILD 	:= $(TOP)/target $(TOP)/project/target $(TOP)/project/project

ifndef RISCV
$(error $$RISCV is undefined, please set $$RISCV to your riscv-toolchain)
endif

all: bitstream

#######################################
#                                      
#         Verilog Generator
#                                      
#######################################

STARSHIP_PKG	?= starship.fpga
# starship.asic
STARSHIP_TOP	?= StarshipFPGATop
# StarshipASICTop
STARSHIP_TH 	?= TestHarness
STARSHIP_FREQ	?= 100
STARSHIP_CONFIG	?= StarshipFPGAConfig
# StarshipSimConfig
EXTRA_CONFIG	?= starship.With$(STARSHIP_FREQ)MHz
DEBUG_OPTION	?= # -ll info

ROCKET_SRC		:= $(SRC)/rocket-chip
ROCKET_BUILD	:= $(BUILD)/rocket-chip
ROCKET_JVM_MEM	?= 2G
ROCKET_JAVA		:= java -Xmx$(ROCKET_JVM_MEM) -Xss8M -jar $(ROCKET_SRC)/sbt-launch.jar
ROCKET_OUTPUT	:= $(STARSHIP_PKG).$(STARSHIP_TOP).$(STARSHIP_CONFIG)
ROCKET_FIRRTL	:= $(ROCKET_BUILD)/$(ROCKET_OUTPUT).fir
ROCKET_TOP_VERILOG	:= $(ROCKET_BUILD)/$(ROCKET_OUTPUT).top.v
ROCKET_TH_VERILOG 	:= $(ROCKET_BUILD)/$(ROCKET_OUTPUT).testharness.v
ROCKET_TOP_INCLUDE	:= $(ROCKET_BUILD)/$(ROCKET_OUTPUT).top.f
ROCKET_TH_INCLUDE 	:= $(ROCKET_BUILD)/$(ROCKET_OUTPUT).testharness.f
ROCKET_TOP_MEMCONF	:= $(ROCKET_BUILD)/$(ROCKET_OUTPUT).sram.top.conf
ROCKET_TH_MEMCONF 	:= $(ROCKET_BUILD)/$(ROCKET_OUTPUT).sram.testharness.conf

$(ROCKET_FIRRTL): 
	mkdir -p $(ROCKET_BUILD)
	$(ROCKET_JAVA) "runMain freechips.rocketchip.system.Generator	\
					-td $(ROCKET_BUILD) -T $(STARSHIP_PKG).$(STARSHIP_TH)	\
					-C $(STARSHIP_PKG).$(STARSHIP_CONFIG),$(EXTRA_CONFIG) \
					-n $(ROCKET_OUTPUT)"

$(ROCKET_TOP_VERILOG): $(ROCKET_FIRRTL)
	mkdir -p $(ROCKET_BUILD)
	$(ROCKET_JAVA) "runMain starship.utils.stage.Generator \
					-td $(ROCKET_BUILD) --infer-rw $(STARSHIP_TOP) \
				  	-T $(STARSHIP_TOP) -oinc $(ROCKET_TOP_INCLUDE) \
					--repl-seq-mem -c:$(STARSHIP_TOP):-o:$(ROCKET_TOP_MEMCONF) \
					-faf $(ROCKET_BUILD)/$(ROCKET_OUTPUT).anno.json \
					-fct firrtl.passes.InlineInstances -i $< -o $@ -X verilog $(DEBUG_OPTION)"

$(ROCKET_TH_VERILOG): $(ROCKET_FIRRTL)
	mkdir -p $(ROCKET_BUILD)
	$(ROCKET_JAVA) "runMain starship.utils.stage.Generator \
					-td $(ROCKET_BUILD) --infer-rw $(STARSHIP_TH) \
					-T $(STARSHIP_TOP) -TH $(STARSHIP_TH) -oinc $(ROCKET_TH_INCLUDE) \
					--repl-seq-mem -c:$(STARSHIP_TH):-o:$(ROCKET_TH_MEMCONF) \
					-faf $(ROCKET_BUILD)/$(ROCKET_OUTPUT).anno.json \
					-fct firrtl.passes.InlineInstances -i $< -o $@ -X verilog $(DEBUG_OPTION)"

verilog: $(ROCKET_TOP_VERILOG) $(ROCKET_TH_VERILOG)



#######################################
#
#         SRAM Generator
#
#######################################

FIRMWARE_SRC	:= $(TOP)/firmware
FIRMWARE_BUILD	:= $(BUILD)/firmware
FSBL_SRC		:= $(FIRMWARE_SRC)/fsbl
FSBL_BUILD		:= $(FIRMWARE_BUILD)/fsbl

ROCKET_INCLUDE 	:= $(ROCKET_BUILD)/$(ROCKET_OUTPUT).f
ROCKET_ROM_HEX 	:= $(FSBL_BUILD)/sdboot.hex
ROCKET_ROM		:= $(ROCKET_BUILD)/$(ROCKET_OUTPUT).rom.v
ROCKET_TOP_SRAM	:= $(ROCKET_BUILD)/$(ROCKET_OUTPUT).behav_srams.top.v
ROCKET_TH_SRAM	:= $(ROCKET_BUILD)/$(ROCKET_OUTPUT).behav_srams.testharness.v

VERILOG_SRC		:= $(ROCKET_TOP_SRAM) $(ROCKET_TH_SRAM) \
				   $(ROCKET_ROM) $(ROCKET_ROM_HEX) \
				   $(ROCKET_TH_VERILOG) $(ROCKET_TOP_VERILOG)

$(ROCKET_INCLUDE): $(ROCKET_TOP_VERILOG) $(ROCKET_TH_VERILOG)
	mkdir -p $(ROCKET_BUILD)
	cat $(ROCKET_TH_INCLUDE) $(ROCKET_TOP_INCLUDE) 2> /dev/null | sort -u >> $@
	echo $(VERILOG_SRC) >> $@

$(ROCKET_TOP_SRAM) $(ROCKET_TH_SRAM): $(ROCKET_INCLUDE)
	mkdir -p $(ROCKET_BUILD)
	$(ROCKET_SRC)/scripts/vlsi_mem_gen $(ROCKET_TOP_MEMCONF) >> $(ROCKET_TOP_SRAM)
	$(ROCKET_SRC)/scripts/vlsi_mem_gen $(ROCKET_TH_MEMCONF) >> $(ROCKET_TH_SRAM)

$(ROCKET_ROM_HEX):
	mkdir -p $(FSBL_BUILD)
	$(MAKE) -C $(FSBL_SRC) PBUS_CLK=$(STARSHIP_FREQ)000000 ROOT_DIR=$(TOP) ROCKET_OUTPUT=$(ROCKET_OUTPUT) hex

$(ROCKET_ROM): $(ROCKET_ROM_HEX)
	mkdir -p $(ROCKET_BUILD)
	$(ROCKET_SRC)/scripts/vlsi_rom_gen $(ROCKET_BUILD)/$(ROCKET_OUTPUT).rom.conf $< > $@

sram: $(VERILOG_SRC)




#######################################
#
#         Bitstream Generator
#
#######################################

BOARD				:= vc707
SCRIPT_SRC			:= $(SRC)/fpga-shells
VIVADO_SRC			:= $(SCRIPT_SRC)/xilinx
VIVADO_BUILD		:= $(BUILD)/vivado
VIVADO_BITSTREAM 	:= $(VIVADO_BUILD)/$(ROCKET_OUTPUT).bit

$(VIVADO_BITSTREAM): $(ROCKET_VERILOG) $(ROCKET_INCLUDE) $(ROCKET_TOP_SRAM) $(ROCKET_TH_SRAM) $(ROCKET_ROM)
	mkdir -p $(VIVADO_BUILD)
	cd $(VIVADO_BUILD); vivado -mode batch -nojournal \
		-source $(VIVADO_SRC)/common/tcl/vivado.tcl \
		-tclargs -F "$(ROCKET_INCLUDE)" \
		-top-module "$(STARSHIP_TH)" \
		-ip-vivado-tcls "$(shell find '$(ROCKET_BUILD)' -name '*.vivado.tcl')" \
		-board "$(BOARD)"

bitstream: $(VIVADO_BITSTREAM)




#######################################
#
#               Utils
#
#######################################

clean:
	rm -rf $(BUILD) $(SBT_BUILD)