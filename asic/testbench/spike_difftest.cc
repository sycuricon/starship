
#include <svdpi.h>
#include <stdio.h>
#include <unistd.h>
#include "cj.h"

cosim_cj_t* simulator = NULL;
config_t cfg;
char* spike_misa = "rv64gc_xdummy";
char* fuzz_target = "/eda/project/difuzz-rtl/Fuzzer/output/.input";

extern "C" void cosim_init (const char *testcase, unsigned char verbose) {
  cfg.elffile = testcase;
  cfg.isa = spike_misa;
  if (verbose)
    cfg.verbose = true;
  simulator = new cosim_cj_t(cfg);
  return;
}

extern "C" int cosim_commit (int hartid, reg_t dut_pc, uint32_t dut_insn) {
  return simulator->cosim_commit_stage(0, dut_pc, dut_insn, true);
}

extern "C" int cosim_judge (int hartid, const char * which, int dut_waddr, reg_t dut_wdata) {
  if (strcmp(which, "float") == 0)
    return simulator->cosim_judge_stage(0, dut_waddr, dut_wdata, true);
  else
    return simulator->cosim_judge_stage(0, dut_waddr, dut_wdata, false);
}

extern "C" void cosim_raise_trap (int hartid, reg_t cause) {
  simulator->cosim_raise_trap(hartid, cause);
}

extern "C" reg_t cosim_finish () {
  return simulator->get_tohost();
}

extern "C" unsigned long int cosim_randomizer_insn (unsigned long int in, unsigned long int pc) {
  if (simulator) {
    return simulator->cosim_randomizer_insn(in, pc);
  }
  else
    return in;
}

extern "C" unsigned long int cosim_randomizer_data (unsigned int read_select) {
  reg_t addr = read_select;
  printf("[Magic] Read Select = %u; Addr = %u \n", read_select, addr);
  if (simulator) {
    return simulator->cosim_randomizer_data(addr);
  }
  else {
    return 0x20220611;
  }
}

extern "C" void cosim_reinit (const char *testcase, unsigned char verbose) {
  if (simulator) {
    delete simulator;
  }

  cfg.elffile = testcase;

  if (verbose)
    cfg.verbose = true;
  simulator = new cosim_cj_t(cfg);
  return;
}

extern "C" void update_symlink() {
  static unsigned int round = 0;
  remove("./testcase.elf");
  remove("./testcase.hex");
  
  if (round == 10)
    exit(0);

  char path_name[1024];
  sprintf(path_name, "%s_%d.elf", fuzz_target, round);
  printf("Redirect to %s\n", path_name);
  symlink(path_name, "./testcase.elf");

  sprintf(path_name, "%s_%d.hex", fuzz_target, round);
  printf("Redirect to %s\n", path_name);
  symlink(path_name, "./testcase.hex");

  round ++;
}