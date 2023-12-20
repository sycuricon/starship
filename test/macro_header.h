#ifndef __MACRO_HEADER_H__
#define __MACRO_HEADER_H__

#define REG(index) \
    x ## index
#define SET_REG(index,val) \
    li REG(index), val;
#define WRITE_CSR(csr_index,reg_index) \
    .insn i 0b1110011, 0b001, x0, REG(reg_index), csr_index;
#define CREXK(func7,csr,rd,rs1,rs2) \
    .insn r 0b1101011, csr, func7, REG(rd), REG(rs1), REG(rs2);
#define CRDXK(func7,csr,rd,rs1,rs2) \
    .insn r 0b1101011, csr, func7, REG(rd), REG(rs1), REG(rs2);
#define ADD_IMM(index,imm) \
    addi REG(index), REG(index), imm;
#define ADD(index1,index2) \
    add REG(index1), REG(index1), REG(index2);
#define ADD_FULL(index1,index2,index3) \
    add REG(index1), REG(index2), REG(index3)
#define ADD_IMM_FULL(index1,index2,imm) \
    addi REG(index1),REG(index2),imm
#define OPEN_STACK(depth) \
    addi sp,sp,-8*depth
#define CLOSE_STACK(depth) \
    addi sp,sp,8*depth
#define PUT_STACK(index,reg_index) \
    sd REG(reg_index), 8*index(sp)
#define GET_STACK(index,reg_index) \
    ld REG(reg_index), 8*index(sp)
#endif