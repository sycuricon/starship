#ifndef __UTILS_HPP__
#define __UTILS_HPP__
#include<iostream>
#include<string>
#include<cstdlib>
#include<ctime>
#include<cstdint>
#include<bitset>
class TestGenerator{
    private:
        int asm_funct7(int begin,int end,int decrpy);
        int64_t asm_imm12(int64_t imm);
    public:
        static constexpr int keyindex[16]={0x5f0,0x5f1,0x7f0,0x7f1,0x5f2,0x5f3,0x5f4,0x5f5,\
            0x5f6,0x5f7,0x5f8,0x5f9,0x5fa,0x5fb,0x5fc,0x5fd};
        TestGenerator(){std::srand(std::time(0));}
        void rand_init();
        int rand_imm(){return ((uint64_t)std::rand()<<48)|\
            ((uint64_t)std::rand()<<32)|((uint64_t)std::rand()<<16)|((uint64_t)std::rand());}
        int rand_regindex(){return std::rand()%32;}
        int rand_csrindex(){return std::rand()%8;}
        void generate_crexk(int begin,int end,int csr_index,int rd,int rs1,int rs2);
        void generate_crdxk(int begin,int end,int csr_index,int rd,int rs1,int rs2);
        void generate_set_reg(int index,unsigned long long val);
        void generate_write_csr(int csr_index,int reg_index);
        void generate_add_imm(int index,uint64_t imm);
        void generate_add(int index1,int index2);
        void generate_add_full(int index1,int index2,int index3);
        void generate_add_imm_full(int index1,int index2,uint64_t imm);
        void generate_open_stack(int depth);
        void generate_close_stack(int depth);
        void generate_put_stack(int index,int reg_index);
        void generate_get_stack(int index,int reg_index);
        void generate_header();
        void generate_tail();
};

#endif