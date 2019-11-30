
PPU_CTRL	=$2000
PPU_MASK	=$2001
PPU_STATUS	=$2002
PPU_OAM_ADDR    =$2003
PPU_OAM_DATA    =$2004
PPU_SCROLL	=$2005
PPU_ADDR	=$2006
PPU_DATA	=$2007
DMC_FREQ	=$4010
PPU_OAM_DMA	=$4014
CTRL_PORT1	=$4016
CTRL_PORT2	=$4017
PPU_FRAMECNT    =$4017


.import _zp_src, _zp_dst, _zp_len

;4200 128 map regs
;4280 32  apu regs
;42A0 32  ppu pal
;42C0 04  ppu regs ctrl, mask, scrl_hi, scrl_lo
;42CF 01  'S' constant

;0000 src ptr
;0002 dst ptr
;5000 reg_a

;6000 8K app bank

;ss banks mapping
;01:0x6000 2K  WRAM
;01:0x6800 4K  VRAM
;01:0x7800 128 mapper regs
;01:0x7880 32  apu regs
;01:0x78A0 32  ppu pal
;01:0x78C0 04  ppu regs. (ctrl, mask, scrl_hi, scrl_lo)
;01:0x79C8 04  cpu regs: a, x, y, sp
;01:0x78CF 01  'S' constant. used for save state data tetection
;01:0x7900 256 OAM memory
;01:0x7A00 512 mapper memory
;01:0x7C00 1K  mapper memory
;02:0x6000 8K  CHR
;03:0x6000 8K  EXRAM (cartridge ram expansion). not used anymore.


.macro  set_ptr ptr, addr
    lda #(addr & $ff)
    sta ptr
    lda #(addr>>8)
    sta ptr+1
.endmacro


REG_SST_ADDR     = $40F2
REG_SST_DATA     = $40F3

REG_APP_BANK    = $4106

BNK_SRM_BASE    = $10
BNK_NES         = $01
BNK_CHR         = $02
BNK_EXRAM       = $03

MEM_START       = $6000
MEM_WRAM        = $6000
MEM_VRAM        = $6800
MEM_MAP_REGS    = $7800
MEM_APU_REGS    = $7880
MEM_PPU_PAL     = $78A0
MEM_PPU_REGS    = $78C0
MEM_CPU_REGS    = $78C8
MEM_S_CONST     = $78CF
MEM_OAM         = $7900



reg_a   = $5000
src     = 0
dst     = 2

.segment "CODE"
.export ss_save
.import start
ss_save:
    
    sta reg_a
    
    lda #0
    sta PPU_CTRL
    sta PPU_MASK
    
    lda #$ff
    sta $4017
    lda #$00
    sta $4015
    sta $4010
    lda $4015
    lda PPU_STATUS
;************************************** save cpu regs    
    lda #BNK_NES
    sta REG_APP_BANK
    lda reg_a
    sta MEM_CPU_REGS+0
    stx MEM_CPU_REGS+1
    sty MEM_CPU_REGS+2
    tsx 
    stx MEM_CPU_REGS+3
    ldx #$ff
    txs
;************************************** fade to black
    lda #$3F
    sta PPU_ADDR
    lda #$00
    sta PPU_ADDR
    lda #$3F
    sta PPU_DATA
;************************************** bacup WRAM
    lda 0
    sta MEM_WRAM+0
    lda 1
    sta MEM_WRAM+1
    lda 2
    sta MEM_WRAM+2
    lda 3
    sta MEM_WRAM+3
      
    ldx #8 ;2K
    ldy #4 ;skip first 4 bytes in zeropage (pointers)
    set_ptr src, $0000
    set_ptr dst, MEM_WRAM
bc_wram:
    lda (src), y
    sta (dst), y
    iny
    bne bc_wram
    inc src+1
    inc dst+1
    dex
    bne bc_wram

;************************************** bacup hardware registers 
    lda MEM_CPU_REGS+0
    pha
    lda MEM_CPU_REGS+1
    pha
    lda MEM_CPU_REGS+2
    pha
    lda MEM_CPU_REGS+3
    pha

    ldx #8 ;2K
    ldy #0
    sty REG_SST_ADDR
    sty REG_SST_ADDR
    set_ptr dst, MEM_MAP_REGS
bc_hvregs: 
    lda REG_SST_DATA
    sta (dst), y
    iny
    bne bc_hvregs
    inc dst+1
    dex
    bne bc_hvregs

;restore cpu regs from stack   
    pla
    sta MEM_CPU_REGS+3
    pla
    sta MEM_CPU_REGS+2
    pla
    sta MEM_CPU_REGS+1
    pla
    sta MEM_CPU_REGS+0
;************************************** bacup VRAM
    lda #$20
    sta PPU_ADDR
    lda #$00
    sta PPU_ADDR
    lda PPU_DATA ;dummy read
    ldx #16 ;4K
    ldy #0
    set_ptr dst, MEM_VRAM
bc_vram:
    lda PPU_DATA
    sta (dst), y
    iny
    bne bc_vram
    inc dst+1
    dex
    bne bc_vram
;************************************** bacup CHR ram
    lda #BNK_CHR
    sta REG_APP_BANK

    lda #$00
    sta PPU_ADDR
    sta PPU_ADDR
    lda PPU_DATA ;dummy read
    ldx #32 ;8K
    ldy #0
    set_ptr dst, MEM_START
bc_chr:
    lda PPU_DATA
    sta (dst), y
    iny
    bne bc_chr
    inc dst+1
    dex
    bne bc_chr
;************************************** bacup cart wram
    jmp skip_exram_bc;this section moded to saveram.c due conflicts with FDS
    ldx #32 ;8K
    ldy #0
    set_ptr src, MEM_START
