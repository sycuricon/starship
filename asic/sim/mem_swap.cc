#include <svdpi.h>
#include <fstream>
#include <iostream>
#include <cstdint>
#include <cassert>
#include <string>
#include <cstring>
#include <cstdlib>
#include <vector>

static const size_t PAGE_SIZE = 0x1000;
void do_mem_swap(unsigned char idx, size_t swap_index);
extern "C" void swap_memory_initial(const char* bin_dist);
extern "C" void swap_memory_write_byte(unsigned char idx, unsigned long int addr,unsigned char data);
extern "C" unsigned char swap_memory_read_byte(unsigned char idx, unsigned long int addr);

class SwapMem{
    struct SwapBlock{
        uint8_t* swap_block;
        size_t swap_block_begin;
        size_t swap_block_len;
        SwapBlock();
        SwapBlock(uint8_t* swap_block, size_t swap_block_begin, size_t swap_block_len);
    };

        uint8_t** mem_page_array;
        size_t mem_begin;
        size_t mem_len;

        static const size_t swap_block_max_len = 256;
        std::vector<SwapBlock> swap_block_array;

    public:
        SwapMem(size_t mem_begin, size_t mem_end);
        ~SwapMem();
        static uint8_t* malloc_mem_block(size_t block_len, std::string* file_name);
        void register_mem(uint8_t* mem_block, size_t block_begin, size_t block_end);
        void register_swap_block(uint8_t* mem_block, size_t mem_begin, size_t mem_end);
        void do_mem_swap(size_t swap_index);
        void write_byte(size_t addr, uint8_t data);
        uint8_t read_byte(size_t addr);
        void print_swap_mem();
};

SwapMem* origin_mem;
SwapMem* variant_mem;

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

SwapMem::SwapMem(size_t mem_begin, size_t mem_len){
    except_examine(mem_begin % PAGE_SIZE == 0, "the memory bound must be aligned to page_size");
    except_examine(mem_len != 0, "the memory bound must be larger than zero");
    except_examine(mem_begin + mem_len >= mem_begin, "the memory address space is overflow");
    this->mem_begin = mem_begin;
    this->mem_len = UpPage(mem_len);
    size_t array_entry_num = mem_len/PAGE_SIZE;
    this->mem_page_array = new uint8_t*[array_entry_num];
    std::memset(mem_page_array, 0, sizeof(uint8_t*)*array_entry_num);
}

SwapMem::~SwapMem(){
    delete [] mem_page_array;
}

uint8_t* SwapMem::malloc_mem_block(size_t block_len, std::string* file_name=nullptr){
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
    return mem_block;
}

void SwapMem::register_mem(uint8_t* mem_block, size_t block_begin, size_t block_len){
    block_len = UpPage(block_len);
    except_examine(mem_block, "the mmeory block is null");
    except_examine(mem_begin <= block_begin && block_len > 0 && block_begin + block_len <= mem_begin + mem_len,\
        "the memory bound is out of the swap memory array");
    except_examine(block_begin + block_len >= block_begin, "the block address space is overflow");
    block_begin -= mem_begin;
    block_len /= PAGE_SIZE;
    block_begin /= PAGE_SIZE;
    size_t block_end = block_begin + block_len;
    for(int i = block_begin; i < block_end; i++){
        except_examine(mem_page_array[i] == NULL, "the memory_bound is overlapped");
        mem_page_array[i] = &mem_block[i*PAGE_SIZE];
    }
}

void SwapMem::register_swap_block(uint8_t* mem_block, size_t mem_begin, size_t mem_end){
    except_examine(swap_block_array.size() < this->swap_block_max_len, "the swap block is full");
    except_examine(mem_block, "the memory bound is mepty");
    swap_block_array.push_back(SwapBlock(mem_block, mem_begin, mem_len));
}

