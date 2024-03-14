# Starship Project
# Copyright (C) 2020-2023 by phantom
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

GCC_VERSION	:= $(word 1,$(subst ., ,$(shell gcc -dumpversion)))
ifeq ($(shell echo $(GCC_VERSION)\>=9 | bc ),0)
  SCL_PREFIX := source scl_source enable devtoolset-10 &&
endif

all: bitstream


#######################################
#                                      
#         Starship Configuration
#                                      
#######################################

include conf/build.mk

ifeq ($(STARSHIP_CORE),CVA6)
  ifndef CVA6_REPO_DIR
    $(error $$CVA6_REPO_DIR is undefined, please add $$CVA6_REPO_DIR in your configuration)
  else
    export CVA6_REPO_DIR
  endif
endif

#######################################
#                                      
#         Verilog Generator
#                                      
#######################################

ROCKET_TOP		:= $(STARSHIP_TH)
ROCKET_CONF		:= starship.With$(STARSHIP_CORE)Core,$(STARSHIP_CONFIG),starship.With$(STARSHIP_FREQ)MHz
ROCKET_SRC		:= $(SRC)/rocket-chip
ROCKET_BUILD	:= $(BUILD)/rocket-chip
ROCKET_SRCS     := $(shell find $(TOP) -name "*.scala")
ROCKET_OUTPUT	:= $(STARSHIP_CORE).$(lastword $(subst ., ,$(STARSHIP_TOP))).$(lastword $(subst ., ,$(STARSHIP_CONFIG)))
ROCKET_FIRRTL	:= $(ROCKET_BUILD)/$(ROCKET_OUTPUT).fir
ROCKET_ANNO		:= $(ROCKET_BUILD)/$(ROCKET_OUTPUT).anno.json
ROCKET_DTS		:= $(ROCKET_BUILD)/$(ROCKET_OUTPUT).dts
ROCKET_ROMCONF	:= $(ROCKET_BUILD)/$(ROCKET_OUTPUT).rom.conf
ROCKET_TOP_VERILOG	:= $(ROCKET_BUILD)/$(ROCKET_OUTPUT).top.v
ROCKET_TH_VERILOG 	:= $(ROCKET_BUILD)/$(ROCKET_OUTPUT).testharness.v
ROCKET_TOP_INCLUDE	:= $(ROCKET_BUILD)/$(ROCKET_OUTPUT).top.f
ROCKET_TH_INCLUDE 	:= $(ROCKET_BUILD)/$(ROCKET_OUTPUT).testharness.f
ROCKET_TOP_MEMCONF	:= $(ROCKET_BUILD)/$(ROCKET_OUTPUT).sram.top.conf
ROCKET_TH_MEMCONF 	:= $(ROCKET_BUILD)/$(ROCKET_OUTPUT).sram.testharness.conf

verilog-debug: FIRRTL_DEBUG_OPTION ?= -ll info

$(ROCKET_FIRRTL) $(ROCKET_DTS) $(ROCKET_ROMCONF) $(ROCKET_ANNO)&: $(ROCKET_SRCS)
	mkdir -p $(ROCKET_BUILD)
	sbt "runMain starship.utils.stage.FIRRTLGenerator \
		--dir $(ROCKET_BUILD) \
		--top $(ROCKET_TOP) \
		--config $(ROCKET_CONF) \
		--name $(ROCKET_OUTPUT)"

$(ROCKET_TOP_VERILOG) $(ROCKET_TOP_INCLUDE) $(ROCKET_TOP_MEMCONF) $(ROCKET_TH_VERILOG) $(ROCKET_TH_INCLUDE) $(ROCKET_TH_MEMCONF)&: $(ROCKET_FIRRTL)
	mkdir -p $(ROCKET_BUILD)
	sbt "runMain starship.utils.stage.RTLGenerator \
		--infer-rw $(STARSHIP_TOP) \
		-T $(STARSHIP_TOP) -oinc $(ROCKET_TOP_INCLUDE) \
		--repl-seq-mem -c:$(STARSHIP_TOP):-o:$(ROCKET_TOP_MEMCONF) \
		-faf $(ROCKET_ANNO) -fct firrtl.passes.InlineInstances \
		-X verilog $(FIRRTL_DEBUG_OPTION) \
		-i $< -o $(ROCKET_TOP_VERILOG)"
	sbt "runMain starship.utils.stage.RTLGenerator \
		--infer-rw $(STARSHIP_TH) \
		-T $(STARSHIP_TOP) -TH $(STARSHIP_TH) -oinc $(ROCKET_TH_INCLUDE) \
		--repl-seq-mem -c:$(STARSHIP_TH):-o:$(ROCKET_TH_MEMCONF) \
		-faf $(ROCKET_ANNO) -fct firrtl.passes.InlineInstances \
		-X verilog $(FIRRTL_DEBUG_OPTION) \
		-i $< -o $(ROCKET_TH_VERILOG)"
	touch $(ROCKET_TOP_INCLUDE) $(ROCKET_TH_INCLUDE)
	cp $(ROCKET_TOP_VERILOG) $(ROCKET_TOP_VERILOG).bak

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

