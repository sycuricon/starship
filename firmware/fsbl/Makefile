# RISCV environment variable must be set
ROOT_DIR	?=	$(dir $(abspath $(lastword $(MAKEFILE_LIST))))
BUILD_DIR	:=	$(ROOT_DIR)/build/firmware/fsbl

CC			=	$(RISCV)/bin/riscv64-unknown-elf-gcc
OBJCOPY		=	$(RISCV)/bin/riscv64-unknown-elf-objcopy
OBJDUMP		=	$(RISCV)/bin/riscv64-unknown-elf-objdump
CFLAGS		=	-march=rv64ima -mcmodel=medany -O2 -std=gnu11 -Wall -nostartfiles
CFLAGS		+=	-fno-common -g -DENTROPY=0 -mabi=lp64 -DNONSMP_HART=0
CFLAGS		+=	-I./include -I. -I$(BUILD_DIR)
LFLAGS		=	-static -nostdlib -L ./linker -T sdboot.elf.lds

PBUS_CLK ?= 1000000 # default to 1MHz but really should be overridden

default: elf bin dump

dtb		:= $(BUILD_DIR)/$(ROCKET_OUTPUT).dtb
dts		:= $(BUILD_DIR)/$(ROCKET_OUTPUT).dts
dts_h	:= $(BUILD_DIR)/dts.h
dts_org	:= $(ROOT_DIR)/build/rocket-chip/$(ROCKET_OUTPUT).dts

$(dts): $(dts_org)
	mkdir -p $(BUILD_DIR)
	cp $< $(dts)
	sed -i "s/clock-frequency = <0>/clock-frequency = <$(PBUS_CLK)>/g" $(dts)

$(dts_h): $(dts)
	mkdir -p $(BUILD_DIR)
	echo "#ifndef _STARSHIP_FSBL_H" > $(dts_h)
	echo "#define _STARSHIP_FSBL_H" >> $(dts_h)
	grep -q "sifive,uart" $(dts) && echo "#define UART" >> $(dts_h) || true
	grep -q "sifive,spi" $(dts)  && echo "#define SD_SPI" >> $(dts_h) || true
	echo "#endif" >> $(dts_h)

$(dtb): $(dts) $(dts_h)
	mkdir -p $(BUILD_DIR)
	dtc -I dts -O dtb -o $@ $(dts)


elf := $(BUILD_DIR)/sdboot.elf
$(elf): head.S kprintf.c sd.c $(dtb)
	mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -DTL_CLK="$(PBUS_CLK)UL" -DDEVICE_TREE='"$(dtb)"' $(LFLAGS) -o $@ head.S sd.c kprintf.c

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
$(hex): $(bin) dump
	od -t x4 -An -w4 -v $< > $@

.PHONY: hex
hex: $(hex)

.PHONY: clean
clean::
	rm -rf $(BUILD_DIR)
