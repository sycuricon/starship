#include"EffectGenerator.hpp"
void EffectGenerator::generate_header(){
    TestGenerator::generate_header();
    rand_init();
    std::cout<<"\tla sp,stack_bottom"<<std::endl;
}

void EffectGenerator::generate_tail(){
    TestGenerator::generate_tail();
    std::cout<<""<<std::endl;
    std::cout<<".section .stack"<<std::endl;
    std::cout<<"stack_top:"<<std::endl;
    std::cout<<"\t.space 0x1000"<<std::endl;
    std::cout<<"stack_bottom:"<<std::endl;
}

void EffectGenerator::store_stack(){
    for(int i=0;i<32;i++){
        reginfo[i].dirty=false;
        reginfo[i].plaintext=true;
        reginfo[i].encrpy=false;
        reginfo[i].stack_index=-1;
    }
    for(int i=stack_depth;i>=0;i--){
        int index=rand_regindex();
        while(index==0||index==2||reginfo[index].encrpy==true){
            index=rand_regindex();
        }
        reginfo[index].encrpy=true;
        reginfo[index].plaintext=false;
        reginfo[index].stack_index=i;
        stackinfo[i].key_index=rand_csrindex();
        stackinfo[i].reg_index=index;
        generate_add_imm(2,-8);
        generate_crexk(0,7,stackinfo[i].key_index,index,index,2);
        generate_put_stack(0,index);
    }
}

void EffectGenerator::store_reg(int i){
    int stack_index=reginfo[i].stack_index;
    generate_add_imm(2,stack_index*8);
    generate_crexk(0,7,stackinfo[stack_index].key_index,i,i,2);
    generate_put_stack(0,i);
    generate_add_imm(2,-stack_index*8);
    reginfo[i].dirty=false;
    reginfo[i].plaintext=false;
}

void EffectGenerator::recovery_reg(int i){
    int stack_index=reginfo[i].stack_index;
    generate_add_imm(2,stack_index*8);
    generate_get_stack(0,i);
    generate_crdxk(0,7,stackinfo[stack_index].key_index,i,i,2);
    generate_add_imm(2,-stack_index*8);
    reginfo[i].dirty=false;
    reginfo[i].plaintext=true;
}

void EffectGenerator::recovery_stack(){
    for(int i=0;i<32;i++){
        if(reginfo[i].dirty){
            store_reg(i);
        }
    }
    for(int i=0;i<stack_depth;i++){
        int index=stackinfo[i].reg_index;
        generate_get_stack(0,index);
        generate_crdxk(0,7,stackinfo[i].key_index,index,index,2);
        generate_add_imm(2,8);
    }
}

void EffectGenerator::change_reg(){
    int rd=rand_regindex();
    while(rd==2){
        rd=rand_regindex();
    }
    int rs1=rand_regindex();
    if(std::rand()%10<8){
        rs1=stackinfo[std::rand()%stack_depth].reg_index;
    }
    int rs2=rand_regindex();
    if(std::rand()%10<8){
        rs2=stackinfo[std::rand()%stack_depth].reg_index;
    }
    if(reginfo[rs1].plaintext==false){
        recovery_reg(rs1);
    }
    if(reginfo[rs2].plaintext==false){
        recovery_reg(rs2);
    }
    if(!reginfo[rd].encrpy){
        generate_add_full(rd,rs1,rs2);
    }else if(rd==rs1||rd==rs2){
        generate_add_full(rd,rs1,rs2);
        reginfo[rd].dirty=true;
    }else if(reginfo[rd].dirty){
        store_reg(rd);
        generate_add_full(rd,rs1,rs2);
    }else{
        generate_add_full(rd,rs1,rs2);
        reginfo[rd].plaintext=false;
    }
}

void EffectGenerator::generate_test(int iter){
    generate_header();
    store_stack();
    for(int i=0;i<iter;i++){
        change_reg();
    }
    recovery_stack();
    generate_tail();
}