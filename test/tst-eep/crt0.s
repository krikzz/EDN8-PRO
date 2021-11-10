
NES_MAPPER      = 16;mapper number
NES_PRG_BANKS   = 2;number of 16K PRG banks, change to 2 for NROM256
NES_CHR_BANKS   = 2;number of 8K CHR banks
NES_MIRRORING   = 1;0 horizontal, 1 vertical, 8 four screen

PPU_CTRL	=$2000 
PPU_MASK	=$2001
PPU_STATUS	=$2002
PPU_OAM_ADDR    =$2003
PPU_OAM_DATA    =$2004
PPU_SCROLL	=$2005
PPU_ADDR	=$2006
PPU_DATA	=$2007
PPU_OAM_DMA	=$4014
PPU_FRAMECNT    =$4017
DMC_FREQ	=$4010
CTRL_PORT1	=$4016
CTRL_PORT2	=$4017

OS_ZRAM = $90
GFX_PTR = OS_ZRAM+2
PRG_PTR = OS_ZRAM+4
CTR1 = OS_ZRAM+6
CTR2 = OS_ZRAM+7


.define cmd_addr1 $4400
.define cmd_data1 $4401
.define cmd_addr2 $4402
.define cmd_data2 $4403


.export start,__STARTUP__:absolute=1
.import __RAM_START__   ,__RAM_SIZE__
.import __ROM0_START__  ,__ROM0_SIZE__
.import __STARTUP_LOAD__,__STARTUP_RUN__,__STARTUP_SIZE__
.import	__CODE_LOAD__   ,__CODE_RUN__   ,__CODE_SIZE__
.import	__RODATA_LOAD__ ,__RODATA_RUN__ ,__RODATA_SIZE__


.include "zeropage.inc"
.import initlib, push0, popa, popax, _main, zerobss, copydata
.import _main

.segment "HEADER"

    .byte $4e,$45,$53,$1a
    .byte NES_PRG_BANKS
    .byte NES_CHR_BANKS
    .byte NES_MIRRORING|((NES_MAPPER & 15)<<4)
    .byte NES_MAPPER&$f0 | 8
    .byte $50, $00, $20
    .res 5,0

.segment "CODE"
start:
    
    sei
    ldx #$ff
    txs
    lda #0
    sta $E00F
    sta $800F
    

    ldx #0
    stx PPU_MASK
    stx PPU_CTRL
    stx $4013
    stx $4015
    stx $4010

    ldx #$ff
    stx $4017
    ldx $4015
    
    lda #$05
    jsr fill_pal ;red
    ;ldx #10
    ;jsr delay
      

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

    lda #$19
    jsr fill_pal ;green
    
    jmp _main

fill_pal:
    ldx #$3f
    stx PPU_ADDR
    ldx #$00
    stx PPU_ADDR
    ldx #16
@1:
    sta PPU_DATA
    dex
    bne @1
    rts

delay:
    jsr _gfx_vsync
    dex
    bne delay
    rts


nmi:
irq:
rti

.segment "CODE"

.include "gfx.s"


.segment "VECTORS"


.word nmi ;$fffa vblank nmi
.word start ;$fffc reset
.word irq ;$fffe irq / brk


.segment "CHARS" 
.incbin "tileset.bin"
