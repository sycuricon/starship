#ifndef SWAP_DEBUG
#include <svdpi.h>
#endif
#include <fstream>
#include <iostream>
#include <cassert>
#include "mem_swap.h"

static const size_t PAGE_SIZE = 0x1000;
SwapMem swap_mem_array[2];

#define except_examine(judge_result, comment) except_examine_func((judge_result), (comment), __FILE__, __LINE__)

void except_examine_func(bool judge_result, const char* comment, const char* file_name, int line_name){
    if(!judge_result){
        std::cerr << comment << " in file " << file_name << "'s line "<< line_name <<std::endl;
        std::exit(-1);
    }
}

SwapMem::SwapBlock::SwapBlock(){
    swap_block = NULL;
    swap_block_begin = 0;
    swap_block_len = 0;
}

SwapMem::SwapBlock::SwapBlock(uint8_t* swap_block, size_t swap_block_begin, size_t swap_block_len):
    swap_block(swap_block),swap_block_begin(swap_block_begin),swap_block_len(swap_block_len){
    ;
}

#define UpPage(addr) (((addr) + PAGE_SIZE - 1)&~0xfff)

SwapMem::SwapMem():
    mem_begin(0), mem_len(0), mem_page_array(nullptr), swap_block_index(0){
    ;
}

SwapMem::~SwapMem(){
    delete [] mem_page_array;
    for(auto p:mem_pool){
        delete [] p;
    }
}

uint8_t* SwapMem::malloc_mem_block(size_t block_len, std::string* file_name){
    block_len = UpPage(block_len);
    except_examine(block_len != 0, "the bound of block is zero");
    uint8_t* mem_block = new uint8_t[block_len];

    if(file_name){
        std::ifstream fin(*file_name, std::ios_base::binary);
        fin.seekg(0, std::ios::end);
        size_t fsize = fin.tellg();
        except_examine(fsize <= block_len, "the file content is larger than memory bound");
        fin.seekg(0, std::ios::beg);

        fin.read((char*)mem_block, fsize);
    }

    mem_pool.push_back(mem_block);
    return mem_block;
}

void SwapMem::register_mem(size_t block_begin, size_t block_len, std::string& file_name){
    uint8_t* mem_block = malloc_mem_block(block_len, &file_name);
    add_mem(mem_block, block_begin, block_len);
}

void SwapMem::add_mem(uint8_t* block, size_t block_begin, size_t block_len){
    block_begin -= mem_begin;
    block_begin /= PAGE_SIZE;
    block_len /= PAGE_SIZE;
    size_t block_end = block_begin + block_len;

    for(int i = block_begin; i < block_end; i++){
        // if(mem_page_array[i]!=nullptr){
        //     std::cout << "i = "<< i << std::endl;
        //     std::cout << "block_begin = "<< block_begin << std::endl;
        //     std::cout << "block_len = "<< block_len << std::endl;
        // }
        // except_examine(mem_page_array[i] == nullptr, "the memory_bound is overlapped");
        mem_page_array[i] = &block[(i - block_begin)*PAGE_SIZE];
    }
}

void SwapMem::remove_mem(size_t block_begin, size_t block_len){
    block_begin -= mem_begin;
    block_begin /= PAGE_SIZE;
    block_len /= PAGE_SIZE;
    size_t block_end = block_begin + block_len;

    for(int i = block_begin; i < block_end; i++){
        except_examine(mem_page_array[i] != nullptr, "the memory_bound is not use");
        mem_page_array[i] = nullptr;
    }
}

void SwapMem::register_swap_block(size_t block_begin, size_t block_len, std::string& file_name, int swap_index){
    uint8_t* mem_block = malloc_mem_block(block_len, &file_name);

    size_t block_end = block_begin + block_len;
    SwapBlock swap_block(mem_block, block_begin, block_len);
    if(swap_block_array.size() < swap_index + 1){
        swap_block_array.resize(swap_index+1);
    }
    swap_block_array[swap_index].push_back(swap_block);
    swap_block_index = swap_block_array.size();
}