bc_exram:
    lda #BNK_SRM_BASE
    sta REG_APP_BANK
@0:
    lda (src), y
    sta $0200, y
    iny
    bne @0

    lda #BNK_EXRAM
    sta REG_APP_BANK
@1:
    lda $0200, y 
    lda (src), y
    iny
    bne @1

    inc src+1
    dex
    bne bc_exram
skip_exram_bc:
;************************************** run in-game menu
.include "zeropage.inc"
.import __RAM_START__   ,__RAM_SIZE__
.import initlib, zerobss, copydata
.import _inGameMenu
    ldx #$ff
    txs
    jsr	zerobss
    jsr	copydata

    lda #<(__RAM_START__+__RAM_SIZE__)
    sta	sp
    lda	#>(__RAM_START__+__RAM_SIZE__)
    sta	sp+1            ; Set argument stack ptr

    jsr	initlib
    jmp _inGameMenu
    
;*******************************************************************************
;*******************************************************************************
;*******************************************************************************

.export _ss_return
_ss_return:
    bit PPU_STATUS
@0:
    bit PPU_STATUS
    bpl @0

    ;sta REG_SS_SNA ;write any val to unlock sniffer

    lda #0
    sta PPU_CTRL
    sta PPU_MASK
    lda #$3F
    sta PPU_ADDR
    lda #$00
    sta PPU_ADDR
    lda #$3F
    sta PPU_DATA
;************************************** restore cart wram   
    jmp skip_exram_re;this section moded to saveram.c due conflicts with FDS
    ldx #32 ;8K
    ldy #0
    set_ptr src, MEM_START
re_exram:
    lda #BNK_EXRAM
    sta REG_APP_BANK
@0:
    lda (src), y
    sta $0200, y
    iny
    bne @0

    lda #BNK_SRM_BASE
    sta REG_APP_BANK
@1:
    lda $0200, y 
    lda (src), y
    iny
    bne @1

    inc src+1
    dex
    bne re_exram
skip_exram_re:
;************************************** restore CHR ram
    lda #BNK_CHR
    sta REG_APP_BANK
    lda #$00
    sta PPU_ADDR
    sta PPU_ADDR
    ldx #32 ;8K
    ldy #0
    set_ptr src, MEM_START
re_chr:
    lda (src), y
    sta PPU_DATA
    iny
    bne re_chr
    inc src+1
    dex
    bne re_chr
;************************************** restore VRAM
    lda #BNK_NES
    sta REG_APP_BANK

    lda #$20
    sta PPU_ADDR
    lda #$00
    sta PPU_ADDR
    ldx #16 ;4K
    ldy #0
    set_ptr src, MEM_VRAM
re_vram:
    lda (src), y
    sta PPU_DATA
    iny
    bne re_vram
    inc src+1
    dex
    bne re_vram
;************************************** restore WRAM     
    ldx #8 ;2K
    ldy #4 ;skip first 4 bytes in zeropage (pointers)
    set_ptr src, MEM_WRAM
    set_ptr dst, $0000
re_wram:
    lda (src), y
    sta (dst), y
    iny
    bne re_wram
    inc src+1
    inc dst+1
    dex
    bne re_wram    
;************************************** restore mapper registes
    ldx #8 ;2K
    ldy #0
    sty REG_SST_ADDR
    sty REG_SST_ADDR
    set_ptr src, MEM_MAP_REGS
re_hvregs:
    lda (src), y
    sta REG_SST_DATA
    iny
    bne re_hvregs
    inc src+1
    dex
    bne re_hvregs
;************************************** restore ppu pal
    lda #$3F
    sta PPU_ADDR
    lda #$00
    sta PPU_ADDR
    ldy #0
    set_ptr src, MEM_PPU_PAL
re_ppu_pal:
    lda (src), y
    sta PPU_DATA
    iny
    cpy #32
    bne re_ppu_pal
;************************************** restore oam
    lda #0
    sta PPU_OAM_ADDR
    lda #(MEM_OAM>>8)
    bit PPU_STATUS
re_oam:
    bit PPU_STATUS
    bpl re_oam
    sta PPU_OAM_DMA
;************************************** restore APU
    lda MEM_APU_REGS + $15
    sta $4000 + $15
    ldx #0
re_apu:
    cpx #$10
    beq skip_apu_reg
    cpx #$14
    beq skip_apu_reg
    cpx #$15
    beq skip_apu_reg
    cpx #$16
    beq skip_apu_reg
    lda MEM_APU_REGS, x
    sta $4000, x
skip_apu_reg:
    inx
    cpx #$18
    bne re_apu

    ;lda SNIF_APU_REGS + $17
    ;sta $4000 + $17
    lda $4015
;**************************************
    ;restore first 4 bytes of zeropage
    lda MEM_WRAM+0
    sta 0
    lda MEM_WRAM+1
    sta 1
    lda MEM_WRAM+2
    sta 2
    lda MEM_WRAM+3
    sta 3

    ;ppu scroll
    lda MEM_PPU_REGS+2
    sta PPU_SCROLL
    lda MEM_PPU_REGS+2
    sta PPU_SCROLL

    ;Y and SP regs restore
    ldy MEM_CPU_REGS+2
    ldx MEM_CPU_REGS+3
    txs
    
    ;ppu mask and ctrl will be restored during vblank
    lda MEM_PPU_REGS+0
    ldx MEM_PPU_REGS+1
    ;sta REG_SS_ACK ;ss acknowledge 
vsync:
    bit PPU_STATUS
@1:
    bit PPU_STATUS
    bpl @1

    stx PPU_MASK
    sta PPU_CTRL
    
    ;restore A and X
    lda MEM_CPU_REGS+0
    ldx MEM_CPU_REGS+1

    ;return to game via nmi handler
    jmp ($FFFA)  


