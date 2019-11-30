

.exportzp _zp_src, _zp_dst, _zp_len, _zp_arg, _zp_ret, _zp_app
.segment "ZEROPAGE"

;_zp_dat:    .res 32
_zp_app:    .res 128 
_zp_src:    .res 2
_zp_dst:    .res 2
_zp_len:    .res 2
_zp_arg:    .res 2
_zp_ret:    .res 2


REG_FIFO_DATA   = $40F0
REG_FIFO_STAT   = $40F1
REG_MSTAT       = $40FF

REG_VRM_ADDR    = $4100
REG_VRM_DATA    = $4102

STAT_UNLOCK     = 1
STAT_MCU_PEND   = 2
STAT_FPG_PEND   = 4
STAT_STROBE     = 8

PPU_STAT	=$2002
PPU_SCRL	=$2005
PPU_ADDR	=$2006
PPU_DATA	=$2007

.segment "CODE"
;*******************************************************************************
.macro  app_load   app_addr, app_end, mem_addr
    ldx #0
@90:
    lda app_addr, x
    sta mem_addr, x
    inx
    cpx #(app_end - app_addr)
    bne @90
    jmp mem_addr
.endmacro

.macro  wait_status
@91:
    lda REG_MSTAT
    sta _zp_arg+1
    lda REG_MSTAT

    eor #STAT_STROBE
    cmp _zp_arg+1
    bne @91
    
    eor #(STAT_MCU_PEND | STAT_FPG_PEND)
    and _zp_arg
    cmp _zp_arg
    bne @91

    lda _zp_arg+1
    and #$F0
    cmp #$A0
    bne @91
.endmacro
;******************************************************************************* fpga reboot
.export _bi_reboot_exec
mem_vals:;such pattern matches to cold start memory state on famicom av
;.byte $ff, $ff, $ff, $ff,$00, $00, $00, $00,  $00, $00, $00, $00, $ff, $ff, $ff, $ff 
.byte $00, $00, $00, $00, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $00, $00, $00, $00
_bi_reboot_exec:
    ldx #0
@0:
    ldy #0
@1:
    cpy #16
    beq @0
    lda mem_vals, y 
    sta $0100, x
    sta $0200, x
    sta $0300, x
    sta $0400, x
    sta $0500, x
    sta $0600, x
    sta $0700, x
    iny
    inx
    bne @1

    lda _zp_arg 
    sta REG_MSTAT ;set mcu or fpg pend bits if need
    app_load app_reboot, app_reboot_end, $640
app_reboot:;wait for STATUS_UNLOCK state and clearing FPG_PEND
    lda #0
    sta REG_FIFO_DATA;exec
    wait_status

    ldx #0
@1:
    lda $0100, y
    sta $0000, x
    inx 
    bne @1    

    bit PPU_STAT
@2:
    bit PPU_STAT
    bpl @2

    ldx #$fd
    txs
    lda #$34
    pha
    ldx #0
    ldy #0
    txa
    plp

    jmp ($FFFC)
app_reboot_end:

;******************************************************************************* halt
.export _bi_halt_exec
_bi_halt_exec:
    lda _zp_arg 
    sta REG_MSTAT ;set mcu or fpg pend bits if need
    app_load app_halt_exec, app_halt_exec_end, _zp_app
app_halt_exec:;wait for defined in zp_arg state
    lda #0
    sta REG_FIFO_DATA ;exec mcu routine
    wait_status
    rts
app_halt_exec_end:
;*******************************************************************************   
.export _bi_put_str
_bi_put_str:
    ldy #0
    ldx _zp_len
@0:
    lda (_zp_src), y
    cmp #0
    beq @2
    iny
    bne @1
    inc _zp_src+1
@1:
    sta REG_VRM_DATA
    dex
    bne @0
@2:
    rts

.export _bi_clean_screen
_bi_clean_screen:
    ldx #0
    txa
@1:
    sta REG_VRM_DATA
    sta REG_VRM_DATA
    sta REG_VRM_DATA
    sta REG_VRM_DATA
    dex
    bne @1
    rts

.export _bi_copy_screen
_bi_copy_screen:
    ldx #0
@1:
    lda REG_VRM_DATA
    sta REG_VRM_DATA
    lda REG_VRM_DATA
    sta REG_VRM_DATA
    lda REG_VRM_DATA
    sta REG_VRM_DATA
    lda REG_VRM_DATA
    sta REG_VRM_DATA
    dex
    bne @1
    rts

.export _bi_vram_fill
_bi_vram_fill:
    lda _zp_arg
    ldx _zp_len
@0:
    sta REG_VRM_DATA
    dex
    bne @0
    rts
.export _bi_copy_screen_safe
_bi_copy_screen_safe:
    ldy #5
    bit PPU_STAT
    jmp @1
@0:;skip scroll setup at first iteration
    lda #0
    sta PPU_SCRL
    lda #(0-6)
    sta PPU_SCRL;
@1:
    jsr vsync
    lda _zp_dst+1
    sta PPU_ADDR
    lda _zp_dst
    sta PPU_ADDR
    ldx #87
@2:
    lda REG_VRM_DATA
    sta PPU_DATA
    lda REG_VRM_DATA
    sta PPU_DATA
    dex
    bne @2

    dey
    beq @3
    
    clc
    lda _zp_dst
    adc #174
    sta _zp_dst
    lda _zp_dst+1
    adc #0
    sta _zp_dst+1
    jmp @0
@3:
    lda #0
    sta PPU_SCRL
    lda #(240-6)
    sta PPU_SCRL

    rts

vsync:
    ;bit PPU_STAT
@1:
    bit PPU_STAT
    bpl @1
    rts 
   
;*******************************************************************************  
.export _bi_fifo_read
_bi_fifo_read:
    ldy #0
    ldx _zp_len
@0:
    lda REG_FIFO_STAT
    bmi @0
    lda REG_FIFO_DATA
    sta (_zp_dst), y
    iny
    bne @1
    inc _zp_dst+1
@1:
    dex
    bne @0
    rts
.export _bi_fifo_write
_bi_fifo_write:
    ldy #0
    ldx _zp_len
@0:
    lda (_zp_src), y
    sta REG_FIFO_DATA

    iny
    bne @1
    inc _zp_src+1
@1:
    dex
    bne @0

    rts
