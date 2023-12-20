OUTPUT_ARCH( "riscv" )
ENTRY(_start1)

SECTIONS
{
  . = 0x80000000;
  .text : {
    mode.o(.text)
    . = ALIGN(0x10);
    *(.text)
  }
  . = ALIGN(0x10);
  .data : {*(.data)}
  . = 0x80001000;
  .tohost : {*(.tohost)}
}
