# Starship Project
# Copyright (C) 2020-2023 by phantom
# Email: phantom@zju.edu.cn
# This file is under MIT License, see https://www.phvntom.tech/LICENSE.txt

TOP			:= $(CURDIR)
SRC			:= $(TOP)/repo
BUILD		:= $(TOP)/build
CONFIG		:= $(TOP)/conf
ASIC		:= $(TOP)/asic
SCRIPT		:= $(TOP)/scripts

ifndef RISCV
  $(error $$RISCV is undefined, please set $$RISCV to your riscv-toolchain)
endif

GCC_VERSION	:= $(word 1,$(subst ., ,$(shell gcc -dumpversion)))
ifeq ($(shell echo $(GCC_VERSION)\>=9 | bc ),0)
  $(error At least GCC 9 is required.)
endif

all: bitstream


#######################################
#                                      
#         Starship Configuration
#                                      
#######################################

include conf/build.mk

ifeq ($(STARSHIP_CORE),CVA6)
  ifeq ($(CVA6_REPO_DIR),)
    $(error $$CVA6_REPO_DIR must point to CVA6 repository)
  else
    export CVA6_REPO_DIR
  endif
endif

ifeq ($(STARSHIP_CORE),XiangShan)
  ifeq ($(XS_REPO_DIR),)
    $(error $$XS_REPO_DIR must point to XiangShan repository)
  else
    export XS_REPO_DIR
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

export JAVA_OPTS	:= -Xmx5G

verilog-debug: FIRRTL_DEBUG_OPTION ?= -ll info

$(ROCKET_FIRRTL) $(ROCKET_DTS) $(ROCKET_ROMCONF) $(ROCKET_ANNO)&: $(ROCKET_SRCS)
	mkdir -p $(ROCKET_BUILD)
	sbt "runMain starship.utils.stage.FIRRTLGenerator \
		--dir $(ROCKET_BUILD) \
		--top $(ROCKET_TOP) \
		--config $(ROCKET_CONF) \
		--name $(ROCKET_OUTPUT)"
	touch $(ROCKET_ROMCONF)

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
	$(MAKE) verilog-patch

#######################################
#
#         SRAM Generator
#
#######################################

FIRMWARE_SRC	:= $(TOP)/firmware
FIRMWARE_BUILD	:= $(BUILD)/firmware
FSBL_SRC		:= $(FIRMWARE_SRC)/fsbl
FSBL_BUILD		:= $(FIRMWARE_BUILD)/fsbl

ROCKET_INCLUDE 	:= $(ROCKET_BUILD)/$(ROCKET_OUTPUT).$(SIMULATION_MODE).f
ROCKET_ROM_HEX 	:= $(FSBL_BUILD)/sdboot.hex
ROCKET_ROM		:= $(ROCKET_BUILD)/$(ROCKET_OUTPUT).rom.v
ROCKET_TOP_SRAM	:= $(ROCKET_BUILD)/$(ROCKET_OUTPUT).behav_srams.top.v
ROCKET_TH_SRAM	:= $(ROCKET_BUILD)/$(ROCKET_OUTPUT).behav_srams.testharness.v

VERILOG_SRC		:= $(ROCKET_TOP_SRAM) $(ROCKET_TH_SRAM) $(ROCKET_ROM) \
				   $(ROCKET_TOP_VERILOG) $(ROCKET_TH_VERILOG)

$(ROCKET_INCLUDE): | $(ROCKET_TH_INCLUDE) $(ROCKET_TOP_INCLUDE)
	mkdir -p $(ROCKET_BUILD)
	cat $(ROCKET_TH_INCLUDE) $(ROCKET_TOP_INCLUDE) 2> /dev/null | sort -u > $@
	echo $(VERILOG_SRC) | tr ' ' '\n' >> $@
	sed -i "s/.*\.f$$/-f &/g" $@
ifeq ($(SIMULATION_MODE),variant)
  ifeq ($(STARSHIP_CORE),XiangShan)
	sed -i "/XSList.f/d" $@
  endif
	sed -i "/$(ROCKET_OUTPUT).behav_srams.top.v/d" $@
	sed -i "s/$(ROCKET_OUTPUT).top.v/$(ROCKET_OUTPUT).top.ift.v/g" $@
endif

$(ROCKET_TOP_SRAM): $(ROCKET_TOP_MEMCONF)
	mkdir -p $(ROCKET_BUILD)
	$(ROCKET_SRC)/scripts/vlsi_mem_gen $(ROCKET_TOP_MEMCONF) > $(ROCKET_TOP_SRAM)