$(ROCKET_INCLUDE): | $(ROCKET_TH_INCLUDE) $(ROCKET_TOP_INCLUDE)
	mkdir -p $(ROCKET_BUILD)
	cat $(ROCKET_TH_INCLUDE) $(ROCKET_TOP_INCLUDE) 2> /dev/null | sort -u > $@
	echo $(VERILOG_SRC) | tr ' ' '\n' >> $@
	sed -i "s/.*\.f$$/-f &/g" $@

$(ROCKET_TOP_SRAM): $(ROCKET_TOP_MEMCONF)
	mkdir -p $(ROCKET_BUILD)
	$(ROCKET_SRC)/scripts/vlsi_mem_gen $(ROCKET_TOP_MEMCONF) > $(ROCKET_TOP_SRAM)

$(ROCKET_TH_SRAM): $(ROCKET_TH_MEMCONF)
	mkdir -p $(ROCKET_BUILD)
	$(ROCKET_SRC)/scripts/vlsi_mem_gen $(ROCKET_TH_MEMCONF) > $(ROCKET_TH_SRAM)

$(ROCKET_ROM_HEX): $(ROCKET_DTS)
	mkdir -p $(FSBL_BUILD)
	$(MAKE) -C $(FSBL_SRC) PBUS_CLK=$(STARSHIP_FREQ)000000 ROOT_DIR=$(TOP) DTS=$(ROCKET_DTS) hex

$(ROCKET_ROM): $(ROCKET_ROM_HEX) $(ROCKET_ROMCONF)
	mkdir -p $(ROCKET_BUILD)
	$(ROCKET_SRC)/scripts/vlsi_rom_gen $(ROCKET_ROMCONF) $< > $@

verilog: $(VERILOG_SRC)

verilog-debug: $(VERILOG_SRC)

verilog-patch: $(VERILOG_SRC)
	sed -i "s/s2_pc <= 42'h10000/s2_pc <= 42'h80000000/g" $(ROCKET_TOP_VERILOG)
	sed -i "s/s2_pc <= 40'h10000/s2_pc <= 40'h80000000/g" $(ROCKET_TOP_VERILOG)
	sed -i "s/core_boot_addr_i = 64'h10000/core_boot_addr_i = 64'h80000000/g" $(ROCKET_TOP_VERILOG)
	sed -i "s/40'h10000 : 40'h0/40'h80000000 : 40'h0/g" $(ROCKET_TOP_VERILOG)
	sed -i "s/ram\[initvar\] = {2 {\$$random}}/ram\[initvar\] = 0/g" $(ROCKET_TH_SRAM)
	sed -i "s/_covMap\[initvar\] = _RAND/_covMap\[initvar\] = 0; \/\//g" $(ROCKET_TOP_VERILOG)
	sed -i "s/_covState = _RAND/_covState = 0; \/\//g" $(ROCKET_TOP_VERILOG)
	sed -i "s/_covSum = _RAND/_covSum = 0; \/\//g" $(ROCKET_TOP_VERILOG)

YOSYS_TOP = $(lastword $(subst ., ,$(STARSHIP_TOP)))
YOSYS_CONFIG = $(lastword $(subst ., ,$(STARSHIP_CONFIG)))
export YOSYS_TOP YOSYS_CONFIG

verilog-instrument: $(VERILOG_SRC) $(ROCKET_INCLUDE)
	cp $(ROCKET_TOP_VERILOG).bak $(ROCKET_TOP_VERILOG)
	$(MAKE) verilog-patch 
	cp $(ROCKET_TOP_VERILOG) $(ROCKET_TOP_VERILOG).untainted
	# yosys -s asic/syn/pift.ys
	yosys -c asic/syn/pift.tcl
	sed -i "/$(ROCKET_OUTPUT).behav_srams.top.v/d" $(ROCKET_INCLUDE)

#######################################
#
#         Bitstream Generator
#
#######################################