void SwapMem::initial_swap_mem(const char* bin_dist_name){
    std::ifstream bin_dist_file(bin_dist_name);
    uint64_t mem_begin, mem_end;
    bin_dist_file >> std::hex >> mem_begin >> std::hex >> mem_end;
    mem_end = UpPage(mem_end);
    except_examine(mem_end, "the memory bound is smaller than one block");
    this->mem_begin = mem_begin;
    this->mem_len = mem_end - mem_begin;

    mem_page_array = new uint8_t*[mem_len/PAGE_SIZE];
    for(int i = 0; i < mem_len/PAGE_SIZE; i++){
        mem_page_array[i] = nullptr;
    }

    size_t block_begin;
    size_t block_len;
    std::string block_kind;
    std::string file_name;
    int swap_index;
    while(bin_dist_file >> std::hex >> block_begin >> std::hex >> block_len >> block_kind >> file_name){
        block_len = UpPage(block_len);
        except_examine(block_begin%PAGE_SIZE == 0, "the mmeory is not aligned to page");
        except_examine(mem_begin <= block_begin && block_len > 0 && block_begin + block_len <= mem_begin + mem_len,\
            "the memory bound is out of the swap memory array");
        except_examine(block_begin + block_len >= block_begin, "the block address space is overflow");

        if(block_kind == "keep"){
            register_mem(block_begin, block_len, file_name);
        }else if(block_kind == "swap"){
            bin_dist_file >> swap_index;
            register_swap_block(block_begin, block_len, file_name, swap_index);
        }else{
            except_examine(false, "the block_kind is invalid");
        }
    }

    // print_swap_mem();
}

void SwapMem::write_byte(size_t addr, uint8_t data){
    // std::cout << "write: ";
    // std::cout << "addr = " << std::hex << (uint64_t)addr;
    // std::cout << "; data = " << std::hex << (uint64_t)data << std::endl;
    
    except_examine( addr < mem_len, "the addr of write_byte is not in the memory bound");
    size_t page_index = addr / PAGE_SIZE;
    size_t page_offset = addr % PAGE_SIZE;
    uint8_t* page_ptr = mem_page_array[page_index];
    if(!page_ptr){
        page_ptr = mem_page_array[page_index] = malloc_mem_block(PAGE_SIZE, nullptr);
    }
    page_ptr[page_offset] = data;
}

uint8_t SwapMem::read_byte(size_t addr){
    except_examine( addr < mem_len, "the addr of write_byte is not in the memory bound");
    size_t page_index = addr / PAGE_SIZE;
    size_t page_offset = addr % PAGE_SIZE;
    uint8_t* page_ptr = mem_page_array[page_index];
    if(!page_ptr){
        page_ptr = mem_page_array[page_index] = malloc_mem_block(PAGE_SIZE, nullptr);
    }
    uint8_t data = page_ptr[page_offset];

    // std::cout << "read: ";
    // std::cout << "addr = " << std::hex << (uint64_t)addr;
    // std::cout << "; data = " << std::hex << (uint64_t)data << std::endl;

    return data;
}

void SwapMem::do_mem_swap(){
    if(swap_block_index  < swap_block_array.size()){
        std::vector<SwapBlock>& swap_block_vector = swap_block_array[swap_block_index];
        for(auto p = swap_block_vector.begin();p != swap_block_vector.end();p++){
            remove_mem(p->swap_block_begin, p->swap_block_len);
        }
    }
    swap_block_index --;

    except_examine(swap_block_index >= 0, "the swap_block_index < 0, program does not halt in proper");

    std::vector<SwapBlock>& swap_block_vector = swap_block_array[swap_block_index];
    for(auto p = swap_block_vector.begin();p != swap_block_vector.end();p++){
        add_mem(p->swap_block, p->swap_block_begin, p->swap_block_len);
    }

    // print_swap_mem();
}

