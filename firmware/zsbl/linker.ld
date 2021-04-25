SECTIONS
{
    START_ADDRESS = 0x10000; /* ... but actually position independent */

    . = START_ADDRESS;
    .text.start : { *(.text.start) }
}
