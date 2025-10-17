#ifndef __MEM_SWAP_H__
#define __MEM_SWAP_H__

#include <cstdint>
#include <cstdlib>
#include <vector>
#include <string>
#include <cstring>
#include <fstream>
#include <iostream>
#include <cassert>
#include <queue>
#include <map>

void except_examine_func(bool judge_result, const char *comment, const char *file_name, int line_name);
#define except_examine(judge_result, comment) except_examine_func((judge_result), (comment), __FILE__, __LINE__)

#define TB_MEM_PAGE_SIZE 0x1000
#define UpPage(addr) (((addr) + TB_MEM_PAGE_SIZE - 1) & ~0xfff)

struct SwapBlock {
    uint8_t *swap_block;
    size_t swap_block_begin;
    size_t swap_block_len;
    bool is_vm;
    char priv;
    bool attack;

    SwapBlock() {
        swap_block = NULL;
        swap_block_begin = 0;
        swap_block_len = 0;
        is_vm = false;
        priv = 'M';
        attack = false;
    }

    SwapBlock(uint8_t *swap_block, size_t swap_block_begin, size_t swap_block_len, std::string &mode, std::string &phase)
        : swap_block(swap_block), swap_block_begin(swap_block_begin), swap_block_len(swap_block_len) {
            except_examine(mode.length() == 2, "Invalid execution mode length");
            priv = mode[0];
            is_vm = mode[1] == 'v';
            attack = phase == "attack";
        }
};

class SwappableMem {
    std::vector<uint8_t *> mem_region_keeper;
    uint8_t **mem_block_array;
    size_t mem_begin;
    size_t mem_len;

    int current_swap;
    std::queue<int> swap_schedule;
    std::map<int, std::vector<SwapBlock>> swap_block_map;

private:
    uint8_t *malloc_mem_blocks(size_t block_len, std::string *file_name);
    void mount_mem_blocks(uint8_t *block, size_t block_begin, size_t block_len);
    void unmount_mem_blocks(size_t block_begin, size_t block_len);

public:
    SwappableMem() : mem_begin(0), mem_len(0), mem_block_array(nullptr), current_swap(-1) {}
    ~SwappableMem() {
        delete[] mem_block_array;
        for (auto p : mem_region_keeper) {
            delete[] p;
        }
    }

    void initial_mem(size_t mem_start_addr, size_t max_mem_size, std::vector<int>& schedule_list);
    void register_swap_blocks(size_t block_begin, size_t block_len, std::string &file_name, int swap_index, std::string &mode, std::string &phase);
    void register_normal_blocks(size_t block_begin, size_t block_len, std::string &file_name);

    unsigned long int do_mem_swap();
    void write_byte(size_t addr, uint8_t data);
    uint8_t read_byte(size_t addr);
    void print_swap_mem();
};

#endif
