#include <fcntl.h>
#include <stdio.h>
#include <svdpi.h>
#include <time.h>
#include <unistd.h>
#include <stdlib.h>
#include <string>
#include <string.h>

extern "C" unsigned long int testbench_memory_do_swap(unsigned char is_variant);

#define CMD_MASK                0xFFFF'FFFF'FFFF'0000ul
#define OP_MASK                 0x0000'0000'0000'FFFFul

#define CMD_SWITCH_STATE        0xAF1B'608E'883A'0000ul
#define STATE_DEFAULT           0
#define STATE_DUMP_NUM          1
#define STATE_DUMP_CHAR         2
#define STATE_DUMP_ADDR         3

#define CMD_POWER_OFF           0xAF1B'608E'883B'0000ul

#define CMD_SWAP_BLOCK          0xAF1B'608E'883C'0000ul

#define CMD_GIVE_ME_SECRET      0xAF1B'608E'883D'0000ul

int state = 0;

extern "C" unsigned long int parafuzz_probebuff_tick(unsigned char is_variant, unsigned long int data) {

    if (is_variant) {
        switch (data & CMD_MASK) {
            case CMD_GIVE_ME_SECRET:
                return 0;
            case CMD_SWAP_BLOCK:
                return testbench_memory_do_swap(is_variant);
            default:
                break;
        }
        return 0;
    }
    else {
        switch (data & CMD_MASK) {
            case CMD_SWITCH_STATE:
                state = data & OP_MASK;
                return 0;
            case CMD_GIVE_ME_SECRET:
                return -1;
            case CMD_SWAP_BLOCK:
                return testbench_memory_do_swap(is_variant);
            case CMD_POWER_OFF:
                printf("[*] simulation exit with %ld\n", data & OP_MASK);
                return 0;
            default:
                break;
        }
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

    return 0;
}

extern "C" char is_variant_hierachy(const char* hierachy) {
    return strstr(hierachy, "testHarness_variant") ? 1 : 0;
}
