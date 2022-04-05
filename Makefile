# Starship Project
# Copyright (C) 2020-2022 by phantom
# Email: phantom@zju.edu.cn
# This file is under MIT License, see https://www.phvntom.tech/LICENSE.txt

TOP			:= $(CURDIR)
SRC			:= $(TOP)/repo
BUILD		:= $(TOP)/build
CONFIG		:= $(TOP)/conf
SBT_BUILD 	:= $(TOP)/target $(TOP)/project/target $(TOP)/project/project
ASIC		:= $(TOP)/asic

ifndef RISCV
$(error $$RISCV is undefined, please set $$RISCV to your riscv-toolchain)
endif

all: bitstream




#######################################
#                                      
#         Starship Configuration
#                                      
#######################################

STARSHIP_FREQ	?= 100
STARSHIP_TH 	?= TestHarness
STARSHIP_TOP	?= StarshipFPGATop
STARSHIP_PKG	?= starship.fpga
STARSHIP_CONFIG	?= StarshipFPGAConfig
EXTRA_CONFIG	?= starship.With$(STARSHIP_FREQ)MHz

# STARSHIP_FREQ	?= 100
# STARSHIP_TH 	?= TestHarness
# STARSHIP_TOP	?= StarshipASICTop
# STARSHIP_PKG	?= starship.asic
# STARSHIP_CONFIG	?= StarshipSimConfig
# EXTRA_CONFIG	?= starship.With$(STARSHIP_FREQ)MHz




#######################################
#                                      
#         Verilog Generator
#                                      
#######################################

ROCKET_SRC		:= $(SRC)/rocket-chip
ROCKET_BUILD	:= $(BUILD)/rocket-chip
ROCKET_JAVA		:= java -Xmx2G -Xss8M -jar $(ROCKET_SRC)/sbt-launch.jar
ROCKET_OUTPUT	:= $(STARSHIP_PKG).$(STARSHIP_TOP).$(STARSHIP_CONFIG)
ROCKET_FIRRTL	:= $(ROCKET_BUILD)/$(ROCKET_OUTPUT).fir
ROCKET_TOP_VERILOG	:= $(ROCKET_BUILD)/$(ROCKET_OUTPUT).top.v
ROCKET_TH_VERILOG 	:= $(ROCKET_BUILD)/$(ROCKET_OUTPUT).testharness.v
ROCKET_TOP_INCLUDE	:= $(ROCKET_BUILD)/$(ROCKET_OUTPUT).top.f
ROCKET_TH_INCLUDE 	:= $(ROCKET_BUILD)/$(ROCKET_OUTPUT).testharness.f
ROCKET_TOP_MEMCONF	:= $(ROCKET_BUILD)/$(ROCKET_OUTPUT).sram.top.conf
ROCKET_TH_MEMCONF 	:= $(ROCKET_BUILD)/$(ROCKET_OUTPUT).sram.testharness.conf
FIRRTL_DEBUG_OPTION	?= # -ll info

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
					-fct firrtl.passes.InlineInstances -i $< -o $@ -X verilog $(FIRRTL_DEBUG_OPTION)"

$(ROCKET_TH_VERILOG): $(ROCKET_FIRRTL)
	mkdir -p $(ROCKET_BUILD)
	$(ROCKET_JAVA) "runMain starship.utils.stage.Generator \
					-td $(ROCKET_BUILD) --infer-rw $(STARSHIP_TH) \
					-T $(STARSHIP_TOP) -TH $(STARSHIP_TH) -oinc $(ROCKET_TH_INCLUDE) \
					--repl-seq-mem -c:$(STARSHIP_TH):-o:$(ROCKET_TH_MEMCONF) \
					-faf $(ROCKET_BUILD)/$(ROCKET_OUTPUT).anno.json \
					-fct firrtl.passes.InlineInstances -i $< -o $@ -X verilog $(FIRRTL_DEBUG_OPTION)"

