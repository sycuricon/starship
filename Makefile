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

GCC_VERSION	:= $(word 1, $(subst ., ,$(shell gcc -dumpversion)))
ifeq ($(shell echo $(GCC_VERSION)\>=9 | bc ),0)
SCL_PREFIX := source scl_source enable devtoolset-9 &&
endif

all: bitstream




#######################################
#                                      
#         Starship Configuration
#                                      
#######################################

# STARSHIP_FREQ	?= 100
# STARSHIP_TH 	?= TestHarness
# STARSHIP_TOP	?= StarshipFPGATop
# STARSHIP_PKG	?= starship.fpga
# STARSHIP_CONFIG	?= StarshipFPGAConfig
# EXTRA_CONFIG	?= starship.With$(STARSHIP_FREQ)MHz

STARSHIP_FREQ	?= 100
STARSHIP_TH 	?= TestHarness
STARSHIP_TOP	?= StarshipASICTop
STARSHIP_PKG	?= starship.asic
STARSHIP_CONFIG	?= StarshipSimConfig
EXTRA_CONFIG	?= starship.With$(STARSHIP_FREQ)MHz




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

verilog-debug: FIRRTL_DEBUG_OPTION ?= -ll info

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

rocket-patch:
	cd $(ROCKET_SRC); git checkout -- src/main/scala/rocket/RocketCore.scala src/main/scala/tile/Core.scala src/main/scala/tile/FPU.scala src/main/scala/rocket/IBuf.scala
	sed -i "s/import chisel3.withClock/import chisel3.{withClock,dontTouch}/g" $(ROCKET_SRC)/src/main/scala/rocket/RocketCore.scala
	sed -i "s/nBreakpoints: Int = 1/nBreakpoints: Int = 3/g" $(ROCKET_SRC)/src/main/scala/rocket/RocketCore.scala
	# sed -i "s/useHypervisor: Boolean = false/useHypervisor: Boolean = true/g" $(ROCKET_SRC)/src/main/scala/rocket/RocketCore.scala
	# sed -i "s/useRVE: Boolean = false/useRVE: Boolean = true/g" $(ROCKET_SRC)/src/main/scala/rocket/RocketCore.scala
	sed -i "/val csr =/adontTouch(csr.io)" $(ROCKET_SRC)/src/main/scala/rocket/RocketCore.scala
	sed -i "s/val enableCommitLog = false/val enableCommitLog = true/g" $(ROCKET_SRC)/src/main/scala/tile/Core.scala
	sed -i "s/, ieee(wdata)/, ieee(wdata).suggestName(\"rtlFuzz_fregWriteData\")/g" $(ROCKET_SRC)/src/main/scala/tile/FPU.scala
	sed -i "s/, load_wb_data/, ieee(wdata).suggestName(\"rtlFuzz_fregLoadData\")/g" $(ROCKET_SRC)/src/main/scala/tile/FPU.scala
	sed -i "s/when ((!wbInfo(0).cp && wen(0)) || divSqrt_wen)/when (fregWrite)/g" $(ROCKET_SRC)/src/main/scala/tile/FPU.scala
	sed -i "/val wexc =/aval fregWrite = ((!wbInfo(0).cp && wen(0)) || divSqrt_wen).suggestName(\"rtlFuzz_fregWriteEnable\")" $(ROCKET_SRC)/src/main/scala/tile/FPU.scala
	echo -e "package freechips.rocketchip.util\nimport chisel3._\nimport chisel3.util._\nclass MCBlackbox extends BlackBox {\n  val io = IO(new Bundle {\n  val clock = Input(Clock())\n  val en = Input(Bool())\n  val in = Input(UInt(64.W))\n  val pc = Input(UInt(64.W))\n  val out = Output(UInt(64.W))})}\n"	> $(ROCKET_SRC)/src/main/scala/util/InsnRandom.scala
	sed -i "/io.pc := Mux/a  val randomizer = Module(new MCBlackbox)\n  randomizer.io.clock := clock\n  randomizer.io.in := inst\n  randomizer.io.pc := io.pc\n  randomizer.io.en := io.inst(0).valid" $(ROCKET_SRC)/src/main/scala/rocket/IBuf.scala
	sed -i "s/expand(0, 0, inst)/expand(0, 0, randomizer.io.out)/g" $(ROCKET_SRC)/src/main/scala/rocket/IBuf.scala




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

