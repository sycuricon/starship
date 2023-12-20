.section .text
.global write_host
write_host:
    la t0,tohost
    sd a0,0(t0)
    j write_host

.section .tohost
tohost:
    .space 0x40
fromhost:
    .space 0x40