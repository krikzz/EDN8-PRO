

    .export _gfx_vsync
    .export _gfx_init


pal: 
.byte $0f, $10, $0f, $28
.byte $0f, $0f, $0f, $0f
.byte $0f, $0f, $0f, $0f
.byte $0f, $30, $00, $28

;copy x*256 bytes to ppu. ppu addr must be set from outside
_gfx_init:
    jsr _gfx_vsync
    lda #0
    sta PPU_CTRL
    sta PPU_MASK
    

;clean ppu ram
    lda #$20
    sta PPU_ADDR
    lda #$00
    sta PPU_ADDR
    lda #$20
    ldx #8
    ldy #0
cl_loop:
    sta PPU_DATA
    sta PPU_DATA
    sta PPU_DATA
    sta PPU_DATA
    dey
    bne cl_loop
    dex
    bne cl_loop

    lda #$3f
    sta PPU_ADDR
    lda #0
    sta PPU_ADDR
    ldy #0
@pal_init:
    lda pal, y
    sta PPU_DATA
    iny
    cpy #16
    bne @pal_init



    rts




_gfx_vsync:
    bit PPU_STATUS
@1:
    bit PPU_STATUS
    bpl @1
    rts
    
