// Copyright 2023 Sycuricon Group
// Author: Jinyan Xu (phantom@zju.edu.cn)


#include "VTOP.h"
#include "verilated.h"

#define max_time 200000

int main(int argc, char** argv, char**) {
    // Setup context, defaults, and parse command line
    Verilated::debug(0);
    const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};
    contextp->traceEverOn(true);
    contextp->commandArgs(argc, argv);

    // Construct the Verilated model, from Vtop.h generated from Verilating
    const std::unique_ptr<VTestbench> topp{new VTestbench{contextp.get()}};


    // Simulate until $finish
    while (contextp->time()<max_time && !contextp->gotFinish()) {
        // Evaluate model
        topp->eval();
        // Advance time
        if(!topp->eventsPending())break;
        contextp->time(topp->nextTimeSlot());
        // printf("%d\n",contextp->time());
    }

    if (!contextp->gotFinish()) {
        VL_DEBUG_IF(VL_PRINTF("+ Exiting without $finish; no events left\n"););
    }

    // Final model cleanup
    topp->final();
    return 0;
}