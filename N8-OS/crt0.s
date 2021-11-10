
NES_MAPPER      = 255;mapper number
NES_PRG_BANKS   = 8;number of 16K PRG banks, change to 2 for NROM256
NES_CHR_BANKS   = 2;number of 8K CHR banks
NES_MIRRORING   = 1;0 horizontal, 1 vertical, 8 four screen

PPU_CTRL	=$2000 
PPU_MASK	=$2001
PPU_STAT	=$2002
PPU_SCRL	=$2005
PPU_ADDR	=$2006
PPU_DATA	=$2007




.export start,__STARTUP__:absolute=1
.import __RAM_START__   ,__RAM_SIZE__
.import __ROM0_START__  ,__ROM0_SIZE__
.import __STARTUP_LOAD__,__STARTUP_RUN__,__STARTUP_SIZE__
.import	__CODE_LOAD__   ,__CODE_RUN__   ,__CODE_SIZE__
.import	__RODATA_LOAD__ ,__RODATA_RUN__ ,__RODATA_SIZE__


.include "zeropage.inc"
.import initlib, push0, popa, popax, _main, zerobss, copydata




.segment "HEADER"

    .byte $4e,$45,$53,$1a
    .byte NES_PRG_BANKS
    .byte NES_CHR_BANKS
    .byte NES_MIRRORING|((NES_MAPPER & 15)<<4)
    .byte NES_MAPPER&$f0
    .res 8,0

;.segment "STARTUP"
.segment "CODE"
start:
    sei
    ldx #$ff
    txs

    ldx #0
    stx PPU_CTRL
    bit PPU_STAT
vs1:
    bit PPU_STAT
    bpl vs1

    ldx #0
    stx PPU_MASK
    stx $4013
    stx $4015
    stx $4010

    ldx #$ff
    stx $4017
    ldx $4015

    ldy #0
    lda #0
clram:
    sta $0000, y
    sta $0100, y
    sta $0200, y
    sta $0300, y
    sta $0400, y
    sta $0500, y
    sta $0600, y
    sta $0700, y
    iny
    bne clram


    jsr	zerobss
    jsr	copydata

    lda #<(__RAM_START__+__RAM_SIZE__)
    sta	sp
    lda	#>(__RAM_START__+__RAM_SIZE__)
    sta	sp+1            ; Set argument stack ptr

    jsr	initlib
    jmp _main

   
;.segment "BNK05"
;nop

irq:
rti

.segment "CODE"


.segment "VECTORS"

.import ss_save

.word ss_save ;$fffa vblank nmi
.word start ;$fffc reset
.word irq ;$fffe irq / brk


.segment "CHARS" 
.incbin "font_nes.bin"


;.segment "BNK03"
;.incbin "fdsio.bin"

.segment "BNK00"
.segment "BNK01"
.segment "BNK02"
.segment "BNK03"
.segment "BNK04"
.segment "BNK05"
.segment "BNK06"
.segment "BNK07"


    