GER_SRC = main.cpp PressureGenerator.cpp ../utils.cpp
GER_OBJ = $(patsubst %.cpp,%.o,$(GER_SRC))
TESTCASE_ELF := regvault
TESTCASE_ASM := regvault.asm

all:regvault.S
	$(RISCV_GCC) $(RISCV_GCC_OPTS) -T ../link.ld $< -o $(TESTCASE_ELF)
	$(RISCV_OBJDUMP) $(TESTCASE_ELF) > $(TESTCASE_ASM)

regvault.S:generator
	./$< 32000 > $@

generator:$(GER_OBJ)
	g++ $^ -o $@

%.o:%.cpp
	g++ -c $<

clean:
	rm -f *.o *.S *.asm *.hex regvault generator regvault.S