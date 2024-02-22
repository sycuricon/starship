
#include <fcntl.h>
#include <stdio.h>
#include <svdpi.h>
#include <time.h>
#include <unistd.h>
#include <stdlib.h>

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

#include <string>
#include <string.h>

extern "C" char is_variant(const char* hierachy) {
    return strstr(hierachy, "testHarness_variant") ? 1 : 0;
}

std::string variant_scope(std::string base_scope) {
    return base_scope.replace(
            base_scope.find("testHarness"), 
            sizeof("testHarness")-1,
            "testHarness_variant"
        );
}

std::string parent(std::string scope) {
    return scope.substr(0, scope.find_last_of("."));
}

extern "C" void get_selection(char* select);
extern "C" char xref_variant_mux(const char* hierachy) {
    if (is_variant(hierachy)) {
        return 0;
    }
    else {
        char base_selection, variant_selection;
        svSetScope(svGetScopeFromName(hierachy));
        get_selection(&base_selection);

        svSetScope(svGetScopeFromName(variant_scope(hierachy).c_str()));
        get_selection(&variant_selection);

        return base_selection ^ variant_selection;
    }
}

extern "C" void get_enable(char* enable);
extern "C" char xref_variant_dffe(const char* hierachy) {
    if (is_variant(hierachy)) {
        return 0;
    }
    else {
        char base_enable, variant_enable;
        svSetScope(svGetScopeFromName(hierachy));
        get_enable(&base_enable);

        svSetScope(svGetScopeFromName(variant_scope(hierachy).c_str()));
        get_enable(&variant_enable);

        return base_enable ^ variant_enable;
    }
}

extern "C" void get_srst(char* srst);
extern "C" char xref_variant_sdff(const char* hierachy) {
    if (is_variant(hierachy)) {
        return 0;
    }
    else {
        char base_srst, variant_srst;
        svSetScope(svGetScopeFromName(hierachy));
        get_srst(&base_srst);

        svSetScope(svGetScopeFromName(variant_scope(hierachy).c_str()));
        get_srst(&variant_srst);

        return base_srst ^ variant_srst;
    }
}

extern "C" void get_arst(char* arst);
extern "C" char xref_variant_adff(const char* hierachy) {
    if (is_variant(hierachy)) {
        return 0;
    }
    else {
        char base_arst, variant_arst;
        svSetScope(svGetScopeFromName(hierachy));
        get_arst(&base_arst);

        svSetScope(svGetScopeFromName(variant_scope(hierachy).c_str()));
        get_arst(&variant_arst);

        return base_arst ^ variant_arst;
    }
}

