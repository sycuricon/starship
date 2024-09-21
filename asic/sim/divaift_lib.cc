
#include <fcntl.h>
#include <stdio.h>
#include <svdpi.h>
#include <time.h>
#include <unistd.h>
#include <stdlib.h>
#include <string>
#include <string.h>
#include <map>


inline unsigned int group_idx(unsigned int ref_id) {
    return ref_id / 2;
}

inline bool is_variant_id(unsigned int ref_id) {
    return (ref_id % 2) != 0;
}

struct Reference {
    std::string dut_str;
    std::string vnt_str;

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
    }

    const char* dut() {
        return dut_str.c_str();
    }

    const char* vnt() {
        return vnt_str.c_str();
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

#define IDX_GATE_CMP   0

extern "C" void get_gate_cmp(unsigned char* cmp);
extern "C" unsigned char xref_diff_gate_cmp(unsigned int ref_id) {
    Reference& h = refMap.at(group_idx(ref_id));

    unsigned char dut_sel, vnt_sel;
    svSetScope(svGetScopeFromName(h.dut()));
    get_gate_cmp(&dut_sel);

    svSetScope(svGetScopeFromName(h.vnt()));
    get_gate_cmp(&vnt_sel);
    unsigned char result = dut_sel ^ vnt_sel;
    // printf("[%ld] %s %d %d <%d>\n", now, h.dut(), dut_sel, vnt_sel, result);

    return result;
}

#define IDX_MUX_S   0

extern "C" void get_mux_sel(unsigned char* select);
extern "C" unsigned char xref_diff_mux_sel(unsigned int ref_id) {
    Reference& h = refMap.at(group_idx(ref_id));

    unsigned char dut_sel, vnt_sel;
    svSetScope(svGetScopeFromName(h.dut()));
    get_mux_sel(&dut_sel);

    svSetScope(svGetScopeFromName(h.vnt()));
    get_mux_sel(&vnt_sel);

    unsigned char result = dut_sel ^ vnt_sel;
    return result;
}

#define IDX_DFF_EN  0

extern "C" void get_dff_en(unsigned char* en);
extern "C" unsigned char xref_diff_dff_en(unsigned int ref_id) {
    Reference& h = refMap.at(group_idx(ref_id));

    unsigned char dut_en, vnt_en;
    svSetScope(svGetScopeFromName(h.dut()));
    get_dff_en(&dut_en);

    svSetScope(svGetScopeFromName(h.vnt()));
    get_dff_en(&vnt_en);

    unsigned char result = dut_en ^ vnt_en;
    return result;
}

#define IDX_DFF_SRST  1

extern "C" void get_dff_srst(unsigned char* srst);
extern "C" unsigned char xref_diff_dff_srst(unsigned int ref_id) {
    Reference& h = refMap.at(group_idx(ref_id));

    unsigned char dut_srst, vnt_srst;
    svSetScope(svGetScopeFromName(h.dut()));
    get_dff_srst(&dut_srst);

    svSetScope(svGetScopeFromName(h.vnt()));
    get_dff_srst(&vnt_srst);

    unsigned char result = dut_srst ^ vnt_srst;
    return result;
}

#define IDX_DFF_ARST  2

extern "C" void get_dff_arst(unsigned char* arst);
extern "C" unsigned char xref_diff_dff_arst(unsigned int ref_id) {
    Reference& h = refMap.at(group_idx(ref_id));

    unsigned char dut_arst, vnt_arst;
    svSetScope(svGetScopeFromName(h.dut()));
    get_dff_arst(&dut_arst);

    svSetScope(svGetScopeFromName(h.vnt()));
    get_dff_arst(&vnt_arst);

    unsigned char result = dut_arst ^ vnt_arst;
    return result;
}

// wt en 0 ~ 16
#define IDX_MEM_WEN(index)  (0 + index)

extern "C" void get_mem_wt_en(unsigned int index, unsigned char* en);
extern "C" unsigned char xref_diff_mem_wt_en(unsigned int ref_id, unsigned int index) {
    Reference& h = refMap.at(group_idx(ref_id));

    unsigned char dut_en, vnt_en;
    svSetScope(svGetScopeFromName(h.dut()));
    get_mem_wt_en(index, &dut_en);

    svSetScope(svGetScopeFromName(h.vnt()));
    get_mem_wt_en(index, &vnt_en);

    unsigned char result = dut_en ^ vnt_en;
    return result;
}

// rd [a|s]rst 16 ~ 24
#define IDX_MEM_RRST(index)  (16 + index)

extern "C" void get_mem_rd_arst(unsigned int index, unsigned char* arst);
extern "C" unsigned char xref_diff_mem_rd_arst(unsigned int ref_id, unsigned int index) {
    Reference& h = refMap.at(group_idx(ref_id));

    unsigned char dut_arst, vnt_arst;
    svSetScope(svGetScopeFromName(h.dut()));
    get_mem_rd_arst(index, &dut_arst);

    svSetScope(svGetScopeFromName(h.vnt()));
    get_mem_rd_arst(index, &vnt_arst);

    unsigned char result = dut_arst ^ vnt_arst;
    return result;
}

extern "C" void get_mem_rd_srst(unsigned int index, unsigned char* srst);
extern "C" unsigned char xref_diff_mem_rd_srst(unsigned int ref_id, unsigned int index) {
    Reference& h = refMap.at(group_idx(ref_id));

    unsigned char dut_srst, vnt_srst;
    svSetScope(svGetScopeFromName(h.dut()));
    get_mem_rd_srst(index, &dut_srst);

    svSetScope(svGetScopeFromName(h.vnt()));
    get_mem_rd_srst(index, &vnt_srst);

    unsigned char result = dut_srst ^ vnt_srst;
    return result;
}

// rd en 24 ~ 32
#define IDX_MEM_REN(index)  (24 + index)

extern "C" void get_mem_rd_en(unsigned int index, unsigned char* en);
extern "C" unsigned char xref_diff_mem_rd_en(unsigned int ref_id, unsigned int index) {
    Reference& h = refMap.at(group_idx(ref_id));

    unsigned char dut_en, vnt_en;
    svSetScope(svGetScopeFromName(h.dut()));
    get_mem_rd_en(index, &dut_en);

    svSetScope(svGetScopeFromName(h.vnt()));
    get_mem_rd_en(index, &vnt_en);

    unsigned char result = dut_en ^ vnt_en;
    return result;
}

// rd addr 32 ~ 40
#define IDX_MEM_RADDR(index)  (32 + index)

extern "C" void get_mem_rd_addr(unsigned int index, unsigned int* addr);
extern "C" unsigned char xref_diff_mem_rd_addr(unsigned int ref_id, unsigned int index) {
    Reference& h = refMap.at(group_idx(ref_id));

    unsigned int dut_addr, vnt_addr;
    svSetScope(svGetScopeFromName(h.dut()));
    get_mem_rd_addr(index, &dut_addr);

    svSetScope(svGetScopeFromName(h.vnt()));
    get_mem_rd_addr(index, &vnt_addr);

    unsigned char result = dut_addr != vnt_addr;
    return result;
}

// wt addr 40 ~ 56
#define IDX_MEM_WADDR(index)  (40 + index)

extern "C" void get_mem_wt_addr(unsigned int index, unsigned int* addr);
extern "C" unsigned char xref_diff_mem_wt_addr(unsigned int ref_id, unsigned int index) {
    Reference& h = refMap.at(group_idx(ref_id));

    unsigned int dut_addr, vnt_addr;
    svSetScope(svGetScopeFromName(h.dut()));
    get_mem_wt_addr(index, &dut_addr);

    svSetScope(svGetScopeFromName(h.vnt()));
    get_mem_wt_addr(index, &vnt_addr);

    unsigned char result = dut_addr != vnt_addr;
    return result;
}
