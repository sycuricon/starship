STACK_DEPTH ?= 4
ITER ?= 10000
GER_SRC = main.cpp EffectGenerator.cpp ../utils.cpp
GER_OBJ = $(patsubst %.cpp,%.o,$(GER_SRC))
TESTCASE_ELF := regvault
TESTCASE_ASM := regvault.asm

all:regvault.S
	$(RISCV_GCC) $(RISCV_GCC_OPTS) -T ../link.ld $< -o $(TESTCASE_ELF)
	$(RISCV_OBJDUMP) $(TESTCASE_ELF) > $(TESTCASE_ASM)

regvault.S:generator
	./$< $(STACK_DEPTH) $(ITER) > $@

generator:$(GER_OBJ)
	g++ $^ -g -o $@

%.o:%.cpp
	g++ -c -g $<

clean:
	rm -f *.o *.S *.asm *.hex regvault generator regvault.S