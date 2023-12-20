.section .text
.extern _start1
_sbi_start:
    li t0,0x800
    csrw mstatus,t0
    la t0,_start1
    csrw mepc,t0
    li t0,0x8
    csrw mie,t0
    li x1,0x34567890abcdef12
    .insn i 0b1110011, 0b001, x0, x1, 0x7f0
    li x1,0x4567890abcdef123
    .insn i 0b1110011, 0b001, x0, x1, 0x7f1
    .insn i 0b1110011, 0b010, x1, x0, 0x7f0
    .insn i 0b1110011, 0b010, x1, x0, 0x7f1
    li x1,0x1234123412341234
    li x2,0x5678567856785678
    .insn r 0b1101011, 0b001, 0b1110000, x3, x1, x2
    .insn r 0b1101011, 0b001, 0b1110001, x4, x3, x2
    la t0,_start1
    jalr zero,0(t0)