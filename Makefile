# Starship Project
# Copyright (C) 2021 by phantom
# Email: phantom@zju.edu.cn
# This file is under MIT License, see https://www.phvntom.tech/LICENSE.txt

TOP			:= $(CURDIR)
SRC			:= $(TOP)/repo
BUILD		:= $(TOP)/build
CONFIG		:= $(TOP)/conf
SBT_BUILD 	:= $(TOP)/target $(TOP)/project/target $(TOP)/project/project

ROCKET_TOP_PROJ	?= starship.fpga
ROCKET_CON_PROJ	?= starship.fpga
ROCKET_CONFIG	?= StarshipFPGAConfig

# ROCKET_TOP_PROJ	?= starship.asic
# ROCKET_CON_PROJ	?= starship.asic
# ROCKET_CONFIG	?= StarshipSimConfig

ifndef RISCV
$(error $$RISCV is undefined, please set $$RISCV to your riscv-toolchain)
endif

all: bitstream

#######################################
#                                      
#         Verilog Generator
#                                      
#######################################

ROCKET_SRC		:= $(SRC)/rocket-chip
ROCKET_BUILD	:= $(BUILD)/rocket-chip
ROCKET_JVM_MEM	?= 2G
ROCKET_JAVA		:= java -Xmx$(ROCKET_JVM_MEM) -Xss8M -jar $(ROCKET_SRC)/sbt-launch.jar
ROCKET_TOP		?= TestHarness
ROCKET_FREQ		?= 100
ROCKET_OUTPUT	:= $(ROCKET_TOP_PROJ).$(ROCKET_TOP).$(ROCKET_CONFIG)
ROCKET_VERILOG	:= $(ROCKET_BUILD)/$(ROCKET_OUTPUT).v
ROCKET_FIRRTL	:= $(ROCKET_BUILD)/$(ROCKET_OUTPUT).fir

$(ROCKET_FIRRTL): 
	mkdir -p $(ROCKET_BUILD)
	$(ROCKET_JAVA) "runMain freechips.rocketchip.system.Generator	\
					-td $(ROCKET_BUILD) -T $(ROCKET_TOP_PROJ).$(ROCKET_TOP)	\
					-C $(ROCKET_CON_PROJ).$(ROCKET_CONFIG),$(ROCKET_CON_PROJ).With$(ROCKET_FREQ)MHz \
					-n $(ROCKET_OUTPUT)"

$(ROCKET_VERILOG): $(ROCKET_FIRRTL)
	mkdir -p $(ROCKET_BUILD)
	$(ROCKET_JAVA) "runMain firrtl.stage.FirrtlMain	\
					-td $(ROCKET_BUILD) --infer-rw $(ROCKET_TOP) \
					--repl-seq-mem -c:$(ROCKET_TOP):-o:$(ROCKET_BUILD)/$(ROCKET_OUTPUT).sram.conf \
					-faf $(ROCKET_BUILD)/$(ROCKET_OUTPUT).anno.json \
					-fct firrtl.passes.InlineInstances \
					-i $< -o $@ -X verilog"

verilog: $(ROCKET_VERILOG)
verilog-debug: verilog
verilog-patch: verilog
	# sed -i "s/s2_pc <= 42'h10000/s2_pc <= 42'h80000000/g" $(ROCKET_VERILOG)
	# sed -i "s/s2_pc <= 40'h10000/s2_pc <= 40'h80000000/g" $(ROCKET_VERILOG)
	sed -i "s/s2_pc <= 58'h10000/s2_pc <= 58'h80000000/g" $(ROCKET_VERILOG)
	sed -i "s/core_boot_addr_i = 64'h10000/core_boot_addr_i = 64'h80000000/g" $(ROCKET_VERILOG)
	# sed -i "s/40'h10000 : 40'h0/40'h80000000 : 40'h0/g" $(ROCKET_VERILOG)
	sed -i "s/58'h10000 : 58'h0/40'h80000000 : 58'h0/g" $(ROCKET_VERILOG)
	sed -i "s/_covMap\[initvar\] = _RAND/_covMap\[initvar\] = 0; \/\//g" $(ROCKET_VERILOG)
	sed -i "s/_covState = _RAND/_covState = 0; \/\//g" $(ROCKET_VERILOG)
	sed -i "s/_covSum = _RAND/_covSum = 0; \/\//g" $(ROCKET_VERILOG)

#######################################
#
#         Bitstream Generator
#
#######################################

FIRMWARE_SRC	:= $(TOP)/firmware
FIRMWARE_BUILD	:= $(BUILD)/firmware
FSBL_SRC		:= $(FIRMWARE_SRC)/fsbl
FSBL_BUILD		:= $(FIRMWARE_BUILD)/fsbl
STARSHIP_ROM_HEX := $(FSBL_BUILD)/sdboot.hex

