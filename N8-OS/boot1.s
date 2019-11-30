
PPU_CTRL	=$2000 
PPU_MASK	=$2001
PPU_STAT	=$2002

PPU_STATUS	=$2002
PPU_SCRL	=$2005
PPU_ADDR	=$2006
PPU_DATA	=$2007


REG_MSTAT       = $40FF
STAT_UNLOCK     = 1
STAT_MCU_PEND   = 2
STAT_FPG_PEND   = 4
STAT_STROBE     = 8


.segment "CODE"
.byte "EverDrive N8    "
.byte "Bootcode v1.00  "
.byte "2019 KRIKZZ IT  "
.byte "Igor Golubovskiy"

rst:
    sei
    ldx #$ff
    txs

    ldx #0
    stx PPU_CTRL
@1:
    lda wait_fpga, x
    sta 1024, x
    inx
    bne @1
    jmp 1024

wait_fpga:

;******************** vait vblank
    bit PPU_STAT
vs1:
    bit PPU_STAT
    bpl vs1
;******************** turn on bg rendering
    lda #$00
    sta PPU_CTRL
    lda #$0A
    sta PPU_MASK

;******************** fill screen in blue color
    lda #$3f
    sta PPU_ADDR
    lda #$00
    sta PPU_ADDR

    lda #$0C 
    ldx #32
@0:    
    sta PPU_DATA
    dex
    bne @0
;******************** wait for fpga configuration
@1:
    lda REG_MSTAT
    eor #STAT_STROBE
    cmp REG_MSTAT
    bne @1

    tax
    and #STAT_UNLOCK
    cmp #STAT_UNLOCK
    bne @1

    txa
    and #$F0
    cmp #$A0
    bne @1

;******************** vblank
    bit PPU_STAT
vs2:
    bit PPU_STAT
    bpl vs2

;******************** fill screen in red color
    lda #$3f
    sta PPU_ADDR
    lda #$00
    sta PPU_ADDR

    lda #$06 ;red
    ldx #32
@2:    
    sta PPU_DATA
    dex
    bne @2

;*************************** jump to OS
    jmp ($FFFC)

;color indicators.
;blue: system stuck at fpga configuration
;red: OS execution fails. Likely something wrong with PRG ROM memory

vbl:
irq:
rti

.segment "VECTORS"

.import ss_save

.word vbl ;$fffa vblank nmi
.word rst ;$fffc reset
.word irq ;$fffe irq / brk