#include "mem_swap.h"

uint8_t *SwappableMem::malloc_mem_blocks(size_t block_len, std::string *file_name) {
    block_len = UpPage(block_len);
    except_examine(block_len != 0, "the bound of block is zero");
    uint8_t *mem_block = new uint8_t[block_len];

    for (size_t i = 0; i < block_len; i++) {
        mem_block[i] = 0xff;
    }

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
        // Is this neccessary ?
        // except_examine(mem_block_array[i] != nullptr, "Try to unmount a memory block that is not mounted");
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
    except_examine(addr < mem_len, "the addr of read_byte is not in the memory bound");
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

unsigned long int SwappableMem::do_mem_swap() {
    if (current_swap > 0) {
        for (auto const& block : swap_block_map[current_swap]) {
            unmount_mem_blocks(block.swap_block_begin, block.swap_block_len);
        }
    }

    if (swap_schedule.empty()) {
        std::cerr << "The schedule queue is empty, the simulation did not execute as expected" << std::endl;
        exit(EXIT_FAILURE);
    }

    current_swap = swap_schedule.front();
    printf("[*] swap to swap id %d\n", current_swap);

    if (swap_block_map.count(current_swap) == 0) {
        std::cerr << "Swap to an invalid swap id " << current_swap << std::endl;
        exit(EXIT_FAILURE);
    }

    size_t start_addr = mem_begin + mem_len;
    for (auto const& block : swap_block_map[current_swap]) {
        mount_mem_blocks(block.swap_block, block.swap_block_begin, block.swap_block_len);
        start_addr = std::min(start_addr, block.swap_block_begin);
    }
    
    swap_schedule.pop();

    // print_swap_mem();

    #define DEJAVUZZ_VM_MASK    0xfffffffffff00000ul
    #define DEJAVUZZ_PRIV_M     0b11
    #define DEJAVUZZ_PRIV_S     0b01
    #define DEJAVUZZ_PRIV_U     0b00
    #define DEJAVUZZ_VM_FLAG    0b100
    #define DEJAVUZZ_ATK_TVC    0b1000
    
    // TODO: replace this vector
    size_t return_info = start_addr;
    // setup address prefix
    if ((swap_block_map[current_swap][0].priv == 'S') && swap_block_map[current_swap][0].is_vm) {
        return_info = (start_addr | DEJAVUZZ_VM_MASK) | DEJAVUZZ_VM_FLAG;
    }
    else if ((swap_block_map[current_swap][0].priv == 'U') && swap_block_map[current_swap][0].is_vm) {
        return_info = (start_addr & ~DEJAVUZZ_VM_MASK) | DEJAVUZZ_VM_FLAG;
    }

    if (swap_block_map[current_swap][0].priv == 'S') {
        return_info |= DEJAVUZZ_PRIV_S;
    }
    else if (swap_block_map[current_swap][0].priv == 'U') {
        return_info |= DEJAVUZZ_PRIV_U;
    }
    else {
        return_info |= DEJAVUZZ_PRIV_M;
    }

    if (swap_block_map[current_swap][0].attack) {
        return_info |= DEJAVUZZ_ATK_TVC;
    }

    return return_info;
}

void SwappableMem::print_swap_mem() {
    printf("Memory Information:\n");
    printf("  mem_begin: %lx\n", mem_begin);
    printf("  mem_end: %lx\n", mem_len + mem_begin);
    printf("  live memory block:\n");
    for (size_t i = 0; i < mem_len / TB_MEM_PAGE_SIZE; i++) {
        if (mem_block_array[i] != nullptr) {
            printf("    %lx@%lx\n", mem_begin + i * TB_MEM_PAGE_SIZE, (uint64_t)mem_block_array[i]);
        }
    }
    printf("  swap memory block:\n");
    for (auto const& group : swap_block_map) {
        printf("    swap id: %d\n", group.first);
        for (auto const& block : group.second) {
            printf("      %lx-%lx@%lx\n", block.swap_block_begin, block.swap_block_len, (uint64_t)block.swap_block);
        }
    }
    printf("  current live swap id: %d\n", current_swap);
    printf(" registed memory region:\n");
    for (auto p : mem_region_keeper) {
        printf("    %lx\n", (uint64_t)p);
    }
}

void SwappableMem::initial_mem(size_t mem_start_addr, size_t max_mem_size, std::vector<int>& swap_schedule_list) {    
    this->mem_begin = mem_start_addr;
    this->mem_len = UpPage(max_mem_size);

    except_examine(this->mem_len, "the memory bound is smaller than one block");

    mem_block_array = new uint8_t *[mem_len / TB_MEM_PAGE_SIZE];
    for (int i = 0; i < mem_len / TB_MEM_PAGE_SIZE; i++) {
        mem_block_array[i] = nullptr;
    }

    for (auto &swap_id : swap_schedule_list) {
        swap_schedule.push(swap_id);
    }
}

void SwappableMem::register_swap_blocks(size_t block_begin, size_t block_len, std::string &file_name, int swap_index, std::string &mode, std::string &phase) {
    block_len = UpPage(block_len);
    except_examine(block_begin % TB_MEM_PAGE_SIZE == 0, "the memory is not aligned to page");
    except_examine(mem_begin <= block_begin && block_len > 0 && block_begin + block_len <= mem_begin + mem_len,
                    "the memory bound is out of the swap memory array");
    except_examine(block_begin + block_len >= block_begin, "the block address space is overflow");

    uint8_t *mem_block = malloc_mem_blocks(block_len, &file_name);

    size_t block_end = block_begin + block_len;
    SwapBlock swap_block(mem_block, block_begin, block_len, mode, phase);
    swap_block_map[swap_index].push_back(swap_block);
}

void SwappableMem::register_normal_blocks(size_t block_begin, size_t block_len, std::string &file_name) {
    if (block_len == 0)
        return;
    block_len = UpPage(block_len);
    except_examine(block_begin % TB_MEM_PAGE_SIZE == 0, "the memory is not aligned to page");
    except_examine(mem_begin <= block_begin && block_len > 0 && block_begin + block_len <= mem_begin + mem_len,
                    "the memory bound is out of the swap memory array");
    except_examine(block_begin + block_len >= block_begin, "the block address space is overflow");

    uint8_t *mem_block = malloc_mem_blocks(block_len, &file_name);
    mount_mem_blocks(mem_block, block_begin, block_len);
}
