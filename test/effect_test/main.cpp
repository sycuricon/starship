#include"EffectGenerator.hpp"
#include<cstdlib>
int main(int argc,const char* argv[]){
    if(argc<3){
        std::cout<<"no stack depth and iter param"<<std::endl;
        std::exit(1);
    }
    int stack_depth=std::atoi(argv[1]);
    EffectGenerator generator(stack_depth);
    int iter=std::atoi(argv[2]);
    generator.generate_test(iter);
}