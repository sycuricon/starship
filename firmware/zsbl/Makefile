ROOT_DIR	?=	$(dir $(abspath $(lastword $(MAKEFILE_LIST))))
BUILD_DIR	:=	$(ROOT_DIR)/build/firmware/zsbl

CC			=	$(RISCV)/bin/riscv64-unknown-elf-gcc
OBJCOPY		=	$(RISCV)/bin/riscv64-unknown-elf-objcopy
OBJDUMP		=	$(RISCV)/bin/riscv64-unknown-elf-objdump

elf	:= $(BUILD_DIR)/bootrom.elf
bin	:= $(BUILD_DIR)/bootrom.bin
img	:= $(BUILD_DIR)/bootrom.img

all: $(img)

elf: $(elf)
$(elf): bootrom.S linker.ld
	mkdir -p $(BUILD_DIR)
	$(CC) -Tlinker.ld $< -nostdlib -static -Wl,--no-gc-sections -o $@

bin:$(bin)
$(bin): $(elf)
	mkdir -p $(BUILD_DIR)
	$(OBJCOPY) -O binary $< $@

img:$(img)
$(img): $(bin)
	mkdir -p $(BUILD_DIR)
	dd if=$< of=$@ bs=128 count=1