$(ROCKET_TH_SRAM): $(ROCKET_TH_MEMCONF)
	mkdir -p $(ROCKET_BUILD)
	$(SCRIPT)/tb_mem_gen.py $(ROCKET_TH_MEMCONF) --swap > $(ROCKET_TH_SRAM)

th_sram: $(ROCKET_TH_SRAM)

$(ROCKET_ROM_HEX): $(ROCKET_DTS)
	mkdir -p $(FSBL_BUILD)
	$(MAKE) -C $(FSBL_SRC) PBUS_CLK=$(STARSHIP_FREQ)000000 ROOT_DIR=$(TOP) DTS=$(ROCKET_DTS) hex

$(ROCKET_ROM): $(ROCKET_ROM_HEX) $(ROCKET_ROMCONF)
	mkdir -p $(ROCKET_BUILD)
	$(ROCKET_SRC)/scripts/vlsi_rom_gen $(ROCKET_ROMCONF) $< > $@

verilog: $(VERILOG_SRC)

verilog-debug: $(VERILOG_SRC)

verilog-patch: $(ROCKET_TOP_VERILOG)
ifeq ($(STARSHIP_CORE),BOOM)
	sed -i "s/40'h10000 : 40'h0/40'h80000000 : 40'h0/g" $(ROCKET_TOP_VERILOG)
else ifeq ($(STARSHIP_CORE),CVA6)
	sed -i "s/core_boot_addr_i = 64'h10000/core_boot_addr_i = 64'h80000000/g" $(ROCKET_TOP_VERILOG)
else ifeq ($(STARSHIP_CORE),Rocket)
	sed -i "s/s2_pc <= 42'h10000/s2_pc <= 42'h80000000/g" $(ROCKET_TOP_VERILOG)
	sed -i "s/s2_pc <= 40'h10000/s2_pc <= 40'h80000000/g" $(ROCKET_TOP_VERILOG)
endif
ifeq ($(SIMULATION_MODE),cosim)
	sed -i "s/_covMap\[initvar\] = _RAND/_covMap\[initvar\] = 0; \/\//g" $(ROCKET_TOP_VERILOG)
	sed -i "s/_covState = _RAND/_covState = 0; \/\//g" $(ROCKET_TOP_VERILOG)
	sed -i "s/_covSum = _RAND/_covSum = 0; \/\//g" $(ROCKET_TOP_VERILOG)
endif

#######################################
#
#              Yosys
#
#######################################

YOSYS_SRC	:= $(ASIC)/yosys
YOSYS_TOP = $(lastword $(subst ., ,$(STARSHIP_TOP)))
YOSYS_CONFIG = $(lastword $(subst ., ,$(STARSHIP_CONFIG)))
export YOSYS_TOP YOSYS_CONFIG

YOSYS_TOP_VERILOG_OPT	:= $(ROCKET_BUILD)/$(ROCKET_OUTPUT).top.opt.v
YOSYS_TOP_VERILOG_IFT	:= $(ROCKET_BUILD)/$(ROCKET_OUTPUT).top.ift.v

ifneq (,$(filter $(SIMULATION_MODE),taint variant))
  VERILOG_SRC := $(subst $(ROCKET_TOP_VERILOG),$(YOSYS_TOP_VERILOG_IFT),$(VERILOG_SRC))
  VERILOG_SRC := $(subst $(ROCKET_TOP_SRAM),,$(VERILOG_SRC))
  VERILOG_SRC := $(subst $(ROCKET_ROM),,$(VERILOG_SRC))
endif

$(YOSYS_TOP_VERILOG_OPT): $(ROCKET_TOP_SRAM) $(ROCKET_ROM) $(ROCKET_TOP_VERILOG)
ifeq ($(STARSHIP_CORE),BOOM)
	$(YOSYS_SRC)/boom_vec_collect.sh
	yosys -c $(YOSYS_SRC)/boom_opt.tcl
else ifeq ($(STARSHIP_CORE),XiangShan)
	$(YOSYS_SRC)/xiangshan_vec_collect.sh
	yosys -c $(YOSYS_SRC)/xiangshan_opt.tcl
else
$(error Unsupported core yet!)
endif

$(YOSYS_TOP_VERILOG_IFT): $(YOSYS_TOP_VERILOG_OPT) | $(ROCKET_INCLUDE)
ifeq ($(STARSHIP_CORE),BOOM)
	yosys -c $(YOSYS_SRC)/boom_ift.tcl
