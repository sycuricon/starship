
#include <fcntl.h>
#include <stdio.h>
#include <svdpi.h>
#include <time.h>
#include <unistd.h>
#include <stdlib.h>
#include <string>
#include <string.h>
#include <map>

typedef long long int time_stamp_t;
typedef unsigned int state_t;

inline unsigned int group_idx(unsigned int idx) {
    return idx / 2;
}

inline bool is_variant_idx(unsigned int idx) {
    return (idx % 2) != 0;
}

struct Reference {
    std::string dut_str;
    std::string vnt_str;

    time_stamp_t time_stamp;
    state_t cached;
    state_t prev_result;

    Reference(std::string raw) {
        time_stamp = 0;
        cached = 0;
        prev_result = 0;

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

    void clean_cache(unsigned char state_idx) {
        cached = cached & ~(1 << state_idx);
    }

    bool has_cache(time_stamp_t now, unsigned char state_idx) {
        return ((cached >> state_idx) & 1) && (time_stamp == now);
    }

    void set_cache(time_stamp_t now, unsigned char state_idx, unsigned char update) {
        time_stamp = now;
        cached = cached | (1 << state_idx);
        prev_result = (prev_result & ~(1 << state_idx)) | (update << state_idx);
    }

    unsigned char get_cache(unsigned char state_idx) {
        return (prev_result >> state_idx) & 1;
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
extern "C" unsigned char xref_diff_gate_cmp(time_stamp_t now, unsigned int idx) {
    Reference& h = refMap.at(group_idx(idx));

    if (h.has_cache(now, IDX_GATE_CMP)) {
        h.clean_cache(IDX_GATE_CMP);
        return h.get_cache(IDX_GATE_CMP);
    }
    else {
        unsigned char dut_sel, vnt_sel;
        svSetScope(svGetScopeFromName(h.dut()));
        get_gate_cmp(&dut_sel);

        svSetScope(svGetScopeFromName(h.vnt()));
        get_gate_cmp(&vnt_sel);
        unsigned char result = dut_sel ^ vnt_sel;
        h.set_cache(now, IDX_GATE_CMP, result);
        return result;
    }
}

#define IDX_MUX_S   0

extern "C" void get_mux_sel(unsigned char* select);
extern "C" unsigned char xref_diff_mux_sel(time_stamp_t now, unsigned int idx) {
    Reference& h = refMap.at(group_idx(idx));

    if (h.has_cache(now, IDX_MUX_S)) {
        h.clean_cache(IDX_MUX_S);
        return h.get_cache(IDX_MUX_S);
    }
    else {
        unsigned char dut_sel, vnt_sel;
        svSetScope(svGetScopeFromName(h.dut()));
        get_mux_sel(&dut_sel);

        svSetScope(svGetScopeFromName(h.vnt()));
        get_mux_sel(&vnt_sel);

        unsigned char result = dut_sel ^ vnt_sel;
        h.set_cache(now, IDX_MUX_S, result);
        return result;
    }
}

#define IDX_DFF_EN  0

extern "C" void get_dff_en(unsigned char* en);
extern "C" unsigned char xref_diff_dff_en(time_stamp_t now, unsigned int idx) {
    Reference& h = refMap.at(group_idx(idx));

    if (h.has_cache(now, IDX_DFF_EN)) {
        h.clean_cache(IDX_DFF_EN);
        return h.get_cache(IDX_DFF_EN);
    }
    else {
        unsigned char dut_en, vnt_en;
        svSetScope(svGetScopeFromName(h.dut()));
        get_dff_en(&dut_en);

        svSetScope(svGetScopeFromName(h.vnt()));
        get_dff_en(&vnt_en);

        unsigned char result = dut_en ^ vnt_en;
        h.set_cache(now, IDX_DFF_EN, result);
        return result;   
    }
}

#define IDX_DFF_SRST  1

extern "C" void get_dff_srst(unsigned char* srst);
extern "C" unsigned char xref_diff_dff_srst(time_stamp_t now, unsigned int idx) {
    Reference& h = refMap.at(group_idx(idx));

    if (h.has_cache(now, IDX_DFF_SRST)) {
        h.clean_cache(IDX_DFF_SRST);
        return h.get_cache(IDX_DFF_SRST);
    }
    else {
        unsigned char dut_srst, vnt_srst;
        svSetScope(svGetScopeFromName(h.dut()));
        get_dff_srst(&dut_srst);

        svSetScope(svGetScopeFromName(h.vnt()));
        get_dff_srst(&vnt_srst);

        unsigned char result = dut_srst ^ vnt_srst;
        h.set_cache(now, IDX_DFF_SRST, result);
        return result;
    }
}

#define IDX_DFF_ARST  2

extern "C" void get_dff_arst(unsigned char* arst);
extern "C" unsigned char xref_diff_dff_arst(time_stamp_t now, unsigned int idx) {
    Reference& h = refMap.at(group_idx(idx));

    if (h.has_cache(now, IDX_DFF_ARST)) {
        h.clean_cache(IDX_DFF_ARST);
        return h.get_cache(IDX_DFF_ARST);
    }
    else {
        unsigned char dut_arst, vnt_arst;
        svSetScope(svGetScopeFromName(h.dut()));
        get_dff_arst(&dut_arst);

        svSetScope(svGetScopeFromName(h.vnt()));
        get_dff_arst(&vnt_arst);

        unsigned char result = dut_arst ^ vnt_arst;
        h.set_cache(now, IDX_DFF_ARST, result);
        return result;
    }
}

#define IDX_MEM_WEN(idx)  (0 + idx)

extern "C" void get_mem_wt_en(unsigned int index, unsigned char* en);
extern "C" unsigned char xref_diff_mem_wt_en(time_stamp_t now, unsigned int idx, unsigned int index) {
    Reference& h = refMap.at(group_idx(idx));

    if (h.has_cache(now, IDX_MEM_WEN(idx))) {
        h.clean_cache(IDX_MEM_WEN(idx));
        return h.get_cache(IDX_MEM_WEN(idx));
    }
    else {
        unsigned char dut_en, vnt_en;
        svSetScope(svGetScopeFromName(h.dut()));
        get_mem_wt_en(index, &dut_en);

        svSetScope(svGetScopeFromName(h.vnt()));
        get_mem_wt_en(index, &vnt_en);

        unsigned char result = dut_en ^ vnt_en;
        h.set_cache(now, IDX_MEM_WEN(idx), result);
        return result;
    }
}

#define IDX_MEM_RRST(idx)  (8 + idx)

extern "C" void get_mem_rd_arst(unsigned int index, unsigned char* arst);
extern "C" unsigned char xref_diff_mem_rd_arst(time_stamp_t now, unsigned int idx, unsigned int index) {
    Reference& h = refMap.at(group_idx(idx));

    if (h.has_cache(now, IDX_MEM_RRST(idx))) {
        h.clean_cache(IDX_MEM_RRST(idx));
        return h.get_cache(IDX_MEM_RRST(idx));
    }
    else {
        unsigned char dut_arst, vnt_arst;
        svSetScope(svGetScopeFromName(h.dut()));
        get_mem_rd_arst(index, &dut_arst);

        svSetScope(svGetScopeFromName(h.vnt()));
        get_mem_rd_arst(index, &vnt_arst);

        unsigned char result = dut_arst ^ vnt_arst;
        h.set_cache(now, IDX_MEM_RRST(idx), result);
        return result;
    }
}

extern "C" void get_mem_rd_srst(unsigned int index, unsigned char* srst);
extern "C" unsigned char xref_diff_mem_rd_srst(time_stamp_t now, unsigned int idx, unsigned int index) {
    Reference& h = refMap.at(group_idx(idx));

    if (h.has_cache(now, IDX_MEM_RRST(idx))) {
        h.clean_cache(IDX_MEM_RRST(idx));
        return h.get_cache(IDX_MEM_RRST(idx));
    }
    else {
        unsigned char dut_srst, vnt_srst;
        svSetScope(svGetScopeFromName(h.dut()));
        get_mem_rd_srst(index, &dut_srst);

        svSetScope(svGetScopeFromName(h.vnt()));
        get_mem_rd_srst(index, &vnt_srst);

        unsigned char result = dut_srst ^ vnt_srst;
        h.set_cache(now, IDX_MEM_RRST(idx), result);
        return result;
    }
}

#define IDX_MEM_REN(idx)  (16 + idx)

extern "C" void get_mem_rd_en(unsigned int index, unsigned char* en);
extern "C" unsigned char xref_diff_mem_rd_en(time_stamp_t now, unsigned int idx, unsigned int index) {
    Reference& h = refMap.at(group_idx(idx));

    if (h.has_cache(now, IDX_MEM_REN(idx))) {
        h.clean_cache(IDX_MEM_REN(idx));
        return h.get_cache(IDX_MEM_REN(idx));
    }
    else {
        unsigned char dut_en, vnt_en;
        svSetScope(svGetScopeFromName(h.dut()));
        get_mem_rd_en(index, &dut_en);

        svSetScope(svGetScopeFromName(h.vnt()));
        get_mem_rd_en(index, &vnt_en);

        unsigned char result = dut_en ^ vnt_en;
        h.set_cache(now, IDX_MEM_REN(idx), result);
        return result;
    }
}