void SwapMem::print_swap_mem(){
    std::cout << "the info of swap memory:" << std::endl;
    std::cout << "mem_begin:" << std::hex << mem_begin << std::endl;
    std::cout << "mem_end:" << std::hex << mem_len + mem_begin << std::endl;
    std::cout << "mem_page_array:" << std::endl; 
    for(size_t i=0;i<mem_len/PAGE_SIZE;i++){
        if(mem_page_array[i] != nullptr){
            std::cout << '\t' << std::hex << (mem_begin + i*PAGE_SIZE)\
                << ": " << std::hex<< (uint64_t)mem_page_array[i] << std::endl;
        }
    }
    std::cout << std::endl;
    std::cout << "swap_block_info" << std::endl;
    int i=0;
    for(auto p=swap_block_array.begin();p!=swap_block_array.end();p++,i++){
        std::cout << "\tswap " << i << std::endl;
        for(auto q = p->begin();q != p->end();q ++){
            std::cout << "\t\tswap_begin: " << std::hex << q->swap_block_begin << std::endl;
            std::cout << "\t\tswap_end: " << std::hex << q->swap_block_begin + q->swap_block_len << std::endl;
            std::cout << "\t\tswap_mem: " << std::hex<< (uint64_t)q->swap_block << std::endl;
            std::cout << std::endl;
        }
    }
    std::cout << "\tcurr swap index:" << swap_block_index << std::endl;
    std::cout <<  std::endl;

    std::cout << "memory_pool info:" << std::endl;
    for(auto p:mem_pool){
        std::cout << "\t" << std::hex << (uint64_t)p << std::endl;
    }
    std::cout << std::endl;
}

void do_mem_swap(unsigned char idx){
    std::cout << ((idx&1)?"variant":"origin") << " do memory swap" << std::endl;
    swap_mem_array[idx&1].do_mem_swap();
}

void swap_memory_initial(unsigned char idx, const char* origin_dist, const char* variant_dist){
    if(idx&1){
        std::cout << "variant initial memory: " << variant_dist << std::endl;
        swap_mem_array[1].initial_swap_mem(variant_dist);
    }else{
        std::cout << "origin initial memory: " << origin_dist << std::endl;
        swap_mem_array[0].initial_swap_mem(origin_dist);
    }
}

void swap_memory_write_byte(unsigned char idx, unsigned long int addr,unsigned char data){
    swap_mem_array[idx&1].write_byte(addr, data);
}

unsigned char swap_memory_read_byte(unsigned char idx, unsigned long int addr){
    return swap_mem_array[idx&1].read_byte(addr);
}

#ifdef SWAP_DEBUG
int main(){
    swap_memory_initial(0, "/home/zyy/divafuzz-workspace/build/fuzz_code/origin.dist", "/home/zyy/divafuzz-workspace/build/fuzz_code/variant.dist");
    swap_memory_initial(1, "/home/zyy/divafuzz-workspace/build/fuzz_code/origin.dist", "/home/zyy/divafuzz-workspace/build/fuzz_code/variant.dist");

    do_mem_swap(0);
    do_mem_swap(1);
    do_mem_swap(1);
    swap_mem_array[0].print_swap_mem();
    swap_mem_array[1].print_swap_mem();

    for(int i=0;i<64;i++){
        size_t addr = i*PAGE_SIZE;
        std::cout << "\t" << std::hex << addr <<": ";
        std::cout << std::hex << (uint32_t)swap_memory_read_byte(0, addr+3) << std::hex << (uint32_t)swap_memory_read_byte(0, addr+2) <<\
            std::hex << (uint32_t)swap_memory_read_byte(0, addr+1) << std::hex << (uint32_t)swap_memory_read_byte(0, addr) << std::endl;
    }
    for(int i=0;i<64;i++){
        size_t addr = i*PAGE_SIZE;
        swap_memory_write_byte(0, addr+3, 0xde);
        swap_memory_write_byte(0, addr+2, 0xad);
        swap_memory_write_byte(0, addr+1, 0xbe);
        swap_memory_write_byte(0, addr+0, 0xef);
        std::cout << "\t" << std::hex << addr <<": ";
        std::cout << std::hex << (uint32_t)swap_memory_read_byte(0, addr+3) << std::hex << (uint32_t)swap_memory_read_byte(0, addr+2) <<\
            std::hex << (uint32_t)swap_memory_read_byte(0, addr+1) << std::hex << (uint32_t)swap_memory_read_byte(0, addr) << std::endl;
    }
    swap_mem_array[0].print_swap_mem();
    swap_mem_array[1].print_swap_mem();

}
#endif