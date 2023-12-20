OUTPUT_ARCH( "riscv" )
ENTRY(start)

SECTIONS
{
  . = 0x80000000;
  .text : {*(.text)}
  . = ALIGN(0x10);
  .data : {*(.data)}
  . = ALIGN(0x10);
  .tohost : {*(.tohost)}
  . = ALIGN(0x1000);
  .stack : {*(.stack)}
}