else ifeq ($(STARSHIP_CORE),XiangShan)
	yosys -c $(YOSYS_SRC)/xiangshan_ift.tcl
endif

verilog-instrument: $(YOSYS_TOP_VERILOG_OPT)
	rm -f $(YOSYS_TOP_VERILOG_IFT)
	$(MAKE) $(YOSYS_TOP_VERILOG_IFT)


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

CHISEL_DEFINE 	:= +define+PRINTF_COND=$(TB_TOP).printf_cond	\
			   	   +define+STOP_COND=!$(TB_TOP).reset

SPIKE_DIR		:= $(SRC)/riscv-isa-sim
SPIKE_SRC		:= $(shell find $(SPIKE_DIR) -name "*.cc" -o -name "*.h" -o -name "*.c")
SPIKE_BUILD		:= $(BUILD)/spike
SPIKE_LIB		:= $(addprefix $(SPIKE_BUILD)/,libcosim.a libriscv.a libdisasm.a libsoftfloat.a libfesvr.a libfdt.a)
SPIKE_INCLUDE	:= $(SPIKE_DIR) $(SPIKE_DIR)/cosim $(SPIKE_DIR)/fdt $(SPIKE_DIR)/fesvr \
				   $(SPIKE_DIR)/riscv $(SPIKE_DIR)/softfloat $(SPIKE_BUILD)

SIM_SRC_C		:= $(SIM_DIR)/probebuffer.cc		\
				   $(SIM_DIR)/mem_swap.cc 			\
			   	   $(SIM_DIR)/tb_mem.cc
SIM_SRC_V		:= $(SIM_DIR)/tty.v					\
				   $(SIM_DIR)/probebuffer.v			\
				   $(SIM_DIR)/archstep.v
SIM_DEFINE		:= +define+MODEL=$(STARSHIP_TH)			\
			   	   +define+CLOCK_PERIOD=1.0	   			\
				   +define+TARGET_$(STARSHIP_CORE)

ifeq ($(SIMULATION_MODE),cosim)
SIM_SRC_C		+= $(SIM_DIR)/spike_difftest.cc		\
				   $(SPIKE_LIB)
SIM_SRC_V		+= $(SIM_DIR)/Testbench.v			\
				   $(SIM_DIR)/spike_difftest.v
SIM_DEFINE		+= +define+COVERAGE_SUMMARY +define+COSIMULATION
else ifeq ($(SIMULATION_MODE),robprofile)
SIM_SRC_V		+= $(SIM_DIR)/Testbench.v			\
				   $(SIM_DIR)/robprofile.v
SIM_DEFINE		+= +define+ROBPROFILE
else ifeq ($(SIMULATION_MODE),taint)
SIM_SRC_C		+= $(SIM_DIR)/divaift_lib.cc
SIM_SRC_V		+= $(SIM_DIR)/Testbench.ift.v		\
				   $(SIM_DIR)/divaift_lib.v			\
				   $(SIM_DIR)/robprofile.v
SIM_DEFINE		+= +define+HASTAINT
else ifeq ($(SIMULATION_MODE),variant)
SIM_SRC_C		+= $(SIM_DIR)/divaift_lib.cc
SIM_SRC_V		+= $(SIM_DIR)/Testbench.ift.v		\
				   $(SIM_DIR)/divaift_lib.v			\
				   $(SIM_DIR)/robprofile.v
SIM_DEFINE		+= +define+HASVARIANT
else
SIM_SRC_V		+= $(SIM_DIR)/Testbench.v
endif

export LD_LIBRARY_PATH=$(SPIKE_BUILD)

$(SPIKE_BUILD)/Makefile:
	mkdir -p $(SPIKE_BUILD)
	cd $(SPIKE_BUILD); $(SPIKE_DIR)/configure

$(SPIKE_LIB)&: $(SPIKE_SRC) $(SPIKE_BUILD)/Makefile
	cd $(SPIKE_BUILD); make -j$(shell nproc) $(notdir $(SPIKE_LIB))

spike: $(SPIKE_LIB)

#######################################
#
#            Synopsys VCS
#
#######################################

VCS_OUTPUT	:= $(BUILD)/vcs/$(STARSHIP_CONFIG)_$(STARSHIP_CORE)_$(SIMULATION_MODE)
VERDI_OUTPUT:= $(BUILD)/verdi
VCS_BUILD	:= $(VCS_OUTPUT)/build
VCS_LOG		:= $(VCS_OUTPUT)/log
VCS_WAVE	:= $(VCS_OUTPUT)/wave

