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

#define TB_MEM_PAGE_SIZE 0x1000

struct SwapBlock {
    uint8_t *swap_block;
    size_t swap_block_begin;
    size_t swap_block_len;

    SwapBlock() {
        swap_block = NULL;
        swap_block_begin = 0;
        swap_block_len = 0;
    }
    SwapBlock(uint8_t *swap_block, size_t swap_block_begin, size_t swap_block_len)
        : swap_block(swap_block), swap_block_begin(swap_block_begin), swap_block_len(swap_block_len) {}
};

class SwappableMem {
    std::vector<uint8_t *> mem_region_keeper;
    uint8_t **mem_block_array;
    size_t mem_begin;
    size_t mem_len;

    static const size_t swap_block_max_len = 256;
    std::vector<std::vector<SwapBlock>> swap_block_array;
    size_t swap_block_index;

private:
    uint8_t *malloc_mem_blocks(size_t block_len, std::string *file_name);
    void mount_mem_blocks(uint8_t *block, size_t block_begin, size_t block_len);
    void unmount_mem_blocks(size_t block_begin, size_t block_len);

public:
    SwappableMem() : mem_begin(0), mem_len(0), mem_block_array(nullptr), swap_block_index(0) {}
    ~SwappableMem() {
        delete[] mem_block_array;
        for (auto p : mem_region_keeper) {
            delete[] p;
        }
    }

    void initial_mem(size_t mem_start_addr, size_t max_mem_size);
    void register_swap_blocks(size_t block_begin, size_t block_len, std::string &file_name, int swap_index);
    void register_normal_blocks(size_t block_begin, size_t block_len, std::string &file_name);

    void do_mem_swap();
    void write_byte(size_t addr, uint8_t data);
    uint8_t read_byte(size_t addr);
    void print_swap_mem();
};

#endif