$(ROCKET_INCLUDE): | $(ROCKET_TOP_VERILOG) $(ROCKET_TH_VERILOG)
	mkdir -p $(ROCKET_BUILD)
	cat $(ROCKET_TH_INCLUDE) $(ROCKET_TOP_INCLUDE) 2> /dev/null | sort -u > $@
	echo $(VERILOG_SRC) >> $@
	sed -i "s/.*\.f$$/-f &/g" $@

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
verilog-debug: verilog
verilog-patch: $(VERILOG_SRC)
	# sed -i "s/s2_pc <= 42'h10000/s2_pc <= 42'h80000000/g" $(ROCKET_TOP_VERILOG)
	sed -i "s/s2_pc <= 40'h10000/s2_pc <= 40'h80000000/g" $(ROCKET_TOP_VERILOG)
	sed -i "s/core_boot_addr_i = 64'h10000/core_boot_addr_i = 64'h80000000/g" $(ROCKET_TOP_VERILOG)
	sed -i "s/40'h10000 : 40'h0/40'h80000000 : 40'h0/g" $(ROCKET_TOP_VERILOG)
	sed -i "s/ram\[initvar\] = {2 {\$$random}}/ram\[initvar\] = 0/g" $(ROCKET_TH_SRAM)
	sed -i "s/_covMap\[initvar\] = _RAND/_covMap\[initvar\] = 0; \/\//g" $(ROCKET_TOP_VERILOG)
	sed -i "s/_covState = _RAND/_covState = 0; \/\//g" $(ROCKET_TOP_VERILOG)
	sed -i "s/_covSum = _RAND/_covSum = 0; \/\//g" $(ROCKET_TOP_VERILOG)
	



#######################################
#
#         Bitstream Generator
#
#######################################

BOARD				:= vc707
VIVADO_SRC			:= $(SRC)/fpga-shells
VIVADO_SCRIPT		:= $(VIVADO_SRC)/xilinx
VIVADO_BUILD		:= $(BUILD)/vivado
VIVADO_BITSTREAM 	:= $(VIVADO_BUILD)/$(ROCKET_OUTPUT).bit

$(VIVADO_BITSTREAM): $(ROCKET_VERILOG) $(ROCKET_INCLUDE) $(ROCKET_TOP_SRAM) $(ROCKET_TH_SRAM) $(ROCKET_ROM)
	mkdir -p $(VIVADO_BUILD)
	cd $(VIVADO_BUILD); vivado -mode batch -nojournal \
		-source $(VIVADO_SCRIPT)/common/tcl/vivado.tcl \
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

TB_DIR		:= $(ASIC)/testbench
VCS_OUTPUT	:= $(BUILD)/vcs
VERDI_OUTPUT:= $(BUILD)/verdi
VCS_BUILD	:= $(VCS_OUTPUT)/build
VCS_LOG		:= $(VCS_OUTPUT)/log
VCS_WAVE	:= $(VCS_OUTPUT)/wave

SPIKE_DIR		:= $(SRC)/riscv-isa-sim
SPIKE_SRC		:= $(shell find $(SPIKE_DIR) -name "*.cc" -o -name "*.h" -o -name "*.c")
SPIKE_BUILD		:= $(BUILD)/spike
SPIKE_LIB		:= $(SPIKE_BUILD)/libcosim.a
SPIKE_INCLUDE	:= $(SPIKE_DIR) $(SPIKE_DIR)/cosim $(SPIKE_DIR)/fdt $(SPIKE_DIR)/fesvr \
			       $(SPIKE_DIR)/riscv $(SPIKE_DIR)/softfloat $(SPIKE_BUILD)
SPIKE_CONFIG  	:= $(SPIKE_BUILD)/cj-config.h
SPIKE_CONFIG_OPT = --testcase $(TESTCASE_ELF)