rocket: $(ROCKET_TOP_VERILOG) $(ROCKET_TH_VERILOG)




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
				   $(ROCKET_ROM) \
				   $(ROCKET_TH_VERILOG) $(ROCKET_TOP_VERILOG)

$(ROCKET_INCLUDE): $(ROCKET_TOP_VERILOG) $(ROCKET_TH_VERILOG)
	mkdir -p $(ROCKET_BUILD)
	cat $(ROCKET_TH_INCLUDE) $(ROCKET_TOP_INCLUDE) 2> /dev/null | sort -u > $@
	echo $(VERILOG_SRC) >> $@

$(ROCKET_TOP_SRAM): $(ROCKET_INCLUDE)
	mkdir -p $(ROCKET_BUILD)
	$(ROCKET_SRC)/scripts/vlsi_mem_gen $(ROCKET_TOP_MEMCONF) > $(ROCKET_TOP_SRAM)

$(ROCKET_TH_SRAM): $(ROCKET_INCLUDE)
	mkdir -p $(ROCKET_BUILD)
	$(ROCKET_SRC)/scripts/vlsi_mem_gen $(ROCKET_TH_MEMCONF) > $(ROCKET_TH_SRAM)

$(ROCKET_ROM_HEX):
	mkdir -p $(FSBL_BUILD)
	$(MAKE) -C $(FSBL_SRC) PBUS_CLK=$(STARSHIP_FREQ)000000 ROOT_DIR=$(TOP) ROCKET_OUTPUT=$(ROCKET_OUTPUT) hex

$(ROCKET_ROM): $(ROCKET_ROM_HEX)
	mkdir -p $(ROCKET_BUILD)
	$(ROCKET_SRC)/scripts/vlsi_rom_gen $(ROCKET_BUILD)/$(ROCKET_OUTPUT).rom.conf $< > $@

verilog: $(VERILOG_SRC)




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
#         VCS Simulation
#
#######################################

TB_SCR		:= $(ASIC)/tb
VCS_OUTPUT	:= $(BUILD)/vcs
VERDI_OUTPUT:= $(BUILD)/verdi
VCS_BUILD	:= $(VCS_OUTPUT)/build
VCS_LOG		:= $(VCS_OUTPUT)/log
VCS_WAVE	:= $(VCS_OUTPUT)/wave

DROMAJO_SCR		:= $(SRC)/dromajo
DROMAJO_BUILD	:= $(BUILD)/dromajo
DROMAJO_LIB		:= $(DROMAJO_BUILD)/libdromajo_cosim.a
DROMAJO_WRAP	:= $(TB_SCR)/dromajo_difftest.v $(TB_SCR)/dromajo_difftest.cc

VCS_TB		?= Testbench
VCS_TB_VLOG ?= $(TB_SCR)/$(VCS_TB).v
VCS_SIMV	:= $(VCS_BUILD)/simv
VCS_INCLUDE	:= $(ROCKET_BUILD)+$(TB_SCR)
VCS_CFLAGS	:= -std=c++11 -I$(DROMAJO_SCR)/include

TB_DEFINE	:= +define+MODEL=$(STARSHIP_TH)					\
			   +define+TOP_DIR=\"$(VCS_OUTPUT)\"			\
			   +define+INITIALIZE_MEMORY					\
			   +define+CLOCK_PERIOD=1.0	   

CHISEL_DEFINE := +define+PRINTF_COND=$(VCS_TB).printf_cond	\
			   	 +define+STOP_COND=!$(VCS_TB).reset			\
				 +define+RANDOMIZE_MEM_INIT					\
				 +define+RANDOMIZE_REG_INIT					\
				 +define+RANDOMIZE_GARBAGE_ASSIGN			\
				 +define+RANDOMIZE_INVALID_ASSIGN			\
				 +define+RANDOMIZE_DELAY=0.1


