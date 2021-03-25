# Copyright (C) 2021 by phantom
# Email: phantom@zju.edu.cn
# This file is under MIT License, see https://www.phvntom.tech/LICENSE.txt

TOP	:= $(CURDIR)
BUILD	:= $(TOP)/build
SRC	:= $(TOP)/repo
CONFIG	:= $(TOP)/conf

ifndef RISCV
$(error RISCV is undefined)
endif

all: rocket


ROCKET_SRC	:= $(SRC)/rocket-chip
ROCKET_BUILD	:= $(BUILD)/rocket-chip
ROCKET_JVM_MEMORY ?= 2G
ROCKET_JAVA	:= java -Xmx$(ROCKET_JVM_MEMORY) -Xss8M -jar $(ROCKET_SRC)/sbt-launch.jar
ROCKET_PROJECT	?= freechips.rocketchip.system
ROCKET_TOP	?= TestHarness
ROCKET_CONFIG	?= DefaultConfig
ROCKET_OUTPUT	:= starship
ROCKET_VERILOG	:= $(ROCKET_BUILD)/$(ROCKET_OUTPUT).v
ROCKET_FIRRTL	:= $(ROCKET_BUILD)/$(ROCKET_OUTPUT).fir

#######################################
#
#	RocketChip Generator
#
#######################################

$(ROCKET_FIRRTL): 
	mkdir -p $(ROCKET_BUILD)
	cd $(ROCKET_SRC) && $(ROCKET_JAVA) 		\
		"runMain $(ROCKET_PROJECT).Generator	\
	       	-td $(ROCKET_BUILD) 			\
		-T $(ROCKET_PROJECT).$(ROCKET_TOP)	\
	       	-C $(ROCKET_PROJECT).$(ROCKET_CONFIG)	\
		-n $(ROCKET_OUTPUT)"

$(ROCKET_VERILOG): $(ROCKET_FIRRTL)
	mkdir -p $(ROCKET_BUILD)
	cd $(ROCKET_SRC) && $(ROCKET_JAVA)              \
		"runMain firrtl.stage.FirrtlMain	\
		-i $< -o $@ -X verilog"

rocket: $(ROCKET_VERILOG)


clean:
	rm -rf $(BUILD)

