TESTCASE_SOURCE := $(shell find . -name "*.S")
TESTCASE_OBJECT := $(patsubst %.S,%.o,$(TESTCASE_SOURCE))
TESTCASE_ELF := regvault
TESTCASE_ASM := regvault.asm

target:$(TESTCASE_OBJECT)
	$(RISCV_GCC) $(RISCV_GCC_OPTS) -Tlink.ld $(TESTCASE_OBJECT) -o $(TESTCASE_ELF)
	$(RISCV_OBJDUMP) $(TESTCASE_ELF) > $(TESTCASE_ASM)

$(TESTCASE_OBJECT):$(TESTCASE_SOURCE)
	$(RISCV_GCC) $(RISCV_GCC_OPTS) -c $(TESTCASE_SOURCE)

clean:
	rm -f *.o *.asm *.hex regvault
