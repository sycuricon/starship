// Copyright 2023 Sycuricon Group
// Author: Jinyan Xu (phantom@zju.edu.cn)


#include "VTOP.h"
#define MAX_CYCLE 200000

int main(int argc, char **argv, char **env) {
    Verilated::commandArgs(argc,argv);
    Verilated::traceEverOn(true);
    VTestbench *dut = new VTestbench();
    for(int i=0;i<MAX_CYCLE;i++){
        dut->eval();
    }
    delete dut;
    return 0;
}
