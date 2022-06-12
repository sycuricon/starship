
#include <svdpi.h>
#include <stdio.h>
#include <unistd.h>
#include "cj.h"

cosim_cj_t* simulator = NULL;

extern "C" void cosim_init (const char *testcase, unsigned char verbose) {
  config_t cfg;
  cfg.elffile = testcase;
  cfg.isa = "rv64gc_xdummy";
  if (verbose)
    cfg.verbose = true;
  simulator = new cosim_cj_t(cfg);
  return;
}

extern "C" int cosim_commit (int hartid, reg_t dut_pc, uint32_t dut_insn) {
    // printf("in commit\n");
    return simulator->cosim_commit_stage(0, dut_pc, dut_insn, true);
}
extern "C" int cosim_judge (int hartid, const char * which, int dut_waddr, reg_t dut_wdata) {
    if (strcmp(which, "float") == 0)
        return simulator->cosim_judge_stage(0, dut_waddr, dut_wdata, true);
    else
        return simulator->cosim_judge_stage(0, dut_waddr, dut_wdata, false);
}
extern "C" void cosim_raise_trap (int hartid, reg_t cause) {
    // printf("in interrupt\n");
    simulator->cosim_raise_trap(hartid, cause);
}
extern "C" reg_t cosim_finish () {
    return simulator->get_tohost();
}
extern "C" unsigned long int cosim_randomizer_insn (unsigned long int in, unsigned long int pc) {
    if (simulator)
      return simulator->cosim_randomizer_insn(in, pc);
    else
      return in;
}

extern "C" unsigned long int cosim_randomizer_data (unsigned int read_select) {
  static int cnt = -1;
  cnt ++;
  printf("[Todo] replace me with real magic access, %d\n", cnt);
  return 0x20220611 + cnt;
}



// extern "C" int dromajo_step (int hartid, long long dut_pc, int dut_insn,
//     long long dut_wdata, long long mstatus, bool check) {
//     return dromajo_cosim_step(simulator, hartid, dut_pc, dut_insn, dut_wdata, mstatus, true);
// }

// extern "C" void dromajo_raise_trap(int hartid, long long cause) {
//     dromajo_cosim_raise_trap(simulator, hartid, cause);
// }

// extern "C" long long dromajo_finish() {
//     long long tohost = 0;
//     RISCVMachine *s = (RISCVMachine *)simulator;
//     if (s != NULL && s->htif_tohost_addr) {
//         bool fail = true;
//         tohost = riscv_phys_read_u32(s->cpu_state[0], s->htif_tohost_addr, &fail);
//         if (fail) {
//             tohost = 0;
//         }
//     }
//     return tohost;
// }

// extern "C" int dromajo_check_sboard(int hartid, int dut_waddr, long long dut_wdata) {
//     return dromajo_cosim_check_sboard(simulator, hartid, dut_waddr, dut_wdata);
// }

// extern "C" int dromajo_check_fsboard(int hartid, int dut_waddr, long long dut_wdata) {
//     return dromajo_cosim_check_fsboard(simulator, hartid, dut_waddr, dut_wdata);
// }