export LD_LIBRARY_PATH=$(SPIKE_BUILD)
export CVA6_REPO_DIR=/eda/project/dut/cva6

VCS_TB		?= Testbench
VCS_SIMV	:= $(VCS_BUILD)/simv
VCS_INCLUDE	:= $(ROCKET_BUILD)+$(TB_DIR)
VCS_CFLAGS	:= -std=c++11 $(addprefix -I,$(SPIKE_INCLUDE))
VCS_TB_VLOG ?= $(TB_DIR)/$(VCS_TB).v

#TESTCASE_ROOT	?= /eda/project/riscv-tests/build/isa
TESTCASE_ROOT	?= /home/hesirui/riscv-tests/build/isa
# /eda/project/riscv-tests/build/isa  /eda/project/riscv-tests/build/benchmarks
TESTCASE		:= cosim-p-test
# rv64ui-p-addi rv64uf-v-fdiv dhrystone.riscv rv64ssvnapot-p-napot
TESTCASE_ELF	:= $(TESTCASE_ROOT)/$(TESTCASE)
TESTCASE_BIN	:= $(shell mktemp)
TESTCASE_HEX	:= $(TESTCASE_ROOT)/$(TESTCASE).hex

VCS_SRC_C	:= $(TB_DIR)/spike_difftest.cc $(SPIKE_LIB) \
			   $(addprefix $(SPIKE_BUILD)/,libriscv.a libdisasm.a libsoftfloat.a libfesvr.a libfdt.a) \
			   $(TB_DIR)/timer.cc  

VCS_SRC_V	:= $(VCS_TB_VLOG) \
			   $(TB_DIR)/spike_difftest.v \
			   $(TB_DIR)/tty.v \
			   $(TB_DIR)/coverage.v

TB_DEFINE	:= +define+MODEL=$(STARSHIP_TH)					\
			   +define+TOP_DIR=\"$(VCS_OUTPUT)\"			\
			   +define+INITIALIZE_MEMORY					\
			   +define+CLOCK_PERIOD=1.0	   					\
			   +define+DEBUG_FSDB

CHISEL_DEFINE := +define+PRINTF_COND=$(VCS_TB).printf_cond	\
			   	 +define+STOP_COND=!$(VCS_TB).reset			\
				 +define+RANDOMIZE_MEM_INIT					\
				 +define+RANDOMIZE_REG_INIT					\
				 +define+RANDOMIZE_GARBAGE_ASSIGN			\
				 +define+RANDOMIZE_INVALID_ASSIGN			\
				 +define+RANDOMIZE_DELAY=0.1

VCS_PARAL_COM	:= -j$(shell nproc) # -fgp
VCS_PARAL_RUN	:= # -fgp=num_threads:1,num_fsdb_threads:1 # -fgp=num_cores:$(shell nproc),percent_fsdb_cores:30

VCS_OPTION	:= -quiet -notice -line +rad -full64 +nospecify +notimingcheck -deraceclockdata 		\
			   -sverilog +systemverilogext+.sva+.pkg+.sv+.SV+.vh+.svh+.svi+ -assert svaext 			\
			   +v2k -debug_acc+all -timescale=1ns/10ps +incdir+$(VCS_INCLUDE) 						\
			   $(VCS_PARAL_COM) -CFLAGS "$(VCS_CFLAGS)" 											\
			   $(CHISEL_DEFINE) $(TB_DEFINE)
VSIM_OPTION	:= $(VCS_PARAL_RUN) +fuzz +uart_tx=1 +testcase=$(TESTCASE_ELF) # +interrupt

vcs-debug: VSIM_OPTION += +verbose +dump

$(SPIKE_BUILD)/Makefile:
	mkdir -p $(SPIKE_BUILD)
	cd $(SPIKE_BUILD); $(SCL_PREFIX) $(SPIKE_DIR)/configure

$(SPIKE_LIB): $(SPIKE_SRC) $(SPIKE_BUILD)/Makefile
	cd $(SPIKE_BUILD); $(SCL_PREFIX) make -j$(shell nproc) libcosim.a

