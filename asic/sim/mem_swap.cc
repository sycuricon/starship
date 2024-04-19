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
extern "C" void swap_memory_initial(const char* bin_dist);
extern "C" unsigned long int swap_memory_read_bitmap(unsigned char idx);
extern "C" void swap_memory_write_bitmap(unsigned char idx, unsigned long int data);
extern "C" void swap_memory_write_byte(unsigned char idx, unsigned long int addr,unsigned char data);
extern "C" unsigned char swap_memory_read_byte(unsigned char idx, unsigned long int addr);

class SwapMem{
    struct SwapPair{
        uint8_t* swap_mem_pair[2];
        size_t swap_mem_begin;
        size_t swap_mem_len;
        SwapPair();
        SwapPair(uint8_t* swap_mem_0, uint8_t* swap_mem_1, size_t swap_mem_begin, size_t swap_mem_len);
    };

        uint8_t** mem_page_array;
        size_t mem_begin;
        size_t mem_len;

        uint64_t swap_bitmap;
        static const size_t swap_pair_max_len = 12;
        std::vector<SwapPair> swap_pair;

    public:
        SwapMem(size_t mem_begin, size_t mem_end);
        ~SwapMem();
        static uint8_t* malloc_mem_block(size_t block_len, std::string* file_name);
        void register_mem(uint8_t* mem_block, size_t block_begin, size_t block_end);
        void register_swap_mem(uint8_t* mem_block_0, uint8_t* mem_block_1, size_t mem_begin, size_t mem_end);
        uint64_t read_swap_bitmap();
        void write_swap_bitmap(uint64_t data);
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


SwapMem::SwapPair::SwapPair(){
    swap_mem_pair[0] = NULL;
    swap_mem_pair[1] = NULL;
    swap_mem_begin = 0;
    swap_mem_len = 0;
}

SwapMem::SwapPair::SwapPair(uint8_t* swap_mem_0, uint8_t* swap_mem_1, size_t swap_mem_begin, size_t swap_mem_len){
    this->swap_mem_pair[0] = swap_mem_0;
    this->swap_mem_pair[1] = swap_mem_1;
    this->swap_mem_begin = swap_mem_begin;
    this->swap_mem_len = swap_mem_len;
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
    this->swap_bitmap = 0;
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

void SwapMem::register_swap_mem(uint8_t* mem_block_0, uint8_t* mem_block_1, size_t mem_begin, size_t mem_len){
    except_examine(swap_pair.size() < this->swap_pair_max_len, "the swap block is full");
    except_examine(mem_block_0 && mem_block_1, "the memory bound is mepty");
    size_t swap_pair_index =  swap_pair.size();
    swap_pair.push_back(SwapPair(mem_block_0, mem_block_1, mem_begin, mem_len));

    bool swap_index = this->swap_bitmap & (1<<swap_pair_index);
    register_mem((swap_pair[swap_pair_index]).swap_mem_pair[swap_index], mem_begin, mem_len);
}

uint64_t SwapMem::read_swap_bitmap(){
    return this->swap_bitmap;
}

void SwapMem::write_swap_bitmap(uint64_t data){
    data = data & ((1<<swap_pair.size())-1);
    uint64_t xor_result = data ^ this->swap_bitmap;
    this->swap_bitmap = data;
    size_t swap_index = 0;
    while(xor_result){
        if(xor_result&1){
            do_mem_swap(swap_index);
        }
        xor_result >>= 1;
        swap_index += 1;
    }
}

void SwapMem::do_mem_swap(size_t swap_index){
    bool swap_pair_index = this->swap_bitmap & (1<<swap_index);
    SwapPair& swap_pair = this->swap_pair[swap_index];
    uint8_t* mem_block = swap_pair.swap_mem_pair[swap_pair_index];
    size_t block_begin = swap_pair.swap_mem_begin - mem_begin;
    size_t block_end = swap_pair.swap_mem_len + block_begin;
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
    std::cout << "swap_page_pair_info" << std::endl;
    int i=0;
    for(auto p=swap_pair.begin();p!=swap_pair.end();p++,i++){
        std::cout << '\t' << "swap_begin: " << std::hex << p->swap_mem_begin << std::endl;
        std::cout << '\t' << "swap_end: " << std::hex << p->swap_mem_begin + p->swap_mem_len << std::endl;
        std::cout << '\t' << "swap_mem: " << std::hex<< (uint64_t)p->swap_mem_pair[0] << ' ' << std::hex << (uint64_t)p->swap_mem_pair[1] << std::endl;
        std::cout << '\t' << "the chosen one: " << std::hex << (uint64_t)((swap_bitmap & (1<<i))?p->swap_mem_pair[1]:p->swap_mem_pair[0]) << std::endl;
        std::cout << std::endl;
    }
    std::cout << std::endl;
}

// length, kind, initial, filename
// kind: xor, shared, swap / init, uninit
extern "C" void swap_memory_initial(const char* bin_dist){
    std::ifstream bin_dist_file(bin_dist);
    uint64_t mem_begin, mem_len;
    uint64_t xor_num, shared_num, swap_num, uninitial_num;
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
            std::string train_swap_file_name, nop_swap_file_name;
            std::string* train_swap_file_name_ptr = nullptr;
            std::string* nop_swap_file_name_ptr = nullptr;
            if(do_init){
                bin_dist_file >> train_swap_file_name >> nop_swap_file_name;
                train_swap_file_name_ptr = &train_swap_file_name;
                nop_swap_file_name_ptr = &nop_swap_file_name;
            }
            uint8_t* train_mem_block = SwapMem::malloc_mem_block(block_len, train_swap_file_name_ptr);
            uint8_t* nop_mem_block = SwapMem::malloc_mem_block(block_len, nop_swap_file_name_ptr);
            origin_mem->register_swap_mem(nop_mem_block, train_mem_block, block_begin, block_len);
            variant_mem->register_swap_mem(nop_mem_block, train_mem_block, block_begin, block_len);
        }else{
            except_examine(false, "the block_kind is invalid");
        }
    }
}

extern "C" unsigned long int swap_memory_read_bitmap(unsigned char idx){
    if(idx&1){
        return variant_mem->read_swap_bitmap();
    }else{
        return origin_mem->read_swap_bitmap();
    }
}

extern "C" void swap_memory_write_bitmap(unsigned char idx, unsigned long int data){
    if(idx&1){
        return variant_mem->write_swap_bitmap(data);
    }else{
        return origin_mem->write_swap_bitmap(data);
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