VCS_OPTION	:= -quiet -notice -line +rad -full64 +nospecify +notimingcheck		\
			   -sverilog +systemverilogext+.sva+.pkg+.sv+.SV+.vh+.svh+.svi+ 	\
			   +v2k -debug_acc+all	-timescale=1ns/10ps +incdir+$(VCS_INCLUDE) 	\
			   -CFLAGS "$(VCS_CFLAGS)" $(CHISEL_DEFINE) $(TB_DEFINE)
VCS_OPTION	+= +define+DEBUG

TESTCASE_ROOT	?= /eda/project/riscv-tests/build/isa
TESTCASE		:= rv64ui-p-addi
TESTCASE_ELF	:= $(TESTCASE_ROOT)/$(TESTCASE)
TESTCASE_BIN	:= $(shell mktemp)
TESTCASE_HEX	:= $(TESTCASE_ROOT)/$(TESTCASE).hex

$(DROMAJO_LIB):
	mkdir -p $(DROMAJO_BUILD)
	cd $(DROMAJO_BUILD); cmake $(DROMAJO_SCR)
	cd $(DROMAJO_BUILD); make dromajo_cosim

$(VCS_SIMV): $(VERILOG_SRC) $(ROCKET_INCLUDE) $(VCS_TB_VLOG) $(DROMAJO_LIB)
	mkdir -p $(VCS_BUILD) $(VCS_LOG) $(VCS_WAVE)
	sed -i "s/s2_pc <= 40'h10000/s2_pc <= 40'h80000000/g" $(ROCKET_TOP_VERILOG)
	cd $(VCS_BUILD); vcs $(VCS_OPTION) -l $(VCS_LOG)/vcs.log -top $(VCS_TB) -f $(ROCKET_INCLUDE) -o $@ $(VCS_TB_VLOG) $(DROMAJO_WRAP) $(DROMAJO_LIB)

$(TESTCASE_HEX): $(TESTCASE_ELF)
	riscv64-unknown-elf-objcopy --gap-fill 0 --set-section-flags .bss=alloc,load,contents --set-section-flags .sbss=alloc,load,contents -O binary $< $(TESTCASE_BIN)
	od -v -An -tx8 $(TESTCASE_BIN) > $@
	rm $(TESTCASE_BIN)

vcs: $(VCS_SIMV) $(TESTCASE_HEX)
	mkdir -p $(VCS_BUILD) $(VCS_LOG) $(VCS_WAVE)
	cd $(VCS_BUILD); $(VCS_SIMV) -quiet +ntb_random_seed_automatic -l $(VCS_LOG)/sim.log \
								 +dromajo_config=$(CONFIG)/dromajo.json +verbose \
								 +uart_tx=1 +testcase=$(TESTCASE_HEX) $(VCS_EXTRA_OPT) 2>&1 | tee $(VCS_LOG)/rocket.log

verdi: $(VCS_WAVE)/*.fsdb
	cd $(VCS_BUILD); verdi -$(VCS_OPTION) -q -ssy -ssv -ssz -autoalias	\
						   -ssf $(VCS_WAVE)/starship.fsdb -sswr $(VERDI_OUTPUT)/starship.rc \
						   -logfile $(VCS_LOG)/verdi.log -top $(VCS_TB) -f $(ROCKET_INCLUDE) $(VCS_TB_VLOG) &




#######################################
#
#         DC Sythesis
#
#######################################

DC_SRC		:= $(ASIC)/scripts/syn
DC_OUTPUT	:= $(BUILD)/syn
DC_BUILD	:= $(DC_OUTPUT)/build
DC_LOG		:= $(DC_OUTPUT)/log
DC_NETLIST	:= $(DC_OUTPUT)/netlist

DC_TOP		:= $(STARSHIP_TOP)




#######################################
#
#               Utils
#
#######################################

clean:
	rm -rf $(BUILD) $(SBT_BUILD)
