
#include <svdpi.h>
#include <stdio.h>
#include <unistd.h>
#include "dromajo_cosim.h"
#include "riscv_cpu.h"


dromajo_cosim_state_t* simulator = NULL;

extern "C" int dromajo_init (char* config_file) {
  char *argv[] = {"zjv_rtlfuzz", config_file};
  simulator = dromajo_cosim_init(sizeof(argv)/sizeof(char*), argv);
  if (simulator) {
    RISCVMachine *s = (RISCVMachine *)simulator;
    riscv_set_pc(s->cpu_state[0], s->cpu_state[0]->machine->ram_base_addr); 
  }
  return simulator == NULL;
}

extern "C" int dromajo_step (int hartid, long long dut_pc, int dut_insn,
    long long dut_wdata, long long mstatus, bool check) {
    return dromajo_cosim_step(simulator, hartid, dut_pc, dut_insn, dut_wdata, mstatus, true);
}

extern "C" void dromajo_raise_trap(int hartid, long long cause) {
    dromajo_cosim_raise_trap(simulator, hartid, cause);
}

extern "C" long long dromajo_finish() {
    long long tohost = 0;
    RISCVMachine *s = (RISCVMachine *)simulator;
    if (s != NULL && s->htif_tohost_addr) {
        bool fail = true;
        tohost = riscv_phys_read_u32(s->cpu_state[0], s->htif_tohost_addr, &fail);
        if (fail) {
            tohost = 0;
        }
    }
    return tohost;
}