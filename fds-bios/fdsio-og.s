    
.segment "CODE"
    
.byte $00
;FONT BITMAPS

.byte $38,$4C,$C6,$C6,$C6,$64,$38,$00,$18,$38,$18,$18,$18,$18,$7E,$00
.byte $7C,$C6,$0E,$3C,$78,$E0,$FE,$00,$7E,$0C,$18,$3C,$06,$C6,$7C,$00
.byte $1C,$3C,$6C,$CC,$FE,$0C,$0C,$00,$FC,$C0,$FC,$06,$06,$C6,$7C,$00
.byte $3C,$60,$C0,$FC,$C6,$C6,$7C,$00,$FE,$C6,$0C,$18,$30,$30,$30,$00
.byte $7C,$C6,$C6,$7C,$C6,$C6,$7C,$00,$7C,$C6,$C6,$7E,$06,$0C,$78,$00
.byte $38,$6C,$C6,$C6,$FE,$C6,$C6,$00,$FC,$C6,$C6,$FC,$C6,$C6,$FC,$00
.byte $3C,$66,$C0,$C0,$C0,$66,$3C,$00,$F8,$CC,$C6,$C6,$C6,$CC,$F8,$00
.byte $FE,$C0,$C0,$FC,$C0,$C0,$FE,$00,$FE,$C0,$C0,$FC,$C0,$C0,$C0,$00
.byte $3E,$60,$C0,$DE,$C6,$66,$7E,$00,$C6,$C6,$C6,$FE,$C6,$C6,$C6,$00
.byte $7E,$18,$18,$18,$18,$18,$7E,$00,$1E,$06,$06,$06,$C6,$C6,$7C,$00
.byte $C6,$CC,$D8,$F0,$F8,$DC,$CE,$00,$60,$60,$60,$60,$60,$60,$7E,$00
.byte $C6,$EE,$FE,$FE,$D6,$C6,$C6,$00,$C6,$E6,$F6,$FE,$DE,$CE,$C6,$00
.byte $7C,$C6,$C6,$C6,$C6,$C6,$7C,$00,$FC,$C6,$C6,$C6,$FC,$C0,$C0,$00
.byte $7C,$C6,$C6,$C6,$DE,$CC,$7A,$00,$FC,$C6,$C6,$CE,$F8,$DC,$CE,$00
.byte $78,$CC,$C0,$7C,$06,$C6,$7C,$00,$7E,$18,$18,$18,$18,$18,$18,$00
.byte $C6,$C6,$C6,$C6,$C6,$C6,$7C,$00,$C6,$C6,$C6,$EE,$7C,$38,$10,$00
.byte $C6,$C6,$D6,$FE,$FE,$EE,$C6,$00,$C6,$EE,$7C,$38,$7C,$EE,$C6,$00
.byte $66,$66,$66,$3C,$18,$18,$18,$00,$FE,$0E,$1C,$38,$70,$E0,$FE,$00
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$30,$30,$20,$00
.byte $00,$00,$00,$00,$30,$30,$00,$00,$00,$00,$00,$00,$6C,$6C,$08,$00
.byte $38,$44,$BA,$AA,$B2,$AA,$44,$38
    
;131 clock cycle delay
Delay131:
    PHA
    LDA #$16
    SEC
_E14D:
    SBC #$01
    BCS _E14D
    PLA
    RTS
    
;millisecond delay timer. Delay	in clock cycles	is: 1790*Y+5.
MilSecTimer:
    LDX $00
    ;rts
    ;nop

    LDX #$fe
_E157:
    NOP
    DEX
    BNE _E157
    CMP $00
    DEY
    BNE MilSecTimer
    RTS
    
;disable playfield & objects
DisPfOBJ:
    LDA $FE
    AND #$e7
_E165:
    STA $FE
    STA $2001;	[NES] PPU setup	#2
    RTS
    
;enable playfield & objects
EnPfOBJ:
    LDA $FE
    ORA #$18
    BNE _E165
    
;disable objects
DisOBJs:
    LDA $FE
    AND #$ef
    JMP $E165
    
;enable objects
EnOBJs:
    LDA $FE
    ORA #$10
    BNE _E165
    
;disable playfield
DisPF:
    LDA $FE
    AND #$f7
    JMP $E165
    
;enable playfield
EnPF:
    LDA $FE
    ORA #$08
    BNE _E165
    
    
;????????????????????????????????????????????????????????????????????????????
;NMI program control?????????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;this routine controls what action occurs on a NMI, based on [$0100].
    
;[$0100]	program control	on NMI
;-------	----------------------
;00xxxxxx:	VINTwait was called; return PC to address that called VINTwait
;01xxxxxx:	use [$DFF6] vector
;10xxxxxx:	use [$DFF8] vector
;11xxxxxx:	use [$DFFA] vector
    
    
;NMI branch target
NMI:
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
    
    
;----------------------------------------------------------------------------
;wait for VINT
VINTwait:
    PHA;	save A
    LDA $0100
    PHA;	save old NMI pgm ctrl byte
    LDA #$00
    STA $0100;	set NMI pgm ctrl byte to 0
    
;enable VINT
    LDA $FF
    ORA #$80
    STA $FF
    STA $2000;	[NES] PPU setup	#1
    
;infinite loop
_E1C5:
    BNE _E1C5
    
    
;????????????????????????????????????????????????????????????????????????????
;IRQ program control?????????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;this routine controls what action occurs on a IRQ, based on [$0101].
IRQ:
    BIT $0101
    BMI _E1EA
    BVC _E1D9
    
;disk transfer routine ([$0101]	= 01xxxxxx)
    jmp disk_rw_og ;STA $4024
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
    JSR Delay131
    PLA
    RTI
    
    
;????????????????????????????????????????????????????????????????????????????
;load files??????????????????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;loads files from disk into memory.
    
;params
;------
;RETaddr	pointer to 10-byte disk header compare string
;RETaddr+2	pointer to list	of files to identify & load
    
    
;the disk header compare string	is compared against the first 10 bytes to
;come after the	'*NINTENDO-HVC*' string in the first block. if any matches
;fail, an error	is generated. If the compare string has a -1 in	it, that
;skips the testing of that particular byte. Generally, this string is used to
;verify that the disk side and number data of a	disk is corect.
    
;the file ID list is simply a list of files to be loaded from disk. These
;ID numbers (1 byte each) are tested against the file ID numbers of the
;individual files on disk, and matched file IDs	results in that	particular
;file being loaded into memory.	The list is assumed to contain 20 ID's, but
;-1 can be placed at the end of	the string to terminate the search
;prematurely. If -1 is the first ID in the string, this means that a system
;boot is to commence. Boot files are loaded via	the BootID code	in the first
;block of the disk. Files that match or are less than this BootID code are
;the ones that get loaded. Everytime a matching	file is found, a counter is
;incremented. When the load finishes, this count will indicate how many files
;were found. No	error checking occurs with the found file count.
    
;if an error occurs on the first try, the subroutine will make an additional
;attempt to read the disk, before returning with an error code other than 0.
    
    
;returns error # (if any) in A,	and count of found files in Y.
    
    
LoadFiles:
    LDA #$00
    STA $0E
    LDA #$ff;	get 2 16-bit pointers
    JSR GetHCPwNWPchk
    LDA $0101
    PHA
    LDA #$02;	error retry count
    STA $05
_E209:
    JSR _E21A 
    BEQ _E212;	return address if errors occur
    DEC $05;	decrease retry count
    BNE _E209
_E212:
    PLA
    STA $0101
    LDY $0E
    TXA
    RTS
    
_E21A:
    JSR ChkDiskHdr
    JSR Get_ofFiles;returns # in [$06]
    LDA $06
    BEQ _E233;	skip it all if none
_E224:
    LDA #$03
    JSR CheckBlkType
    JSR FileMatchTest
    JSR LoadData
    DEC $06
    BNE _E224
_E233:
    JSR XferDone
    RTS
    
    
;????????????????????????????????????????????????????????????????????????????
;Write file & set file count?????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;writes a single file to the last position on the disk, according to the
;disk's file count. uses header compare string, and pointer to file header
;structure (described in SaveData subroutine).
    
;this is the only mechanism the	ROM BIOS provides for writing data to the
;disk, and it only lets you write one stinking file at a time! if that isn't
;enough, the disk's file count is modified everytime this routine is called
;so that the disk logically ends after the written file.
    
;logic:
    
;- if (WriteFile called) and (A	<> -1), DiskFileCount := A
;- disk is advanced to the end,	in accordance to DiskFileCount
;- writes data pointed to by RETaddr+2 to end of disk
;- DiskFileCount is increased
;- data is read	back, and compared against data	written
;- if error occurs (like the comparison fails),	DiskFileCount is decreased
    
;note that DiskFileCount is the	actual recorded	file count on the disk.
    
    
;load hardcoded	parameters
AppendFile:
    LDA #$ff;	use current DiskFileCount
WriteFile:
    STA $0E;	specify file count in A
    LDA #$ff
    JSR GetHCPwWPchk;loads Y with [$0E] on error
    LDA $0101
    PHA
    
;write data to end of disk
    LDA #$03;	2 tries
    STA $05
_E248:
    DEC $05
    BEQ _E265
    JSR WriteLastFile
    BNE _E248
    
;verify data at	end of disk
    LDA #$02
    STA $05
_E255:
    JSR CheckLastFile
    BEQ _E265
    DEC $05
    BNE _E255
    
;if error occured during readback, hide last file
    STX $05;	save error #
    JSR SetFileCnt
    LDX $05;	restore error #
    
;return
_E265:
    PLA
    STA $0101
    TXA
    RTS
    
WriteLastFile:
    JSR ChkDiskHdr 
    LDA $0E
    CMP #$ff
    BNE _E288
    JSR Get_ofFiles
    JSR SkipFiles;	advance to end of disk
    LDA #$03
    JSR WriteBlkType
    LDA #$00
    JSR SaveData;	write out last file
    JSR XferDone
    RTS
_E288:
    STA $06
    JSR Set_ofFiles
    JMP $E277
    
CheckLastFile:
    JSR ChkDiskHdr
    LDX $06;	load current file count
    INX
    TXA
    JSR Set_ofFiles;increase current file count
    JSR SkipFiles;	skip to last file
    LDA #$03
    JSR CheckBlkType
    LDA #$ff
    JSR SaveData;	verify last file
    JSR XferDone
    RTS
    
;sets file count via [$06]
SetFileCnt:
    JSR ChkDiskHdr
    LDA $06
    JSR Set_ofFiles
    JSR XferDone
    RTS
    
    
;????????????????????????????????????????????????????????????????????????????
;adjust file count???????????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;reads disk's original file count, then subtracts the A value from it and
;writes the difference to the disk as the new file count. uses header compare
;string. if A is greater than original disk file count, error 31 is returned.
    
;this routine has 2 entry points. one which adjusts the current	file count
;via A, and one	which simply sets the file count to the A value. Since this
;routine makes a disk read cycle no matter which entry point is	called, it is
;better to use SetFileCnt0/1 to	simply set the disk file count to A.
    
SetFileCnt2:
    LDX #$ff;	use A value
    BNE _E2BD
AdjFileCnt:
    LDX #$00;	use FileCnt-A
_E2BD:
    STX $09
    JSR GetHCPwWPchk
    LDA $0101
    PHA
    
;get disk file count
    LDA #$03;	2 tries
    STA $05
_E2CA:
    DEC $05
    BEQ _E2F1
    JSR GetFileCnt
    BNE _E2CA
    
;calculate difference
    LDA $06;	load file count
    SEC
    SBC $02;	calculate difference
    LDX $09
    BEQ _E2DE
    LDA $02;	use original accumulator value
_E2DE:
    LDX #$31;
    BCC _E2F1;	branch if A is less than current file count
    STA $06
    
;set disk file count
    LDA #$02;	2 tries
    STA $05
_E2E8:
    JSR SetFileCnt
    BEQ _E2F1
    DEC $05
    BNE _E2E8
    
_E2F1:
    PLA
    STA $0101
    TXA
    RTS
    
;stores file count in [$06]
GetFileCnt:
    JSR ChkDiskHdr
    JSR Get_ofFiles
    JSR XferDone
    RTS
    
    
;????????????????????????????????????????????????????????????????????????????
;set disk file count?????????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;this routine only rewrites a disk's file count (stored in block 2; specified
;in A). no other files are read/written after this. uses header	compare
;string.
    
SetFileCnt1:
    LDX #$01;	add 1 to value in A
    BNE _E307
SetFileCnt0:
    LDX #$00;	normal entry point
