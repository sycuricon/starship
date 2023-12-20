.section .text
.global _start1
.extern write_host
_start1:
test1:
    li x1,0x34567890abcdef12
    .insn i 0b1110011, 0b001, x0, x1, 0x5f0
    .insn i 0b1110011, 0b010, x2, x0, 0x5f0
    

    li x1,0x4567890abcdef123
    .insn i 0b1110011, 0b001, x0, x1, 0x5f1
    .insn i 0b1110011, 0b010, x2, x0, 0x5f1
    

    li x1,0x567890abcdef1234
    .insn i 0b1110011, 0b001, x0, x1, 0x5f2
    .insn i 0b1110011, 0b010, x2, x0, 0x5f2
    

    li x1,0x67890abcdef12345
    .insn i 0b1110011, 0b001, x0, x1, 0x5f3
    .insn i 0b1110011, 0b010, x2, x0, 0x5f3
    

    li x1,0x7890abcdef123456
    .insn i 0b1110011, 0b001, x0, x1, 0x5f4
    .insn i 0b1110011, 0b010, x2, x0, 0x5f4
    

    li x1,0x890abcdef1234567
    .insn i 0b1110011, 0b001, x0, x1, 0x5f5
    .insn i 0b1110011, 0b010, x2, x0, 0x5f5
    

    li x1,0x90abcdef12345678
    .insn i 0b1110011, 0b001, x0, x1, 0x5f6
    .insn i 0b1110011, 0b010, x2, x0, 0x5f6
    

    li x1,0x0abcdef123456789
    .insn i 0b1110011, 0b001, x0, x1, 0x5f7
    .insn i 0b1110011, 0b010, x2, x0, 0x5f7
    

    li x1,0xabcdef1234567890
    .insn i 0b1110011, 0b001, x0, x1, 0x5f8
    .insn i 0b1110011, 0b010, x2, x0, 0x5f8
    

    li x1,0xbcdef1234567890a
    .insn i 0b1110011, 0b001, x0, x1, 0x5f9
    .insn i 0b1110011, 0b010, x2, x0, 0x5f9
    

    li x1,0xcdef1234567890ab
    .insn i 0b1110011, 0b001, x0, x1, 0x5fa
    .insn i 0b1110011, 0b010, x2, x0, 0x5fa
    

    li x1,0xdef1234567890abc
    .insn i 0b1110011, 0b001, x0, x1, 0x5fb
    .insn i 0b1110011, 0b010, x2, x0, 0x5fb
    

    li x1,0xef1234567890abcd
    .insn i 0b1110011, 0b001, x0, x1, 0x5fc
    .insn i 0b1110011, 0b010, x2, x0, 0x5fc
    

    li x1,0xf1234567890abcde
    .insn i 0b1110011, 0b001, x0, x1, 0x5fd
    .insn i 0b1110011, 0b010, x2, x0, 0x5fd
    

    li x1,0x1234123412341234
    li x2,0x5678567856785678
    .insn r 0b1101011, 0b000, 0b1110000, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b1110001, x4, x3, x2
    

    li x1,0x1234123412341234
    li x2,0x5678567856785678
    .insn r 0b1101011, 0b000, 0b1100010, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b1100011, x4, x3, x2
    

    li x1,0x1234123412341234
    li x2,0x5678567856785678
    .insn r 0b1101011, 0b000, 0b1010100, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b1010101, x4, x3, x2
    

    li x1,0x1234123412341234
    li x2,0x5678567856785678
    .insn r 0b1101011, 0b000, 0b1000110, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b1000111, x4, x3, x2
    

    li x1,0x1234123412341234
    li x2,0x5678567856785678
    .insn r 0b1101011, 0b000, 0b0110110, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b0110111, x4, x3, x2
    

    li x1,0x1234473287364564
    li x2,0x5abc729dfbc01838
    .insn r 0b1101011, 0b000, 0b1010000, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b1010001, x4, x3, x2
    

    li x1,0x4cf3583c7edc4800
    li x2,0x0ec0eca8cdcae400
    .insn r 0b1101011, 0b000, 0b1100110, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b1100111, x4, x3, x2
    
    
    li x1,0x164d58f913c02300
    li x2,0x1b2334b01588e600
    .insn r 0b1101011, 0b000, 0b1100100, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b1100101, x4, x3, x2
    
    
    li x1,0xa8f0b9b577a5e800
    li x2,0x0e5cefdb16a32000
    .insn r 0b1101011, 0b000, 0b1010010, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b1010011, x4, x3, x2
    
    
    li x1,0x15b46325f7595400
    li x2,0x41e837175a544800
    .insn r 0b1101011, 0b000, 0b0100010, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b0100011, x4, x3, x2
    
    
    li x1,0x0159ea85d936bbf0
    li x2,0x0ba6fe01c45d8a00
    .insn r 0b1101011, 0b000, 0b1101000, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b1101001, x4, x3, x2
    
    
    li x1,0x63e1f19427757c00
    li x2,0x0a9d1ec5ce6aba80
    .insn r 0b1101011, 0b000, 0b1000110, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b1000111, x4, x3, x2
    
    
    li x1,0x3042bb6a81039e00
    li x2,0x504b7b763aa9f400
    .insn r 0b1101011, 0b000, 0b1101010, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b1101011, x4, x3, x2
    
    
    li x1,0x0e887d9ab75af180
    li x2,0x343e39f87e8a1000
    .insn r 0b1101011, 0b000, 0b1000000, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b1000001, x4, x3, x2
    
    
    li x1,0x269b202b99a85600
    li x2,0x0cef44fe32cd0f80
    .insn r 0b1101011, 0b000, 0b1111100, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b1111101, x4, x3, x2
    
    
    li x1,0x3b7eeee8a3f8ba00
    li x2,0x11b3c0c1b49d7d00
    .insn r 0b1101011, 0b000, 0b1101000, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b1101001, x4, x3, x2
    
    
    li x1,0x3debb39702f9c800
    li x2,0x1d33756f04bf5c00
    .insn r 0b1101011, 0b000, 0b1110110, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b1110111, x4, x3, x2
    
    
    li x1,0xad33e1a830aec000
    li x2,0x24a16c06e66a1600
    .insn r 0b1101011, 0b000, 0b1110000, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b1110001, x4, x3, x2
    
   
    li x1,0x1cd63f11c5d84d00
    li x2,0x23f08d6c2dda4e00
    .insn r 0b1101011, 0b000, 0b1111010, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b1111011, x4, x3, x2
    

    li x1,0x3a631a5a8f1a1a00
    li x2,0x263b22e66d757a00
    .insn r 0b1101011, 0b000, 0b1100100, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b1100101, x4, x3, x2
    
    
    li x1,0x994ad45c8fbd4000
    li x2,0x12d8f722a6ec0b00
    .insn r 0b1101011, 0b000, 0b1010010, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b1010011, x4, x3, x2
    
    
    li x1,0xbdaece5c09c55000
    li x2,0x63f673bc1074ac00
    .insn r 0b1101011, 0b000, 0b1101010, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b1101011, x4, x3, x2
    
    
    li x1,0x1ffa045e7ad17a00
    li x2,0x3101a915d090a200
    .insn r 0b1101011, 0b000, 0b0110010, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b0110011, x4, x3, x2
    
    
    li x1,0x230fdc01420d3800
    li x2,0x5858149ff2448c00
    .insn r 0b1101011, 0b000, 0b0000000, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b0000001, x4, x3, x2
    
    
    li x1,0x02770f496151e600
    li x2,0x6780431f9cb00000
    .insn r 0b1101011, 0b000, 0b1110010, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b1110011, x4, x3, x2
    
    
    li x1,0x8f12c0199ddd3000
    li x2,0x0e7bb136b404d300
    .insn r 0b1101011, 0b000, 0b1010100, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b1010101, x4, x3, x2
    
    
    li x1,0x225e24e82acbdc00
    li x2,0xb8bcc967cdd2e000
    .insn r 0b1101011, 0b000, 0b1110110, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b1110111, x4, x3, x2
    

    li x1,0xa1eec2144a8f4000
    li x2,0x0a6e963c0a24b980
    .insn r 0b1101011, 0b000, 0b1000110, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b1000111, x4, x3, x2
    

    li x1,0x0411b5acc0009b40
    li x2,0x6afc53a307490000
    .insn r 0b1101011, 0b000, 0b1100000, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b1100001, x4, x3, x2
    

    li x1,0x34607cf2a273a600
    li x2,0x843f7d8a129dd000
    .insn r 0b1101011, 0b000, 0b1001000, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b1001001, x4, x3, x2
    

    li x1,0x08ece164db7f3d00
    li x2,0x02a0106a16e59120
    .insn r 0b1101011, 0b000, 0b1010110, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b1010111, x4, x3, x2
    

    li x1,0x54084111139fbc00
    li x2,0xa8e6e73f526d5000
    .insn r 0b1101011, 0b000, 0b0110000, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b0110001, x4, x3, x2
    

    li x1,0x9d98950d258eb000
    li x2,0x73463c7c6bad8800
    .insn r 0b1101011, 0b000, 0b1000110, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b1000111, x4, x3, x2
    

    li x1,0x0543fa654a07da40
    li x2,0x07dc4d7682c46480
    .insn r 0b1101011, 0b000, 0b1010000, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b1010001, x4, x3, x2
    

    li x1,0x0d8808be480d3a00
    li x2,0xa1f7bca8e9333800
    .insn r 0b1101011, 0b000, 0b1110110, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b1110111, x4, x3, x2
    

    li x1,0x390293d1384aea00
    li x2,0x738d875f1fffa800
    .insn r 0b1101011, 0b000, 0b0100000, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b0100001, x4, x3, x2
    

    li x1,0x322f819490961000
    li x2,0x1def8cb271b74d00
    .insn r 0b1101011, 0b000, 0b1001000, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b1001001, x4, x3, x2
    

    li x1,0x02706d1a649cde80
    li x2,0x98538f3a0d0c5800
    .insn r 0b1101011, 0b000, 0b1101000, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b1101001, x4, x3, x2
    

    li x1,0x02a92b289fcece20
    li x2,0x673de0a8909f0000
    .insn r 0b1101011, 0b000, 0b1110100, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b1110101, x4, x3, x2
    

    li x1,0x12bfda43d3822800
    li x2,0x27b508fe63f7ae00
    .insn r 0b1101011, 0b000, 0b1100110, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b1100111, x4, x3, x2
    

    li x1,0x21729ce595fe2800
    li x2,0x6134ada950bd6800
    .insn r 0b1101011, 0b000, 0b1111010, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b1111011, x4, x3, x2
    

    li x1,0x8af705c9c2bc5000
    li x2,0x7284b76696bd0400
    .insn r 0b1101011, 0b000, 0b1101010, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b1101011, x4, x3, x2
    

    li x1,0x041721a410f5dd40
    li x2,0x1357fe9bc48aab00
    .insn r 0b1101011, 0b000, 0b1100100, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b1100101, x4, x3, x2
    

    li x1,0x040ea380c72f2cc0
    li x2,0x3b0664d47bb32800
    .insn r 0b1101011, 0b000, 0b1100110, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b1100111, x4, x3, x2
    

    li x1,0x563c53d6345bb000
    li x2,0x5a3e43821904d800
    .insn r 0b1101011, 0b000, 0b1110110, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b1110111, x4, x3, x2
    

    li x1,0x791490316fba8400
    li x2,0x46e7734ff3111c00
    .insn r 0b1101011, 0b000, 0b1111110, x3, x1, x2
    .insn r 0b1101011, 0b000, 0b1111111, x4, x3, x2
    


