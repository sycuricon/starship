#ifndef __PRESSURE_GENERATOR_HPP__
#define __PRESSURE_GENERATOR_HPP__
#include"../utils.hpp"
class EffectGenerator:public TestGenerator{
    private:
        struct StackInfo{
            int reg_index;
            int key_index;
        };
        struct RegInfo{
            bool plaintext;
            bool encrpy;
            bool dirty;
            int stack_index;
        };
        int stack_depth;
        StackInfo* stackinfo;
        RegInfo* reginfo;
        void store_stack();
        void recovery_stack();
        void change_reg();
        void store_reg(int i);
        void recovery_reg(int i);
    public:
        EffectGenerator(int stack_depth):stack_depth(stack_depth%16){
            stackinfo=new StackInfo[stack_depth];
            reginfo=new RegInfo[32];
        }
        ~EffectGenerator(){
            delete [] stackinfo;
            delete [] reginfo;
        }
        void generate_test(int iter);
        void generate_header();
        void generate_tail();
};
#endif