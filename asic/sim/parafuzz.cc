
#include <fcntl.h>
#include <stdio.h>
#include <svdpi.h>
#include <time.h>
#include <unistd.h>
#include <stdlib.h>
#include "mem_swap.h"

#define CMD_MASK                0xFFFF'FFFF'FFFF'0000ul
#define OP_MASK                 0x0000'0000'0000'FFFFul

#define CMD_SWITCH_STATE        0xAF1B'608E'883A'0000ul
#define STATE_DEFAULT           0
#define STATE_DUMP_NUM          1
#define STATE_DUMP_CHAR         2
#define STATE_DUMP_ADDR         3

#define CMD_POWER_OFF           0xAF1B'608E'883B'0000ul

#define CMD_SWAP_BLOCK          0xAF1B'608E'883C'0000ul

int state = 0;
int swap_index = 0;

extern "C" void parafuzz_probebuff_tick(unsigned char is_variant, unsigned long int data) {
    if((data & CMD_MASK) == CMD_SWAP_BLOCK){
        do_mem_swap(is_variant);
        return;
    }else if(is_variant){
        return;
    }
    
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
#include <map>

extern "C" char is_variant_hierachy(const char* hierachy) {
    return strstr(hierachy, "testHarness_variant") ? 1 : 0;
}

inline unsigned int group_idx(unsigned int idx) {
    return idx / 2;
}

inline bool is_variant_idx(unsigned int idx) {
    return (idx % 2) != 0;
}

struct Reference {
    std::string dut_str;
    std::string vnt_str;

    bool cached;
    unsigned char prev_result;

    Reference(std::string raw) {
        bool is_variant = raw.find("testHarness_variant") != std::string::npos ? true : false;
        if (!is_variant) {
            dut_str = raw;
            vnt_str = dut_str;
            vnt_str.replace(
                vnt_str.find("testHarness"),
                sizeof("testHarness")-1,
                "testHarness_variant");
        } else {
            vnt_str = raw;
            dut_str = vnt_str;
            dut_str.replace(
                dut_str.find("testHarness_variant"),
                sizeof("testHarness_variant")-1,
                "testHarness");
        }
        clean_cache();
    }

    const char* dut() {
        return dut_str.c_str();
    }

    const char* vnt() {
        return vnt_str.c_str();
    }

    void clean_cache() {
        cached = false;
    }

    bool has_cache() {
        return cached;
    }

    void set_cache(unsigned char update) {
        cached = true;
        prev_result = update;
    }
};

unsigned int total_ref = 0;
std::map<std::string, int> idxMap;
std::map<unsigned int, Reference> refMap;

extern "C" unsigned int register_reference(const char* hierarchy) {
    if (idxMap.find(hierarchy) == idxMap.end()) {
        Reference ref(hierarchy);
        idxMap[ref.dut()] = total_ref;
        idxMap[ref.vnt()] = total_ref + 1;
        refMap.insert(std::pair<unsigned int, Reference>(group_idx(total_ref), ref));

        total_ref += 2;
    }

    return idxMap[hierarchy];
}

extern "C" void get_mux_sel(unsigned char* select);
extern "C" unsigned char xref_diff_mux_sel(unsigned int idx) {
    Reference& h = refMap.at(group_idx(idx));

    if (h.has_cache()) {
        h.clean_cache();
        return h.prev_result;
    }
    else {
        unsigned char dut_sel, vnt_sel;
        svSetScope(svGetScopeFromName(h.dut()));
        get_mux_sel(&dut_sel);

        svSetScope(svGetScopeFromName(h.vnt()));
        get_mux_sel(&vnt_sel);

        unsigned char result = dut_sel ^ vnt_sel;
        h.set_cache(result);
        return result;
    }
}

extern "C" void get_dff_en(unsigned char* en);
extern "C" unsigned char xref_diff_dff_en(unsigned int idx) {
    Reference& h = refMap.at(group_idx(idx));

    if (h.has_cache()) {
        h.clean_cache();
        return h.prev_result;
    }
    else {
        unsigned char dut_en, vnt_en;
        svSetScope(svGetScopeFromName(h.dut()));
        get_dff_en(&dut_en);

        svSetScope(svGetScopeFromName(h.vnt()));
        get_dff_en(&vnt_en);

        unsigned char result = dut_en ^ vnt_en;
        h.set_cache(result);
        return result;   
    }
}

extern "C" void get_dff_srst(unsigned char* srst);
extern "C" unsigned char xref_diff_dff_srst(unsigned int idx) {
    Reference& h = refMap.at(group_idx(idx));

    if (h.has_cache()) {
        h.clean_cache();
        return h.prev_result;
    }
    else {
        unsigned char dut_srst, vnt_srst;
        svSetScope(svGetScopeFromName(h.dut()));
        get_dff_srst(&dut_srst);

        svSetScope(svGetScopeFromName(h.vnt()));
        get_dff_srst(&vnt_srst);

        unsigned char result = dut_srst ^ vnt_srst;
        h.set_cache(result);
        return result;
    }
}

extern "C" void get_dff_arst(unsigned char* arst);
extern "C" unsigned char xref_diff_dff_arst(unsigned int idx) {
    Reference& h = refMap.at(group_idx(idx));

    if (h.has_cache()) {
        h.clean_cache();
        return h.prev_result;
    }
    else {
        unsigned char dut_arst, vnt_arst;
        svSetScope(svGetScopeFromName(h.dut()));
        get_dff_arst(&dut_arst);

        svSetScope(svGetScopeFromName(h.vnt()));
        get_dff_arst(&vnt_arst);

        unsigned char result = dut_arst ^ vnt_arst;
        h.set_cache(result);
        return result;
    }
}

extern "C" void get_dff_taint(unsigned char* tainted);
extern "C" unsigned char xref_merge_dff_taint(unsigned int idx) {
    Reference& h = refMap.at(group_idx(idx));

    if (h.has_cache()) {
        h.clean_cache();
        return h.prev_result;
    }
    else {
        unsigned char dut_tainted, vnt_tainted;
        svSetScope(svGetScopeFromName(h.dut()));
        get_dff_taint(&dut_tainted);

        svSetScope(svGetScopeFromName(h.vnt()));
        get_dff_taint(&vnt_tainted);

        unsigned char result = dut_tainted | vnt_tainted;
        h.set_cache(result);
        return result;
    }
}

extern "C" void get_mem_rd_en(unsigned int index, unsigned char* en);
extern "C" unsigned char xref_diff_mem_rd_en(unsigned int idx, unsigned int index) {
    Reference& h = refMap.at(group_idx(idx));

    unsigned char dut_en, vnt_en;
    svSetScope(svGetScopeFromName(h.dut()));
    get_mem_rd_en(index, &dut_en);

    svSetScope(svGetScopeFromName(h.vnt()));
    get_mem_rd_en(index, &vnt_en);

    unsigned char result = dut_en ^ vnt_en;
    return result;
}

extern "C" void get_mem_wt_en(unsigned int index, unsigned char* en);
extern "C" unsigned char xref_diff_mem_wt_en(unsigned int idx, unsigned int index) {
    Reference& h = refMap.at(group_idx(idx));

    unsigned char dut_en, vnt_en;
    svSetScope(svGetScopeFromName(h.dut()));
    get_mem_wt_en(index, &dut_en);

    svSetScope(svGetScopeFromName(h.vnt()));
    get_mem_wt_en(index, &vnt_en);

    unsigned char result = dut_en ^ vnt_en;
    return result;
}

extern "C" void get_mem_rd_srst(unsigned int index, unsigned char* srst);
extern "C" unsigned char xref_diff_mem_rd_srst(unsigned int idx, unsigned int index) {
    Reference& h = refMap.at(group_idx(idx));

    unsigned char dut_srst, vnt_srst;
    svSetScope(svGetScopeFromName(h.dut()));
    get_mem_rd_srst(index, &dut_srst);

    svSetScope(svGetScopeFromName(h.vnt()));
    get_mem_rd_srst(index, &vnt_srst);

    unsigned char result = dut_srst ^ vnt_srst;
    return result;
}

extern "C" void get_mem_rd_arst(unsigned int index, unsigned char* arst);
extern "C" unsigned char xref_diff_mem_rd_arst(unsigned int idx, unsigned int index) {
    Reference& h = refMap.at(group_idx(idx));

    unsigned char dut_arst, vnt_arst;
    svSetScope(svGetScopeFromName(h.dut()));
    get_mem_rd_srst(index, &dut_arst);

    svSetScope(svGetScopeFromName(h.vnt()));
    get_mem_rd_srst(index, &vnt_arst);

    unsigned char result = dut_arst ^ vnt_arst;
    return result;
}

extern "C" void get_mem_taint(unsigned int index, unsigned char* tainted);
extern "C" unsigned char xref_merge_mem_taint(unsigned int idx, unsigned int index) {
    Reference& h = refMap.at(group_idx(idx));

    unsigned char dut_tainted, vnt_tainted;
    svSetScope(svGetScopeFromName(h.dut()));
    get_mem_taint(index, &dut_tainted);

    svSetScope(svGetScopeFromName(h.vnt()));
    get_mem_taint(index, &vnt_tainted);

    unsigned char result = dut_tainted | vnt_tainted;
    return result;
}
