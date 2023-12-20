#include"utils.hpp"
int TestGenerator::asm_funct7(int begin,int end,int decrpy){
    return ((end&0b111)<<4)|((begin&0b111)<<1)|(decrpy&0b1);
}

void TestGenerator::rand_init(){
    for(int i=1;i<32;i++){
        generate_set_reg(i,rand_imm());
    }
    for(int i=0;i<16;i++){
        generate_write_csr(keyindex[i],rand_regindex());
    }
}

void TestGenerator::generate_crexk(int begin,int end,int csr_index,int rd,int rs1,int rs2){
    std::cout<<"\tCREXK(0b"<<std::bitset<7>(asm_funct7(begin,end,0))\
        <<",0x"<<std::hex<<csr_index<<\
        ","<<std::dec<<rd<<\
        ","<<std::dec<<rs1<<\
        ","<<std::dec<<rs2<<\
        ")"<<std::endl;
}

void TestGenerator::generate_crdxk(int begin,int end,int csr_index,int rd,int rs1,int rs2){
    std::cout<<"\tCRDXK(0b"<<std::bitset<7>(asm_funct7(begin,end,1))\
        <<",0x"<<std::hex<<csr_index<<\
        ","<<std::dec<<rd<<\
        ","<<std::dec<<rs1<<\
        ","<<std::dec<<rs2<<\
        ")"<<std::endl;
}

void TestGenerator::generate_set_reg(int index,unsigned long long val){
    std::cout<<"\tSET_REG("<<std::dec<<index<<\
        ",0x"<<std::hex<<val<<")"<<std::endl;
}

void TestGenerator::generate_write_csr(int csr_index,int reg_index){
    std::cout<<"\tWRITE_CSR(0x"<<std::hex<<csr_index<<\
    ","<<std::dec<<reg_index<<")"<<std::endl;
}

int64_t TestGenerator::asm_imm12(int64_t imm){
    return (imm&0xfff)<<52>>52;
}

void TestGenerator::generate_add_imm(int index,uint64_t imm){
    std::cout<<"\tADD_IMM("<<std::dec<<index<<\
        ",0x"<<std::hex<<asm_imm12(imm)<<")"<<std::endl;
}

void TestGenerator::generate_add(int index1,int index2){
    std::cout<<"\tADD("<<std::dec<<index1<<\
        ","<<std::dec<<index2<<")"<<std::endl;
}

void TestGenerator::generate_header(){
    std::cout<<"#include\"../macro_header.h\""<<std::endl;
    std::cout<<".section .text"<<std::endl;
    std::cout<<".global start"<<std::endl;
    std::cout<<"start:"<<std::endl;
}

void TestGenerator::generate_tail(){
    std::cout<<"write_host:"<<std::endl;
    std::cout<<"\tla t0,tohost"<<std::endl;
    std::cout<<"\tli t1,1"<<std::endl;
    std::cout<<"\tsd t1,0(t0)"<<std::endl;
    std::cout<<"\tj write_host"<<std::endl;
    std::cout<<""<<std::endl;
    std::cout<<".section .tohost"<<std::endl;
    std::cout<<"tohost:"<<std::endl;
    std::cout<<"\t.space 0x40"<<std::endl;
    std::cout<<"fromhost:"<<std::endl;
    std::cout<<"\t.space 0x40"<<std::endl;
}

void TestGenerator::generate_add_full(int index1,int index2,int index3){
    std::cout<<"\tADD_FULL("<<std::dec<<index1<<\
        ","<<std::dec<<index2<<","<<std::dec<<\
        index3<<")"<<std::endl;
}

void TestGenerator::generate_add_imm_full(int index1,int index2,uint64_t imm){
    std::cout<<"\tADD_IMM_FULL("<<std::dec<<index1<<\
        ","<<std::dec<<index2<<","<<std::dec<<\
        asm_imm12(imm)<<")"<<std::endl;
}
void TestGenerator::generate_open_stack(int depth){
    std::cout<<"\tOPEN_STACK("<<std::dec<<depth<<")"<<std::endl;
}

void TestGenerator::generate_close_stack(int depth){
    std::cout<<"\tCLOSE_STACK("<<std::dec<<depth<<")"<<std::endl;
}

void TestGenerator::generate_put_stack(int index,int reg_index){
    std::cout<<"\tPUT_STACK("<<std::dec<<index<<","<<\
        std::dec<<reg_index<<")"<<std::endl;
}

void TestGenerator::generate_get_stack(int index,int reg_index){
    std::cout<<"\tGET_STACK("<<std::dec<<index<<","<<\
        reg_index<<")"<<std::endl;
}