#include"PressureGenerator.hpp"
#include<iostream>
#include<cstdlib>
int main(int argc,const char* argv[]){
    PressureGenerator generator;
    if(argc<2){
        std::cout<<"no iter param"<<std::endl;
        std::exit(1);
    }
    int iter=std::atoi(argv[1]);
    generator.generate_test(iter);
}