_E307:
    STX $07
    JSR GetHCPwWPchk
    LDA $0101
    PHA
    CLC
    LDA $02;	initial A value	(or 3rd byte in	HC parameter)
    ADC $07
    STA $06
    LDA #$02;	2 tries
    STA $05
_E31B:
    JSR SetFileCnt
    BEQ _E324
    DEC $05
    BNE _E31B
_E324:
    PLA
    STA $0101
    TXA
    RTS
    
    
;????????????????????????????????????????????????????????????????????????????
;get disk information????????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;this procedure	reads the whole	disk, and only returns information like
;disk size, filenames, etc.
    
;params
;------
;RETaddr	pointer to destination address for info. to collect
    
    
;info. format
;------------
;0	1	manufacturer code
;1	4	game name string
;5	1	game version
;6	1	disk side #
;7	1	disk #1
;8	1	disk #2
;9	1	disk #3
;A	1	# of files on disk
    
; (the following block will appear for as many files as the files on disk
; byte indicates)
    
;B	1	file ID code
;C	8	file name (ASCII)
    
; (the following is present after the last file	info block)
    
;x	1	disk size high byte
;x+1	1	disk size low  byte
    
    
;returns error # (if any) in A.
    
GetDiskInfo:
    LDA #$00
    JSR GetHCPwNWPchk;get 1 16-bit pointer; put A in [$02]
    LDA $0101
    PHA
    LDA #$02
    STA $05
_E337:
    JSR _E346
    BEQ _E340;	escape if no errors
    DEC $05
    BNE _E337
_E340:
    PLA
    STA $0101
    TXA
    RTS
    
;start up disk read process
_E346:
    JSR StartXfer;	verify FDS string at beginning of disk
    LDA $00
    STA $0A
    LDA $01
    STA $0B
    LDY #$00
    STY $02
    STY $03
    
;load next 10 bytes off disk into RAM at Ptr($0A)
_E357:
    JSR XferByte
    STA ($0A),Y
    INY
    CPY #$0a
    BNE _E357
    JSR AddYtoPtr0A;add 10 to Word($0A)
    
;discard rest of data in this file (31 bytes)
    LDY #$1f
_E366:
    JSR XferByte
    DEY
    BNE _E366
    
;get # of files
    JSR EndOfBlkRead
    JSR Get_ofFiles;stores it in [$06]
    LDY #$00
    LDA $06
    STA ($0A),Y;	store # of files in ([$0A])
    BEQ _E3CB;	branch if # of files = 0
    
;get info for next file
_E37A:
    LDA #$03
    JSR CheckBlkType
    JSR XferByte;	discard file sequence #
    JSR XferByte;	file ID code
    LDY #$01
    STA ($0A),Y;	store file ID code
    
;store file name string (8 letters)
_E389:
    INY
    JSR XferByte
    STA ($0A),Y
    CPY #$09
    BNE _E389
    
    JSR AddYtoPtr0A;advance 16-bit dest ptr
    JSR XferByte;	throw away low	load address
    JSR XferByte;	throw away high	load address
    
;Word($02) += $105 + FileSize
    CLC
    LDA #$05
    ADC $02
    STA $02
    LDA #$01
    ADC $03
    STA $03
    JSR XferByte;	get low  FileSize
    STA $0C
    JSR XferByte;	get high FileSize
    STA $0D
    CLC
    LDA $0C
    ADC $02
    STA $02
    LDA $0D
    ADC $03
    STA $03
    LDA #$ff
    STA $09
    JSR RdData;	dummy read data	off disk
    DEC $06;	decrease file count #
    BNE _E37A
    
;store out disk	size
_E3CB:
    LDA $03
    LDY #$01;	fix-up from RdData
    STA ($0A),Y
    LDA $02
    INY
    STA ($0A),Y
    JSR XferDone
    RTS
    
;adds Y to Word(0A)
AddYtoPtr0A:
    TYA
    CLC
    ADC $0A
    STA $0A
    LDA #$00
    ADC $0B
    STA $0B
    RTS
    
    
;????????????????????????????????????????????????????????????????????????????
;get hard-coded	pointer(s)???????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;this routine does 3 things. First, it fetches 1 or 2 hardcoded	16-bit
;pointers that follow the second return address. second, it checks the
;disk set or even write-protect	status of the disk, and if the checks fail,
;the first return address on the stack is discarded, and program control is
;returned to the second return address. finally, it saves the position of
;the stack so that when an error occurs, program control will be returned to
;the same place.
    
;params
;------
;2nd call addr	1 or 2 16-bit pointers
    
;A	-1	2 16-bit pointers are present
;	other values	1 16-bit pointer present
    
    
;rtns (no error)
;---------------
;PC	original call address
    
;A	00
    
;[$00]	where parameters were loaded (A	is placed in [$02] if not -1)
    
    
;(error)
;-------
;PC	second call address
    
;Y	byte stored in [$0E]
    
;A	01	if disk wasn't set
;	03	if disk is write-protected
    
    
;entry points
GetHCPwNWPchk:
    SEC;	don't do write-protect check
    BCS _E3EB
GetHCPwWPchk:
    CLC;	check for write	protection
    
;load 2nd return address into Ptr($05)
_E3EB:
    TSX
    DEX
    STX $04;	store stack pointer-1 in [$04]
    PHP
    STA $02
    LDY $0104,X
    STY $05
    LDY $0105,X
    STY $06
    
;load 1st 16-bit parameter into	Ptr($00)
    TAX
    LDY #$01
    LDA ($05),Y
    STA $00
    INY
    LDA ($05),Y
    STA $01
    LDA #$02
    
;load 2nd 16-bit parameter into	Ptr($02) if A was originally -1
    CPX #$ff
    BNE _E41A
    INY
    LDA ($05),Y
    STA $02
    INY
    LDA ($05),Y
    STA $03
    LDA #$04
    
;increment 2nd return address appropriately
_E41A:
    LDX $04
    CLC
    ADC $05
    STA $0104,X
    LDA #$00
    ADC $06
    STA $0105,X
    
;test disk set status flag
    PLP
    LDX #$01;	disk set error
    LDA $4032
    AND #$01
    BNE _E43E
    BCS _E444;	skip write-protect check
    
;test write-protect status
    LDX #$03;	write-protect error
    LDA $4032
    AND #$04
    BEQ _E444
    
;discard return	address if tests fail
_E43E:
    PLA
    PLA
    LDY $0E
    TXA
    CLI
_E444:
    RTS
    
    
;????????????????????????????????????????????????????????????????????????????
;disk header check???????????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;routine simply	compares the first 10 bytes on the disk coming after the FDS
;string, to 10 bytes pointed to	by Ptr($00). To	bypass the checking of any
;byte, a -1 can	be placed in the equivelant place in the compare string.
;Otherwise, if the comparison fails, an appropriate error will be generated.
    
ChkDiskHdr:
    JSR StartXfer;	check FDS string
    LDX #$04
    STX $08
    LDY #$00
_E44E:
    JSR XferByte
    CMP ($00),Y;	compares code to byte stored at	[Ptr($00)+Y]
    BEQ _E464
    LDX $08
    CPX #$0a
    BNE _E45D
    LDX #$10
_E45D:
    LDA ($00),Y
    CMP #$ff
    JSR XferFailOnNEQ
_E464:
    INY
    CPY #$01
    BEQ _E46D
    CPY #$05
    BCC _E46F
_E46D:
    INC $08
_E46F:
    CPY #$0a
    BNE _E44E
    JSR XferByte;	boot read file code
    STA $08
    LDY #$1e;	30 iterations
_E47A:
    JSR XferByte;	dummy read 'til end of block
    DEY
    BNE _E47A
    JSR EndOfBlkRead
    RTS
    
    
;????????????????????????????????????????????????????????????????????????????
;file count block routines???????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;these routines	specifically handle reading & writing of the file count block
;stored on FDS disks.
    
;loads # of files recorded in block type #2 into [$06]
Get_ofFiles:
    LDA #$02
    JSR CheckBlkType
    JSR XferByte
    STA $06
    JSR EndOfBlkRead
    RTS
    
;writes # of files (via A) to be recorded on disk.
Set_ofFiles:
    PHA
    LDA #$02
    JSR WriteBlkType
    PLA
    JSR XferByte;	write out disk file count
    JSR EndOfBlkWrite
    RTS
    
    
;????????????????????????????????????????????????????????????????????????????
;file match test?????????????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;this routine uses a byte string pointed at by Ptr($02) to tell	the disk
;system which files to load. The file ID's number is searched for in the
;string. if an exact match is found, [$09] is 0'd, and [$0E] is incremented.
;if no matches are found after 20 bytes, or a -1 entry is encountered, [$09]
;is set to -1. if the first byte in the string is -1, the BootID number is
;used for matching files (any FileID that is not greater than the BootID
;qualifies as a	match).
    
;logic:
    
;if String[0] =	-1 then
;  if FileID <=	BootID then
;    [$09]:=$00
;    Inc([$0E])
    
;else
;  I:=0
;  while (String[I]<>FileID) or	(String[I]<>-1)	or (I<20) do Inc(I)
    
;  if String[I]	= FileID then
;    [$09]:=$00
;    Inc([$0E])
    
;  else
;    [$09]:=$FF;
    
FileMatchTest:
    JSR XferByte;	file sequence #
    JSR XferByte;	file ID # (gets	loaded into X)
    LDA #$08;	set IRQ mode to	skip next 8 bytes
    STA $0101
    CLI
    LDY #$00
    LDA ($02),Y
    CMP #$ff;	if Ptr($02) = -1 then test boot	ID code
    BEQ _E4C8
    
_E4B4:
    TXA;	file ID #
    CMP ($02),Y
    BEQ _E4CE
    INY
    CPY #$14
    BEQ _E4C4
    LDA ($02),Y
    CMP #$ff
    BNE _E4B4
    
_E4C4:
    LDA #$ff
    BNE _E4D2