$(VCS_SIMV): $(VERILOG_SRC) $(ROCKET_INCLUDE) $(VCS_SRC_V) $(VCS_SRC_C) $(SPIKE_LIB)
	mkdir -p $(VCS_BUILD) $(VCS_LOG) $(VCS_WAVE)
	cd $(VCS_BUILD); $(SCL_PREFIX) vcs $(VCS_OPTION) -l $(VCS_LOG)/vcs.log -top $(VCS_TB) \
						 -f $(ROCKET_INCLUDE) $(VCS_SRC_V) $(VCS_SRC_C) -o $@

$(TESTCASE_HEX): $(TESTCASE_ELF)
	riscv64-unknown-elf-objcopy --gap-fill 0			\
		--set-section-flags .bss=alloc,load,contents	\
		--set-section-flags .sbss=alloc,load,contents	\
		--set-section-flags .tbss=alloc,load,contents	\
		-O binary $< $(TESTCASE_BIN)
	od -v -An -tx8 $(TESTCASE_BIN) > $@
	rm $(TESTCASE_BIN)

# dromajo-config:
# 	$(CONFIG)/dromajo_config.py $(DROMAJO_CONFIG_OPT) > $(DROMAJO_CONFIG)

reglist-convert:
	mkdir -p $(VERDI_OUTPUT) $(ROCKET_BUILD) 
	$(CONFIG)/reglist_convert.py -f signal -p "Testbench.testHarness" -n Probe_TestHarness \
								 -o $(ROCKET_BUILD)/TestHarness.vh $(ROCKET_BUILD)/TestHarness.reglist
	$(CONFIG)/reglist_convert.py -f signal -p "Testbench.testHarness.ldut" -n Probe_StarshipASICTop \
								 -o $(ROCKET_BUILD)/StarshipASICTop.vh $(ROCKET_BUILD)/StarshipASICTop.reglist
	$(CONFIG)/reglist_convert.py -f wave -p "addSignal /Testbench/testHarness" \
								 -o $(VERDI_OUTPUT)/TestHarness.rc $(ROCKET_BUILD)/TestHarness.reglist
	$(CONFIG)/reglist_convert.py -f wave -p "addSignal /Testbench/testHarness/ldut" \
								 -o $(VERDI_OUTPUT)/StarshipASICTop.rc $(ROCKET_BUILD)/StarshipASICTop.reglist

vcs: $(VCS_SIMV) $(TESTCASE_HEX)
	mkdir -p $(VCS_BUILD) $(VCS_LOG) $(VCS_WAVE)
	cd $(VCS_BUILD); $(VCS_SIMV) -quiet +ntb_random_seed_automatic -l $(VCS_LOG)/sim.log  \
								  $(VSIM_OPTION)  2>&1 | tee /home/hesirui/rocket.log; exit "$${PIPESTATUS[0]}"

vcs-coverage:
	$(CONFIG)/reglist_convert.py -f label -p "Testbench.testHarness.ldut" \
								 -o $(VCS_WAVE)/StarshipASICTop.label $(ROCKET_BUILD)/StarshipASICTop.reglist
	$(CONFIG)/heatmap.py -o $(VCS_WAVE) -n $(TESTCASE) -l $(VCS_WAVE)/StarshipASICTop.label $(VCS_BUILD)/heat.map


vcs-debug: vcs

verdi: $(VCS_WAVE)/*.fsdb
	mkdir -p $(VERDI_OUTPUT)
	touch $(VERDI_OUTPUT)/signal.rc
	cd $(VERDI_OUTPUT); verdi -$(VCS_OPTION) -q -ssy -ssv -ssz -autoalias	\
						   -ssf $(VCS_WAVE)/starship.fsdb -sswr $(VERDI_OUTPUT)/signal.rc \
						   -logfile $(VCS_LOG)/verdi.log -top $(VCS_TB) -f $(ROCKET_INCLUDE) $(VCS_SRC_V) &




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
	rm -rf $(BUILD)

clean-all:
	rm -rf $(BUILD) $(SBT_BUILD)