VIVADO_TOP			:= $(lastword $(subst ., ,$(STARSHIP_TH)))
VIVADO_SRC			:= $(SRC)/rocket-chip-fpga-shells
VIVADO_SCRIPT		:= $(VIVADO_SRC)/xilinx
VIVADO_BUILD		:= $(BUILD)/vivado
VIVADO_BITSTREAM 	:= $(VIVADO_BUILD)/$(ROCKET_OUTPUT).bit

$(VIVADO_BITSTREAM): $(ROCKET_INCLUDE) $(VERILOG_SRC)
	mkdir -p $(VIVADO_BUILD)
	cd $(VIVADO_BUILD); vivado -mode batch -nojournal \
		-source $(VIVADO_SCRIPT)/common/tcl/vivado.tcl \
		-tclargs -F "$(ROCKET_INCLUDE)" \
		-top-module "$(VIVADO_TOP)" \
		-ip-vivado-tcls "$(shell find '$(ROCKET_BUILD)' -name '*.vivado.tcl')" \
		-board "$(STARSHIP_BOARD)"

bitstream: $(VIVADO_BITSTREAM)

#######################################
#
#         RTL Simulation
#
#######################################

SIM_DIR			:= $(ASIC)/sim
TB_TOP			?= Testbench

TESTCASE_ELF	:= $(STARSHIP_TESTCASE)
TESTCASE_BIN	:= $(shell mktemp)
TESTCASE_HEX	:= $(STARSHIP_TESTCASE).hex

CHISEL_DEFINE 	:= +define+PRINTF_COND=$(TB_TOP).printf_cond	\
			   	   +define+STOP_COND=!$(TB_TOP).reset

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


#######################################
#
#            Synopsys VCS
#
#######################################

VCS_OUTPUT	:= $(BUILD)/vcs
VERDI_OUTPUT:= $(BUILD)/verdi
VCS_BUILD	:= $(VCS_OUTPUT)/build
VCS_LOG		:= $(VCS_OUTPUT)/log
VCS_WAVE	:= $(VCS_OUTPUT)/wave

VCS_TARGET	:= $(VCS_BUILD)/$(TB_TOP)
VCS_INCLUDE	:= $(ROCKET_BUILD)+$(SIM_DIR)
VCS_CFLAGS	:= -std=c++17 $(addprefix -I,$(SPIKE_INCLUDE)) -I$(ROCKET_BUILD)

VCS_SRC_C	:= $(SIM_DIR)/spike_difftest.cc \
			   $(SPIKE_LIB) \
			   $(SIM_DIR)/timer.cc  \
			   $(SIM_DIR)/parafuzz.cc

VCS_SRC_V	:= $(SIM_DIR)/$(TB_TOP).v \
			   $(SIM_DIR)/spike_difftest.v \
			   $(SIM_DIR)/tty.v \
			   $(SIM_DIR)/pift_lib.v \
			   $(SIM_DIR)/parafuzz.sv

VCS_DEFINE	:= +define+MODEL=$(STARSHIP_TH)					\
			   +define+TOP_DIR=\"$(VCS_OUTPUT)\"			\
			   +define+CLOCK_PERIOD=1.0	   					\
			   +define+DEBUG_FSDB							\
			   +define+TARGET_$(STARSHIP_CORE)

vcs-fuzz:		VCS_DEFINE += +define+COVERAGE_SUMMARY +define+COSIMULATION
vcs-fuzz-debug:	VCS_DEFINE += +define+COVERAGE_SUMMARY +define+COSIMULATION

VCS_PARAL_COM	:= -j$(shell nproc) # -fgp
VCS_PARAL_RUN	:= # -fgp=num_threads:1,num_fsdb_threads:1 # -fgp=num_cores:$(shell nproc),percent_fsdb_cores:30

VCS_OPTION	:= -quiet -notice -line +rad -full64 +nospecify +notimingcheck -deraceclockdata 		\
			   -sverilog +systemverilogext+.sva+.pkg+.sv+.SV+.vh+.svh+.svi+ -assert svaext 			\
			   +vcs+initreg+random +v2k -debug_acc+all -timescale=1ns/10ps +incdir+$(VCS_INCLUDE) 	\
			   $(VCS_PARAL_COM) -CFLAGS "$(VCS_CFLAGS)" 											\
			   $(CHISEL_DEFINE) $(VCS_DEFINE)
VCS_SIM_OPTION	:= +vcs+initreg+0 $(VCS_PARAL_RUN) +testcase=$(TESTCASE_ELF) +taintlog=$(notdir $(TESTCASE_ELF))

