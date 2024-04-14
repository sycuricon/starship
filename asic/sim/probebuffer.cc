#include <fcntl.h>
#include <stdio.h>
#include <svdpi.h>
#include <time.h>
#include <unistd.h>
#include <stdlib.h>
#include <string>
#include <string.h>

#define CMD_MASK                0xFFFF'FFFF'FFFF'0000ul
#define OP_MASK                 0x0000'0000'0000'FFFFul

#define CMD_SWITCH_STATE        0xAF1B'608E'883A'0000ul
#define STATE_DEFAULT           0
#define STATE_DUMP_NUM          1
#define STATE_DUMP_CHAR         2
#define STATE_DUMP_ADDR         3

#define CMD_POWER_OFF           0xAF1B'608E'883B'0000ul


int state = 0;

extern "C" void parafuzz_probebuff_tick(unsigned long int data) {
    switch (data & CMD_MASK) {
        case CMD_SWITCH_STATE:
            state = data & OP_MASK;
            return;
        case CMD_POWER_OFF:
            printf("[*] simulation exit with %ld\n", data & OP_MASK);
            exit(0);
        default:
            break;
    }

    switch (state) {
        case STATE_DEFAULT:
            printf("[*] prober get data: %lu\n", data);
            break;
        case STATE_DUMP_NUM:
            printf("%lu ", data);
            break;
        case STATE_DUMP_CHAR:
            printf("%c", data);
            break;
        case STATE_DUMP_ADDR:
            printf("%p ", (void *)data);
            break;
        default:
            break;
    }
}

extern "C" char is_variant_hierachy(const char* hierachy) {
    return strstr(hierachy, "testHarness_variant") ? 1 : 0;
}
