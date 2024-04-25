#ifndef SWAP_DEBUG
#include <svdpi.h>
#endif

#include <fstream>
#include <iostream>
#include <cassert>
#include <vector>
#include <string>

#include <libconfig.h++>
using namespace libconfig;

#include "mem_swap.h"


struct MemRegionConfig {
    std::string type;
    unsigned long long start_addr;
    unsigned long long max_len;
    std::string init_file;
    int swap_id;
};

struct TBConfig {
    bool has_variant;
    unsigned long long start_addr;
    unsigned long long max_mem_size;
    std::vector<MemRegionConfig> mem_regions;

    TBConfig() {
        has_variant = false;
        start_addr = 0x80000000UL;
        max_mem_size = 0;
    }

    void update_size(size_t real_mem_size) {
        max_mem_size = real_mem_size;
    }

    void load_config(std::string input_file) {
        if (input_file.find(".cfg") != std::string::npos) {
            has_variant = true;

            Config cfg;
            cfg.readFile(input_file.c_str());

            start_addr = cfg.lookup("start_addr");
            size_t cfg_mem_size = cfg.lookup("max_mem_size");
            if (cfg_mem_size > max_mem_size) {
                std::cerr << "Configuration file memory size is larger than the real memory size!" << std::endl;
                exit(EXIT_FAILURE);
            }

            const libconfig::Setting &root = cfg.getRoot();
            const libconfig::Setting &region_config = root["memory_regions"];

            for (int i = 0; i < region_config.getLength(); i++) {
                const libconfig::Setting &region = region_config[i];
                MemRegionConfig mem_region;
                if (!(region.lookupValue("type", mem_region.type)
                    && region.lookupValue("start_addr", mem_region.start_addr)
                    && region.lookupValue("max_len", mem_region.max_len)
                    && region.lookupValue("init_file", mem_region.init_file)
                )) {
                    std::cerr << "Invalid memory region configuration!" << std::endl;
                    exit(EXIT_FAILURE);
                }
                if (mem_region.type == "swap" && !region.lookupValue("swap_id", mem_region.swap_id)) {
                    std::cerr << "Swap memory region requires a swap_id!" << std::endl;
                    exit(EXIT_FAILURE);
                }
                mem_regions.push_back(mem_region);
            }
        } else {
            has_variant = false;
            MemRegionConfig mem_region;
            mem_region.type = "dut";
            mem_region.start_addr = start_addr;
            mem_region.max_len = max_mem_size;
            mem_region.init_file = input_file;
            mem_regions.push_back(mem_region);
        }
    }
};

bool init_done = false;
TBConfig tb_config;
SwapMem mem_pool[2];

#define DUT_MEM 0
#define VNT_MEM 1

extern "C" void testbench_memory_initial(const char *input_file, unsigned long int size) {
    if (init_done) {
        return;
    }

    if (strlen(input_file) == 0) {
        std::cerr << "A testcase binary or configuration file is required!" << std::endl;
        exit(1);
    }

    tb_config.update_size(size);
    tb_config.load_config(input_file);

    mem_pool[DUT_MEM].initial_mem(tb_config.start_addr, tb_config.max_mem_size);
    if (tb_config.has_variant)
        mem_pool[DUT_MEM].initial_mem(tb_config.start_addr, tb_config.max_mem_size);

    for (auto &mem_region : tb_config.mem_regions) {
        if (mem_region.type == "dut") {
            mem_pool[DUT_MEM].register_normal_blocks(mem_region.start_addr, mem_region.max_len, mem_region.init_file);
        }
        else if (mem_region.type == "vnt") {
            mem_pool[VNT_MEM].register_normal_blocks(mem_region.start_addr, mem_region.max_len, mem_region.init_file);
        }
        else if (mem_region.type == "swap") {
            mem_pool[DUT_MEM].register_swap_blocks(mem_region.start_addr, mem_region.max_len, mem_region.init_file, mem_region.swap_id);
            mem_pool[VNT_MEM].register_swap_blocks(mem_region.start_addr, mem_region.max_len, mem_region.init_file, mem_region.swap_id);
        }
        else {
            std::cerr << "Invalid memory region type: " << mem_region.type << std::endl;
            exit(2);
        }
    }

    init_done = true;
}

extern "C" void testbench_memory_do_swap(unsigned char is_variant) {
    std::cout << ((is_variant) ? "variant" : "origin") << " do memory swap" << std::endl;
    if (tb_config.has_variant || !is_variant)
        mem_pool[is_variant].do_mem_swap();
}

extern "C" void testbench_memory_write_byte(unsigned char is_variant, unsigned long int addr, unsigned char data) {
    if (tb_config.has_variant || !is_variant)
        mem_pool[is_variant].write_byte(addr, data);
}

extern "C" unsigned char testbench_memory_read_byte(unsigned char is_variant, unsigned long int addr) {
    if (tb_config.has_variant)
        return mem_pool[is_variant].read_byte(addr);
    else
        return mem_pool[DUT_MEM].read_byte(addr);
}

#ifdef SWAP_DEBUG
int main() {
    swap_memory_initial(0, "/home/zyy/divafuzz-workspace/build/fuzz_code/origin.dist", "/home/zyy/divafuzz-workspace/build/fuzz_code/variant.dist");
    swap_memory_initial(1, "/home/zyy/divafuzz-workspace/build/fuzz_code/origin.dist", "/home/zyy/divafuzz-workspace/build/fuzz_code/variant.dist");

    do_mem_swap(0);
    do_mem_swap(1);
    do_mem_swap(1);
    swap_mem_array[0].print_swap_mem();
    swap_mem_array[1].print_swap_mem();

    for (int i = 0; i < 64; i++) {
        size_t addr = i * TB_MEM_PAGE_SIZE;
        std::cout << "\t" << std::hex << addr << ": ";
        std::cout << std::hex << (uint32_t)swap_memory_read_byte(0, addr + 3) << std::hex << (uint32_t)swap_memory_read_byte(0, addr + 2) << std::hex << (uint32_t)swap_memory_read_byte(0, addr + 1) << std::hex << (uint32_t)swap_memory_read_byte(0, addr) << std::endl;
    }

    for (int i = 0; i < 64; i++) {
        size_t addr = i * TB_MEM_PAGE_SIZE;
        swap_memory_write_byte(0, addr + 3, 0xde);
        swap_memory_write_byte(0, addr + 2, 0xad);
        swap_memory_write_byte(0, addr + 1, 0xbe);
        swap_memory_write_byte(0, addr + 0, 0xef);
        std::cout << "\t" << std::hex << addr << ": ";
        std::cout << std::hex << (uint32_t)swap_memory_read_byte(0, addr + 3) << std::hex << (uint32_t)swap_memory_read_byte(0, addr + 2) << std::hex << (uint32_t)swap_memory_read_byte(0, addr + 1) << std::hex << (uint32_t)swap_memory_read_byte(0, addr) << std::endl;
    }
    swap_mem_array[0].print_swap_mem();
    swap_mem_array[1].print_swap_mem();
}

#endif