vcs-wave: 		VCS_SIM_OPTION += +dump +uart_tx=0
vcs-debug: 		VCS_SIM_OPTION += +verbose +dump +uart_tx=0
vcs-fuzz: 		VCS_SIM_OPTION += +fuzzing +uart_tx=0
vcs-fuzz-debug:	VCS_SIM_OPTION += +fuzzing +verbose +dump +uart_tx=0
vcs-jtag: 		VCS_SIM_OPTION += +jtag_rbb_enable=1 +verbose +uart_tx=0
vcs-jtag-debug: VCS_SIM_OPTION += +jtag_rbb_enable=1 +verbose +dump +uart_tx=0

$(VCS_TARGET): $(VERILOG_SRC) $(ROCKET_ROM_HEX) $(ROCKET_INCLUDE) $(VCS_SRC_V) $(VCS_SRC_C) $(SPIKE_LIB)
	mkdir -p $(VCS_BUILD) $(VCS_LOG) $(VCS_WAVE)
	cd $(VCS_OUTPUT); $(SCL_PREFIX) vcs $(VCS_OPTION) -l $(VCS_LOG)/vcs.log -top $(TB_TOP) \
		-f $(ROCKET_INCLUDE) $(VCS_SRC_V) $(VCS_SRC_C) -o $@

$(TESTCASE_HEX): $(TESTCASE_ELF)
	riscv64-unknown-elf-objcopy --gap-fill 0			\
		--set-section-flags .bss=alloc,load,contents	\
		--set-section-flags .sbss=alloc,load,contents	\
		--set-section-flags .tbss=alloc,load,contents	\
		-O binary $< $(TESTCASE_BIN)
	od -v -An -tx8 $(TESTCASE_BIN) > $@
	rm $(TESTCASE_BIN)

vcs-dummy: $(VCS_TARGET)

vcs: $(VCS_TARGET) $(TESTCASE_HEX)
	cd $(VCS_OUTPUT); time \
	$(VCS_TARGET) -quiet +ntb_random_seed_automatic -l $(VCS_LOG)/sim.log  \
		$(VCS_SIM_OPTION) $(EXTRA_SIM_ARGS) 2>&1 | tee /tmp/rocket.log; exit "$${PIPESTATUS[0]}";

vcs-wave vcs-debug: vcs
vcs-fuzz vcs-fuzz-debug: vcs
vcs-jtag vcs-jtag-debug: vcs

verdi:
	mkdir -p $(VERDI_OUTPUT)
	touch $(VERDI_OUTPUT)/signal.rc
	cd $(VERDI_OUTPUT); \
	verdi -$(VCS_OPTION) -q -ssy -ssv -ssz -autoalias \
		-ssf $(VCS_WAVE)/starship.fsdb -sswr $(VERDI_OUTPUT)/signal.rc \
		-logfile $(VCS_LOG)/verdi.log -top $(TB_TOP) -f $(ROCKET_INCLUDE) $(VCS_SRC_V) &

#######################################
#
#            Verilator
#
#######################################

VLT_OUTPUT	:= $(BUILD)/verilator
VLT_BUILD	:= $(VLT_OUTPUT)/build
VLT_WAVE 	:= $(VLT_OUTPUT)/wave
VLT_TARGET  := $(VLT_BUILD)/$(TB_TOP)

VLT_CFLAGS	:= -std=c++17 $(addprefix -I,$(SPIKE_INCLUDE)) -I$(ROCKET_BUILD)

VLT_SRC_C	:= $(SIM_DIR)/spike_difftest.cc \
			   $(SPIKE_LIB) \
			   $(SIM_DIR)/timer.cc \
			   $(SIM_DIR)/parafuzz.cc

VLT_SRC_V	:= $(SIM_DIR)/$(TB_TOP).v \
			   $(SIM_DIR)/spike_difftest.v \
			   $(SIM_DIR)/tty.v \
			   $(SIM_DIR)/pift_lib.v \
			   $(SIM_DIR)/parafuzz.sv

VLT_DEFINE	:= +define+MODEL=$(STARSHIP_TH)				\
			   +define+TOP_DIR=\"$(VLT_OUTPUT)\"		\
			   +define+CLOCK_PERIOD=1.0	   				\
			   +define+DEBUG_VCD						\
			   +define+TARGET_$(STARSHIP_CORE)

vlt-fuzz:		VLT_DEFINE += +define+COVERAGE_SUMMARY +define+COSIMULATION
vlt-fuzz-debug:	VLT_DEFINE += +define+COVERAGE_SUMMARY +define+COSIMULATION

