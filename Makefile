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

all: rocket

#######################################
#                                      
#        RocketChip Generator          
#                                      
#######################################

ROCKET_SRC		:= $(SRC)/rocket-chip
ROCKET_BUILD	:= $(BUILD)/rocket-chip
ROCKET_JVM_MEM	?= 2G
ROCKET_JAVA		:= java -Xmx$(ROCKET_JVM_MEM) -Xss8M -jar $(ROCKET_SRC)/sbt-launch.jar
ROCKET_TOP_PROJ	?= starship.fpga
ROCKET_TOP		?= TestHarness
ROCKET_CON_PROJ	?= starship
ROCKET_CONFIG	?= StarshipDefaultConfig
ROCKET_OUTPUT	:= $(ROCKET_TOP_PROJ).$(ROCKET_TOP).$(ROCKET_CONFIG)
ROCKET_VERILOG	:= $(ROCKET_BUILD)/$(ROCKET_OUTPUT).v
ROCKET_FIRRTL	:= $(ROCKET_BUILD)/$(ROCKET_OUTPUT).fir

$(ROCKET_FIRRTL): 
	mkdir -p $(ROCKET_BUILD)
	$(ROCKET_JAVA) "runMain freechips.rocketchip.system.Generator	\
					-td $(ROCKET_BUILD) -T $(ROCKET_TOP_PROJ).$(ROCKET_TOP)	\
					-C $(ROCKET_CON_PROJ).$(ROCKET_CONFIG) -n $(ROCKET_OUTPUT)"

$(ROCKET_VERILOG): $(ROCKET_FIRRTL)
	mkdir -p $(ROCKET_BUILD)
	$(ROCKET_JAVA) "runMain firrtl.stage.FirrtlMain	\
					-td $(ROCKET_BUILD) --infer-rw $(ROCKET_TOP) \
					--repl-seq-mem -c:$(ROCKET_TOP):-o:$(ROCKET_BUILD)/$(ROCKET_OUTPUT).rom.conf \
					-faf $(ROCKET_BUILD)/$(ROCKET_OUTPUT).anno.json \
					-fct firrtl.passes.InlineInstances \
					-i $< -o $@ -X verilog"

rocket: $(ROCKET_VERILOG)


#######################################
#
#            StarShip Soc
#
#######################################



#######################################
#
#            Bitstream
#
#######################################





clean:
	rm -rf $(BUILD) $(SBT_BUILD)