_E4C8:
    CPX $08;	compare boot read file code to current
    BEQ _E4CE
    BCS _E4D2;	branch if above	(or equal, but isn't possible)
_E4CE:
    LDA #$00
    INC $0E
_E4D2:
    STA $09
_E4D4:
    LDA $0101
    BNE _E4D4;	wait until all 8 bytes have been read
    RTS
    
    
;????????????????????????????????????????????????????????????????????????????
;skip files??????????????????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;this routine uses the value stored in [$06] to	determine how many files to
;dummy-read (skip over) from the current file position.
    
SkipFiles:
    LDA $06
    STA $08
    BEQ _E4F8;	branch if file count = 0
_E4E0:
    LDA #$03
    JSR CheckBlkType
    LDY #$0a;	skip 10 bytes
_E4E7:
    JSR XferByte
    DEY
    BNE _E4E7
    LDA #$ff
    STA $09
    JSR LoadData;	dummy read file	data
    DEC $08
    BNE _E4E0
_E4F8:
    RTS
    
    
;????????????????????????????????????????????????????????????????????????????
;load file off disk into memory??????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;loads data from current file off disk into a destination address specified
;by the file's header information stored on disk.
    
;params
;------
;[$09]:	dummy read only	(if not zero)
    
    
LoadData:
    LDY #$00
_E4FB:
    JSR Xfer1stByte
    STA $000A,Y
    INY
    CPY #$04
    BNE _E4FB
    
;Ptr($0A):	destination address
;Ptr($0C):	byte xfer count
    
RdData:
    JSR DecPtr0C
    JSR XferByte;	get kind of file
    PHA
    JSR EndOfBlkRead
    LDA #$04
    JSR CheckBlkType
    LDY $09
    PLA
    BNE _E549;	copy to VRAM if	not zero
    
    CLC
    LDA $0A
    ADC $0C
    LDA $0B
    ADC $0D
    BCS _E531;	branch if (DestAddr+XferCnt)<10000h
    
;if DestAddr < 0200h then do dummy copying
    LDA $0B
    CMP #$20
    BCS _E533;	branch if DestAddr >= 2000h
    AND #$07
    CMP #$02
    BCS _E533;	branch if DestAddr >= 0200h
_E531:
    LDY #$ff
    
_E533:
    JSR XferByte
    CPY #$00
    BNE _E542
    STA ($0A),Y
    INC $0A
    BNE _E542
    INC $0B
_E542:
    JSR DecPtr0C
    BCS _E533
    BCC _E572
    
;VRAM data copy
_E549:
    CPY #$00
    BNE _E563
    LDA $FE
    AND #$e7
    STA $FE
    STA $2001;	[NES] PPU setup	#2
    LDA $2002;	[NES] PPU status
    LDA $0B
    STA $2006;	[NES] VRAM address select
    LDA $0A
    STA $2006;	[NES] VRAM address select
    
_E563:
    JSR XferByte
    CPY #$00
    BNE _E56D
    STA $2007;	[NES] VRAM data
_E56D:
    JSR DecPtr0C
    BCS _E563
    
_E572:
    LDA $09
    BNE _E57A
    JSR EndOfBlkRead
    RTS
_E57A:
    ;JSR XferByte
    ;JSR XferByte
    nop
    nop
    nop
    nop
    nop
    nop
    JMP ChkDiskSet
    
    
;????????????????????????????????????????????????????????????????????????????
;load size & source address operands into $0A..$0D???????????????????????????
;????????????????????????????????????????????????????????????????????????????
;this routine is used only for when writing/verifying file data	on disk. it
;uses the data string at Ptr($02) to load size and source address operands
;into Ptr($0C) and Ptr($0A), respectfully. It also checks if the source
;address is from video memory, and programs the	PPU address register if so.
    
;load size of file via string offset $0B into Word($0C)
LoadSiz_Src:
    LDY #$0b
    LDA ($02),Y;	file size LO
    STA $0C
    INY
    LDA ($02),Y;	file size HI
    STA $0D
    
;load source address via string	offset $0E into	Ptr($0A)
    LDY #$0e
    LDA ($02),Y;	source address LO
    STA $0A
    INY
    LDA ($02),Y;	source address HI
    STA $0B
    
;load source type byte (anything other than 0 means use PPU memory)
    INY
    LDA ($02),Y
    BEQ _E5B1
    
;program PPU address registers with source address
    JSR DisPfOBJ
    LDA $2002;	reset flip-flop
    LDA $0B
    STA $2006;	store HI address
    LDA $0A
    STA $2006;	store LO address
    LDA $2007;	discard first read
_E5B1:
    JSR DecPtr0C;	adjust transfer	count for range	(0..n-1)
    RTS
    
    
;????????????????????????????????????????????????????????????????????????????
;save data in memory to file on	disk?????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;this routine does 2 things, which involve working with file data. if called
;with A set to 0, file data is written to disk from memory. if called with
;A <> 0, file data on disk is verified (compared to data in memory). Ptr($02)
;contains the address to a 17-byte structure described below. Note that the
;disk transfer direction bit ($4025.2) must be set in sync with	A, since this
;routine will not modify it automatically.
    
;00 1	ID
;01 8	Name
;09 2	load address
;0B 2	Size
;0D 1	type (0 = CPU data)
;0E 2	source address of file data (NOT written to disk)
;10 1	source address type (0 = CPU; NOT written to disk)
;11
    
;the first 14 bytes of the structure are used directly as the file header
;data. the file	sequence # part	of the file header is specified	seperately
;(in [$06]). Data at offset 0E and on is not used as file header data.
    
;offset 0E of the structure specifies the address in memory which the actual
;file data resides. offset 10 specifies the source memory type (0 = CPU;
;other = PPU).
    
    
;entry point
SaveData:
    STA $09;	value of A is stored in [$09]
    LDA $06;	load current file #
    JSR XferByte;	write out file sequence # (from	[$06])
    LDX $09
    BEQ _E5C7;	[$09] should be	set to jump when writing
    LDX #$26;	error #
    CMP $06;	cmp. recorded sequence # to what it should be
    JSR XferFailOnNEQ
    
;loop to write/check entire file header block (minus the file sequence #)
_E5C7:
    LDY #$00
_E5C9:
    LDA ($02),Y;	load header byte
    JSR XferByte;	write it out (or read it in)
    LDX $09
    BEQ _E5D9;	jump around check if writing data to disk
    LDX #$26;	error #
    CMP ($02),Y;	cmp. recorded header byte to what it should be
    JSR XferFailOnNEQ
_E5D9:
    INY;	advance pointer	position
    CPY #$0e;	loop is finished if 14 bytes have been checked
    BNE _E5C9
    
;set up next block for reading
    LDX $09
    BEQ _E616;	branch if writing instead
    JSR EndOfBlkRead
    JSR LoadSiz_Src;sets up Ptr($0A) & Ptr($0C)
    LDA #$04
    JSR CheckBlkType
    
;check source type and read/verify status
    LDY #$10
    LDA ($02),Y;	check data source type bit
    BNE _E624;	branch if NOT in CPU memory map	(PPU instead)
    LDY #$00
    LDX $09;	check if reading or writing
    BEQ _E60A;	branch if writing
    
;check data on disk
_E5F9:
    JSR XferByte
    LDX #$26
    CMP ($0A),Y
    JSR XferFailOnNEQ
    JSR inc0Adec0C
    BCS _E5F9
    BCC _E638
    
;write data to disk
_E60A:
    LDA ($0A),Y
    JSR XferByte
    JSR inc0Adec0C
    BCS _E60A
    BCC _E638
    
;set up next block for writing
_E616:
    JSR EndOfBlkWrite
    JSR LoadSiz_Src;sets up Ptr($0A) & Ptr($0C)
    LDA #$04
    JSR WriteBlkType
    JMP $E5ED
    
;verify data on	disk with VRAM
_E624:
    LDX $09
    BEQ _E640
    JSR XferByte
    LDX #$26;	error #
    CMP $2007
    JSR XferFailOnNEQ
    JSR DecPtr0C
    BCS _E624
    
;end block reading
_E638:
    LDX $09
    BEQ _E649;	branch if writing instead
    JSR EndOfBlkRead
    RTS
    
;write data from VRAM to disk
_E640:
    LDA $2007;	[NES] VRAM data
    JSR XferByte
    JMP $E633
    
;end block writing
_E649:
    JSR EndOfBlkWrite
    RTS
    
    
;????????????????????????????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;waits until drive is ready (i.e., the disk head is at the start of the disk)
WaitForRdy:
    JSR StopMotor
    LDY #$00
    JSR MilSecTimer;0.256 sec delay rem!
    JSR MilSecTimer;0.256 sec delay rem!
    JSR StartMotor
    LDY #$96
    JSR MilSecTimer;0.150 sec delay rem!
    LDA $F9
    ORA #$80;	enable battery checking
    STA $F9
    STA $4026
    LDX #$02;	battery error
    EOR $4033
    ROL A
    JSR XferFailOnCy
    JSR StopMotor
    JSR StartMotor
_E678:
    LDX #$01;	disk set error
    LDA $4032
    LSR A;	check disk set bit
    JSR XferFailOnCy
    LSR A;	check ready bit
    BCS _E678;	wait for drive to become ready
    RTS
    
;stop disk drive motor
StopMotor:
    LDA $FA
    AND #$08
    ORA #$26
    STA $4025
    RTS
    
;verifies that first byte in file is equal to value in accumulator
CheckBlkType:
    LDY #$05
    JSR MilSecTimer;0.005 sec delay
    STA $07
    CLC
    ADC #$21;	error # = 21h +	failed block type (1..4)
    TAY
    LDA $FA
    ORA #$40
    STA $FA
    STA $4025
    JSR Xfer1stByte
    PHA
    TYA
    TAX
    PLA
    CMP $07
    JSR XferFailOnNEQ
    RTS
    
;writes out block start mark, plus byte in accumulator
WriteBlkType:
    LDY #$0a
    STA $07
    LDA $FA
    AND #$2b;	set xfer direction to write
    STA $4025
    ;JSR MilSecTimer;0.010 sec delay
    nop
    nop
    nop
    LDY #$00
    STY $4024;	zero out write register
    ORA #$40;	tell FDS to write data to disk NOW
    STA $FA
    STA $4025
    ;LDA #$80
    LDA $07
    JSR Xfer1stByte;write out block	start mark
    ;LDA $07
    nop
    nop
    ;JSR XferByte;	write out block	type
    nop
    nop
    nop
    RTS
    
;FDS string
FDSstr:
.byte  "*CVH-ODNETNIN*"
    
;starts transfer
StartXfer:
    JSR WaitForRdy
    LDY #$c5
    ;JSR MilSecTimer;0.197 sec delay
    nop
    nop
    nop
    LDY #$46
    ;JSR MilSecTimer;0.070 sec delay
    nop
    nop
    nop
    LDA #$01
    JSR CheckBlkType
    LDY #$0d
_E6F7:
    JSR XferByte
    LDX #$21;	error 21h if FDS string failed comparison
    CMP FDSstr,Y
    JSR XferFailOnNEQ
    DEY
    BPL _E6F7
    RTS
    
;checks the CRC	OK bit at the end of a block
EndOfBlkRead:
    ;JSR XferByte;	first CRC byte
    nop
    nop
    nop
    LDX #$28;	premature file end error #
    LDA $4030
    AND #$40;	check "end of disk" status
    BNE XferFail
    LDA $FA
    ORA #$10;	set while processing block end mark (CRC)
    STA $FA
    STA $4025
    ;JSR XferByte;	second CRC byte
    nop
    nop
    nop
    LDX #$27;	CRC fail error #
    LDA $4030
    AND #$10;	test CRC bit
    BNE XferFail
    BEQ ChkDiskSet
    
;takes care of writing CRC value out to block being written
EndOfBlkWrite:
    ;JSR XferByte
    ;LDX #$29
    ;LDA $4030
    ;AND #$40
    ;BNE XferFail
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    LDA $FA
    ORA #$10;	causes FDS to write out CRC immediately
    STA $FA;	following completion of pending	byte write
    STA $4025
    LDX #$b2;	0.0005 second delay (to allow adaptor pleanty
_E740:
    DEX;	of time to write out entire CRC)
    BNE _E740
    LDX #$30
    LDA $4032
    AND #$02
    BNE XferFail
    
;disables disk transfer interrupts & checks disk set status
ChkDiskSet:
    LDA $FA
    AND #$2f
    ORA #$04
    STA $FA
    STA $4025
    LDX #$01;	disk set error #
    LDA $4032
    LSR A
    JSR XferFailOnCy
    RTS
    
;reads in CRC value at end of block into Ptr($0A)+Y. Note that this
;subroutine is not used by any other disk routines.
ReadCRC:
    JSR XferByte
    STA ($0A),Y
    LDX #$28
    LDA $4030
    AND #$40
    BNE XferFail
    INY
    JSR XferByte
    STA ($0A),Y
    JMP ChkDiskSet
    
;dispatched when transfer is to	be terminated. returns error # in A.
XferDone:
    LDX #$00;	no error
    BEQ _E786
XferFailOnCy:
    BCS XferFail
_E77E:
    RTS
XferFailOnNEQ:
    BEQ _E77E
XferFail:
    TXA
    LDX $04
    TXS;	restore PC to original caller's address
    TAX
_E786:
    LDA $FA
    AND #$09
    ORA #$26
    STA $FA
    STA $4025
    TXA
    CLI
    RTS
    
;the main interface for data exchanges between the disk drive &	the system.
Xfer1stByte:
    LDX #$40
    STX $0101
    ROL $FA
    SEC
    ROR $FA
    LDX $FA
    STX $4025
XferByte:
    CLI
    JMP $E7A4
    
;routine for incrementing 16-bit pointers in the zero-page
inc0Adec0C:
    INC $0A
    BNE DecPtr0C
    INC $0B
DecPtr0C:
    SEC
    LDA $0C
    SBC #$01
    STA $0C
    LDA $0D
    SBC #$00
    STA $0D
    RTS
    
    
;????????????????????????????????????????????????????????????????????????????
;PPU data processor??????????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;this routine treats a string of bytes as custom instructions. These strings
;are stored in a mannar similar	to regular CPU instructions, in	that the
;instructions are stored & processed sequentially, and instruction length is
;dynamic. The instructions haved been designed to allow easy filling/copying
;of data to random places in the PPU memory map. Full random access to PPU
;memory is supported, and it is	even possible to call subroutines. All data
;written to PPU	memory is stored in the actual instructions (up	to 64
;sequential bytes of data can be stored in 1 instruction).
    
;the 16-bit immediate which follows the 'JSR PPUdataPrsr' opcode is a pointer
;to the first PPU data string to be processed.
    
;the PPU data processor's opcodes are layed out as follows.
    
    
;+---------------+
;|special opcodes|
;+---------------+
; $4C:	call subroutine. 16-bit call address follows. This opcode is
;	the equivelant of a 'JMP $xxxx'	6502 mnemonic.
    
; $60:	end subroutine.	returns to the instruction after the call.
;	This opcode is the equivelant of a 'RTS' 6502 mnemonic.
    
; $80..$FF:	end program. processing will not stop until this opcode is
;	encountered.
    
    
;+---------------------------------+
;|move/fill data instruction format|
;+---------------------------------+
    
; byte 0
; ------
;  high byte of	destination PPU	address. cannot	be equal to $60, $4C or
;  greater than	$7F.
    
; byte 1
; ------
;  low byte of destination PPU address.
    
; byte 2 bit description
; ----------------------
;  7:	 increment PPU address by 1/32 (0/1)
;  6:	 copy/fill data	to PPU mem (0/1)
;  5-0:	 byte xfer count (0 indicates 64 bytes)
    
; bytes 3..n
; ----------
;  - if the fill bit is set, there is only one byte here, which	is the value
;  to fill the PPU memory with,	for the specified byte xfer count.
;  - if copy mode is set instead, this data contains the bytes to be copied
;  to PPU memory. The number of	bytes appearing	here is equal to the byte
;  xfer count.
    
    
;entry point
PPUdataPrsr:
    JSR GetHCparam
    JMP $E815
    
;[Param] is in A
_E7C1:
    PHA;	save [Param]
    STA $2006;	[NES] VRAM address select
    INY
    LDA ($00),Y;	load [Param+1]
    STA $2006;	[NES] VRAM address select
    INY
    LDA ($00),Y;	load [Param+2]	IFcccccc
    ASL A;	bit 7 in carry	Fcccccc0
    PHA;	save [Param+2]
    
;if Bit(7,[Param+2]) then PPUinc:=32 else PPUinc:=1
    LDA $FF
    ORA #$04
    BCS _E7D8
    AND #$fb
_E7D8:
    STA $2000;	[NES] PPU setup	#1
    STA $FF
    
;if Bit(6,[Param+2]) then
    PLA;	load [Param+2]	Fcccccc0
    ASL A
    PHP;	save zero status
    BCC _E7E5
    ORA #$02
    INY;	advance to next	byte if fill bit set
    
;if Zero([Param+2] and $3F) then carry:=1 else carry:=0
_E7E5:
    PLP
    CLC
    BNE _E7EA
    SEC
_E7EA:
    ROR A
    LSR A
    TAX
    
;for I:=0 to X-1 do [$2007]:=[Param+3+(X and not Bit(6,[Param+2]))]
_E7ED:
    BCS _E7F0
    INY
_E7F0:
    LDA ($00),Y
    STA $2007;	[NES] VRAM data
    DEX
    BNE _E7ED
    
;not sure what this is supposed	to do, since it	looks like it's zeroing out
;the entire PPU	address register in the end
    PLA;	load [Param]
    CMP #$3f
    BNE _E809
    STA $2006;	[NES] VRAM address select
    STX $2006;	[NES] VRAM address select
    STX $2006;	[NES] VRAM address select
    STX $2006;	[NES] VRAM address select
    
;increment Param by Y+1
_E809:
    SEC
    TYA
    ADC $00
    STA $00
    LDA #$00
    ADC $01
    STA $01
    
;exit if bit(7,[Param]) is 1
_E815:
    LDX $2002;	[NES] PPU status
    LDY #$00
    LDA ($00),Y;	load opcode
    BPL _E81F
    RTS
    
;test for RET instruction
_E81F:
    CMP #$60
    BNE _E82D
    
;[Param] = $60:
;pop Param off stack
    PLA
    STA $01
    PLA
    STA $00
    LDY #$02;	increment amount
    BNE _E809;	unconditional
    
;test for JSR opcode
_E82D:
    CMP #$4c
    BNE _E7C1
    
;[Param] = $4C
;push Param onto stack
    LDA $00
    PHA
    LDA $01
    PHA
    
;Param = [Param+1]
    INY
    LDA ($00),Y
    TAX
    INY
    LDA ($00),Y
    STA $01
    STX $00
    BCS _E815;	unconditional
    
    
;????????????????????????????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;fetches hardcoded 16-bit value	after second return address into [$00] & [$01]
;that return address is then incremented by 2.
GetHCparam:
    TSX
    LDA $0103,X
    STA $05
    LDA $0104,X
    STA $06
    LDY #$01
    LDA ($05),Y
    STA $00
    INY
    LDA ($05),Y
    STA $01
    CLC
    LDA #$02
    ADC $05
    STA $0103,X
    LDA #$00
    ADC $06
    STA $0104,X
    RTS
    
    
_E86A:
    LDA $FF
    AND #$fb
    STA $2000;	[NES] PPU setup	#1
    STA $FF
    LDX $2002;	[NES] PPU status
    LDY #$00
    BEQ _E8A5
_E87A:
    PHA
    STA $2006;	[NES] VRAM address select
    INY
    LDA $0302,Y
    STA $2006;	[NES] VRAM address select
    INY
    LDX $0302,Y
_E889:
    INY
    LDA $0302,Y
    STA $2007;	[NES] VRAM data
    DEX
    BNE _E889
    PLA
    CMP #$3f
    BNE _E8A4
    STA $2006;	[NES] VRAM address select
    STX $2006;	[NES] VRAM address select
    STX $2006;	[NES] VRAM address select
    STX $2006;	[NES] VRAM address select
_E8A4:
    INY
_E8A5:
    LDA $0302,Y
    BPL _E87A
    STA $0302
    LDA #$00
    STA $0301
    RTS
    
    
    LDA $2002;	[NES] PPU status
_E8B6:
    LDA $0300,X
    STA $2006;	[NES] VRAM address select
    INX
    LDA $0300,X
    STA $2006;	[NES] VRAM address select
    INX
    LDA $2007;	[NES] VRAM data
    LDA $2007;	[NES] VRAM data
    STA $0300,X
    INX
    DEY
    BNE _E8B6
    RTS
    
    
_E8D2:
    STA $03
    STX $02
    STY $04
    JSR GetHCparam
    LDY #$ff
    LDA #$01
    BNE _E8F6
    STA $03
    STX $02
    JSR GetHCparam
    LDY #$00
    LDA ($00),Y
    AND #$0f
    STA $04
    LDA ($00),Y
    LSR A
    LSR A
    LSR A
    LSR A
_E8F6:
    STA $05
    LDX $0301
_E8FB:
    LDA $03
    STA $0302,X
    JSR _E93C
    LDA $02
    STA $0302,X
    JSR _E93C
    LDA $04
    STA $06
    STA $0302,X
_E912:
    JSR _E93C
    INY
    LDA ($00),Y
    STA $0302,X
    DEC $06
    BNE _E912
    JSR _E93C
    STX $0301
    CLC
    LDA #$20
    ADC $02
    STA $02
    LDA #$00
    ADC $03
    STA $03
    DEC $05
    BNE _E8FB
    LDA #$ff
    STA $0302,X
    RTS
    
    
_E93C:
    INX
    CPX $0300
    BCC _E94E
    LDX $0301
    LDA #$ff
    STA $0302,X
    PLA
    PLA
    LDA #$01
_E94E:
    RTS
    
    
    DEX
    DEX
    DEX
    TXA
_E953:
    CLC
    ADC #$03
    DEY
    BNE _E953
    TAX
    TAY
    LDA $0300,X
    CMP $00
    BNE _E970
    INX
    LDA $0300,X
    CMP $01
    BNE _E970
    INX
    LDA $0300,X
    CLC
    RTS
    
    
_E970:
    LDA $00
    STA $0300,Y
    INY
    LDA $01
    STA $0300,Y
    SEC
    RTS
    
    
    LDA #$08
    STA $00
    LDA $02
    ASL A
    ROL $00
    ASL A
    ROL $00
    AND #$e0
    STA $01
    LDA $03
    LSR A
    LSR A
    LSR A
    ORA $01
    STA $01
    RTS
    
    
    LDA $01
    ASL A
    ASL A
    ASL A
    STA $03
    LDA $01
    STA $02
    LDA $00
    LSR A
    ROR $02
    LSR A
    ROR $02
    LDA #$f8
    AND $02
    STA $02
    RTS
    
    
;????????????????????????????????????????????????????????????????????????????
;Random number generator?????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;uses a shift register and a XOR to generate pseudo-random numbers.
    
;algorithm
;---------
;carry	[X]	[X+1]	[X+n]
;-->    --->	--->    --->	--->    --->	--->
;C	765432*0	765432*0	76543210	...
    
;notes
;-----
;* these 2 points are XORed, and the result is stored in C.
    
;- when the shift occurs, C is shifted into the	MSB of [X], the	LSB of [X] is
;  shifted into	the MSB of [X+1], and so on, for as many more numbers there
;  are (# of bytes to use is indicated by Y).
    
;- at least 2 8-bit shift registers need to be used here, but using more will
;  not effect the random number	generation. Also, after 16 shifts, the
;  16-bit results in the first 2 bytes will be the same as the next 2, so
;  it's really not neccessary to use more than 2 bytes for this algorithm.
    
;- a new random	number is available after each successive call to this
;  subroutine, but to get a good random number to start off with, it may be
;  neccessary to call this routine several times.
    
;- upon the first time calling this routine, make sure the first 2 bytes
;  do not both contain 0, otherwise the random number algorithm	won't work.
    
    
;Y is number of	8-bit registers	to use (usually	2)
;X is base 0pg addr for shifting
    
    
;store first bit sample
RndmNbrGen:
    LDA $00,X
    AND #$02
    STA $00
    
;xor second bit	sample with first
    LDA $01,X
    AND #$02
    EOR $00
    
;set carry to result of XOR
    CLC
    BEQ _E9C1
    SEC
    
;multi-precision shift for Y amount of bytes
_E9C1:
    ROR $00,X
    INX
    DEY
    BNE _E9C1
    RTS
    
    
;????????????????????????????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
    
_E9C8:
    LDA #$00
    STA $2003;	[NES] SPR-RAM address select
    LDA #$02
    STA $4014;	[NES] Sprite DMA trigger
    RTS
    
    
_E9D3:
    STX $00
    DEC $00,X
    BPL _E9DE
    LDA #$09    ;timer for copyright
    STA $00,X
    TYA
_E9DE:
    TAX
_E9DF:
    LDA $00,X
    BEQ _E9E5
    DEC $00,X
_E9E5:
    DEX
    CPX $00
    BNE _E9DF
    RTS
    
    
;????????????????????????????????????????????????????????????????????????????
;controller read function
    
;- strobes controllers
;- [$F5] contains 8 reads of bit 0 from [$4016]
;- [$00] contains 8 reads of bit 1 from [$4016]
;- [$F6] contains 8 reads of bit 0 from [$4017]
;- [$01] contains 8 reads of bit 1 from [$4017]
    
ReadCtrlrs:
    LDX $FB
    INX
    STX $4016;	[NES] Joypad & I/O port for port #1
    DEX
    STX $4016;	[NES] Joypad & I/O port for port #1
    LDX #$08
_E9F7:
    LDA $4016;	[NES] Joypad & I/O port for port #1
    LSR A
    ROL $F5
    LSR A
    ROL $00
    LDA $4017;	[NES] Joypad & I/O port for port #2
    LSR A
    ROL $F6
    LSR A
    ROL $01
    DEX
    BNE _E9F7
    RTS
    
    
;????????????????????????????????????????????????????????????????????????????
;controller OR function
    
;[$F5]|=[$00]
;[$F6]|=[$01]
    
ORctrlrRead:
    LDA $00
    ORA $F5
    STA $F5
    LDA $01
    ORA $F6
    STA $F6
    RTS
    
    
;????????????????????????????????????????????????????????????????????????????
;get controller	status
    
;- returns status of controller	buttons in [$F7] (CI) and [$F8]	(CII)
;- returns which new buttons have been pressed since last update in
;  [$F5] (CI) and [$F6] (CII)
    
GetCtrlrSts:
    JSR ReadCtrlrs
    BEQ _EA25;	always branches	because ReadCtrlrs sets zero flag
    JSR ReadCtrlrs;	this instruction is not used
    JSR ORctrlrRead;this instruction is not used
_EA25:
    LDX #$01
_EA27:
    LDA $F5,X
    TAY
    EOR $F7,X
    AND $F5,X
    STA $F5,X
    STY $F7,X
    DEX
    BPL _EA27
    RTS
    
    
;????????????????????????????????????????????????????????????????????????????
    
    JSR ReadCtrlrs
_EA39:
    LDY $F5
    LDA $F6
    PHA
    JSR ReadCtrlrs
    PLA
    CMP $F6
    BNE _EA39
    CPY $F5
    BNE _EA39
    BEQ _EA25
    JSR ReadCtrlrs
    JSR ORctrlrRead
_EA52:
    LDY $F5
    LDA $F6
    PHA
    JSR ReadCtrlrs
    JSR ORctrlrRead
    PLA
    CMP $F6
    BNE _EA52
    CPY $F5
    BNE _EA52
    BEQ _EA25
    JSR ReadCtrlrs
    LDA $00
    STA $F7
    LDA $01
    STA $F8
    LDX #$03
_EA75:
    LDA $F5,X
    TAY
    EOR $F1,X
    AND $F5,X
    STA $F5,X
    STY $F1,X
    DEX
    BPL _EA75
    RTS
    
    
;????????????????????????????????????????????????????????????????????????????
;VRAM fill routine???????????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;this routine basically fills a	specified place	in VRAM with a desired value.
;when writing to name table memory, another value can be specified to fill the
;attribute table with. parameters are as follows:
    
;A is HI VRAM addr (LO VRAM addr is always 0)
    
;X is fill value
    
;Y is iteration	count (256 written bytes per iteration). if A is $20 or
;  greater (indicating name table VRAM), iteration count is always 4,
;  and this data is used for attribute fill data.
    
VRAMfill:
    STA $00
    STX $01
    STY $02
    
;reset 2006's flip flop
    LDA $2002;	[NES] PPU status
    
;set PPU address increment to 1
    LDA $FF
    AND #$fb
    STA $2000;	[NES] PPU setup	#1
    STA $FF
    
;PPUaddrHI:=[$00]
;PPUaddrLO:=$00
    LDA $00
    STA $2006;	[NES] VRAM address select
    LDY #$00
    STY $2006;	[NES] VRAM address select
    
;if PPUaddr<$2000 then X:=[$02]	else X:=4
    LDX #$04
    CMP #$20
    BCS _EAA8;	branch if more than or equal to	$20
    LDX $02
    
;for i:=X downto 1 do Fill([$2007],A,256)
_EAA8:
    LDY #$00
    LDA $01
_EAAC:
    STA $2007;	[NES] VRAM data
    DEY
    BNE _EAAC
    DEX
    BNE _EAAC
    
;set up Y for next loop
    LDY $02
    
;if PPUaddr>=$2000 then
    LDA $00
    CMP #$20
    BCC _EACF;	branch if less than $20
    
;  PPUaddrHI:=[$00]+3
;  PPUaddrLO:=$C0
    ADC #$02
    STA $2006;	[NES] VRAM address select
    LDA #$c0
    STA $2006;	[NES] VRAM address select
    
;  for I:=1 to $40 do [$2007]:=[$02]
    LDX #$40
_EAC9:
    STY $2007;	[NES] VRAM data
    DEX
    BNE _EAC9
    
;restore X
_EACF:
    LDX $01
    RTS
    
    
;????????????????????????????????????????????????????????????????????????????
;CPU memory fill routine?????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;this routine simply fills CPU mapped memory with a given value. granularity
;is pages (256 bytes). parameters are as follows:
    
;A is fill value
;X is first page #
;Y is last  page #
    
MemFill:
    PHA
    TXA
    STY $01
    CLC
    SBC $01
    TAX
    PLA
    LDY #$00
    STY $00
_EADF:
    STA ($00),Y
    DEY
    BNE _EADF
    DEC $01
    INX
    BNE _EADF
    RTS
    
    
;????????????????????????????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;restore PPU reg's 0 & 5 from mem
RstPPU05:
    LDA $2002;	reset scroll register flip-flop
    LDA $FD
    STA $2005;	[NES] PPU scroll
    LDA $FC
    STA $2005;	[NES] PPU scroll
    LDA $FF
    STA $2000;	[NES] PPU setup	#1
    RTS
    
    
;????????????????????????????????????????????????????????????????????????????
    
    ASL A
    TAY
    INY
    PLA
    STA $00
    PLA
    STA $01
    LDA ($00),Y
    TAX
    INY
    LDA ($00),Y
    STA $01
    STX $00
    JMP ($0000)
    
    
    LDA $FB
    AND #$f8
    STA $FB
    ORA #$05
    STA $4016;	[NES] Joypad & I/O port for port #1
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    LDX #$08
_EB26:
    LDA $FB
    ORA #$04
    STA $4016;	[NES] Joypad & I/O port for port #1
    LDY #$0a
_EB2F:
    DEY
    BNE _EB2F
    NOP
    LDY $FB
    LDA $4017;	[NES] Joypad & I/O port for port #2
    LSR A
    AND #$0f
    BEQ _EB62
    STA $00,X
    LDA $FB
    ORA #$06
    STA $4016;	[NES] Joypad & I/O port for port #1
    LDY #$0a
_EB48:
    DEY
    BNE _EB48
    NOP
    NOP
    LDA $4017;	[NES] Joypad & I/O port for port #2
    ROL A
    ROL A
    ROL A
    AND #$f0
    ORA $00,X
    EOR #$ff
    STA $00,X
    DEX
    BPL _EB26
    LDY $FB
    ORA #$ff
_EB62:
    STY $4016;	[NES] Joypad & I/O port for port #1
    RTS
    
    
;????????????????????????????????????????????????????????????????????????????
;CPU to PPU copy routine?????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;CPUtoPPUcpy is	used for making	data transfers between the PPU & CPU.
;arguments are passed in CPU registers, and also hardcoded as an immediate
;value after the call instruction.
    
;parameters
;----------
    
;[RETaddr+1] is	CPU xfer address (the 2 bytes immediately after	the JSR inst.)
    
;X reg:	# of 16-byte units to xfer to/from PPU
    
;Y reg:	bits 8-15 of PPU xfer addr
    
;A reg:	bottom part of PPU xfer addr, and xfer control.	the bit layout
;	is as follows:
    
;  0:	invert data/fill type
    
;  1:	xfer direction (0 = write to video mem)
    
;  2-3:	xfer mode. note	that on each iteration, 2 groups of 8 bytes
;	are always xfered in/out of the	PPU, but depending on the
;	mode, 8 or 16 bytes will be xfered to/from CPU.	The following
;	chart describes	how xfers to/from the PPU via the CPU are
;	made.
    
;	1st 8 bytes	2nd 8 bytes
;	-----------	-----------
;     0:	CPU	CPU+8
;     1:	CPU	fill bit
;     2:	fill bit	CPU
;     3:	CPU ^ inv.bit	CPU
    
    
;  4-7:	bits 4-7 of PPU	xfer addr. bits	0-3 are assumed	0.
    
    
;increment word	at [$00] by 8.
;decrement byte	at [$02].
Inc00by8:
    LDA #$08
Inc00byA:
    PHP
    LDY #$00
    CLC
    ADC $00
    STA $00
    LDA #$00
    ADC $01
    STA $01
    PLP
    DEC $02
    RTS
    
;move 8 bytes pointed to by word[$00] to video buf.
;move direction	is reversed if carry is set.
Mov8BVid:
    LDX #$08
_EB7C:
    BCS _EB88
    LDA ($00),Y
    STA $2007;	[NES] VRAM data
_EB83:
    INY
    DEX
    BNE _EB7C
    RTS
_EB88:
    LDA $2007;	[NES] VRAM data
    STA ($00),Y
    BCS _EB83
    
;move the byte at [$03] to the video buffer 8 times.
;if carry is set, then make dummy reads.
FillVidW8B:
    LDA $03
    LDX #$08
_EB93:
    BCS _EB9C
    STA $2007;	[NES] VRAM data
_EB98:
    DEX
    BNE _EB93
    RTS
_EB9C:
    LDA $2007;	[NES] VRAM data
    BCS _EB98
    
;move 8 bytes pointed to by word[$00] to video buf.
;data is XORed with [$03] before being moved.
Mov8BtoVid:
    LDX #$08
_EBA3:
    LDA $03
    EOR ($00),Y
    STA $2007;	[NES] VRAM data
    INY
    DEX
    BNE _EBA3
    RTS
    
;load register variables into temporary memory
CPUtoPPUcpy:
    STA $04
    STX $02
    STY $03
    JSR GetHCparam;	load hard-coded	param into [$00]&[$01]
    
;set PPU address increment to 1
    LDA $2002;	[NES] PPU status
    LDA $FF
    AND #$fb
    STA $FF
    STA $2000;	[NES] PPU setup	#1
    
;PPUaddrHI:=[$03]
;PPUaddrLO:=[$04]and $F0
    LDY $03
    STY $2006;	[NES] VRAM address select
    LDA $04
    AND #$f0
    STA $2006;	[NES] VRAM address select
    
;[$03]:=Bit(0,[$04])	 0 if clear; -1	if set
    LDA #$00
    STA $03
    LDA $04
    AND #$0f
    LSR A
    BCC _EBDD
    DEC $03
    
;if Bit(1,[$04])then Temp:=[$2007]
_EBDD:
    LSR A
    BCC _EBE3
    LDX $2007;	dummy read to validate internal	read buffer
    
;case [$04]and $0C of
_EBE3:
    TAY
    BEQ _EBFB;	00xx
    DEY
    BEQ _EC09;	01xx
    DEY
    BEQ _EC15;	02xx
    DEY;	Y=0
    
;$0C: #2 plane copy (plane 1 is	filled with same data, but can be inverted)
_EBED:
    JSR Mov8BtoVid
    LDY #$00
    JSR Mov8BVid
    JSR Inc00by8
    BNE _EBED
    RTS
    
;$00: double plane copy
_EBFB:
    JSR Mov8BVid
    JSR Mov8BVid
    LDA #$10
    JSR Inc00byA
    BNE _EBFB
    RTS
    
;$04: #1 plane copy (plane 2 is	filled with [$03])
_EC09:
    JSR Mov8BVid
    JSR FillVidW8B
    JSR Inc00by8
    BNE _EC09
    RTS
    
;$08: #2 plane copy (plane 1 is	filled with [$03])
_EC15:
    JSR FillVidW8B
    JSR Mov8BVid
    JSR Inc00by8
    BNE _EC15
    RTS
    
;????????????????????????????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
    
_EC21:
    RTS
    
_EC22:
    LDY #$0b
    LDA ($00),Y
    STA $02
    LDA #$02
    STA $03
    DEY
    LDA ($00),Y
    LSR A
    LSR A
    LSR A
    LSR A
    BEQ _EC21
    STA $04
    STA $0C
    LDA ($00),Y
    AND #$0f
    BEQ _EC21
    STA $05
    LDY #$01
    LDA ($00),Y
    TAX
    DEY
    LDA ($00),Y
    BEQ _EC4F
    BPL _EC21
    LDX #$f4
_EC4F:
    STX $08
    LDY #$08
    LDA ($00),Y
    LSR A
    AND #$08
    BEQ _EC5C
    LDA #$80
_EC5C:
    ROR A
    STA $09
    INY
    LDA ($00),Y
    AND #$23
    ORA $09
    STA $09
    LDY #$03
    LDA ($00),Y
    STA $0A
    LDA $05
    STA $07
    LDY #$00
    STY $0B
_EC76:
    LDA $04
    STA $06
    LDX $08
_EC7C:
    TXA
    STA ($02),Y
    CMP #$f4
    BEQ _EC87
    CLC
    ADC #$08
    TAX
_EC87:
    INY
    INY
    LDA $09
    STA ($02),Y
    INY
    LDA $0A
    STA ($02),Y
    INY
    INC $0B
    DEC $06
    BNE _EC7C
    LDA $0A
    CLC
    ADC #$08
    STA $0A
    DEC $07
    BNE _EC76
    LDY #$07
    LDA ($00),Y
    STA $07
    DEY
    LDA ($00),Y
    STA $08
    LDA #$00
    STA $0A
    CLC
    LDX $0B
    DEY
_ECB7:
    LDA ($00),Y
    CLC
    ADC $07
    STA $07
    LDA #$00
    ADC $08
    STA $08
    DEX
    BNE _ECB7
    INC $02
    LDY #$00
    LDA $08
    BNE _ECD3
    DEC $0A
    LDY $07
_ECD3:
    BIT $09
    BMI _ECF5
    BVS _ECF7
_ECD9:
    LDA ($07),Y
    BIT $0A
    BPL _ECE0
    TYA
_ECE0:
    STA ($02,X)
    DEY
    BIT $09
    BMI _ECE9
    INY
    INY
_ECE9:
    LDA #$04
    CLC
    ADC $02
    STA $02
    DEC $0B
    BNE _ECD9
    RTS
    
    
_ECF5:
    BVC _ED09
_ECF7:
    TYA
    CLC
    ADC $0B
    TAY
    DEY
    BIT $09
    BMI _ECD9
    LDA #$ff
    EOR $0C
    STA $0C
    INC $0C
_ED09:
    TYA
    CLC
    ADC $0C
    TAY
    LDA $04
    STA $06
_ED12:
    DEY
    BIT $09
    BMI _ED19
    INY
    INY
_ED19:
    LDA ($07),Y
    BIT $0A
    BPL _ED20
    TYA
_ED20:
    STA ($02,X)
    LDA #$04
    CLC
    ADC $02
    STA $02
    DEC $06
    BNE _ED12
    TYA
    CLC
    ADC $0C
    TAY
    DEC $05
    BNE _ED09
    RTS
    
 ;copyright text   $ED37
.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$17,$12,$17,$1D,$0E
.byte $17,$0D,$18,$24,$28,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
.byte $24,$24,$24,$24,$24,$24,$24,$0F,$0A,$16,$12,$15,$22,$24,$0C,$18
.byte $16,$19,$1E,$1D,$0E,$1B,$24,$1D,$16,$24,$24,$24,$24,$24,$24,$24
.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
.byte $24,$24,$1D,$11,$12,$1C,$24,$19,$1B,$18,$0D,$1E,$0C,$1D,$24,$12
.byte $1C,$24,$16,$0A,$17,$1E,$0F,$0A,$0C,$1D,$1E,$1B,$0E,$0D,$24,$24
.byte $24,$24,$0A,$17,$0D,$24,$1C,$18,$15,$0D,$24,$0B,$22,$24,$17,$12
.byte $17,$1D,$0E,$17,$0D,$18,$24,$0C,$18,$27,$15,$1D,$0D,$26,$24,$24
.byte $24,$24,$18,$1B,$24,$0B,$22,$24,$18,$1D,$11,$0E,$1B,$24,$0C,$18
.byte $16,$19,$0A,$17,$22,$24,$1E,$17,$0D,$0E,$1B,$24,$24,$24,$24,$24
.byte $24,$24,$15,$12,$0C,$0E,$17,$1C,$0E,$24,$18,$0F,$24,$17,$12,$17
.byte $1D,$0E,$17,$0D,$18,$24,$0C,$18,$27,$15,$1D,$0D,$26,$26,$24,$24
    
;a disk-related	subroutine, which somehow ended	up all the way out here...
StartMotor:
    ORA #$01
    STA $4025
    AND #$fd
    STA $FA
    STA $4025
    RTS
    
    
;????????????????????????????????????????????????????????????????????????????
;Reset vector????????????????????????????????????????????????????????????????
    
;????????????????????????????????????????????????????????????????????????????
;disable interrupts (just in case resetting the	CPU doesn't!)
Reset:
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
    
;if ([$102]=$35)and(([$103]=$53)or([$103]=$AC))	then
;  [$103]:=$53
;  CALL RstPPU05
;  CLI
;  JMP [$DFFC]
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
    
;[$300]:=$7D
;[$301]:=$00
;[$302]:=$FF
    STA $0301
    LDA #$7d
    STA $0300
    LDA #$ff
    STA $0302
    
;if Ctrlr1 = $30 then
;  [$0102]:=0
;  JMP $F4CC
    JSR GetCtrlrSts
    ;LDA $F7;	read ctrlr 1 buttons
    lda #$00;   skip test
    CMP #$30;	test if only select & start pressed
    BNE _EEC9
    LDA #$00
    STA $0102
    JMP $F4CC
    
_EEC9:
    ;JSR InitGfx
    jsr init_gfx
    JSR _F0FD
    LDA #$4a
    STA $A1
    LDA #$30
    STA $B1
    LDA #$e4
    STA $83
    LDA #$a9
    STA $FC
    
;test if disk inserted
    LDA $4032
    AND #$01
    BEQ _EEEA 
    
    LDA #$04
    STA $E1
_EEEA:
    LDA #$34
    STA $90
_EEEE:
    JSR _F376 
    JSR VINTwait
    LDA $90
    CMP #$32
    BNE _EEFE
    LDA #$01
    STA $E1
_EEFE:
    JSR _F0B4
    JSR RstPPU05
    JSR EnPfOBJ
    JSR _EFE8
    LDX #$60
    LDY #$20
    JSR RndmNbrGen
    JSR _F143 
    JSR _F342
    LDX #$00
    JSR _F1E5
    LDX #$10
    JSR _F1E5
    LDA #$c0
    STA $00
    LDA #$00
    STA $01
    JSR _EC22
    LDA #$d0
    STA $00
    JSR _EC22
    LDA $4032
    AND #$01
    BNE _EEEA
    LDA $FC
    BEQ _EF42
    LDA #$01
    STA $FC
_EF42:
    LDA $90
    BNE _EEEE   ;msg screen here?
    JSR DisOBJs
    JSR VINTwait
    JSR PPUdataPrsr;,$EFFF fix
.word $EFFF
    JSR PPUdataPrsr;,$F01C fix
.word $F01C
    JSR RstPPU05
    JSR LoadFiles;,$EFF5,$EFF5;load the FDS disk boot files fix
.word $EFF5, $EFF5
    BNE _EF6C   ;error
    JSR _F431   ;init ppu
    BEQ _EFAF   ;run!
    JSR _F5FB   ;unknwn stuff. likely some inits is game not ran 
    LDA #$20
_EF6C:  ;error hendler
    STA $23
    jmp err
    ;JSR InitGfx
    JSR _F0E1
    JSR _F0E7
    JSR _F0ED
    JSR _F179
    LDA #$10
    STA $A3
    LDA $22
    BEQ _EF8B
    LDA #$01
    STA $83
    DEC $21
_EF8B:
    JSR _F376
    JSR VINTwait
    JSR _E86A
    JSR RstPPU05
    JSR EnPF
    JSR _EFE8
    LDA #$02
    STA $E1
    LDA $A3
    BNE _EF8B
_EFA5:
    LDA $4032
    AND #$01
    BEQ _EFA5
    JMP Reset
    
    
_EFAF:
    LDA #$20
    STA $A2
_EFB3:
    JSR VINTwait
    JSR RstPPU05
    JSR EnPF
    LDX $FC
    INX
    INX
    CPX #$b0
    BCS _EFC6
    STX $FC
_EFC6:
    JSR _EFE8  ;sound bee and magic stuff, including copyright timer
    LDA $A2
    ;BNE _EFB3 ;show copyright screen
    nop
    nop
    LDA #$35
    STA $0102
    LDA #$ac
    STA $0103
    JSR DisPF
    LDY #$07
    JSR _F48C
    LDA #$00
    STA $FD
    STA $FC
    JMP _EE9B   ;run 
    
    
_EFE8:
    ;JSR _FF5C ;sounds
    jsr skip
    LDX #$80
    LDA #$9f
    LDY #$bf
    JSR _E9D3
    RTS
    

;$EFF5 seems like load files routine uses tis data. LoadFiles
.byte   $FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$FF,$FF
    
;$EFFF dome blank string?
.byte   $21,$A6,$54,$24
.byte   $FF
    
;$F004 PLEASE SET DISK CARD   
.byte   $21,$A6,$14,$19,$15,$0E,$0A,$1C,$0E,$24,$1C,$0E,$1D,$24,$0D,$12,$1C,$14,$24,$0C,$0A,$1B,$0D
;.byte   $21,$A6,$14,$24,$24,$24,$24,$0F,$0D,$1C,$24,$15,$18,$0A,$0D,$12,$17,$10,$26,$26,$26,$24,$24
.byte   $FF
    
;$F01C	NOW LOADING
.byte $21,$A6,$0E,$17,$18,$20,$24,$15,$18,$0A,$0D,$12,$17,$10,$26,$26,$26
.byte $FF

;$F02E DISK SET BATTERY A\B SIDE DISK NO X.K DISK TROUBLE  ERR 976W.G PRAM CRAM    OK
;PORTv7 ?FWFFFFFFb..7b...
.byte $0D,$12,$1C,$14,$24,$1C,$0E,$1D,$0B,$0A,$1D,$1D,$0E,$1B,$22,$24
.byte $0A,$25,$0B,$24,$1C,$12,$0D,$0E,$0D,$12,$1C,$14,$24,$17,$18,$26
.byte $21,$A6,$14,$0D,$12,$1C,$14,$24,$1D,$1B,$18,$1E,$0B,$15,$0E,$24
.byte $24,$0E,$1B,$1B,$26,$02,$00,$FF,$20,$E8,$10,$19,$1B,$0A,$16,$24
.byte $0C,$1B,$0A,$16,$24,$24,$24,$24,$24,$18,$14,$21,$68,$04,$19,$18
.byte $1B,$1D,$3F,$00,$08,$0F,$20,$0F,$0F,$0F,$0F,$0F,$0F,$2B,$C0,$50
.byte $00,$2B,$D0,$70,$55,$FF
    
;$F094 not string
.byte $80,$B8,$00,$00,$00,$00,$00,$00,$10,$00,$32,$00,$00,$00,$01,$00
.byte $80,$B8,$00,$F0,$00,$00,$00,$00,$00,$01,$32,$18,$00,$00,$FF,$00
    
    
_F0B4:
    LDA $FC
    BEQ _F0C0
    DEC $FC
    BNE _F0C0
    LDA #$10
    STA $94
_F0C0:
    LDX $94
    BEQ _F0CD
    DEX
    BEQ _F0E1
    DEX
    BEQ _F0E7
    DEX
    BEQ _F0ED
_F0CD:
    JSR _E9C8
    JSR _E86A
    LDA $92
    BNE _F0F3
    JSR PPUdataPrsr;,$EFFF fix
.word $EFFF
    LDA #$40
    STA $92
    RTS
    
    
_F0E1:
    JSR PPUdataPrsr;,$F716 fix
.word $F716
    RTS
    
    
_F0E7:
    JSR PPUdataPrsr;,$F723 fix
.word $F723
    RTS
    
    
_F0ED:
    JSR PPUdataPrsr;,$F72C fix
.word $F72C
    RTS
    
    
_F0F3:
    CMP #$2e
    BNE _F0FC
    JSR PPUdataPrsr;,$F004 fix
.word $F004
_F0FC:
    RTS
    
    
;????????????????????????????????????????????????????????????????????????????
;fill $0200-$02FF with $F4
_F0FD:
    LDA #$f4
    LDX #$02
    LDY #$02
    JSR MemFill
    
;move data
;for I:=0 to $1F do [$C0+I]:=[$F094+I]
    LDY #$20
_F108:
    LDA $F093,Y
    STA $00BF,Y
    DEY
    BNE _F108
    
;fill $0230-$02FF with random data
;for I:=$0230 to $02FF do [I]:=Random(256)
    LDA #$d0;	loop count
    STA $60;	load random number target with any data
    STA $01;	save loop count	in [$01]
_F117:
    LDY #$02
    LDX #$60
    JSR RndmNbrGen;	[$60] and [$61]	are random number target
    LDA $60;	get random number
    LDX $01;	load loop count	(and index)
    STA $022F,X;	write out random #
    DEX
    STX $01;	save loop count
    BNE _F117
    
;fill every 4th	byte in random data area with $33
;for I:=0 to $33 do [I*4+$0231]:=$18
    LDA #$18
    LDX #$d0
_F12E:
    STA $022D,X
    DEX
    DEX
    DEX
    DEX
    BNE _F12E
    
;and & or every	4th byte in random data
;for I:=0 to $33 do [I*4+$0232]:=([I*4+$0232]-1)and $03 or $20
    LDX #$d0
    STX $24
_F13B:
    JSR _F156
    CPX #$d0
    BNE _F13B
    RTS
    
    
;????????????????????????????????????????????????????????????????????????????
    
_F143:
    LDA $84
    BNE _F156
    LDA #$04
    STA $84
    LDX #$d0
_F14D:
    DEC $022C,X
    DEX
    DEX
    DEX
    DEX
    BNE _F14D
    
;for I:=0 to 3 do
;  [$022E+X]:=([$022E+X]-1)and $03 or $20
;  X-=4
;  if X=0 then X:=$d0
;end
_F156:
    LDY #$04
_F158:
    LDX $24
    DEC $022E,X
    LDA #$03
    AND $022E,X
    ORA #$20
    STA $022E,X
    DEX
    DEX
    DEX
    DEX
    BNE _F16F
    LDX #$d0
_F16F:
    STX $24
    DEY
    BNE _F158
    RTS
    
    
.byte  $01,$02,$07,$08
    
    
_F179:
    LDY #$18
_F17B:
    LDA $F04D,Y
    STA $003F,Y
    DEY
    BNE _F17B
    LDA $23
    AND #$0f
    STA $56
    LDA $23
    LSR A
    LSR A
    LSR A
    LSR A
    STA $55
    CMP #$02
    BEQ _F1BD
    LDY #$0e
    LDA #$24
_F19A:
    STA $0042,Y
    DEY
    BNE _F19A
    LDY #$05
    LDA $23
_F1A4:
    DEY
    BEQ _F1BD
    CMP $F174,Y
    BNE _F1A4
    TYA
    ASL A
    ASL A
    ASL A
    TAX
    LDY #$07
_F1B3:
    DEX
    LDA $F02E,X
    STA $0043,Y
    DEY
    BPL _F1B3
_F1BD:
    JSR PPUdataPrsr;,$0040 fix
.word $0040
    RTS
    
    
;????????????????????????????????????????????????????????????????????????????
;copy font bitmaps into PPU memory
;src:CPU[$E001]	dest:PPU[$1000]	tiles:41 (41*8 bytes, 1st plane	is inverted)
LoadFonts:
    LDA #$0d
    LDY #$10
    LDX #$29
    JSR CPUtoPPUcpy;,$E001 fix
.word $E001
    
;copy inverted font bitmaps from PPU mem to [$0400]
;src:PPU[$1000]	dest:CPU[$0400]	tiles:41 (41*8 bytes)
    LDA #$06
    LDY #$10
    LDX #$29
    JSR CPUtoPPUcpy;,$0400 fix
.word $0400
    
;copy back fonts & set first plane to all 1's
;src:CPU[$0400]	dest:PPU[$1000]	tiles:41 (41*8 bytes, 1st plane	is all 1's)
    LDA #$09
    LDY #$10
    LDX #$29
    JSR CPUtoPPUcpy;,$0400 fix
.word $0400
    RTS
    
    
;????????????????????????????????????????????????????????????????????????????
    
_F1E5:
    JSR _F1F2
    JSR _F2EC
    JSR _F273
    JSR _F2C6
    RTS
    
    
_F1F2:
    LDA $20,X
    BNE _F227
    LDA $C0,X
    BNE _F227
    LDA $B0
    BNE _F227
    LDA $81,X
    BNE _F227
    LDA $62,X
    AND #$3c
    STA $81,X
    TXA
    BNE _F228
    LDA $B2
    BNE _F236
    LDA $D0
    BEQ _F23D
    LDA $22
    BNE _F21D
    LDA $C3
    CMP #$78
    BCC _F24D
_F21D:
    LDA #$00
    STA $C8,X
    STA $CF,X
    LDA #$ff
    STA $CE,X
_F227:
    RTS
    
    
_F228:
    LDA $C0
    BEQ _F25A
    LDA $22
    BNE _F21D
    LDA $63,X
    CMP #$80
    BCS _F24D
_F236:
    LDA #$00
    STA $CF,X
    STA $CE,X
    RTS
    
    
_F23D:
    LDA $C8
    BNE _F247
    LDA $63,X
    CMP #$c0
    BCC _F21D
_F247:
    LDA $64,X
    CMP #$80
    BCC _F236
_F24D:
    LDA #$10
    STA $C8,X
    LDA #$00
    STA $CF,X
    LDA #$01
    STA $CE,X
    RTS
    
    
_F25A:
    LDA $64,X
    LDY $C8
    BEQ _F264
    CMP #$40
    BCC _F24D
_F264:
    CMP #$c0
    BCC _F236
    LDA #$40
    STA $CF,X
    LDA #$00
    STA $CE,X
    STA $C8,X
    RTS
    
    
_F273:
    LDA $20,X
    BEQ _F2AA
    BMI _F2AB
    CLC
    LDA #$30
    ADC $CD,X
    STA $CD,X
    LDA #$00
    ADC $CC,X
    STA $CC,X
    CLC
    LDA $CD,X
    ADC $C2,X
    STA $C2,X
    LDA $CC,X
    ADC $C1,X
    CMP #$b8
    BCC _F2A4
    TXA
    BNE _F2B6
    LDA $60,X
    AND #$30
    STA $81,X
_F29E:
    LDA #$00
    STA $20,X
    LDA #$b8
_F2A4:
    STA $C1,X
    LDA #$03
    STA $C5,X
_F2AA:
    RTS
    
    
_F2AB:
    DEC $20,X
    LDA #$fd
    STA $CC,X
    LDA #$00
    STA $CD,X
    RTS
    
    
_F2B6:
    STA $C8,X
    LDA #$01
    STA $CE,X
    LDA #$c0
    STA $CF,X
    LDA #$ff
    STA $81,X
    BNE _F29E
_F2C6:
    LDA $B0
    BNE _F2E7
    LDA $A1,X
    BNE _F2E7
    LDA $C0,X
    BEQ _F2E7
    LDA $62,X
    ORA #$10
    AND #$3c
    STA $81,X
    LDY #$10
_F2DC:
    LDA $F094,X
    STA $C0,X
    INX
    DEY
    BNE _F2DC
    STY $B0,X
_F2E7:
    RTS
    
    
    
.byte $00,$02,$01,$02
    
    
_F2EC:
    LDA $C0,X
    BNE _F329
    CLC
    LDA $CF,X
    ADC $C4,X
    STA $C4,X
    LDA $CE,X
    ADC $C3,X
    LDY $B0
    CPY #$20
    BCS _F315
    CMP #$f8
    BCC _F32A
    CPY #$1f
    BCS _F315
    LDA $60,X
    AND #$2f
    ORA #$06
    STA $A1,X
    LDA #$80
    STA $C0,X
_F315:
    STA $C3,X
    LSR A
    LSR A
    AND #$03
    TAY
    LDA $CE,X
    ORA $CF,X
    BNE _F324
    LDY #$01
_F324:
    LDA $F2E8,Y
    STA $C5,X
_F329:
    RTS
    
    
_F32A:
    CMP #$78
    BNE _F315
    CPX $22
    BNE _F315
    LDY $20,X
    BNE _F315
    LDY #$00
    STY $CE,X
    STY $CF,X
    LDY #$80
    STY $20,X
    BNE _F315
_F342:
    LDA $B0
    BNE _F36D
    LDA $C0
    ORA $D0
    BNE _F36D
    CLC
    LDA $C3
    ADC #$19
    CMP $D3
    BCC _F36D
    STA $D3
    LDA #$02
    STA $CE
    STA $DE
    LDA #$00
    STA $CF
    STA $DF
    LDA #$10
    STA $C8
    STA $D8
    LDA #$30
    STA $B0
_F36D:
    RTS
    
    
.byte $2A,$0A,$25,$05,$21,$01,$27,$16
    
    
_F376:
    LDY #$08
    LDA $83
    BNE _F3C8
    LDA $93
    BNE _F3EF
    LDX #$00
_F382:
    LDA $C1,X
    CMP #$a4
    BCS _F39E
    LDA #$20
    LDY $B2
    BNE _F39C
    LDA #$08
    LDY $65
    CPY #$18
    BCS _F39C
    LDA #$08
    STA $B2
    LDA #$20
_F39C:
    STA $83,X
_F39E:
    CPX #$10
    LDX #$10
    BCC _F382
    LDA $22
    BEQ _F3C7
    LDA $82
    BNE _F3C7
    LDA #$08
    STA $82
    LDX #$0f
    LDA $47
    CMP #$0f
    BNE _F3BA
    LDX #$16
_F3BA:
    STX $47
    LDA #$3f
    LDX #$08
    LDY #$08
    JSR _E8D2;,$0040
.word $0040
_F3C7:
    RTS
    
    
_F3C8:
    LDA $F634,Y
    STA $003F,Y
    DEY
    BNE _F3C8
    INC $21
    LDA $21
    AND #$06
    TAY
    LDA $F36E,Y
    STA $42
    LDA $F36F,Y
    STA $43
    LDY #$00
    LDA $B2
    BNE _F3EA
    LDY #$10
_F3EA:
    STY $22
    JMP $F3BC
    
    
_F3EF:
    LDA $F63F,Y
    STA $003F,Y
    DEY
    BNE _F3EF
    BEQ _F3EA
    
    
;????????????????????????????????????????????????????????????????????????????
;initialize graphics?????????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;this subroutine copies pattern	tables from ROM	into the VRAM, and also
;sets up the name & palette tables.
    
;entry point
InitGfx:
    JSR DisPfOBJ;	disable objects	& playfield for	video xfers
    
;src:CPU[$F735]	dest:PPU[$1300]	xfer:88 tiles
    LDA #$00
    LDX #$58
    LDY #$13
    JSR CPUtoPPUcpy;,$F735
.word $F735
;src:CPU[$FCA5]	dest:PPU[$0000]	xfer:25 tiles
    LDA #$00
    LDX #$19
    LDY #$00
    JSR CPUtoPPUcpy;,$FCA5
.word $FCA5
    JSR LoadFonts;	load fonts from	ROM into video mem
    
;dest:PPU[$2000] NTfillVal:=$6D	ATfillVal:=$aa
    LDA #$20
    LDX #$6d
    LDY #$aa
    JSR VRAMfill
    
;dest:PPU[$2800] NTfillVal:=$6D	ATfillVal:=$aa
    LDA #$28
    LDX #$6d
    LDY #$aa
    JSR VRAMfill
    
    JSR VINTwait
    JSR PPUdataPrsr;,InitNT;	initialize name	table
.word InitNT
    RTS
    
    
;????????????????????????????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
    
_F431:
    JSR DisPfOBJ
    LDY #$03
    JSR _F48C   
    JSR LoadFonts
    JSR VINTwait
    JSR PPUdataPrsr;,$F080
.word $F080
    LDA #$20
    LDX #$24
    LDY #$00
    JSR VRAMfill
    LDA $FF
    AND #$fb
    STA $FF
    STA $2000;	[NES] PPU setup	#1
    LDX $2002;	[NES] PPU status
    LDX #$28
    STX $2006;	[NES] VRAM address select
    LDA #$00
    STA $2006;	[NES] VRAM address select
    LDA $2007;	[NES] VRAM data
    LDY #$00
_F468:
    LDA $2007;	[NES] VRAM data
    CMP $ED37,Y ;check copyright strings in vram?
    BNE _F483
    INY
    CPY #$e0
    BNE _F468
    STX $2006;	[NES] VRAM address select
    STY $2006;	[NES] VRAM address select
_F47B:
    LDA #$24
    STA $2007;	[NES] VRAM data
    INY
    BNE _F47B
_F483:
    RTS
    
    
    
.byte $02,$30,$10,$29,$32,$00,$29,$10
    
    
_F48C:
    LDX #$03
_F48E:
    LDA $F484,Y
    STA $07,X
    DEY
    DEX
    BPL _F48E
    LDA #$29
    STA $0B
_F49B:
    LDA $07
    LDX #$01
    LDY $09
    JSR CPUtoPPUcpy;,$0010
.word $0010
    LDA $08
    LDX #$01
    LDY $0A
    JSR CPUtoPPUcpy;,$0010
.word $0010
    LDY #$01
_F4B3:
    CLC
    LDA #$10
    ADC $0007,Y
    STA $0007,Y
    LDA #$00
    ADC $0009,Y
    STA $0009,Y
    DEY
    BPL _F4B3
    DEC $0B
    BNE _F49B
    RTS
    
    
    LDA #$20
    LDX #$24
    LDY #$00
    JSR VRAMfill
    JSR VINTwait
    JSR PPUdataPrsr;,$F066
.word $F066
    JSR _F5FB
    BNE _F527
    LDA #$00
    LDX #$00
    LDY #$00
    JSR CPUtoPPUcpy;,$C000
.word $C000
    LDA #$00
    LDX #$00
    LDY #$10
    JSR CPUtoPPUcpy;,$D000
.word $D000
    LDA #$02
    LDX #$00
    LDY #$00
    JSR CPUtoPPUcpy;,$C000
.word $C000
    LDA #$02
    LDX #$00
    LDY #$10
    JSR CPUtoPPUcpy;,$D000
.word $D000
    LDA #$C0
    STA $01
    LDY #$00
    STY $00
    LDX #$20
    LDA #$7f
    ADC #$02
    JSR _F61B
    BEQ _F54E
    LDA $01
    AND #$03
    STA $01
_F527:
    LDA #$11
    STA $0B
    LDY #$03
    LDA $00
_F52F:
    TAX
    AND #$0F
    STA $0007,Y
    DEY
    TXA
    LSR A
    LSR A
    LSR A
    LSR A
    STA $0007,Y
    LDA $01
    DEY
    BPL _F52F
    LDA #$20
    LDX #$f4
    LDY #$05
    JSR _E8D2;,$0007
.word $0007
_F54E:
    JSR LoadFonts
    JSR GetCtrlrSts
    LDA $F7
    CMP #$81
    BNE _F5B8
    JSR PPUdataPrsr;,$F56B
.word $F56B
    JSR VINTwait
    JSR RstPPU05
    JSR EnPF
    JMP $F568
    
;$F56B internal rom programmed by TAKAO SAWANO
.byte $20,$E7
.byte $0E,$0D,$17,$01,$03,$24,$12,$17,$1D,$0E,$1B,$17,$0A,$15,$24,$1B
.byte $18,$16,$21,$63,$19,$19,$1B,$18,$10,$1B,$0A,$16,$0E,$0D,$24,$0B
.byte $22,$24,$14,$1B,$12,$14,$23,$23,$24,$0D,$0E,$1F,$1C,$24,$21,$A3
.byte $0B,$12,$19,$24,$0B,$18,$19,$24,$0B,$12,$19,$24,$0B,$18,$19,$24
.byte $26,$24,$0D,$0E,$1F,$26,$17,$18,$26,$02
.byte $FF
    
_F5B8:
    LDA #$01
    STA $0F
    LDA #$ff
    CLC
    PHA
    PHP
    JSR VINTwait
    JSR _E86A
    JSR RstPPU05
    JSR EnPF
    DEC $0F
    BNE _F5DD
    PLP
    PLA
    STA $4026
    ROL A
    PHA
    PHP
    LDA #$19
    STA $0F
_F5DD:
    LDA $4033
    LDX #$07
_F5E2:
    LDY #$01
    ASL A
    BCS _F5E8
    DEY
_F5E8:
    STY $07,X
    DEX
    BPL _F5E2
    LDA #$21
    LDX #$70
    LDY #$08
    JSR _E8D2;,$0007
.word $0007
    JMP $F5C1
    
    
_F5FB:
    LDA #$60
    LDX #$80
    STX $03
    PHA
    STA $01
    LDY #$00
    STY $00
    CLV
    JSR _F61B
    PLA
    STA $01
    STY $00
    LDX $03
    LDA #$7f
    ADC #$02
    JSR _F61B
    RTS
    
    
_F61B:
    STX $02
_F61D:
    LDA $02
    BVS _F62E
    STA ($00),Y
_F623:
    INC $02
    DEY
    BNE _F61D
    INC $01
    DEX
    BNE _F61B
    RTS
    
    
_F62E:
    CMP ($00),Y
    BEQ _F623
    STY $00
    RTS
    
;$F635
.byte $0F,$30,$27,$16,$0F,$10,$00,$16
    
;PPU processor data
InitNT:
.byte $3F,$08,$18
.byte $0F,$21,$01,$0F
.byte $0F,$00,$02,$01
.byte $0F,$27,$16,$01
.byte $0F,$27,$30,$1A
.byte $0F,$0F,$01,$0F
.byte $0F,$0F,$0F,$0F

.byte $20,$E4,$02,$6E,$73
.byte $20,$E6,$54,$77
.byte $20,$FA,$02,$78,$7C
.byte $21,$04,$02,$6F,$74
.byte $21,$06,$54,$24
.byte $21,$1A,$02,$79,$7D
.byte $21,$24,$C5,$70
.byte $21,$3B,$C5,$70
.byte $21,$25,$C5,$24
.byte $21,$3A,$C5,$24
.byte $21,$C4,$02,$71,$75
.byte $21,$C6,$54,$24
.byte $21,$DA,$02,$7A,$7E
.byte $21,$E4,$02,$72,$76
.byte $21,$E6,$54,$77
.byte $21,$FA,$02,$7B,$7F
.byte $21,$26,$14,$30,$34,$38,$3B,$3F,$24,$24,$47,$4B,$24,$24,$24,$24,$24,$24,$5D,$61,$24,$24,$28
.byte $21,$46,$14,$31,$35,$32,$3C,$40,$43,$46,$48,$4C,$4E,$51,$3C,$54,$57,$5A,$5E,$62,$65,$68,$6B
.byte $21,$66,$14,$32,$36,$39,$3D,$41,$44,$32,$49,$4D,$4F,$52,$3D,$55,$58,$5B,$5F,$63,$66,$69,$6C
.byte $21,$86,$14,$33,$37,$3A,$3E,$42,$45,$33,$4A,$45,$50,$53,$3E,$56,$59,$5C,$60,$64,$67,$6A,$24
.byte $21,$A6,$54,$24
.byte $22,$0F,$C4,$83
.byte $22,$10,$C4,$84
.byte $22,$8F,$02,$85,$86
.byte $23,$E0,$50,$FF
.byte $23,$F0,$48,$AF
.byte $FF
.byte $20,$40,$60,$80
.byte $20,$20,$60,$81
.byte $20,$00,$60,$81
.byte $FF
.byte $23,$40,$60,$80
.byte $23,$60,$60,$81
.byte $FF
.byte $23,$80,$60,$82
.byte $23,$A0,$60,$82
.byte $FF

PPU_ADDR        =$2006
PPU_DATA	=$2007

;$F735
.segment "USER"
text:
txt_err:
.asciiz "DISK ERROR"

ChkDiskHdr_:
    ;ldy #$06
    ;lda #$2A
    ;sta $402f
    ;lda ($00),y
    ;sta $402e
    ;iny
    ;lda ($00),y
    ;sta $402f

    jmp ChkDiskHdr_

err:
    JSR VINTwait
    jsr DisPfOBJ

    LDA #$20
    LDX #$24
    LDY #$00
    JSR VRAMfill


    LDY #$21
    LDX #$AB
    lda #(txt_err-text)
    jsr print

    JSR RstPPU05

    JSR VINTwait
    jsr EnPF
    jmp forever

init_gfx: 
    JSR VINTwait
    jsr DisPfOBJ
    LDA #$00
    LDX #$00
    LDY #32
    JSR VRAMfill

    LDA #$20
    LDX #$24
    LDY #$00
    JSR VRAMfill

    LDA #$28
    LDX #$24
    LDY #$00
    JSR VRAMfill

    JSR LoadFonts


    lda #$3f
    sta PPU_ADDR
    lda #$00
    sta PPU_ADDR

    lda #$02
    sta PPU_DATA
    lda #$30
    sta PPU_DATA
    lda #$02
    sta PPU_DATA
    sta PPU_DATA
    
    JSR RstPPU05

    ;jsr EnPfOBJ
    ;jmp forever
    rts

skip:
    rts

print: 
    sty PPU_ADDR
    stx PPU_ADDR
    tax
@1:
    lda text, x
    cmp #0
    beq @2
    clc
    sbc #$36
    sta PPU_DATA
    inx
    jmp @1
@2:
    rts

forever:
    jmp forever


fds_disk_addr = $4037
fds_disk = $4400
disk_rw_og:
    STA $4024
    ldx fds_disk_addr
    lda fds_disk + $000, x
    lda fds_disk + $100, x
    lda fds_disk + $200, x
    lda fds_disk + $300, x
    LDX $4031

    PLA
    PLA
    PLA
    TXA
    RTS

font:
;.incbin "font-fds.bin"
.segment "USER_END"    
.byte $FF
_FE36:
    LSR A
    BCS _FE66
    LSR $E1
    BCS _FE47
    LSR A
    BCS _FEA6
    LSR $E1
    BCS _FE7A
    JMP $FF6A
    
    
_FE47:
    LDA #$10
    STA $4000;	[NES] Audio - Square 1
    LDA #$01
    STA $4008;	[NES] Audio - Triangle
    STY $E3
    LDA #$20
    STA $E4
    LDX #$5c
    LDY #$7f
    STX $4004;	[NES] Audio - Square 2
    STY $4005;	[NES] Audio - Square 2
    LDA #$f9
    STA $4007;	[NES] Audio - Square 2
_FE66:
    LDA $E4
    LSR A
    BCC _FE6F
    LDA #$0d
    BNE _FE71
_FE6F:
    LDA #$7c
_FE71:
    STA $4006;	[NES] Audio - Square 2
    JMP $FFC6
    
    
_FE77:
    JMP $FFCA
    
    
_FE7A:
    STY $E3
    LDX #$9c
    LDY #$7f
    STX $4000;	[NES] Audio - Square 1
    STX $4004;	[NES] Audio - Square 2
    STY $4001;	[NES] Audio - Square 1
    STY $4005;	[NES] Audio - Square 2
    LDA #$20
    STA $4008;	[NES] Audio - Triangle
    LDA #$01
    STA $400C;	[NES] Audio - Noise control reg
    LDX #$00
    STX $E9
    STX $EA
    STX $EB
    LDA #$01
    STA $E6
    STA $E7
    STA $E8
_FEA6:
    DEC $E6
    BNE _FEC1
    LDY $E9
    INY
    STY $E9
    LDA $FF1F,Y
    BEQ _FE77
    JSR _FFE9
    STA $E6
    TXA
    AND #$3e
    LDX #$04
    JSR _FFD9
_FEC1:
    DEC $E7
    BNE _FEDA
    LDY $EA
    INY
    STY $EA
    LDA $FF33,Y
    JSR _FFE9
    STA $E7
    TXA
    AND #$3e
    LDX #$00
    JSR _FFD9
_FEDA:
    DEC $E8
    BNE _FEFD
    LDA #$09
    STA $400E;	[NES] Audio - Noise Frequency reg #1
    LDA #$08
    STA $400F;	[NES] Audio - Noise Frequency reg #2
    LDY $EB
    INY
    STY $EB
    LDA $FF46,Y
    JSR _FFE9
    STA $E8
    TXA
    AND #$3e
    LDX #$08
    JSR _FFD9
_FEFD:
    JMP $FF6A
    
    
.byte $03,$57,$00,$00,$08,$D4,$08,$BD,$08,$B2,$09,$AB,$09,$7C,$09,$3F
.byte $09,$1C,$08,$FD,$08,$EE,$09,$FC,$09,$DF,$06,$0C,$12,$18,$08,$48
.byte $CA,$CE,$D4,$13,$11,$0F,$90,$10,$C4,$C8,$07,$05,$15,$C4,$D2,$D4
.byte $8E,$0C,$4F,$00,$D6,$D6,$CA,$0B,$19,$17,$98,$18,$CE,$D4,$15,$13
.byte $11,$D2,$CA,$CC,$96,$18,$57,$CE,$0F,$0F,$0F,$CE,$CE,$CE,$CE,$CE
.byte $0F,$0F,$0F,$CE,$CE,$CE,$CE,$CE,$0F,$0F,$0F,$CE
    
    
_FF5C:
    LDY $E1
    LDA $E3
    LSR $E1
    BCS _FF7B ;part of welcome beep
    LSR A
    BCS _FF9A ;part of welcome beep
    JMP _FE36 ;error
    LDA #$00
    STA $E1
    RTS
    
    
    
.byte $06,$0C,$12,$47,$5F,$71,$5F,$71,$8E,$71,$8E,$BE
    
    
_FF7B:
    STY $E3
    LDA #$12
    STA $E4
    LDA #$02
    STA $E5
    LDX #$9f
    LDY #$7f
    STX $4000;	[NES] Audio - Square 1
    STX $4004;	[NES] Audio - Square 2
    STY $4001;	[NES] Audio - Square 1
    STY $4005;	[NES] Audio - Square 2
    LDA #$20
    STA $4008;	[NES] Audio - Triangle
_FF9A:
    LDA $E4
    LDY $E5
    CMP $FF6F,Y
    BNE _FFC6
    LDA $FF72,Y
    STA $4002;	[NES] Audio - Square 1
    LDX #$58
    STX $4003;	[NES] Audio - Square 1
    LDA $FF75,Y
    STA $4006;	[NES] Audio - Square 2
    STX $4007;	[NES] Audio - Square 2
    LDA $FF78,Y
    STA $400A;	[NES] Audio - Triangle
    STX $400B;	[NES] Audio - Triangle
    LDA $E5
    BEQ _FFC6
    DEC $E5
_FFC6:
    DEC $E4
    BNE _FFD6
    LDA #$00
    STA $E3
    LDA #$10
    STA $4000;	[NES] Audio - Square 1
    STA $4004;	[NES] Audio - Square 2
_FFD6:
    JMP $FF6A
    
    
_FFD9:
    TAY
    LDA $FF01,Y
    BEQ _FFE8
    STA $4002,X;	[NES] Audio - Square 1
    LDA $FF00,Y
    STA $4003,X;	[NES] Audio - Square 1
_FFE8:
    RTS
    
    
_FFE9:
    TAX
    ROR A
    TXA
    ROL A
    ROL A
    ROL A
    AND #$07
    TAY
    LDA $FF1A,Y
    RTS
    
.byte $FF,$FF,$FF,$01
    
.segment "VECTORS"

.word  NMI, Reset, IRQ
