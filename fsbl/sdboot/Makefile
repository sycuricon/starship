# RISCV environment variable must be set
ROOT_DIR	?=	$(dir $(abspath $(lastword $(MAKEFILE_LIST))))
BUILD_DIR	:=	$(ROOT_DIR)/build/fsbl

CC			=	$(RISCV)/bin/riscv64-unknown-elf-gcc
OBJCOPY		=	$(RISCV)/bin/riscv64-unknown-elf-objcopy
OBJDUMP		=	$(RISCV)/bin/riscv64-unknown-elf-objdump
CFLAGS		=	-march=rv64ima -mcmodel=medany -O2 -std=gnu11 -Wall -nostartfiles
CFLAGS		+=	-fno-common -g -DENTROPY=0 -mabi=lp64 -DNONSMP_HART=0
CFLAGS		+=	-I ./include -I.
LFLAGS		=	-static -nostdlib -L ./linker -T sdboot.elf.lds

PBUS_CLK ?= 1000000 # default to 1MHz but really should be overridden

default: elf bin dump

dtb	:= $(BUILD_DIR)/rocketchip.dtb
dts	:= rocketchip.dts

$(dtb): $(dts)
	mkdir -p $(BUILD_DIR)
	dtc -I dts -O dtb -o $@ $<

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

.PHONY: clean
clean::
	rm -rf $(BUILD_DIR)