VCS_TARGET	:= $(VCS_BUILD)/$(TB_TOP)
VCS_INCLUDE	:= $(ROCKET_BUILD)+$(SIM_DIR)
VCS_CFLAGS	:= -std=c++17 $(addprefix -I,$(SPIKE_INCLUDE)) -I$(ROCKET_BUILD)

VCS_SRC_C	:= $(SIM_SRC_C)
VCS_SRC_V	:= $(SIM_SRC_V)
VCS_DEFINE	:= $(SIM_DEFINE)								\
			   +define+TOP_DIR=\"$(VCS_OUTPUT)\"			\
			   +define+DEBUG_FSDB

VCS_PARAL_COM	:= -j$(shell nproc) # -Xkeyopt=rtopt -fgp 
VCS_PARAL_RUN	:= # -fgp=num_threads:4,num_fsdb_threads:1 # -fgp=num_cores:$(shell nproc),percent_fsdb_cores:30

VCS_OPTION	:= -quiet -notice -line +rad -full64 +nospecify +notimingcheck -deraceclockdata 		\
			   -sverilog +systemverilogext+.sva+.pkg+.sv+.SV+.vh+.svh+.svi+ -assert svaext 			\
			   +vcs+initreg+random +v2k -debug_acc+all -timescale=1ns/10ps +incdir+$(VCS_INCLUDE) 	\
			   $(VCS_PARAL_COM) -CFLAGS "$(VCS_CFLAGS)" -lconfig++									\
			   $(CHISEL_DEFINE) $(VCS_DEFINE)
VCS_SIM_OPTION	:= +vcs+initreg+0 $(VCS_PARAL_RUN) +testcase=$(STARSHIP_TESTCASE) +label=$(SIMULATION_LABEL)

vcs-wave: 		VCS_SIM_OPTION += +dump +uart_tx=0
vcs-debug: 		VCS_SIM_OPTION += +verbose +uart_tx=0
vcs-fuzz: 		VCS_SIM_OPTION += +fuzzing +uart_tx=0
vcs-fuzz-debug:	VCS_SIM_OPTION += +fuzzing +verbose +dump +uart_tx=0
vcs-jtag: 		VCS_SIM_OPTION += +jtag_rbb_enable=1 +verbose +uart_tx=0
vcs-jtag-debug: VCS_SIM_OPTION += +jtag_rbb_enable=1 +verbose +dump +uart_tx=0

$(VCS_TARGET): $(VERILOG_SRC) $(ROCKET_ROM_HEX) $(ROCKET_INCLUDE) $(VCS_SRC_V) $(VCS_SRC_C)
	mkdir -p $(VCS_BUILD) $(VCS_LOG) $(VCS_WAVE)
	cd $(VCS_OUTPUT); vcs $(VCS_OPTION) -l $(VCS_LOG)/vcs.log -top $(TB_TOP) \
		-f $(ROCKET_INCLUDE) $(VCS_SRC_V) $(VCS_SRC_C) -o $@

vcs-dummy: $(VCS_TARGET)

vcs: $(VCS_TARGET)
	mkdir -p $(VCS_LOG) $(VCS_WAVE)
	cd $(VCS_OUTPUT); time \
	$(VCS_TARGET) -quiet +ntb_random_seed_automatic -no_save -l $(VCS_LOG)/sim.log  \
		$(VCS_SIM_OPTION) $(EXTRA_SIM_ARGS) 2>&1 | tee /tmp/rocket.log; exit "$${PIPESTATUS[0]}";

vcs-wave vcs-debug: vcs
vcs-fuzz vcs-fuzz-debug: vcs
vcs-jtag vcs-jtag-debug: vcs

verdi:
	mkdir -p $(VERDI_OUTPUT)
	touch $(VERDI_OUTPUT)/signal.rc
	cd $(VERDI_OUTPUT); \
	verdi -$(VCS_OPTION) -q -ssy -ssv -ssz -autoalias \
		-ssf $(VCS_WAVE)/$(SIMULATION_LABEL).fsdb -sswr $(VERDI_OUTPUT)/signal.rc \
		-logfile $(VCS_LOG)/verdi.log -top $(TB_TOP) -f $(ROCKET_INCLUDE) $(VCS_SRC_V) &

#######################################
#
#            Verilator
#
#######################################