BOARD				:= vc707
SCRIPT_SRC			:= $(SRC)/fpga-shells
VIVADO_SRC			:= $(SCRIPT_SRC)/xilinx
VIVADO_BUILD		:= $(BUILD)/vivado
VIVADO_BITSTREAM 	:= $(VIVADO_BUILD)/$(ROCKET_OUTPUT).bit
VERILOG_SRAM		:= $(ROCKET_BUILD)/$(ROCKET_OUTPUT).behav_srams.v
VERILOG_ROM			:= $(ROCKET_BUILD)/$(ROCKET_OUTPUT).rom.v
VERILOG_INCLUDE 	:= $(VIVADO_BUILD)/$(ROCKET_OUTPUT).vsrc.f
VERILOG_SRC			:= $(VERILOG_SRAM) \
					   $(VERILOG_ROM) \
					   $(STARSHIP_ROM_HEX) \
					   $(ROCKET_BUILD)/$(ROCKET_OUTPUT).v \
					   $(ROCKET_BUILD)/plusarg_reader.v \
					   $(ROCKET_BUILD)/EICG_wrapper.v \
					   $(VIVADO_SRC)/$(BOARD)/vsrc/sdio.v \
					   $(VIVADO_SRC)/$(BOARD)/vsrc/vc707reset.v \
					   $(VIVADO_SRC)/common/vsrc/PowerOnResetFPGAOnly.v \
					   $(SCRIPT_SRC)/testbench/SimTestHarness.v
$(VERILOG_INCLUDE):
	mkdir -p $(VIVADO_BUILD)
	echo $(VERILOG_SRC) > $@

$(VERILOG_SRAM):
	$(ROCKET_SRC)/scripts/vlsi_mem_gen $(ROCKET_BUILD)/$(ROCKET_OUTPUT).sram.conf >> $@

$(STARSHIP_ROM_HEX):
	$(MAKE) -C $(FSBL_SRC) PBUS_CLK=$(ROCKET_FREQ)000000 ROOT_DIR=$(TOP) ROCKET_OUTPUT=$(ROCKET_OUTPUT) hex

$(VERILOG_ROM): $(STARSHIP_ROM_HEX)
	$(ROCKET_SRC)/scripts/vlsi_rom_gen $(ROCKET_BUILD)/$(ROCKET_OUTPUT).rom.conf $< > $@

$(VIVADO_BITSTREAM): $(ROCKET_VERILOG) $(VERILOG_INCLUDE) $(VERILOG_SRAM) $(VERILOG_ROM)
	mkdir -p $(VIVADO_BUILD)
	cd $(VIVADO_BUILD); vivado -mode batch -nojournal \
		-source $(VIVADO_SRC)/common/tcl/vivado.tcl \
		-tclargs -F "$(VERILOG_INCLUDE)" \
		-top-module "$(ROCKET_TOP)" \
		-ip-vivado-tcls "$(shell find '$(ROCKET_BUILD)' -name '*.vivado.tcl')" \
		-board "$(BOARD)"

bitstream: $(VIVADO_BITSTREAM)

#######################################
#
#         RTL Simulation
#
#######################################

ASIC		:= $(TOP)/asic
SIM_DIR			:= $(ASIC)/sim
TB_TOP			?= Testbench

STARSHIP_TESTCASE	?=	/home/zyy/extend/starship-regvault/test/function_test/regvault
TESTCASE_ELF	:= $(STARSHIP_TESTCASE)
TESTCASE_BIN	:= $(shell mktemp)
TESTCASE_HEX	:= $(STARSHIP_TESTCASE).hex

CHISEL_DEFINE 	:= +define+PRINTF_COND=$(TB_TOP).printf_cond	\
			   	   +define+STOP_COND=!$(TB_TOP).reset			\
				   +define+RANDOMIZE							\
				   +define+RANDOMIZE_MEM_INIT					\
				   +define+RANDOMIZE_REG_INIT					\
				   +define+RANDOMIZE_GARBAGE_ASSIGN				\
				   +define+RANDOMIZE_INVALID_ASSIGN				\
				   +define+RANDOMIZE_DELAY=0.1

SPIKE_DIR		:= $(SRC)/riscv-isa-sim
SPIKE_SRC		:= $(shell find $(SPIKE_DIR) -name "*.cc" -o -name "*.h" -o -name "*.c")
SPIKE_BUILD		:= $(BUILD)/spike
SPIKE_LIB		:= $(addprefix $(SPIKE_BUILD)/,libcosim.a libriscv.a libdisasm.a libsoftfloat.a libfesvr.a libfdt.a)
SPIKE_INCLUDE	:= $(SPIKE_DIR) $(SPIKE_DIR)/cosim $(SPIKE_DIR)/fdt $(SPIKE_DIR)/fesvr \
			       $(SPIKE_DIR)/riscv $(SPIKE_DIR)/softfloat $(SPIKE_BUILD)

