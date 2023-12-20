export
	RISCV_PREFIX ?= riscv64-unknown-elf-
	RISCV_GCC ?= $(RISCV_PREFIX)gcc
	RISCV_GCC_OPTS ?= -march=rv64gcv -mabi=lp64 -mcmodel=medany -fvisibility=hidden -nostdlib \
		-nostartfiles -DNOBRANCH -g
	BINARY_OBJCOPY ?= $(RISCV_PREFIX)objcopy -O binary
	RISCV_OBJDUMP ?= $(RISCV_PREFIX)objdump -Mno-aliases -D
	RISCV_OBJCOPY ?= $(RISCV_PREFIX)objcopy -O verilog --verilog-data-width 8 --readonly-text
	RISCV_LD  ?= $(RISCV_PREFIX)ld;

function:
	make -C function_test clean
	make -C function_test

pressure:utils.o
	make -C pressure_test clean
	make -C pressure_test

effect:utils.o
	make -C effect_test clean
	make -C effect_test

utils.o:utils.cpp
	g++ $< -c

clean:
	rm -f *.o log
	make -C function_test clean
	make -C pressure_test clean
	make -C effect_test clean