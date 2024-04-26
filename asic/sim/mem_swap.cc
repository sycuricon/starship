#include "mem_swap.h"


#define except_examine(judge_result, comment) except_examine_func((judge_result), (comment), __FILE__, __LINE__)

void except_examine_func(bool judge_result, const char *comment, const char *file_name, int line_name) {
    if (!judge_result) {
        std::cerr << comment << " in file " << file_name << "'s line " << line_name << std::endl;
        std::exit(-1);
    }
}

#define UpPage(addr) (((addr) + TB_MEM_PAGE_SIZE - 1) & ~0xfff)

uint8_t *SwappableMem::malloc_mem_blocks(size_t block_len, std::string *file_name) {
    block_len = UpPage(block_len);
    except_examine(block_len != 0, "the bound of block is zero");
    uint8_t *mem_block = new uint8_t[block_len];

    if (file_name) {
        std::ifstream fin(*file_name, std::ios_base::binary);
        fin.seekg(0, std::ios::end);
        size_t fsize = fin.tellg();
        except_examine(fsize <= block_len, "the file content is larger than memory bound");
        fin.seekg(0, std::ios::beg);

        fin.read((char *)mem_block, fsize);
    }

    mem_region_keeper.push_back(mem_block);
    return mem_block;
}

void SwappableMem::mount_mem_blocks(uint8_t *block, size_t block_begin, size_t block_len) {
    size_t block_begin_offset = block_begin - mem_begin;
    size_t block_begin_page = block_begin_offset / TB_MEM_PAGE_SIZE;
    size_t block_page_size = block_len / TB_MEM_PAGE_SIZE;
    size_t block_end_page = block_begin_page + block_page_size;

    for (size_t i = block_begin_page; i < block_end_page; i++) {
        // if (mem_block_array[i]!=nullptr) {
        //     std::cout << "i = "<< i << std::endl;
        //     std::cout << "block_begin = "<< block_begin << std::endl;
        //     std::cout << "block_len = "<< block_len << std::endl;
        // }
        // except_examine(mem_block_array[i] == nullptr, "the memory_bound is overlapped");
        mem_block_array[i] = &block[(i - block_begin_page) * TB_MEM_PAGE_SIZE];
    }
}

void SwappableMem::unmount_mem_blocks(size_t block_begin, size_t block_len) {
    size_t block_begin_offset = block_begin - mem_begin;
    size_t block_begin_page = block_begin_offset / TB_MEM_PAGE_SIZE;
    size_t block_page_size = block_len / TB_MEM_PAGE_SIZE;
    size_t block_end_page = block_begin_page + block_page_size;

    for (size_t i = block_begin; i < block_end_page; i++) {
        except_examine(mem_block_array[i] != nullptr, "Try to unmount a memory block that is not mounted");
        mem_block_array[i] = nullptr;
    }
}

void SwappableMem::write_byte(size_t addr, uint8_t data) {
    // std::cout << "write: ";
    // std::cout << "addr = " << std::hex << (uint64_t)addr;
    // std::cout << "; data = " << std::hex << (uint64_t)data << std::endl;

    except_examine(addr < mem_len, "the addr of write_byte is not in the memory bound");
    size_t page_index = addr / TB_MEM_PAGE_SIZE;
    size_t page_offset = addr % TB_MEM_PAGE_SIZE;
    uint8_t *page_ptr = mem_block_array[page_index];
    if (!page_ptr) {
        page_ptr = mem_block_array[page_index] = malloc_mem_blocks(TB_MEM_PAGE_SIZE, nullptr);
    }
    page_ptr[page_offset] = data;
}

uint8_t SwappableMem::read_byte(size_t addr) {
    except_examine(addr < mem_len, "the addr of write_byte is not in the memory bound");
    size_t page_index = addr / TB_MEM_PAGE_SIZE;
    size_t page_offset = addr % TB_MEM_PAGE_SIZE;
    uint8_t *page_ptr = mem_block_array[page_index];
    if (!page_ptr) {
        page_ptr = mem_block_array[page_index] = malloc_mem_blocks(TB_MEM_PAGE_SIZE, nullptr);
    }
    uint8_t data = page_ptr[page_offset];

    // std::cout << "read: ";
    // std::cout << "addr = " << std::hex << (uint64_t)addr;
    // std::cout << "; data = " << std::hex << (uint64_t)data << std::endl;

    return data;
}

