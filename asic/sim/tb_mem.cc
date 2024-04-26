#include <fstream>
#include <iostream>
#include <cassert>
#include <vector>
#include <string>

#include <svdpi.h>
#include <libconfig.h++>

#include "mem_swap.h"

struct MemRegionConfig {
    std::string type;
    size_t start_addr;
    size_t max_len;
    std::string init_file;
    int swap_id;
};

struct TBConfig {
    bool has_variant;
    size_t mem_start_addr;
    size_t max_mem_size;
    std::vector<MemRegionConfig> mem_regions;

    TBConfig() {
        has_variant = false;
        mem_start_addr = 0x80000000UL;
        max_mem_size = 0;
    }

    void update_size(size_t real_mem_size) {
        max_mem_size = real_mem_size;
    }

    bool lookupAddrValue(const libconfig::Setting &cfg, const std::string &path, size_t &target) {
        if (!cfg.exists(path))
            return false;
        
        const libconfig::Setting& value = cfg.lookup(path);
        if (value.getType() == libconfig::Setting::TypeInt) {
            unsigned int tmp;
            bool result = cfg.lookupValue(path, tmp);
            target = static_cast<size_t>(tmp);
            return result;
        } else if (value.getType() == libconfig::Setting::TypeInt64) {
            unsigned long long tmp;
            bool result = cfg.lookupValue(path, tmp);
            target = static_cast<size_t>(tmp);
            return result;
        } else {
            return false;
        }
    }

    void load_config(std::string input_file) {
        if (input_file.find(".cfg") != std::string::npos) {
            printf("[*] Init memory via config file: %s\n", input_file.c_str());

            libconfig::Config cfg;
            try {
                cfg.readFile(input_file.c_str());
            } catch(const libconfig::FileIOException &fioex) {
                std::cerr << "I/O error while reading file." << std::endl;
                exit(EXIT_FAILURE);
            } catch(const libconfig::ParseException &pex) {
                std::cerr << "Parse error at " << pex.getFile() << ":" << pex.getLine()
                    << " - " << pex.getError() << std::endl;
                exit(EXIT_FAILURE);
            }
            const libconfig::Setting &cfg_root = cfg.getRoot();

            size_t cfg_mem_size;
            if (!(lookupAddrValue(cfg_root, "start_addr", mem_start_addr) 
                && lookupAddrValue(cfg_root, "max_mem_size", cfg_mem_size)
            )) {
                std::cerr << "Invalid memory configuration!" << std::endl;
                exit(EXIT_FAILURE);
            }

            if (cfg_mem_size > max_mem_size) {
                std::cerr << "Configuration requires a larger memory size!" << std::endl;
                exit(EXIT_FAILURE);
            }

            const libconfig::Setting &cfg_region = cfg_root["memory_regions"];
            for (int i = 0; i < cfg_region.getLength(); i++) {
                const libconfig::Setting &region_cfg = cfg_region[i];
                MemRegionConfig mem_region;
                if (!(region_cfg.lookupValue("type", mem_region.type)
                    && lookupAddrValue(region_cfg, "start_addr", mem_region.start_addr)
                    && lookupAddrValue(region_cfg, "max_len", mem_region.max_len)
                    && region_cfg.lookupValue("init_file", mem_region.init_file)
                )) {
                    std::cerr << "Invalid memory region configuration!" << std::endl;
                    exit(EXIT_FAILURE);
                }

                if (mem_region.type == "vnt") {
                    has_variant = true;
                }

                if (mem_region.type == "swap" && !region_cfg.lookupValue("swap_id", mem_region.swap_id)) {
                    std::cerr << "Swap memory region requires a swap_id!" << std::endl;
                    exit(EXIT_FAILURE);
                }

                mem_regions.push_back(mem_region);
            }
        } else {
            printf("[*] Init memory via binary file: %s\n", input_file.c_str());

            has_variant = false;
            MemRegionConfig mem_region;
            mem_region.type = "dut";
            mem_region.start_addr = mem_start_addr;
            mem_region.max_len = max_mem_size;
            mem_region.init_file = input_file;
            mem_regions.push_back(mem_region);
        }
    }

    void dump_config() {
        std::cout << "start_addr: " << std::hex << mem_start_addr << std::endl;
        std::cout << "max_mem_size: " << std::hex << max_mem_size << std::endl;
        for (auto &mem_region : mem_regions) {
            std::cout << "type: " << mem_region.type << std::endl;
            std::cout << "start_addr: " << std::hex << mem_region.start_addr << std::endl;
            std::cout << "max_len: " << std::hex << mem_region.max_len << std::endl;
            std::cout << "init_file: " << mem_region.init_file << std::endl;
            if (mem_region.type == "swap") {
                std::cout << "swap_id: " << mem_region.swap_id << std::endl;
            }
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
        exit(EXIT_FAILURE);
    }

    tb_config.update_size(size);
    tb_config.load_config(input_file);

    tb_config.dump_config();

    mem_pool[DUT_MEM].initial_mem(tb_config.mem_start_addr, tb_config.max_mem_size);
    if (tb_config.has_variant)
        mem_pool[VNT_MEM].initial_mem(tb_config.mem_start_addr, tb_config.max_mem_size);

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
            exit(EXIT_FAILURE);
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
