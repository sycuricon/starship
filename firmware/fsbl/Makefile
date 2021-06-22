# RISCV environment variable must be set
TARGET_FPGA ?= a7
ROOT_DIR	?=	$(dir $(abspath $(lastword $(MAKEFILE_LIST))))
BUILD_DIR	:=	$(ROOT_DIR)/build/$(TARGET_FPGA)/firmware/fsbl

CC			=	$(RISCV)/bin/riscv64-unknown-elf-gcc
OBJCOPY		=	$(RISCV)/bin/riscv64-unknown-elf-objcopy
OBJDUMP		=	$(RISCV)/bin/riscv64-unknown-elf-objdump
CFLAGS		=	-march=rv64ima -mcmodel=medany -O2 -std=gnu11 -Wall -nostartfiles
CFLAGS		+=	-fno-common -g -DENTROPY=0 -mabi=lp64 -DNONSMP_HART=0
CFLAGS		+=	-I ./include -I.
LFLAGS		=	-static -nostdlib -L ./linker -T sdboot.elf.lds

PBUS_CLK ?= 1000000 # default to 1MHz but really should be overridden

mem_sz_a7  := 0x8000000
mem_oft_a7 := 0x7fff000
mem_sz_vc707  := 0x40000000
mem_oft_vc707 := 0xffff000

default: elf bin dump

dtb		:= $(BUILD_DIR)/$(ROCKET_OUTPUT).dtb
dts		:= $(BUILD_DIR)/$(ROCKET_OUTPUT).dts
dts_org	:= $(ROOT_DIR)/build/$(TARGET_FPGA)/rocket-chip/$(ROCKET_OUTPUT).dts

$(dtb): $(dts_org)
	mkdir -p $(BUILD_DIR)
	cp $< $(dts)
	sed -i "s/clock-frequency = <0>/clock-frequency = <$(PBUS_CLK)>/g" $(dts)
	dtc -I dts -O dtb -o $@ $(dts)

elf := $(BUILD_DIR)/sdboot.elf
$(elf): head.S kprintf.c sd.c $(dtb)
	mkdir -p $(BUILD_DIR)
	$(shell echo DDR_LENGTH = $(mem_sz_$(TARGET_FPGA))\; > linker/board.lds)
	$(CC) $(CFLAGS) -DBOARD_SPECIFIC_OFFSET="$(mem_oft_$(TARGET_FPGA))" -DTL_CLK="$(PBUS_CLK)UL" -DDEVICE_TREE='"$(dtb)"' $(LFLAGS) -o $@ head.S sd.c kprintf.c

.PHONY: elf
elf: $(elf)

bin := $(BUILD_DIR)/sdboot.bin
$(bin): $(elf)
	mkdir -p $(BUILD_DIR)
	$(OBJCOPY) -O binary $< $@

.PHONY: bin
bin: $(bin)

dump := $(BUILD_DIR)/sdboot.dump
$(dump): $(elf)
	$(OBJDUMP) -D -S $< > $@

.PHONY: dump
dump: $(dump)

hex := $(BUILD_DIR)/sdboot.hex
$(hex): $(bin)
	od -t x4 -An -w4 -v $< > $@

.PHONY: hex
hex: $(hex)

.PHONY: clean
clean::
	rm -rf $(BUILD_DIR)