VLT_OUTPUT	:= $(BUILD)/verilator/$(STARSHIP_CONFIG)_$(STARSHIP_CORE)_$(SIMULATION_MODE)
VLT_BUILD	:= $(VLT_OUTPUT)/build
VLT_WAVE 	:= $(VLT_OUTPUT)/wave
VLT_TARGET  := $(VLT_BUILD)/$(TB_TOP)

VLT_CFLAGS	:= -std=c++17 $(addprefix -I,$(SPIKE_INCLUDE)) -I$(ROCKET_BUILD)

VLT_SRC_C	:= $(SIM_SRC_C)
VLT_SRC_V	:= $(SIM_SRC_V)

VLT_DEFINE	:= $(SIM_DEFINE)							\
			   +define+TOP_DIR=\"$(VLT_OUTPUT)\"		\
			   +define+DEBUG_VCD

vlt-fuzz:		VLT_DEFINE += +define+COVERAGE_SUMMARY +define+COSIMULATION
vlt-fuzz-debug:	VLT_DEFINE += +define+COVERAGE_SUMMARY +define+COSIMULATION

VLT_OPTION	:= -Wno-fatal -Wno-WIDTH -Wno-STMTDLY -Werror-IMPLICIT							\
			   --timescale 1ns/10ps --trace --timing -j $(shell nproc) 						\
			   +systemverilogext+.sva+.pkg+.sv+.SV+.vh+.svh+.svi+ -O3						\
			   +incdir+$(ROCKET_BUILD) +incdir+$(SIM_DIR) $(CHISEL_DEFINE) $(VLT_DEFINE)	\
			   --cc --exe --Mdir $(VLT_BUILD) --top-module $(TB_TOP) --main -o $(TB_TOP) 	\
			   -CFLAGS "-DVL_DEBUG -DTOP=${TB_TOP} ${VLT_CFLAGS} -fcoroutines"				\
			   -LDFLAGS "-ldl  -lconfig++"
VLT_SIM_OPTION	:= +testcase=$(STARSHIP_TESTCASE) +label=$(SIMULATION_LABEL)

vlt-wave: 		VLT_SIM_OPTION	+= +dump
vlt-debug: 		VLT_SIM_OPTION 	+= +verbose +dump
vlt-fuzz: 		VLT_SIM_OPTION	+= +fuzzing
vlt-fuzz-debug: VLT_SIM_OPTION	+= +fuzzing +verbose +dump
vlt-jtag: 		VLT_SIM_OPTION	+= +jtag_rbb_enable=1
vlt-jtag-debug: VLT_SIM_OPTION	+= +jtag_rbb_enable=1 +dump

$(VLT_TARGET): $(VERILOG_SRC) $(ROCKET_ROM_HEX) $(ROCKET_INCLUDE) $(VLT_SRC_V) $(VLT_SRC_C)
	mkdir -p $(VLT_BUILD) $(VLT_WAVE)
	cd $(VLT_OUTPUT); verilator $(VLT_OPTION) -f $(ROCKET_INCLUDE) $(VLT_SRC_V) $(VLT_SRC_C)
	make -C $(VLT_BUILD) -f V$(TB_TOP).mk $(TB_TOP) -j $(shell nproc)

vlt-dummy: $(VLT_TARGET)

vlt: $(VLT_TARGET)
	mkdir -p $(VLT_WAVE)
	cd $(VLT_OUTPUT); time \
	$(VLT_TARGET) $(VLT_SIM_OPTION) $(EXTRA_SIM_ARGS)

vlt-wave: 		vlt
vlt-debug:		vlt
vlt-fuzz: 		vlt
vlt-jtag: 		vlt
vlt-jtag-debug: vlt

gtkwave:
	gtkwave $(VLT_WAVE)/$(SIMULATION_LABEL).vcd

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

#######################################
#
#               Utils
#
#######################################

SBT_BUILD 	:= $(TOP)/target $(TOP)/project/target $(TOP)/project/project

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

plot_vcs_taint:
	$(SCRIPT)/taint_sum.py -s vcs -c $(STARSHIP_CONFIG)_$(STARSHIP_CORE)_$(SIMULATION_MODE) -q

plot_vlt_taint:
	$(SCRIPT)/taint_sum.py -s vcs -c $(STARSHIP_CONFIG)_$(STARSHIP_CORE)_$(SIMULATION_MODE) -q

clean:
	rm -rf $(BUILD)

clean-all:
	rm -rf $(BUILD) $(SBT_BUILD)
