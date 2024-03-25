#define ROM_BASE 0x30000000

.section .text.start, "ax", @progbits
.globl _start
_start:
  csrwi 0x7c1, 0 // disable chicken bits
  li s0, ROM_BASE
  csrr a0, mhartid
  li a1, 0
  jr s0