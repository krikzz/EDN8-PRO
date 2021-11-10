

.segment "CODE"
    nop


;loads files from disk into memory.
;RETaddr	pointer to 10-byte disk header compare string
;RETaddr+2	pointer to list	of files to identify & load
.segment "BI_FL_LD"
load_files:     ;E1F8
    nop

.segment "BI_FL_WR"
append_file:    ;E237
    lda #$FF
write_file:     ;E239
    rts


.segment "BI_FL_FC"
set_file_cnt:   ;E2B7
    ldx #$FF
    bne file_cnt
upd_file_cnt:   ;E2BB
    ldx #$00
file_cnt:
    rts


.segment "BI_FL_DF"
def_file_cnt1:  ;E301
    ldx #$01;	add 1 to value in A
    bne def_file_cnt
def_file_cnt0:  ;E305
    ldx #$00
def_file_cnt:
    rts

;RETaddr	pointer to destination address for info. to collect
.segment "BI_DINFO"
disk_info:      ;E32A
    rts


.word $ffff,$ffff,$ffff,$ffff,$ffff
nmi:
    BIT $0100
    BPL _E198
    BVC _E195
    JMP ($DFFA);	11xxxxxx
_E195:
    JMP ($DFF8);	10xxxxxx
_E198:
    BVC _E19D
    JMP ($DFF6);	01xxxxxx
    
;disable further VINTs	00xxxxxx
_E19D:
    LDA $FF
    AND #$7f
    STA $FF
    STA $2000;	[NES] PPU setup	#1
    LDA $2002;	[NES] PPU status
    
;discard interrupted return address (should be $E1C5)
    PLA
    PLA
    PLA
    
;restore byte at [$0100]
    PLA
    STA $0100
    
;restore A
    PLA
    RTS

irq:
    BIT $0101
    BMI _E1EA
    BVC _E1D9
    
;disk transfer routine ([$0101]	= 01xxxxxx)
    STA $4024
    LDX $4031
    
    PLA
    PLA
    PLA
    TXA
    RTS
    
;disk byte skip	routine ([$0101] = 00nnnnnn; n is # of bytes to	skip)
;this is mainly	used when the CPU has to do some calculations while bytes
;read off the disk need to be discarded.
_E1D9:
    PHA
    LDA $0101
    SEC
    SBC #$01
    BCC _E1E8
    STA $0101
    LDA $4031
_E1E8:
    PLA
    RTI
    
;[$0101] = 1Xxxxxxx
_E1EA:
    BVC _E1EF
    JMP ($DFFE);	11xxxxxx
    
;disk IRQ acknowledge routine ([$0101] = 10xxxxxx).
;don't know what this is used for, or why a delay is put here.
_E1EF:
    PHA
    LDA $4030
    ;JSR Delay131
    PLA
    RTI

rst:
    SEI
    
;set up PPU ctrl reg #1
    LDA #$10
    STA $2000;	[NES] PPU setup	#1
    STA $FF
    
;clear decimal flag (in case this code is executed on a CPU with dec. mode)
    CLD
    
;set up PPU ctrl reg #2 (disable playfield & objects)
    LDA #$06
    STA $FE
    STA $2001;	[NES] PPU setup	#2
    
;wait at least 1 frame
    LDX #$02;	loop count = 2 iterations
_EE36:
    LDA $2002;	[NES] PPU status
    BPL _EE36;	branch if VBL has not been reached
    DEX
    BNE _EE36;	exit loop when X = 0
    
    STX $4022;	disable timer interrupt
    STX $4023;	disable sound &	disk I/O
    LDA #$83
    STA $4023;	enable sound & disk I/O
    STX $FD
    STX $FC
    STX $FB
    STX $4016;	[NES] Joypad & I/O port for port #1
    LDA #$2e
    STA $FA
    STA $4025
    LDA #$ff
    STA $F9
    STA $4026
    STX $4010;	[NES] Audio - DPCM control
    LDA #$c0
    STA $4017;	[NES] Joypad & I/O port for port #2
    LDA #$0f
    STA $4015;	[NES] IRQ status / Sound enable
    LDA #$80
    STA $4080
    LDA #$e8
    STA $408A
    LDX #$ff;	set up stack
    TXS
    LDA #$c0
    STA $0100
    LDA #$80
    STA $0101

    LDA $0102
    CMP #$35
    BNE _EEA2 
    LDA $0103
    CMP #$53
    BEQ _EE9B
    CMP #$ac
    BNE _EEA2
    LDA #$53
    STA $0103
_EE9B:
    JSR RstPPU05
    CLI;	enable interrupts
    JMP ($DFFC)
    
;for I:=$F8 downto $01 do [I]:=$00
_EEA2:
    LDA #$00
    LDX #$f8
_EEA6:
    STA $00,X
    DEX
    BNE _EEA6

RstPPU05:
    LDA $2002;	reset scroll register flip-flop
    LDA $FD
    STA $2005;	[NES] PPU scroll
    LDA $FC
    STA $2005;	[NES] PPU scroll
    LDA $FF
    STA $2000;	[NES] PPU setup	#1
    RTS

.segment "VECTORS"
    
.word  nmi, rst, irq
