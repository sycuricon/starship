
#include <svdpi.h>
#include <stdio.h>
#include <unistd.h>
#include "cj.h"

cosim_cj_t* simulator = NULL;
config_t cfg;
char* spike_misa = "rv64gc_xdummy";

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

extern "C" reg_t cosim_get_tohost () {
  return simulator->get_tohost();
}

extern "C" void cosim_set_tohost (reg_t value) {
  simulator->set_tohost(value);
}

extern "C" unsigned long int cosim_randomizer_insn (unsigned long int in, unsigned long int pc) {
  if (simulator && in != 0) {
    return simulator->cosim_randomizer_insn(in, pc);
  }
  else
    return in;
}

extern "C" unsigned long int cosim_randomizer_data (unsigned int read_select) {
  reg_t addr = read_select;
  // printf("[Magic] Read Select = %u; Addr = %u \n", read_select, addr);
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

#define MAX_ROUND 5
#define MAX_ELF   10
char* fuzz_target = "/eda/project/difuzz-rtl/Fuzzer/output/.input";

/* return a non zero value to reinitialize memory */
extern "C" int coverage_collector(unsigned long int cov) {
  static unsigned int round_current = 0;
  static unsigned int elf_current = 0;
  static unsigned long int cov_summary = 0;
  
  printf("[CJ] (%d/%d) coverage summary %d (+%d)\n", elf_current, round_current, cov, cov - cov_summary);
  reg_t tohost = simulator->get_tohost();
  cov_summary = cov;

  if (tohost == 3 && round_current < MAX_ROUND) {
    round_current ++;
    return 0;
  } else if (
    (tohost == 3 && round_current == MAX_ROUND) ||
    (tohost == 1 && elf_current < MAX_ELF)) {
    round_current = 0;
    remove("./testcase.elf");
    remove("./testcase.hex");
    char path_name[1024];
    sprintf(path_name, "%s_%d.elf", fuzz_target, elf_current);
    printf("Redirect to %s\n", path_name);
    symlink(path_name, "./testcase.elf");
    sprintf(path_name, "%s_%d.hex", fuzz_target, elf_current);
    printf("Redirect to %s\n", path_name);
    symlink(path_name, "./testcase.hex");
    elf_current ++;

    return 1;
  } else {
    exit(0);
  }

  return 1;
}