export LD_LIBRARY_PATH=$(SPIKE_BUILD)

$(SPIKE_BUILD)/Makefile:
	mkdir -p $(SPIKE_BUILD)
	cd $(SPIKE_BUILD); $(SCL_PREFIX) $(SPIKE_DIR)/configure

$(SPIKE_LIB)&: $(SPIKE_SRC) $(SPIKE_BUILD)/Makefile
	cd $(SPIKE_BUILD); $(SCL_PREFIX) make -j$(shell nproc) $(notdir $(SPIKE_LIB))

spike:$(SPIKE_LIB)

#######################################
#
#            Verilator
#
#######################################

VLT_BUILD	:= $(BUILD)/verilator
VLT_WAVE 	:= $(VLT_BUILD)/wave
VLT_TARGET  := $(VLT_BUILD)/$(TB_TOP)

VLT_CFLAGS	:= -std=c++17 $(addprefix -I,$(SPIKE_INCLUDE)) -I$(ROCKET_BUILD)

VLT_SRC_C	:= $(SIM_DIR)/spike_difftest.cc \
			   $(SPIKE_LIB) \
			   $(SIM_DIR)/timer.cc

VLT_SRC_V	:= $(SIM_DIR)/$(TB_TOP).v \
			   $(SIM_DIR)/spike_difftest.v \
			   $(SIM_DIR)/tty.v

VLT_DEFINE	:= +define+MODEL=$(STARSHIP_TH)				\
			   +define+TOP_DIR=\"$(VLT_BUILD)\"			\
			   +define+INITIALIZE_MEMORY				\
			   +define+CLOCK_PERIOD=1.0	   				\
			   +define+DEBUG_VCD						\
			   +define+TARGET_$(STARSHIP_CORE)

VLT_OPTION	:= -Wno-WIDTH -Wno-STMTDLY -Wno-fatal --timescale 1ns/10ps --trace --timing		\
			   +systemverilogext+.sva+.pkg+.sv+.SV+.vh+.svh+.svi+ 							\
			   +incdir+$(ROCKET_BUILD) +incdir+$(SIM_DIR) $(CHISEL_DEFINE) $(VLT_DEFINE)		\
			   --cc --exe --Mdir $(VLT_BUILD) --top-module $(TB_TOP) --main -o $(TB_TOP) 	\
			   -CFLAGS "-DVL_DEBUG -DTOP=${TB_TOP} ${VLT_CFLAGS}"
VLT_SIM_OPTION	:= +testcase=$(TESTCASE_ELF)

vlt-wave: 		VLT_SIM_OPTION	+= +dump 
vlt-jtag: 		VLT_SIM_OPTION	+= +jtag_rbb_enable=1
vlt-jtag-debug: VLT_SIM_OPTION	+= +dump +jtag_rbb_enable=1

$(VLT_TARGET): $(ROCKET_BUILD)/$(ROCKET_OUTPUT).v $(VERILOG_SRAM) $(VERILOG_ROM) $(VLT_SRC_V) $(VLT_SRC_C) $(SPIKE_LIB) 
	$(MAKE) verilog-patch
	mkdir -p $(VLT_BUILD) $(VLT_WAVE)
	cd $(VLT_BUILD); verilator $(VLT_OPTION) $(ROCKET_BUILD)/$(ROCKET_OUTPUT).v $(VERILOG_SRAM) $(VERILOG_ROM) $(VLT_SRC_V) $(VLT_SRC_C)
	make -C $(VLT_BUILD) -f V$(TB_TOP).mk $(TB_TOP)

$(TESTCASE_HEX): $(TESTCASE_ELF)
	$(RISCV)/bin/riscv64-unknown-elf-objcopy --gap-fill 0			\
		--set-section-flags .bss=alloc,load,contents	\
		--set-section-flags .sbss=alloc,load,contents	\
		--set-section-flags .tbss=alloc,load,contents	\
		-O binary $< $(TESTCASE_BIN)
	od -v -An -tx8 $(TESTCASE_BIN) > $@
	rm $(TESTCASE_BIN)
	
vlt: $(VLT_TARGET) $(TESTCASE_HEX)
	cd $(VLT_BUILD); ./$(TB_TOP) $(VLT_SIM_OPTION)

vlt-wave: 		vlt
vlt-jtag: 		vlt
vlt-jtag-debug: vlt

gtkwave:
	gtkwave $(VLT_WAVE)/starship.vcd

#######################################
#
#               Utils
#
#######################################

clean:
	rm -rf $(BUILD) $(SBT_BUILD)