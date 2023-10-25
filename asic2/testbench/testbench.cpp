// Copyright 2023 Sycuricon Group
// Author: Jinyan Xu (phantom@zju.edu.cn)


#include "VTOP.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#define max_time 200000

int main(int argc, char **argv, char **env) {
    Verilated::traceEverOn(true);
    VTestbench *topp = new VTestbench();
    VerilatedContext* contextp = new VerilatedContext;
    contextp->debug(0);
    contextp->randReset(10);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    topp->trace(tfp, 99);
    tfp->open("./wave/testbench.vcd");
    Verilated::commandArgs(argc,argv);

    int init_time = 10;
    int clk = 0;
    int rstn = 1;

    topp->reset = rstn;
    for (int i = 0; i < init_time; i++) {
        topp->clock = clk;
        topp->eval();
        clk = !clk;
    }

    rstn = 0;
    while (contextp->time() < max_time && !contextp->gotFinish()) {
        topp->clock = clk;
        topp->reset = rstn;
        contextp->timeInc(1);
        topp->eval();
        tfp->dump(contextp->time());
        clk = !clk;
        rstn = 1;
    }

    tfp->close();
    delete tfp;
    delete topp;
    delete contextp;
    return 0;
}