VLT_OPTION	:= -Wno-fatal -Wno-WIDTH -Wno-STMTDLY -Werror-IMPLICIT							\
			   --timescale 1ns/10ps --trace --timing 										\
			   +systemverilogext+.sva+.pkg+.sv+.SV+.vh+.svh+.svi+ 							\
			   +incdir+$(ROCKET_BUILD) +incdir+$(SIM_DIR) $(CHISEL_DEFINE) $(VLT_DEFINE)	\
			   --cc --exe --Mdir $(VLT_BUILD) --top-module $(TB_TOP) --main -o $(TB_TOP) 	\
			   -j $(shell nproc) -CFLAGS "-DVL_DEBUG -DTOP=${TB_TOP} ${VLT_CFLAGS}"			\
			   -LDFLAGS "-ldl"
VLT_SIM_OPTION	:= +testcase=$(TESTCASE_ELF) +taintlog=$(notdir $(TESTCASE_ELF))

vlt-wave: 		VLT_SIM_OPTION	+= +dump
vlt-debug: 		VLT_SIM_OPTION 	+= +verbose +dump
vlt-fuzz: 		VLT_SIM_OPTION	+= +fuzzing
vlt-fuzz-debug: VLT_SIM_OPTION	+= +fuzzing +verbose +dump
vlt-jtag: 		VLT_SIM_OPTION	+= +jtag_rbb_enable=1
vlt-jtag-debug: VLT_SIM_OPTION	+= +jtag_rbb_enable=1 +dump

$(VLT_TARGET): $(VERILOG_SRC) $(ROCKET_ROM_HEX) $(ROCKET_INCLUDE) $(VLT_SRC_V) $(VLT_SRC_C) $(SPIKE_LIB)
	mkdir -p $(VLT_BUILD) $(VLT_WAVE)
	cd $(VLT_OUTPUT); verilator $(VLT_OPTION) -f $(ROCKET_INCLUDE) $(VLT_SRC_V) $(VLT_SRC_C)
	make -C $(VLT_BUILD) -f V$(TB_TOP).mk $(TB_TOP) -j $(shell nproc)

vlt-dummy: $(VLT_TARGET)

vlt: $(VLT_TARGET) $(TESTCASE_HEX)
	cd $(VLT_OUTPUT); time \
	$(VLT_TARGET) $(VLT_SIM_OPTION) $(EXTRA_SIM_ARGS)

vlt-wave: 		vlt
vlt-debug:		vlt
vlt-fuzz: 		vlt
vlt-jtag: 		vlt
vlt-jtag-debug: vlt

gtkwave:
	gtkwave $(VLT_WAVE)/starship.vcd

#######################################
#
#             Sythesis
#
#######################################

#######################################
#
#            Synopsys DC
#
#######################################

DC_TOP		:= $(lastword $(subst ., ,$(STARSHIP_TH)))
DC_SRC		:= $(ASIC)/scripts/syn
DC_OUTPUT	:= $(BUILD)/syn
DC_BUILD	:= $(DC_OUTPUT)/build
DC_LOG		:= $(DC_OUTPUT)/log
DC_NETLIST	:= $(DC_OUTPUT)/netlist

#######################################
#
#              Yosys
#
#######################################


#######################################
#
#               Utils
#
#######################################

.PHONY: clean clean-all patch

patch:
	find patch -name "*.patch" | \
		awk -F/ '{print \
			"(" \
				"echo \"Apply " $$0 "\" && " \
				"cd repo/" $$2 " && " \
				"git apply --ignore-space-change --ignore-whitespace ../../" $$0 \
			")" \
		}' | sh

clean:
	rm -rf $(BUILD)

clean-all:
	rm -rf $(BUILD) $(SBT_BUILD)

#######################################
#
#               Fuzz
#
#######################################

FUZZ_SRC	=	$(SRC)/InstGenerator
FUZZ_BUILD	=	$(BUILD)/fuzz_code

FUZZ_CODE	=	$(FUZZ_BUILD)/Testbench

FUZZ_MODE = 

fuzz-virtual: FUZZ_MODE += -V
fuzz-do-physics: FUZZ_MODE += --fuzz
fuzz-do-virtual: FUZZ_MODE += -V --fuzz

fuzz:$(FUZZ_SRC)
	mkdir -p $(FUZZ_BUILD)
	cd $(FUZZ_SRC); \
	python DistributeManager.py -I $(FUZZ_SRC)/mem_init.hjson -O $(FUZZ_BUILD) $(FUZZ_MODE)
	make -C $(FUZZ_SRC) BUILD_PATH=$(FUZZ_BUILD)
	cd $(FUZZ_BUILD); riscv64-unknown-elf-objdump -D Testbench > Testbench.asm

fuzz-physics:fuzz
fuzz-virtual:fuzz
fuzz-do-physics:fuzz
fuzz-do-virtual:fuzz