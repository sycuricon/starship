
#include <fcntl.h>
#include <stdio.h>
#include <svdpi.h>
#include <time.h>
#include <unistd.h>

#include "cj.h"

cosim_cj_t *simulator = NULL;
config_t cfg;
char *spike_misa = "rv64gc";

char *morfuzz_prerelease = NULL;
const char *razzle_opt = "-m";

extern "C" void cosim_init(const char *testcase, unsigned char verbose) {
  morfuzz_prerelease = getenv("MORFUZZ_PRERELEASE");

  cfg.elffiles = std::vector<std::string>{testcase};
  cfg.isa = spike_misa;
  cfg.blind = true;
  cfg.commit_ecall = true;
  cfg.sync_state = true;
  if (verbose) cfg.verbose = true;
  simulator = new cosim_cj_t(cfg);
  return;
}

extern "C" int cosim_commit(int hartid, reg_t dut_pc, uint32_t dut_insn) {
  return simulator->cosim_commit_stage(0, dut_pc, dut_insn, true);
}

extern "C" int cosim_judge(int hartid, const char *which, int dut_waddr,
                           reg_t dut_wdata) {
  if (strcmp(which, "float") == 0)
    return simulator->cosim_judge_stage(0, dut_waddr, dut_wdata, true);
  else
    return simulator->cosim_judge_stage(0, dut_waddr, dut_wdata, false);
}

extern "C" void cosim_raise_trap(int hartid, reg_t cause) {
  simulator->cosim_raise_trap(hartid, cause);
}

extern "C" reg_t cosim_get_tohost() { return simulator->get_tohost(); }

extern "C" void cosim_set_tohost(reg_t value) { simulator->set_tohost(value); }

extern "C" unsigned long int cosim_randomizer_insn(unsigned long int in,
                                                   unsigned long int pc) {
  if (simulator && in != 0) {
    return simulator->cosim_randomizer_insn(in, pc);
  } else
    return in;
}

extern "C" unsigned long int cosim_randomizer_data(unsigned int read_select) {
  reg_t addr = read_select;
  // printf("[Magic] Read Select = %u; Addr = %u \n", read_select, addr);
  if (simulator) {
    return simulator->cosim_randomizer_data(addr);
  } else {
    return 0x20220611;
  }
}

extern "C" void cosim_reinit(const char *testcase, unsigned char verbose) {
  if (simulator) {
    delete simulator;
  }

  cfg.elffiles = std::vector<std::string>{testcase};

  if (verbose) cfg.verbose = true;
  simulator = new cosim_cj_t(cfg);
  return;
}

#define MAX_ROUND 5
#define MAX_ELF 10

const char *pygen_elf = "./build/fuzz_0";
const char *pygen_hex = "./build/fuzz_0.hex";
const char *log_file = "../../../morfuzz-log.txt";

/* return a non zero value to reinitialize memory */
extern "C" int coverage_collector(unsigned long int cov) {
  static unsigned int round_current = 0;
  static unsigned int elf_current = 0;
  static unsigned long int elf_cov = 0;
  static unsigned long int prev_elf_cov = 0;
  static unsigned long int cov_summary = 0;
  static unsigned long int inst_cnt_summary = 0;
  static unsigned long int inst_cnt_current = 0;
  static int left_round = MAX_ROUND;
  static int fd = 0;
  static time_t start_time = 0;
  static size_t ext_cnt[5];
  static uint64_t shuffle_seed, seed;

  if (start_time == 0) {
    start_time = time(NULL);
    fd = open(log_file, O_CREAT | O_SYNC | O_TRUNC | O_WRONLY, 0666);
    srand(start_time);
  }

  int delta_cov = cov - cov_summary;
  elf_cov += delta_cov;
  if (cov < 1000000) {
    if (delta_cov < 100) {
      left_round -= 2;
    } else if (delta_cov < 500) {
      left_round--;
    } else if (delta_cov >= 1000) {
      left_round += delta_cov / 1000;
    }
  } else {
    left_round += delta_cov / 1000;
    if (prev_elf_cov < 100) {
      if (delta_cov > 0) {
        left_round++;
      }
    }
  }

  unsigned long inst_cnt = simulator->get_instruction_count();
  time_t current_time = time(NULL);
  unsigned long passed_time = (unsigned long)difftime(current_time, start_time);
  char current_log[1024];
  sprintf(current_log,
          "[CJ] (%d/%d/%d) coverage summary %d (+%d),\tinstruction count %ld "
          "(+%ld),\tpassed time %d hours, %d minutes, %d seconds\n",
          elf_current, round_current, left_round, cov, delta_cov,
          inst_cnt_summary + inst_cnt, inst_cnt - inst_cnt_current,
          passed_time / 3600, (passed_time % 3600) / 60, passed_time % 60);
  printf(current_log);
  write(fd, current_log, strlen(current_log));

  reg_t tohost = simulator->get_tohost();
  simulator->set_tohost(0);
  cov_summary = cov;
  inst_cnt_current = inst_cnt;

  if (tohost == 3 && left_round > 0) {
    round_current++;
    left_round--;
    return 0;
  } else {
    remove("./testcase.elf");
    remove("./testcase.hex");
    char cmd[1024];
    if (round_current > 10) {
      // try to shuffle a little bit if previous elf is excellent
      shuffle_seed = rand();
      shuffle_seed = (shuffle_seed << 32) | rand();
    } else {
      shuffle_seed = rand();
      shuffle_seed = (shuffle_seed << 32) | rand();
      seed = rand();
      seed = (seed << 32) | rand();
      seed |= 0x8000000000000000UL; /* force RV64 */
    }

    // balance MAFDC extension frequency
    for (int i = 0; i < 5; ++i) {
      if (ext_cnt[i] < elf_current / 3) {
        seed |= (1UL << (55 + i));
      }
    }
    for (int i = 0; i < 5; ++i) {
      if (seed & (1UL << (55 + i))) {
        ext_cnt[i]++;
      }
    }

    sprintf(cmd, "%s/razzle/razzle %s --input=%016lx%016lx", morfuzz_prerelease,
            razzle_opt, shuffle_seed, seed);
    system(cmd);

    symlink(pygen_elf, "./testcase.elf");
    symlink(pygen_hex, "./testcase.hex");

    round_current = 0;
    left_round = MAX_ROUND;
    inst_cnt_summary += inst_cnt_current;
    inst_cnt_current = 0;
    elf_current++;
    prev_elf_cov = elf_cov;
    elf_cov = 0;

    return 1;
  }

  return 1;
}
