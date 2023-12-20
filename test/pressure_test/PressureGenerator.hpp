#ifndef __PRESSURE_GENERATOR_HPP__
#define __PRESSURE_GENERATOR_HPP__
#include"../utils.hpp"
class PressureGenerator:public TestGenerator{
    private:
        void change_reg();
        int rand_keyindex(){return TestGenerator::keyindex[rand()%16];}
        void rand_crexk();
        void rand_crdxk();
    public:
        PressureGenerator(){}
        void generate_test(int iter);
};
#endif