void SwapMem::do_mem_swap(size_t swap_index){
    SwapBlock& swap_block = this->swap_block_array[swap_index];
    uint8_t* mem_block = swap_block.swap_block;
    size_t block_begin = swap_block.swap_block_begin - mem_begin;
    size_t block_end = swap_block.swap_block_len + block_begin;
    block_end /= PAGE_SIZE;
    block_begin /= PAGE_SIZE;
    for(int i = block_begin; i < block_end; i++){
        mem_page_array[i] = &mem_block[i*PAGE_SIZE];
    }
}

void SwapMem::write_byte(size_t addr, uint8_t data){
    except_examine( addr < mem_len, "the addr of write_byte is not in the memory bound");
    size_t page_index = addr / PAGE_SIZE;
    size_t page_offset = addr % PAGE_SIZE;
    uint8_t* page_ptr = mem_page_array[page_index];
    if(!page_ptr){
        page_ptr = mem_page_array[page_index] = new uint8_t[PAGE_SIZE];
    }
    page_ptr[page_offset] = data;
}

uint8_t SwapMem::read_byte(size_t addr){
    except_examine( addr < mem_len, "the addr of write_byte is not in the memory bound");
    size_t page_index = addr / PAGE_SIZE;
    size_t page_offset = addr % PAGE_SIZE;
    uint8_t* page_ptr = mem_page_array[page_index];
    if(!page_ptr){
        page_ptr = mem_page_array[page_index] = new uint8_t[PAGE_SIZE];
    }
    return page_ptr[page_offset];
}

void SwapMem::print_swap_mem(){
    std::cout << "the info of swap memory:" << std::endl;
    std::cout << "mem_begin:" << std::hex << mem_begin << std::endl;
    std::cout << "mem_end:" << std::hex << mem_len + mem_begin << std::endl;
    std::cout << "mem_page_array:" << std::endl; 
    for(size_t i=0;i<mem_len/PAGE_SIZE;i++){
        if(mem_page_array[i]){
            std::cout << '\t' << std::hex << (mem_begin + i*PAGE_SIZE)\
                << ": " << std::hex<< (uint64_t)mem_page_array[i] << std::endl;
        }
    }
    std::cout << std::endl;
    std::cout << "swap_block_info" << std::endl;
    int i=0;
    for(auto p=swap_block_array.begin();p!=swap_block_array.end();p++,i++){
        std::cout << '\t' << "swap_begin: " << std::hex << p->swap_block_begin << std::endl;
        std::cout << '\t' << "swap_end: " << std::hex << p->swap_block_begin + p->swap_block_len << std::endl;
        std::cout << '\t' << "swap_mem: " << std::hex<< (uint64_t)p->swap_block << std::endl;
        std::cout << std::endl;
    }
    std::cout << std::endl;
}