//-----------------------------------------------------------

    li x1,0x1234123412341234
    li x2,0x5678567856785678
    .insn r 0b1101011, 0b010, 0b1110000, x3, x1, x2
    .insn r 0b1101011, 0b010, 0b1110001, x4, x3, x2
    

    li x1,0x1234123412341234
    li x2,0x5678567856785678
    .insn r 0b1101011, 0b011, 0b1110000, x3, x1, x2
    .insn r 0b1101011, 0b011, 0b1110001, x4, x3, x2
    

    li x1,0x1234123412341234
    li x2,0x5678567856785678
    .insn r 0b1101011, 0b100, 0b1110000, x3, x1, x2
    .insn r 0b1101011, 0b100, 0b1110001, x4, x3, x2
    

    li x1,0x1234123412341234
    li x2,0x5678567856785678
    .insn r 0b1101011, 0b101, 0b1110000, x3, x1, x2
    .insn r 0b1101011, 0b101, 0b1110001, x4, x3, x2
    

    li x1,0x1234123412341234
    li x2,0x5678567856785678
    .insn r 0b1101011, 0b110, 0b1110000, x3, x1, x2
    .insn r 0b1101011, 0b110, 0b1110001, x4, x3, x2
    

    li x1,0x1234123412341234
    li x2,0x5678567856785678
    .insn r 0b1101011, 0b111, 0b1110000, x3, x1, x2
    .insn r 0b1101011, 0b111, 0b1110001, x4, x3, x2
    

    li x1,0x9876543209876543
    li x2,0x1234567812345678
    li x3,0xabcdef1234567890
    li x4,0xbcdef01234567890
    .insn r 0b1101011, 0b111, 0b1110000, x5, x1, x2
    .insn r 0b1101011, 0b100, 0b1100110, x6, x2, x3
    .insn r 0b1101011, 0b100, 0b1100110, x6, x2, x3
    .insn r 0b1101011, 0b100, 0b1100110, x6, x2, x3
    .insn r 0b1101011, 0b101, 0b1100100, x7, x3, x0
    .insn i 0b1110011, 0b001, x0, x4, 0x5f0
    .insn r 0b1101011, 0b101, 0b1111000, x8, x0, x1
    .insn r 0b1101011, 0b101, 0b1100100, x12, x3, x0
    .insn r 0b1101011, 0b101, 0b1100100, x12, x3, x0
    .insn r 0b1101011, 0b101, 0b1100100, x12, x3, x0
    .insn r 0b1101011, 0b101, 0b1100100, x13, x2, x4
    .insn r 0b1101011, 0b101, 0b1111000, x14, x4, x2
    .insn i 0b1110011, 0b001, x0, x4, 0x5f8
    .insn i 0b1110011, 0b001, x0, x3, 0x5f8
    .insn i 0b1110011, 0b001, x0, x2, 0x5f8
    .insn i 0b1110011, 0b001, x0, x1, 0x5f8
    .insn r 0b1101011, 0b101, 0b1100100, x7, x3, x0
    .insn r 0b1101011, 0b101, 0b1111000, x8, x0, x1
    .insn r 0b1101011, 0b101, 0b1100100, x9, x3, x0
    .insn r 0b1101011, 0b101, 0b1111000, x10, x0, x1
    .insn i 0b1110011, 0b001, x0, x1, 0x5f8
    .insn r 0b1101011, 0b101, 0b1100101, x11, x7, x0
    .insn r 0b1101011, 0b101, 0b1111001, x11, x8, x1
    .insn r 0b1101011, 0b101, 0b1100101, x11, x9, x0
    .insn r 0b1101011, 0b101, 0b1111001, x11, x10, x1
    .insn i 0b1110011, 0b001, x0, x1, 0x5f8
    .insn r 0b1101011, 0b101, 0b1100101, x11, x7, x0
    .insn r 0b1101011, 0b101, 0b1111001, x11, x8, x1
    .insn r 0b1101011, 0b111, 0b1110001, x11, x9, x2
    .insn r 0b1101011, 0b100, 0b1100111, x11, x6, x3

final:
    li a0,0x1
    j write_host

.section .data