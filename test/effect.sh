for stack_depth in 2 4 8;
do
    for iter in 1000 5000 10000;
    do
        make effect STACK_DEPTH=$stack_depth ITER=$iter;
        make -C .. vlt STARSHIP_TESTCASE=~/extend/riscv-starship/test/effect_test/regvault -j20;
    done
done