// length, kind, initial, filename
// kind: xor, shared, swap / init, uninit
extern "C" void swap_memory_initial(const char* bin_dist){
    std::ifstream bin_dist_file(bin_dist);
    uint64_t mem_begin, mem_len;
    bin_dist_file >> std::hex >> mem_begin >> std::hex >> mem_len;
    except_examine(mem_len > 0, "the memory bound is smaller than one block");
    origin_mem = new SwapMem(mem_begin, mem_len);
    variant_mem = new SwapMem(mem_begin, mem_len);

    size_t block_begin;
    size_t block_len;
    std::string block_kind;
    std::string initial;
    while(bin_dist_file >> std::hex >> block_begin >> std::hex >> block_len){
        except_examine(block_begin%PAGE_SIZE == 0, "the block_begin must be aligned to page");
        bin_dist_file >> block_kind;
        bin_dist_file >> initial;

        bool do_init = false;
        if(initial == "init"){
            do_init = true;
        }

        if(block_kind == "xor"){
            std::string* origin_file_name_ptr = nullptr;
            std::string* variant_file_name_ptr = nullptr;
            std::string origin_file_name;
            std::string variant_file_name;
            if(do_init){
                bin_dist_file >> origin_file_name >> variant_file_name;
                origin_file_name_ptr = &origin_file_name;
                variant_file_name_ptr = &variant_file_name;
            }
            uint8_t* origin_mem_block = SwapMem::malloc_mem_block(block_len, origin_file_name_ptr);
            uint8_t* variant_mem_block = SwapMem::malloc_mem_block(block_len, variant_file_name_ptr);
            origin_mem->register_mem(origin_mem_block, block_begin, block_len);
            variant_mem->register_mem(variant_mem_block, block_begin, block_len);
        }else if(block_kind == "shared"){
            std::string shared_file_name;
            std::string* shared_file_name_ptr = nullptr;
            if(do_init){
                bin_dist_file >> shared_file_name;
                shared_file_name_ptr = &shared_file_name;
            }
            uint8_t* shared_mem_block = SwapMem::malloc_mem_block(block_len, shared_file_name_ptr);
            origin_mem->register_mem(shared_mem_block, block_begin, block_len);
            variant_mem->register_mem(shared_mem_block, block_begin, block_len);
        }else if(block_kind == "swap"){
            std::string swap_file_name;
            std::string* swap_file_name_ptr = nullptr;
            if(do_init){
                bin_dist_file >> swap_file_name;
                swap_file_name_ptr = &swap_file_name;
            }
            uint8_t* swap_block = SwapMem::malloc_mem_block(block_len, swap_file_name_ptr);
            origin_mem->register_swap_block(swap_block, block_begin, block_len);
        }else{
            except_examine(false, "the block_kind is invalid");
        }
    }
}

extern "C" void do_mem_swap(unsigned char idx, size_t swap_index){
    if(idx&1){
        variant_mem->do_mem_swap(swap_index);
    }else{
        origin_mem->do_mem_swap(swap_index);
    }
}

extern "C" void swap_memory_write_byte(unsigned char idx, unsigned long int addr,unsigned char data){
    if(idx&1){
        variant_mem->write_byte(addr, data);
    }else{
        origin_mem->write_byte(addr, data);
    }
}

extern "C" unsigned char swap_memory_read_byte(unsigned char idx, unsigned long int addr){
    if(idx&1){
        return variant_mem->read_byte(addr);
    }else{
        return origin_mem->read_byte(addr);
    }
}

#if 0
int main(){
    swap_memory_initial("/home/zyy/divafuzz-workspace/build/fuzz_code/bin_dist");
    origin_mem->print_swap_mem();
    variant_mem->print_swap_mem();

    swap_memory_write_bitmap(0, 0b011);
    swap_memory_write_bitmap(1, 0b110);
    swap_memory_write_bitmap(1, 0b101);
    swap_memory_write_bitmap(1, 0b011);
    swap_memory_write_bitmap(1, 0b101);
    std::cout << std::hex << swap_memory_read_bitmap(0) << std::endl;
    std::cout << std::hex << swap_memory_read_bitmap(1) << std::endl;
    origin_mem->print_swap_mem();
    variant_mem->print_swap_mem();

    for(int i=0;i<64;i++){
        size_t addr = i*PAGE_SIZE + std::rand()%PAGE_SIZE;
        swap_memory_write_byte(0, addr, 0xde);
        swap_memory_write_byte(0, addr+1, 0xad);
        swap_memory_write_byte(0, addr+2, 0xbe);
        swap_memory_write_byte(0, addr+3, 0xef);
        std::cout << std::hex << (uint32_t)swap_memory_read_byte(0, addr) << std::hex << (uint32_t)swap_memory_read_byte(0, addr+1) <<\
            std::hex << (uint32_t)swap_memory_read_byte(0, addr+2) << std::hex << (uint32_t)swap_memory_read_byte(0, addr+3) << std::endl;
    }
    origin_mem->print_swap_mem();
    variant_mem->print_swap_mem();

}
#endif