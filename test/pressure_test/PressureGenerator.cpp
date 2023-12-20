#include"PressureGenerator.hpp"

void PressureGenerator::change_reg(){
    int rand = std::rand()%10;
    if(rand<7){
        generate_add_imm(rand_regindex(),rand_imm());
    }else {
        generate_add(rand_regindex(),rand_regindex());
    }
}

void PressureGenerator::rand_crexk(){
    int begin=std::rand()%8;
    int end=begin+std::rand()%(8-begin);
    generate_crexk(begin,end,rand_csrindex(),rand_regindex(),rand_regindex(),rand_regindex());
}

void PressureGenerator::rand_crdxk(){
    int begin=std::rand()%8;
    int end=begin+std::rand()%(8-begin);
    generate_crdxk(begin,end,rand_csrindex(),rand_regindex(),rand_regindex(),rand_regindex());
}

void PressureGenerator::generate_test(int iter){
    generate_header();
    rand_init();
    for(int i=0;i<iter;i++){
        int rand = std::rand()%10;
        if(rand<4){
            change_reg();
        }else if(rand<7){
            rand_crdxk();
        }else{
            rand_crexk();
        }
    }
    generate_tail();
}