void SwappableMem::do_mem_swap() {
    if (swap_block_index < swap_block_array.size()) {
        std::vector<SwapBlock> &swap_block_vector = swap_block_array[swap_block_index];
        for (auto p = swap_block_vector.begin(); p != swap_block_vector.end(); p++) {
            unmount_mem_blocks(p->swap_block_begin, p->swap_block_len);
        }
    }
    swap_block_index--;

    except_examine(swap_block_index >= 0, "the swap_block_index < 0, program does not halt in proper");

    std::vector<SwapBlock> &swap_block_vector = swap_block_array[swap_block_index];
    for (auto p = swap_block_vector.begin(); p != swap_block_vector.end(); p++) {
        mount_mem_blocks(p->swap_block, p->swap_block_begin, p->swap_block_len);
    }

    // print_swap_mem();
}

void SwappableMem::print_swap_mem() {
    std::cout << "the info of swap memory:" << std::endl;
    std::cout << "mem_begin:" << std::hex << mem_begin << std::endl;
    std::cout << "mem_end:" << std::hex << mem_len + mem_begin << std::endl;
    std::cout << "mem_block_array:" << std::endl;
    for (size_t i = 0; i < mem_len / TB_MEM_PAGE_SIZE; i++) {
        if (mem_block_array[i] != nullptr) {
            std::cout << '\t' << std::hex << (mem_begin + i * TB_MEM_PAGE_SIZE)
                      << ": " << std::hex << (uint64_t)mem_block_array[i] << std::endl;
        }
    }
    std::cout << std::endl;
    std::cout << "swap_block_info" << std::endl;
    int i = 0;
    for (auto p = swap_block_array.begin(); p != swap_block_array.end(); p++, i++) {
        std::cout << "\tswap " << i << std::endl;
        for (auto q = p->begin(); q != p->end(); q++) {
            std::cout << "\t\tswap_begin: " << std::hex << q->swap_block_begin << std::endl;
            std::cout << "\t\tswap_end: " << std::hex << q->swap_block_begin + q->swap_block_len << std::endl;
            std::cout << "\t\tswap_mem: " << std::hex << (uint64_t)q->swap_block << std::endl;
            std::cout << std::endl;
        }
    }
    std::cout << "\tcurr swap index:" << swap_block_index << std::endl;
    std::cout << std::endl;

    std::cout << "memory_pool info:" << std::endl;
    for (auto p : mem_region_keeper) {
        std::cout << "\t" << std::hex << (uint64_t)p << std::endl;
    }
    std::cout << std::endl;
}

void SwappableMem::initial_mem(size_t mem_start_addr, size_t max_mem_size) {    
    this->mem_begin = mem_start_addr;
    this->mem_len = UpPage(max_mem_size);

    except_examine(this->mem_len, "the memory bound is smaller than one block");

    mem_block_array = new uint8_t *[mem_len / TB_MEM_PAGE_SIZE];
    for (int i = 0; i < mem_len / TB_MEM_PAGE_SIZE; i++) {
        mem_block_array[i] = nullptr;
    }
}

void SwappableMem::register_swap_blocks(size_t block_begin, size_t block_len, std::string &file_name, int swap_index) {
    block_len = UpPage(block_len);
    except_examine(block_begin % TB_MEM_PAGE_SIZE == 0, "the memory is not aligned to page");
    except_examine(mem_begin <= block_begin && block_len > 0 && block_begin + block_len <= mem_begin + mem_len,
                    "the memory bound is out of the swap memory array");
    except_examine(block_begin + block_len >= block_begin, "the block address space is overflow");

    uint8_t *mem_block = malloc_mem_blocks(block_len, &file_name);

    size_t block_end = block_begin + block_len;
    SwapBlock swap_block(mem_block, block_begin, block_len);
    if (swap_block_array.size() < swap_index + 1) {
        swap_block_array.resize(swap_index + 1);
    }
    swap_block_array[swap_index].push_back(swap_block);
    swap_block_index = swap_block_array.size();
}

void SwappableMem::register_normal_blocks(size_t block_begin, size_t block_len, std::string &file_name) {
    block_len = UpPage(block_len);
    except_examine(block_begin % TB_MEM_PAGE_SIZE == 0, "the memory is not aligned to page");
    except_examine(mem_begin <= block_begin && block_len > 0 && block_begin + block_len <= mem_begin + mem_len,
                    "the memory bound is out of the swap memory array");
    except_examine(block_begin + block_len >= block_begin, "the block address space is overflow");

    uint8_t *mem_block = malloc_mem_blocks(block_len, &file_name);
    mount_mem_blocks(mem_block, block_begin, block_len);
}
