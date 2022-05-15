
.segment "CODE"

.byte $00
.incbin "font.bin"

;131 clock cycle delay
Delay131:	PHA
$E14A	LDA #$16
$E14C	SEC
$E14D	SBC #$01
$E14F	BCS $E14D
$E151	PLA
$E152	RTS

;millisecond delay timer. Delay	in clock cycles	is: 1790*Y+5.
MilSecTimer:	;0x153
LDX $00
$E155	LDX #$fe
$E157	NOP
$E158	DEX
$E159	BNE $E157
$E15B	CMP $00
$E15D	DEY
$E15E	BNE MilSecTimer
$E160	RTS

;disable playfield & objects
DisPfOBJ:	LDA $FE
$E163	AND #$e7
$E165	STA $FE
$E167	STA $2001;	[NES] PPU setup	#2
$E16A	RTS

;enable playfield & objects
EnPfOBJ:	LDA $FE
$E16D	ORA #$18
$E16F	BNE $E165

;disable objects
DisOBJs:	LDA $FE
$E173	AND #$ef
$E175	JMP $E165

;enable objects
EnOBJs:	LDA $FE
$E17A	ORA #$10
$E17C	BNE $E165

;disable playfield
DisPF:	LDA $FE
$E180	AND #$f7
$E182	JMP $E165

;enable playfield
EnPF:	LDA $FE
$E187	ORA #$08
$E189	BNE $E165


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
NMI:	BIT $0100
$E18E	BPL $E198
$E190	BVC $E195
$E192	JMP ($DFFA);	11xxxxxx
$E195	JMP ($DFF8);	10xxxxxx
$E198	BVC $E19D
$E19A	JMP ($DFF6);	01xxxxxx

;disable further VINTs	00xxxxxx
$E19D	LDA $FF
$E19F	AND #$7f
$E1A1	STA $FF
$E1A3	STA $2000;	[NES] PPU setup	#1
$E1A6	LDA $2002;	[NES] PPU status

;discard interrupted return address (should be $E1C5)
$E1A9	PLA
$E1AA	PLA
$E1AB	PLA

;restore byte at [$0100]
$E1AC	PLA
$E1AD	STA $0100

;restore A
$E1B0	PLA
$E1B1	RTS


;----------------------------------------------------------------------------
;wait for VINT
VINTwait:	PHA;	save A
$E1B3	LDA $0100
$E1B6	PHA;	save old NMI pgm ctrl byte
$E1B7	LDA #$00
$E1B9	STA $0100;	set NMI pgm ctrl byte to 0

;enable VINT
$E1BC	LDA $FF
$E1BE	ORA #$80
$E1C0	STA $FF
$E1C2	STA $2000;	[NES] PPU setup	#1

;infinite loop
$E1C5	BNE $E1C5


;????????????????????????????????????????????????????????????????????????????
;IRQ program control?????????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;this routine controls what action occurs on a IRQ, based on [$0101].
IRQ:	BIT $0101
$E1CA	BMI $E1EA
$E1CC	BVC $E1D9

;disk transfer routine ([$0101]	= 01xxxxxx)
$E1CE	LDX $4031
$E1D1	STA $4024
$E1D4	PLA
$E1D5	PLA
$E1D6	PLA
$E1D7	TXA
$E1D8	RTS

;disk byte skip	routine ([$0101] = 00nnnnnn; n is # of bytes to	skip)
;this is mainly	used when the CPU has to do some calculations while bytes
;read off the disk need to be discarded.
$E1D9	PHA
$E1DA	LDA $0101
$E1DD	SEC
$E1DE	SBC #$01
$E1E0	BCC $E1E8
$E1E2	STA $0101
$E1E5	LDA $4031
$E1E8	PLA
$E1E9	RTI

;[$0101] = 1Xxxxxxx
$E1EA	BVC $E1EF
$E1EC	JMP ($DFFE);	11xxxxxx

;disk IRQ acknowledge routine ([$0101] = 10xxxxxx).
;don't know what this is used for, or why a delay is put here.
$E1EF	PHA
$E1F0	LDA $4030
$E1F3	JSR Delay131
$E1F6	PLA
$E1F7	RTI


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


LoadFiles:	LDA #$00
$E1FA	STA $0E
$E1FC	LDA #$ff;	get 2 16-bit pointers
$E1FE	JSR GetHCPwNWPchk
$E201	LDA $0101
$E204	PHA
$E205	LDA #$02;	error retry count
$E207	STA $05
$E209	JSR $E21A
$E20C	BEQ $E212;	return address if errors occur
$E20E	DEC $05;	decrease retry count
$E210	BNE $E209
$E212	PLA
$E213	STA $0101
$E216	LDY $0E
$E218	TXA
$E219	RTS

$E21A	JSR ChkDiskHdr
$E21D	JSR Get#ofFiles;returns # in [$06]
$E220	LDA $06
$E222	BEQ $E233;	skip it all if none
$E224	LDA #$03
$E226	JSR CheckBlkType
$E229	JSR FileMatchTest
$E22C	JSR LoadData
$E22F	DEC $06
$E231	BNE $E224
$E233	JSR XferDone
$E236	RTS


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
AppendFile:	LDA #$ff;	use current DiskFileCount
WriteFile:	STA $0E;	specify file count in A
$E23B	LDA #$ff
$E23D	JSR GetHCPwWPchk;loads Y with [$0E] on error
$E240	LDA $0101
$E243	PHA

;write data to end of disk
$E244	LDA #$03;	2 tries
$E246	STA $05
$E248	DEC $05
$E24A	BEQ $E265
$E24C	JSR WriteLastFile
$E24F	BNE $E248

;verify data at	end of disk
$E251	LDA #$02
$E253	STA $05
$E255	JSR CheckLastFile
$E258	BEQ $E265
$E25A	DEC $05
$E25C	BNE $E255

;if error occured during readback, hide last file
$E25E	STX $05;	save error #
$E260	JSR SetFileCnt
$E263	LDX $05;	restore error #

;return
$E265	PLA
$E266	STA $0101
$E269	TXA
$E26A	RTS

WriteLastFile:	JSR ChkDiskHdr
$E26E	LDA $0E
$E270	CMP #$ff
$E272	BNE $E288
$E274	JSR Get#ofFiles
$E277	JSR SkipFiles;	advance to end of disk
$E27A	LDA #$03
$E27C	JSR WriteBlkType
$E27F	LDA #$00
$E281	JSR SaveData;	write out last file
$E284	JSR XferDone
$E287	RTS
$E288	STA $06
$E28A	JSR Set#ofFiles
$E28D	JMP $E277

CheckLastFile:	JSR ChkDiskHdr
$E293	LDX $06;	load current file count
$E295	INX
$E296	TXA
$E297	JSR Set#ofFiles;increase current file count
$E29A	JSR SkipFiles;	skip to last file
$E29D	LDA #$03
$E29F	JSR CheckBlkType
$E2A2	LDA #$ff
$E2A4	JSR SaveData;	verify last file
$E2A7	JSR XferDone
$E2AA	RTS

;sets file count via [$06]
SetFileCnt:	JSR ChkDiskHdr
$E2AE	LDA $06
$E2B0	JSR Set#ofFiles
$E2B3	JSR XferDone
$E2B6	RTS


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

SetFileCnt2:	LDX #$ff;	use A value
$E2B9	BNE $E2BD
AdjFileCnt:	LDX #$00;	use FileCnt-A
$E2BD	STX $09
$E2BF	JSR GetHCPwWPchk
$E2C2	LDA $0101
$E2C5	PHA

;get disk file count
$E2C6	LDA #$03;	2 tries
$E2C8	STA $05
$E2CA	DEC $05
$E2CC	BEQ $E2F1
$E2CE	JSR GetFileCnt
$E2D1	BNE $E2CA

;calculate difference
$E2D3	LDA $06;	load file count
$E2D5	SEC
$E2D6	SBC $02;	calculate difference
$E2D8	LDX $09
$E2DA	BEQ $E2DE
$E2DC	LDA $02;	use original accumulator value
$E2DE	LDX #$31;
$E2E0	BCC $E2F1;	branch if A is less than current file count
$E2E2	STA $06

;set disk file count
$E2E4	LDA #$02;	2 tries
$E2E6	STA $05
$E2E8	JSR SetFileCnt
$E2EB	BEQ $E2F1
$E2ED	DEC $05
$E2EF	BNE $E2E8

$E2F1	PLA
$E2F2	STA $0101
$E2F5	TXA
$E2F6	RTS

;stores file count in [$06]
GetFileCnt:	JSR ChkDiskHdr
$E2FA	JSR Get#ofFiles
$E2FD	JSR XferDone
$E300	RTS


;????????????????????????????????????????????????????????????????????????????
;set disk file count?????????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;this routine only rewrites a disk's file count (stored in block 2; specified
;in A). no other files are read/written after this. uses header	compare
;string.

SetFileCnt1:	LDX #$01;	add 1 to value in A
$E303	BNE $E307
SetFileCnt0:	LDX #$00;	normal entry point
$E307	STX $07
$E309	JSR GetHCPwWPchk
$E30C	LDA $0101
$E30F	PHA
$E310	CLC
$E311	LDA $02;	initial A value	(or 3rd byte in	HC parameter)
$E313	ADC $07
$E315	STA $06
$E317	LDA #$02;	2 tries
$E319	STA $05
$E31B	JSR SetFileCnt
$E31E	BEQ $E324
$E320	DEC $05
$E322	BNE $E31B
$E324	PLA
$E325	STA $0101
$E328	TXA
$E329	RTS


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

GetDiskInfo:	LDA #$00
$E32C	JSR GetHCPwNWPchk;get 1 16-bit pointer; put A in [$02]
$E32F	LDA $0101
$E332	PHA
$E333	LDA #$02
$E335	STA $05
$E337	JSR $E346
$E33A	BEQ $E340;	escape if no errors
$E33C	DEC $05
$E33E	BNE $E337
$E340	PLA
$E341	STA $0101
$E344	TXA
$E345	RTS

;start up disk read process
$E346	JSR StartXfer;	verify FDS string at beginning of disk
$E349	LDA $00
$E34B	STA $0A
$E34D	LDA $01
$E34F	STA $0B
$E351	LDY #$00
$E353	STY $02
$E355	STY $03

;load next 10 bytes off disk into RAM at Ptr($0A)
$E357	JSR XferByte
$E35A	STA ($0A),Y
$E35C	INY
$E35D	CPY #$0a
$E35F	BNE $E357
$E361	JSR AddYtoPtr0A;add 10 to Word($0A)

;discard rest of data in this file (31 bytes)
$E364	LDY #$1f
$E366	JSR XferByte
$E369	DEY
$E36A	BNE $E366

;get # of files
$E36C	JSR EndOfBlkRead
$E36F	JSR Get#ofFiles;stores it in [$06]
$E372	LDY #$00
$E374	LDA $06
$E376	STA ($0A),Y;	store # of files in ([$0A])
$E378	BEQ $E3CB;	branch if # of files = 0

;get info for next file
$E37A	LDA #$03
$E37C	JSR CheckBlkType
$E37F	JSR XferByte;	discard file sequence #
$E382	JSR XferByte;	file ID code
$E385	LDY #$01
$E387	STA ($0A),Y;	store file ID code

;store file name string (8 letters)
$E389	INY
$E38A	JSR XferByte
$E38D	STA ($0A),Y
$E38F	CPY #$09
$E391	BNE $E389

$E393	JSR AddYtoPtr0A;advance 16-bit dest ptr
$E396	JSR XferByte;	throw away low	load address
$E399	JSR XferByte;	throw away high	load address

;Word($02) += $105 + FileSize
$E39C	CLC
$E39D	LDA #$05
$E39F	ADC $02
$E3A1	STA $02
$E3A3	LDA #$01
$E3A5	ADC $03
$E3A7	STA $03
$E3A9	JSR XferByte;	get low  FileSize
$E3AC	STA $0C
$E3AE	JSR XferByte;	get high FileSize
$E3B1	STA $0D
$E3B3	CLC
$E3B4	LDA $0C
$E3B6	ADC $02
$E3B8	STA $02
$E3BA	LDA $0D
$E3BC	ADC $03
$E3BE	STA $03
$E3C0	LDA #$ff
$E3C2	STA $09
$E3C4	JSR RdData;	dummy read data	off disk
$E3C7	DEC $06;	decrease file count #
$E3C9	BNE $E37A

;store out disk	size
$E3CB	LDA $03
$E3CD	LDY #$01;	fix-up from RdData
$E3CF	STA ($0A),Y
$E3D1	LDA $02
$E3D3	INY
$E3D4	STA ($0A),Y
$E3D6	JSR XferDone
$E3D9	RTS

;adds Y to Word(0A)
AddYtoPtr0A:	TYA
$E3DB	CLC
$E3DC	ADC $0A
$E3DE	STA $0A
$E3E0	LDA #$00
$E3E2	ADC $0B
$E3E4	STA $0B
$E3E6	RTS


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
GetHCPwNWPchk:	SEC;	don't do write-protect check
$E3E8	BCS $E3EB
GetHCPwWPchk:	CLC;	check for write	protection

;load 2nd return address into Ptr($05)
$E3EB	TSX
$E3EC	DEX
$E3ED	STX $04;	store stack pointer-1 in [$04]
$E3EF	PHP
$E3F0	STA $02
$E3F2	LDY $0104,X
$E3F5	STY $05
$E3F7	LDY $0105,X
$E3FA	STY $06

;load 1st 16-bit parameter into	Ptr($00)
$E3FC	TAX
$E3FD	LDY #$01
$E3FF	LDA ($05),Y
$E401	STA $00
$E403	INY
$E404	LDA ($05),Y
$E406	STA $01
$E408	LDA #$02

;load 2nd 16-bit parameter into	Ptr($02) if A was originally -1
$E40A	CPX #$ff
$E40C	BNE $E41A
$E40E	INY
$E40F	LDA ($05),Y
$E411	STA $02
$E413	INY
$E414	LDA ($05),Y
$E416	STA $03
$E418	LDA #$04

;increment 2nd return address appropriately
$E41A	LDX $04
$E41C	CLC
$E41D	ADC $05
$E41F	STA $0104,X
$E422	LDA #$00
$E424	ADC $06
$E426	STA $0105,X

;test disk set status flag
$E429	PLP
$E42A	LDX #$01;	disk set error
$E42C	LDA $4032
$E42F	AND #$01
$E431	BNE $E43E
$E433	BCS $E444;	skip write-protect check

;test write-protect status
$E435	LDX #$03;	write-protect error
$E437	LDA $4032
$E43A	AND #$04
$E43C	BEQ $E444

;discard return	address if tests fail
$E43E	PLA
$E43F	PLA
$E440	LDY $0E
$E442	TXA
$E443	CLI
$E444	RTS


;????????????????????????????????????????????????????????????????????????????
;disk header check???????????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;routine simply	compares the first 10 bytes on the disk coming after the FDS
;string, to 10 bytes pointed to	by Ptr($00). To	bypass the checking of any
;byte, a -1 can	be placed in the equivelant place in the compare string.
;Otherwise, if the comparison fails, an appropriate error will be generated.

ChkDiskHdr:	JSR StartXfer;	check FDS string
$E448	LDX #$04
$E44A	STX $08
$E44C	LDY #$00
$E44E	JSR XferByte
$E451	CMP ($00),Y;	compares code to byte stored at	[Ptr($00)+Y]
$E453	BEQ $E464
$E455	LDX $08
$E457	CPX #$0a
$E459	BNE $E45D
$E45B	LDX #$10
$E45D	LDA ($00),Y
$E45F	CMP #$ff
$E461	JSR XferFailOnNEQ
$E464	INY
$E465	CPY #$01
$E467	BEQ $E46D
$E469	CPY #$05
$E46B	BCC $E46F
$E46D	INC $08
$E46F	CPY #$0a
$E471	BNE $E44E
$E473	JSR XferByte;	boot read file code
$E476	STA $08
$E478	LDY #$1e;	30 iterations
$E47A	JSR XferByte;	dummy read 'til end of block
$E47D	DEY
$E47E	BNE $E47A
$E480	JSR EndOfBlkRead
$E483	RTS


;????????????????????????????????????????????????????????????????????????????
;file count block routines???????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;these routines	specifically handle reading & writing of the file count block
;stored on FDS disks.

;loads # of files recorded in block type #2 into [$06]
Get#ofFiles:	LDA #$02
$E486	JSR CheckBlkType
$E489	JSR XferByte
$E48C	STA $06
$E48E	JSR EndOfBlkRead
$E491	RTS

;writes # of files (via A) to be recorded on disk.
Set#ofFiles:	PHA
$E493	LDA #$02
$E495	JSR WriteBlkType
$E498	PLA
$E499	JSR XferByte;	write out disk file count
$E49C	JSR EndOfBlkWrite
$E49F	RTS


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

FileMatchTest:	JSR XferByte;	file sequence #
$E4A3	JSR XferByte;	file ID # (gets	loaded into X)
$E4A6	LDA #$08;	set IRQ mode to	skip next 8 bytes
$E4A8	STA $0101
$E4AB	CLI
$E4AC	LDY #$00
$E4AE	LDA ($02),Y
$E4B0	CMP #$ff;	if Ptr($02) = -1 then test boot	ID code
$E4B2	BEQ $E4C8

$E4B4	TXA;	file ID #
$E4B5	CMP ($02),Y
$E4B7	BEQ $E4CE
$E4B9	INY
$E4BA	CPY #$14
$E4BC	BEQ $E4C4
$E4BE	LDA ($02),Y
$E4C0	CMP #$ff
$E4C2	BNE $E4B4

$E4C4	LDA #$ff
$E4C6	BNE $E4D2
$E4C8	CPX $08;	compare boot read file code to current
$E4CA	BEQ $E4CE
$E4CC	BCS $E4D2;	branch if above	(or equal, but isn't possible)
$E4CE	LDA #$00
$E4D0	INC $0E
$E4D2	STA $09
$E4D4	LDA $0101
$E4D7	BNE $E4D4;	wait until all 8 bytes have been read
$E4D9	RTS


;????????????????????????????????????????????????????????????????????????????
;skip files??????????????????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;this routine uses the value stored in [$06] to	determine how many files to
;dummy-read (skip over) from the current file position.

SkipFiles:	LDA $06
$E4DC	STA $08
$E4DE	BEQ $E4F8;	branch if file count = 0
$E4E0	LDA #$03
$E4E2	JSR CheckBlkType
$E4E5	LDY #$0a;	skip 10 bytes
$E4E7	JSR XferByte
$E4EA	DEY
$E4EB	BNE $E4E7
$E4ED	LDA #$ff
$E4EF	STA $09
$E4F1	JSR LoadData;	dummy read file	data
$E4F4	DEC $08
$E4F6	BNE $E4E0
$E4F8	RTS


;????????????????????????????????????????????????????????????????????????????
;load file off disk into memory??????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;loads data from current file off disk into a destination address specified
;by the file's header information stored on disk.

;params
;------
;[$09]:	dummy read only	(if not zero)


LoadData:	LDY #$00
$E4FB	JSR Xfer1stByte
$E4FE	STA $000A,Y
$E501	INY
$E502	CPY #$04
$E504	BNE $E4FB

;Ptr($0A):	destination address
;Ptr($0C):	byte xfer count

RdData:	JSR DecPtr0C
$E509	JSR XferByte;	get kind of file
$E50C	PHA
$E50D	JSR EndOfBlkRead
$E510	LDA #$04
$E512	JSR CheckBlkType
$E515	LDY $09
$E517	PLA
$E518	BNE $E549;	copy to VRAM if	not zero

$E51A	CLC
$E51B	LDA $0A
$E51D	ADC $0C
$E51F	LDA $0B
$E521	ADC $0D
$E523	BCS $E531;	branch if (DestAddr+XferCnt)<10000h

;if DestAddr < 0200h then do dummy copying
$E525	LDA $0B
$E527	CMP #$20
$E529	BCS $E533;	branch if DestAddr >= 2000h
$E52B	AND #$07
$E52D	CMP #$02
$E52F	BCS $E533;	branch if DestAddr >= 0200h
$E531	LDY #$ff

$E533	JSR XferByte
$E536	CPY #$00
$E538	BNE $E542
$E53A	STA ($0A),Y
$E53C	INC $0A
$E53E	BNE $E542
$E540	INC $0B
$E542	JSR DecPtr0C
$E545	BCS $E533
$E547	BCC $E572

;VRAM data copy
$E549	CPY #$00
$E54B	BNE $E563
$E54D	LDA $FE
$E54F	AND #$e7
$E551	STA $FE
$E553	STA $2001;	[NES] PPU setup	#2
$E556	LDA $2002;	[NES] PPU status
$E559	LDA $0B
$E55B	STA $2006;	[NES] VRAM address select
$E55E	LDA $0A
$E560	STA $2006;	[NES] VRAM address select

$E563	JSR XferByte
$E566	CPY #$00
$E568	BNE $E56D
$E56A	STA $2007;	[NES] VRAM data
$E56D	JSR DecPtr0C
$E570	BCS $E563

$E572	LDA $09
$E574	BNE $E57A
$E576	JSR EndOfBlkRead
$E579	RTS
$E57A	JSR XferByte
$E57D	JSR XferByte
$E580	JMP ChkDiskSet


;????????????????????????????????????????????????????????????????????????????
;load size & source address operands into $0A..$0D???????????????????????????
;????????????????????????????????????????????????????????????????????????????
;this routine is used only for when writing/verifying file data	on disk. it
;uses the data string at Ptr($02) to load size and source address operands
;into Ptr($0C) and Ptr($0A), respectfully. It also checks if the source
;address is from video memory, and programs the	PPU address register if so.

;load size of file via string offset $0B into Word($0C)
LoadSiz&Src:	LDY #$0b
$E585	LDA ($02),Y;	file size LO
$E587	STA $0C
$E589	INY
$E58A	LDA ($02),Y;	file size HI
$E58C	STA $0D

;load source address via string	offset $0E into	Ptr($0A)
$E58E	LDY #$0e
$E590	LDA ($02),Y;	source address LO
$E592	STA $0A
$E594	INY
$E595	LDA ($02),Y;	source address HI
$E597	STA $0B

;load source type byte (anything other than 0 means use PPU memory)
$E599	INY
$E59A	LDA ($02),Y
$E59C	BEQ $E5B1

;program PPU address registers with source address
$E59E	JSR DisPfOBJ
$E5A1	LDA $2002;	reset flip-flop
$E5A4	LDA $0B
$E5A6	STA $2006;	store HI address
$E5A9	LDA $0A
$E5AB	STA $2006;	store LO address
$E5AE	LDA $2007;	discard first read
$E5B1	JSR DecPtr0C;	adjust transfer	count for range	(0..n-1)
$E5B4	RTS


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
SaveData:	STA $09;	value of A is stored in [$09]
$E5B7	LDA $06;	load current file #
$E5B9	JSR XferByte;	write out file sequence # (from	[$06])
$E5BC	LDX $09
$E5BE	BEQ $E5C7;	[$09] should be	set to jump when writing
$E5C0	LDX #$26;	error #
$E5C2	CMP $06;	cmp. recorded sequence # to what it should be
$E5C4	JSR XferFailOnNEQ

;loop to write/check entire file header block (minus the file sequence #)
$E5C7	LDY #$00
$E5C9	LDA ($02),Y;	load header byte
$E5CB	JSR XferByte;	write it out (or read it in)
$E5CE	LDX $09
$E5D0	BEQ $E5D9;	jump around check if writing data to disk
$E5D2	LDX #$26;	error #
$E5D4	CMP ($02),Y;	cmp. recorded header byte to what it should be
$E5D6	JSR XferFailOnNEQ
$E5D9	INY;	advance pointer	position
$E5DA	CPY #$0e;	loop is finished if 14 bytes have been checked
$E5DC	BNE $E5C9

;set up next block for reading
$E5DE	LDX $09
$E5E0	BEQ $E616;	branch if writing instead
$E5E2	JSR EndOfBlkRead
$E5E5	JSR LoadSiz&Src;sets up Ptr($0A) & Ptr($0C)
$E5E8	LDA #$04
$E5EA	JSR CheckBlkType

;check source type and read/verify status
$E5ED	LDY #$10
$E5EF	LDA ($02),Y;	check data source type bit
$E5F1	BNE $E624;	branch if NOT in CPU memory map	(PPU instead)
$E5F3	LDY #$00
$E5F5	LDX $09;	check if reading or writing
$E5F7	BEQ $E60A;	branch if writing

;check data on disk
$E5F9	JSR XferByte
$E5FC	LDX #$26
$E5FE	CMP ($0A),Y
$E600	JSR XferFailOnNEQ
$E603	JSR inc0Adec0C
$E606	BCS $E5F9
$E608	BCC $E638

;write data to disk
$E60A	LDA ($0A),Y
$E60C	JSR XferByte
$E60F	JSR inc0Adec0C
$E612	BCS $E60A
$E614	BCC $E638

;set up next block for writing
$E616	JSR EndOfBlkWrite
$E619	JSR LoadSiz&Src;sets up Ptr($0A) & Ptr($0C)
$E61C	LDA #$04
$E61E	JSR WriteBlkType
$E621	JMP $E5ED

;verify data on	disk with VRAM
$E624	LDX $09
$E626	BEQ $E640
$E628	JSR XferByte
$E62B	LDX #$26;	error #
$E62D	CMP $2007
$E630	JSR XferFailOnNEQ
$E633	JSR DecPtr0C
$E636	BCS $E624

;end block reading
$E638	LDX $09
$E63A	BEQ $E649;	branch if writing instead
$E63C	JSR EndOfBlkRead
$E63F	RTS

;write data from VRAM to disk
$E640	LDA $2007;	[NES] VRAM data
$E643	JSR XferByte
$E646	JMP $E633

;end block writing
$E649	JSR EndOfBlkWrite
$E64C	RTS


;????????????????????????????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;waits until drive is ready (i.e., the disk head is at the start of the disk)
WaitForRdy:	JSR StopMotor
$E650	LDY #$00
$E652	JSR MilSecTimer;0.256 sec delay
$E655	JSR MilSecTimer;0.256 sec delay
$E658	JSR StartMotor
$E65B	LDY #$96
$E65D	JSR MilSecTimer;0.150 sec delay
$E660	LDA $F9
$E662	ORA #$80;	enable battery checking
$E664	STA $F9
$E666	STA $4026
$E669	LDX #$02;	battery error
$E66B	EOR $4033
$E66E	ROL A
$E66F	JSR XferFailOnCy
$E672	JSR StopMotor
$E675	JSR StartMotor
$E678	LDX #$01;	disk set error
$E67A	LDA $4032
$E67D	LSR A;	check disk set bit
$E67E	JSR XferFailOnCy
$E681	LSR A;	check ready bit
$E682	BCS $E678;	wait for drive to become ready
$E684	RTS

;stop disk drive motor
StopMotor:	LDA $FA
$E687	AND #$08
$E689	ORA #$26
$E68B	STA $4025
$E68E	RTS

;verifies that first byte in file is equal to value in accumulator
CheckBlkType:	LDY #$05
$E691	JSR MilSecTimer;0.005 sec delay
$E694	STA $07
$E696	CLC
$E697	ADC #$21;	error # = 21h +	failed block type (1..4)
$E699	TAY
$E69A	LDA $FA
$E69C	ORA #$40
$E69E	STA $FA
$E6A0	STA $4025
$E6A3	JSR Xfer1stByte
$E6A6	PHA
$E6A7	TYA
$E6A8	TAX
$E6A9	PLA
$E6AA	CMP $07
$E6AC	JSR XferFailOnNEQ
$E6AF	RTS

;writes out block start mark, plus byte in accumulator
WriteBlkType:	LDY #$0a
$E6B2	STA $07
$E6B4	LDA $FA
$E6B6	AND #$2b;	set xfer direction to write
$E6B8	STA $4025
$E6BB	JSR MilSecTimer;0.010 sec delay rem!
$E6BE	LDY #$00
$E6C0	STY $4024;	zero out write register
$E6C3	ORA #$40;	tell FDS to write data to disk NOW
$E6C5	STA $FA
$E6C7	STA $4025
$E6CA	LDA #$80        
$E6CC	JSR Xfer1stByte ;write out block	start mark
$E6CF	LDA $07
$E6D1	JSR XferByte;	write out block	type
$E6D4	RTS

;FDS string
FDSstr:
.byte  "*CVH-ODNETNIN*"

;starts transfer
StartXfer:	JSR WaitForRdy
$E6E6	LDY #$c5
$E6E8	JSR MilSecTimer;0.197 sec delay
$E6EB	LDY #$46
$E6ED	JSR MilSecTimer;0.070 sec delay
$E6F0	LDA #$01
$E6F2	JSR CheckBlkType
$E6F5	LDY #$0d
$E6F7	JSR XferByte
$E6FA	LDX #$21;	error 21h if FDS string failed comparison
$E6FC	CMP FDSstr,Y
$E6FF	JSR XferFailOnNEQ
$E702	DEY
$E703	BPL $E6F7
$E705	RTS

;checks the CRC	OK bit at the end of a block
EndOfBlkRead:	JSR XferByte;	first CRC byte
$E709	LDX #$28;	premature file end error #
$E70B	LDA $4030
$E70E	AND #$40;	check "end of disk" status
$E710	BNE XferFail
$E712	LDA $FA
$E714	ORA #$10;	set while processing block end mark (CRC)
$E716	STA $FA
$E718	STA $4025
$E71B	JSR XferByte;	second CRC byte
$E71E	LDX #$27;	CRC fail error #
$E720	LDA $4030
$E723	AND #$10;	test CRC bit
$E725	BNE XferFail
$E727	BEQ ChkDiskSet

;takes care of writing CRC value out to block being written
EndOfBlkWrite:	JSR XferByte
$E72C	LDX #$29
$E72E	LDA $4030
$E731	AND #$40
$E733	BNE XferFail
$E735	LDA $FA
$E737	ORA #$10;	causes FDS to write out CRC immediately
$E739	STA $FA;	following completion of pending	byte write
$E73B	STA $4025
$E73E	LDX #$b2;	0.0005 second delay (to allow adaptor pleanty
$E740	DEX;	of time to write out entire CRC)
$E741	BNE $E740
$E743	LDX #$30
$E745	LDA $4032
$E748	AND #$02
$E74A	BNE XferFail

;disables disk transfer interrupts & checks disk set status
ChkDiskSet:	LDA $FA
$E74E	AND #$2f
$E750	ORA #$04
$E752	STA $FA
$E754	STA $4025
$E757	LDX #$01;	disk set error #
$E759	LDA $4032
$E75C	LSR A
$E75D	JSR XferFailOnCy
$E760	RTS

;reads in CRC value at end of block into Ptr($0A)+Y. Note that this
;subroutine is not used by any other disk routines.
ReadCRC:	JSR XferByte
$E764	STA ($0A),Y
$E766	LDX #$28
$E768	LDA $4030
$E76B	AND #$40
$E76D	BNE XferFail
$E76F	INY
$E770	JSR XferByte
$E773	STA ($0A),Y
$E775	JMP ChkDiskSet

;dispatched when transfer is to	be terminated. returns error # in A.
XferDone:	LDX #$00;	no error
$E77A	BEQ $E786
XferFailOnCy:	BCS XferFail
$E77E	RTS
XferFailOnNEQ:	BEQ $E77E
XferFail:	TXA
$E782	LDX $04
$E784	TXS;	restore PC to original caller's address
$E785	TAX
$E786	LDA $FA
$E788	AND #$09
$E78A	ORA #$26
$E78C	STA $FA
$E78E	STA $4025
$E791	TXA
$E792	CLI
$E793	RTS

;the main interface for data exchanges between the disk drive &	the system.
Xfer1stByte:	LDX #$40
$E796	STX $0101
$E799	ROL $FA
$E79B	SEC
$E79C	ROR $FA
$E79E	LDX $FA
$E7A0	STX $4025
XferByte:	CLI
$E7A4	JMP $E7A4

;routine for incrementing 16-bit pointers in the zero-page
inc0Adec0C:	INC $0A
$E7A9	BNE DecPtr0C
$E7AB	INC $0B
DecPtr0C:	SEC
$E7AE	LDA $0C
$E7B0	SBC #$01
$E7B2	STA $0C
$E7B4	LDA $0D
$E7B6	SBC #$00
$E7B8	STA $0D
$E7BA	RTS


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
PPUdataPrsr:	JSR GetHCparam
$E7BE	JMP $E815

;[Param] is in A
$E7C1	PHA;	save [Param]
$E7C2	STA $2006;	[NES] VRAM address select
$E7C5	INY
$E7C6	LDA ($00),Y;	load [Param+1]
$E7C8	STA $2006;	[NES] VRAM address select
$E7CB	INY
$E7CC	LDA ($00),Y;	load [Param+2]	IFcccccc
$E7CE	ASL A;	bit 7 in carry	Fcccccc0
$E7CF	PHA;	save [Param+2]

;if Bit(7,[Param+2]) then PPUinc:=32 else PPUinc:=1
$E7D0	LDA $FF
$E7D2	ORA #$04
$E7D4	BCS $E7D8
$E7D6	AND #$fb
$E7D8	STA $2000;	[NES] PPU setup	#1
$E7DB	STA $FF

;if Bit(6,[Param+2]) then
$E7DD	PLA;	load [Param+2]	Fcccccc0
$E7DE	ASL A
$E7DF	PHP;	save zero status
$E7E0	BCC $E7E5
$E7E2	ORA #$02
$E7E4	INY;	advance to next	byte if fill bit set

;if Zero([Param+2] and $3F) then carry:=1 else carry:=0
$E7E5	PLP
$E7E6	CLC
$E7E7	BNE $E7EA
$E7E9	SEC
$E7EA	ROR A
$E7EB	LSR A
$E7EC	TAX

;for I:=0 to X-1 do [$2007]:=[Param+3+(X and not Bit(6,[Param+2]))]
$E7ED	BCS $E7F0
$E7EF	INY
$E7F0	LDA ($00),Y
$E7F2	STA $2007;	[NES] VRAM data
$E7F5	DEX
$E7F6	BNE $E7ED

;not sure what this is supposed	to do, since it	looks like it's zeroing out
;the entire PPU	address register in the end
$E7F8	PLA;	load [Param]
$E7F9	CMP #$3f
$E7FB	BNE $E809
$E7FD	STA $2006;	[NES] VRAM address select
$E800	STX $2006;	[NES] VRAM address select
$E803	STX $2006;	[NES] VRAM address select
$E806	STX $2006;	[NES] VRAM address select

;increment Param by Y+1
$E809	SEC
$E80A	TYA
$E80B	ADC $00
$E80D	STA $00
$E80F	LDA #$00
$E811	ADC $01
$E813	STA $01

;exit if bit(7,[Param]) is 1
$E815	LDX $2002;	[NES] PPU status
$E818	LDY #$00
$E81A	LDA ($00),Y;	load opcode
$E81C	BPL $E81F
$E81E	RTS

;test for RET instruction
$E81F	CMP #$60
$E821	BNE $E82D

;[Param] = $60:
;pop Param off stack
$E823	PLA
$E824	STA $01
$E826	PLA
$E827	STA $00
$E829	LDY #$02;	increment amount
$E82B	BNE $E809;	unconditional

;test for JSR opcode
$E82D	CMP #$4c
$E82F	BNE $E7C1

;[Param] = $4C
;push Param onto stack
$E831	LDA $00
$E833	PHA
$E834	LDA $01
$E836	PHA

;Param = [Param+1]
$E837	INY
$E838	LDA ($00),Y
$E83A	TAX
$E83B	INY
$E83C	LDA ($00),Y
$E83E	STA $01
$E840	STX $00
$E842	BCS $E815;	unconditional


;????????????????????????????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;fetches hardcoded 16-bit value	after second return address into [$00] & [$01]
;that return address is then incremented by 2.
GetHCparam:	TSX
$E845	LDA $0103,X
$E848	STA $05
$E84A	LDA $0104,X
$E84D	STA $06
$E84F	LDY #$01
$E851	LDA ($05),Y
$E853	STA $00
$E855	INY
$E856	LDA ($05),Y
$E858	STA $01
$E85A	CLC
$E85B	LDA #$02
$E85D	ADC $05
$E85F	STA $0103,X
$E862	LDA #$00
$E864	ADC $06
$E866	STA $0104,X
$E869	RTS


$E86A	LDA $FF
$E86C	AND #$fb
$E86E	STA $2000;	[NES] PPU setup	#1
$E871	STA $FF
$E873	LDX $2002;	[NES] PPU status
$E876	LDY #$00
$E878	BEQ $E8A5
$E87A	PHA
$E87B	STA $2006;	[NES] VRAM address select
$E87E	INY
$E87F	LDA $0302,Y
$E882	STA $2006;	[NES] VRAM address select
$E885	INY
$E886	LDX $0302,Y
$E889	INY
$E88A	LDA $0302,Y
$E88D	STA $2007;	[NES] VRAM data
$E890	DEX
$E891	BNE $E889
$E893	PLA
$E894	CMP #$3f
$E896	BNE $E8A4
$E898	STA $2006;	[NES] VRAM address select
$E89B	STX $2006;	[NES] VRAM address select
$E89E	STX $2006;	[NES] VRAM address select
$E8A1	STX $2006;	[NES] VRAM address select
$E8A4	INY
$E8A5	LDA $0302,Y
$E8A8	BPL $E87A
$E8AA	STA $0302
$E8AD	LDA #$00
$E8AF	STA $0301
$E8B2	RTS


$E8B3	LDA $2002;	[NES] PPU status
$E8B6	LDA $0300,X
$E8B9	STA $2006;	[NES] VRAM address select
$E8BC	INX
$E8BD	LDA $0300,X
$E8C0	STA $2006;	[NES] VRAM address select
$E8C3	INX
$E8C4	LDA $2007;	[NES] VRAM data
$E8C7	LDA $2007;	[NES] VRAM data
$E8CA	STA $0300,X
$E8CD	INX
$E8CE	DEY
$E8CF	BNE $E8B6
$E8D1	RTS


$E8D2	STA $03
$E8D4	STX $02
$E8D6	STY $04
$E8D8	JSR GetHCparam
$E8DB	LDY #$ff
$E8DD	LDA #$01
$E8DF	BNE $E8F6
$E8E1	STA $03
$E8E3	STX $02
$E8E5	JSR GetHCparam
$E8E8	LDY #$00
$E8EA	LDA ($00),Y
$E8EC	AND #$0f
$E8EE	STA $04
$E8F0	LDA ($00),Y
$E8F2	LSR A
$E8F3	LSR A
$E8F4	LSR A
$E8F5	LSR A
$E8F6	STA $05
$E8F8	LDX $0301
$E8FB	LDA $03
$E8FD	STA $0302,X
$E900	JSR $E93C
$E903	LDA $02
$E905	STA $0302,X
$E908	JSR $E93C
$E90B	LDA $04
$E90D	STA $06
$E90F	STA $0302,X
$E912	JSR $E93C
$E915	INY
$E916	LDA ($00),Y
$E918	STA $0302,X
$E91B	DEC $06
$E91D	BNE $E912
$E91F	JSR $E93C
$E922	STX $0301
$E925	CLC
$E926	LDA #$20
$E928	ADC $02
$E92A	STA $02
$E92C	LDA #$00
$E92E	ADC $03
$E930	STA $03
$E932	DEC $05
$E934	BNE $E8FB
$E936	LDA #$ff
$E938	STA $0302,X
$E93B	RTS


$E93C	INX
$E93D	CPX $0300
$E940	BCC $E94E
$E942	LDX $0301
$E945	LDA #$ff
$E947	STA $0302,X
$E94A	PLA
$E94B	PLA
$E94C	LDA #$01
$E94E	RTS


$E94F	DEX
$E950	DEX
$E951	DEX
$E952	TXA
$E953	CLC
$E954	ADC #$03
$E956	DEY
$E957	BNE $E953
$E959	TAX
$E95A	TAY
$E95B	LDA $0300,X
$E95E	CMP $00
$E960	BNE $E970
$E962	INX
$E963	LDA $0300,X
$E966	CMP $01
$E968	BNE $E970
$E96A	INX
$E96B	LDA $0300,X
$E96E	CLC
$E96F	RTS


$E970	LDA $00
$E972	STA $0300,Y
$E975	INY
$E976	LDA $01
$E978	STA $0300,Y
$E97B	SEC
$E97C	RTS


$E97D	LDA #$08
$E97F	STA $00
$E981	LDA $02
$E983	ASL A
$E984	ROL $00
$E986	ASL A
$E987	ROL $00
$E989	AND #$e0
$E98B	STA $01
$E98D	LDA $03
$E98F	LSR A
$E990	LSR A
$E991	LSR A
$E992	ORA $01
$E994	STA $01
$E996	RTS


$E997	LDA $01
$E999	ASL A
$E99A	ASL A
$E99B	ASL A
$E99C	STA $03
$E99E	LDA $01
$E9A0	STA $02
$E9A2	LDA $00
$E9A4	LSR A
$E9A5	ROR $02
$E9A7	LSR A
$E9A8	ROR $02
$E9AA	LDA #$f8
$E9AC	AND $02
$E9AE	STA $02
$E9B0	RTS


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
RndmNbrGen:	LDA $00,X
$E9B3	AND #$02
$E9B5	STA $00

;xor second bit	sample with first
$E9B7	LDA $01,X
$E9B9	AND #$02
$E9BB	EOR $00

;set carry to result of XOR
$E9BD	CLC
$E9BE	BEQ $E9C1
$E9C0	SEC

;multi-precision shift for Y amount of bytes
$E9C1	ROR $00,X
$E9C3	INX
$E9C4	DEY
$E9C5	BNE $E9C1
$E9C7	RTS


;????????????????????????????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????

$E9C8	LDA #$00
$E9CA	STA $2003;	[NES] SPR-RAM address select
$E9CD	LDA #$02
$E9CF	STA $4014;	[NES] Sprite DMA trigger
$E9D2	RTS


$E9D3	STX $00
$E9D5	DEC $00,X
$E9D7	BPL $E9DE
$E9D9	LDA #$09
$E9DB	STA $00,X
$E9DD	TYA
$E9DE	TAX
$E9DF	LDA $00,X
$E9E1	BEQ $E9E5
$E9E3	DEC $00,X
$E9E5	DEX
$E9E6	CPX $00
$E9E8	BNE $E9DF
$E9EA	RTS


;????????????????????????????????????????????????????????????????????????????
;controller read function

;- strobes controllers
;- [$F5] contains 8 reads of bit 0 from [$4016]
;- [$00] contains 8 reads of bit 1 from [$4016]
;- [$F6] contains 8 reads of bit 0 from [$4017]
;- [$01] contains 8 reads of bit 1 from [$4017]

ReadCtrlrs:	LDX $FB
$E9ED	INX
$E9EE	STX $4016;	[NES] Joypad & I/O port for port #1
$E9F1	DEX
$E9F2	STX $4016;	[NES] Joypad & I/O port for port #1
$E9F5	LDX #$08
$E9F7	LDA $4016;	[NES] Joypad & I/O port for port #1
$E9FA	LSR A
$E9FB	ROL $F5
$E9FD	LSR A
$E9FE	ROL $00
$EA00	LDA $4017;	[NES] Joypad & I/O port for port #2
$EA03	LSR A
$EA04	ROL $F6
$EA06	LSR A
$EA07	ROL $01
$EA09	DEX
$EA0A	BNE $E9F7
$EA0C	RTS


;????????????????????????????????????????????????????????????????????????????
;controller OR function

;[$F5]|=[$00]
;[$F6]|=[$01]

ORctrlrRead:	LDA $00
$EA0F	ORA $F5
$EA11	STA $F5
$EA13	LDA $01
$EA15	ORA $F6
$EA17	STA $F6
$EA19	RTS


;????????????????????????????????????????????????????????????????????????????
;get controller	status

;- returns status of controller	buttons in [$F7] (CI) and [$F8]	(CII)
;- returns which new buttons have been pressed since last update in
;  [$F5] (CI) and [$F6] (CII)

GetCtrlrSts:	JSR ReadCtrlrs
$EA1D	BEQ $EA25;	always branches	because ReadCtrlrs sets zero flag
$EA1F	JSR ReadCtrlrs;	this instruction is not used
$EA22	JSR ORctrlrRead;this instruction is not used
$EA25	LDX #$01
$EA27	LDA $F5,X
$EA29	TAY
$EA2A	EOR $F7,X
$EA2C	AND $F5,X
$EA2E	STA $F5,X
$EA30	STY $F7,X
$EA32	DEX
$EA33	BPL $EA27
$EA35	RTS


;????????????????????????????????????????????????????????????????????????????

$EA36	JSR ReadCtrlrs
$EA39	LDY $F5
$EA3B	LDA $F6
$EA3D	PHA
$EA3E	JSR ReadCtrlrs
$EA41	PLA
$EA42	CMP $F6
$EA44	BNE $EA39
$EA46	CPY $F5
$EA48	BNE $EA39
$EA4A	BEQ $EA25
$EA4C	JSR ReadCtrlrs
$EA4F	JSR ORctrlrRead
$EA52	LDY $F5
$EA54	LDA $F6
$EA56	PHA
$EA57	JSR ReadCtrlrs
$EA5A	JSR ORctrlrRead
$EA5D	PLA
$EA5E	CMP $F6
$EA60	BNE $EA52
$EA62	CPY $F5
$EA64	BNE $EA52
$EA66	BEQ $EA25
$EA68	JSR ReadCtrlrs
$EA6B	LDA $00
$EA6D	STA $F7
$EA6F	LDA $01
$EA71	STA $F8
$EA73	LDX #$03
$EA75	LDA $F5,X
$EA77	TAY
$EA78	EOR $F1,X
$EA7A	AND $F5,X
$EA7C	STA $F5,X
$EA7E	STY $F1,X
$EA80	DEX
$EA81	BPL $EA75
$EA83	RTS


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

VRAMfill:	STA $00
$EA86	STX $01
$EA88	STY $02

;reset 2006's flip flop
$EA8A	LDA $2002;	[NES] PPU status

;set PPU address increment to 1
$EA8D	LDA $FF
$EA8F	AND #$fb
$EA91	STA $2000;	[NES] PPU setup	#1
$EA94	STA $FF

;PPUaddrHI:=[$00]
;PPUaddrLO:=$00
$EA96	LDA $00
$EA98	STA $2006;	[NES] VRAM address select
$EA9B	LDY #$00
$EA9D	STY $2006;	[NES] VRAM address select

;if PPUaddr<$2000 then X:=[$02]	else X:=4
$EAA0	LDX #$04
$EAA2	CMP #$20
$EAA4	BCS $EAA8;	branch if more than or equal to	$20
$EAA6	LDX $02

;for i:=X downto 1 do Fill([$2007],A,256)
$EAA8	LDY #$00
$EAAA	LDA $01
$EAAC	STA $2007;	[NES] VRAM data
$EAAF	DEY
$EAB0	BNE $EAAC
$EAB2	DEX
$EAB3	BNE $EAAC

;set up Y for next loop
$EAB5	LDY $02

;if PPUaddr>=$2000 then
$EAB7	LDA $00
$EAB9	CMP #$20
$EABB	BCC $EACF;	branch if less than $20

;  PPUaddrHI:=[$00]+3
;  PPUaddrLO:=$C0
$EABD	ADC #$02
$EABF	STA $2006;	[NES] VRAM address select
$EAC2	LDA #$c0
$EAC4	STA $2006;	[NES] VRAM address select

;  for I:=1 to $40 do [$2007]:=[$02]
$EAC7	LDX #$40
$EAC9	STY $2007;	[NES] VRAM data
$EACC	DEX
$EACD	BNE $EAC9

;restore X
$EACF	LDX $01
$EAD1	RTS


;????????????????????????????????????????????????????????????????????????????
;CPU memory fill routine?????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;this routine simply fills CPU mapped memory with a given value. granularity
;is pages (256 bytes). parameters are as follows:

;A is fill value
;X is first page #
;Y is last  page #

MemFill:	PHA
$EAD3	TXA
$EAD4	STY $01
$EAD6	CLC
$EAD7	SBC $01
$EAD9	TAX
$EADA	PLA
$EADB	LDY #$00
$EADD	STY $00
$EADF	STA ($00),Y
$EAE1	DEY
$EAE2	BNE $EADF
$EAE4	DEC $01
$EAE6	INX
$EAE7	BNE $EADF
$EAE9	RTS


;????????????????????????????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;restore PPU reg's 0 & 5 from mem
RstPPU05:	LDA $2002;	reset scroll register flip-flop
$EAED	LDA $FD
$EAEF	STA $2005;	[NES] PPU scroll
$EAF2	LDA $FC
$EAF4	STA $2005;	[NES] PPU scroll
$EAF7	LDA $FF
$EAF9	STA $2000;	[NES] PPU setup	#1
$EAFC	RTS


;????????????????????????????????????????????????????????????????????????????

$EAFD	ASL A
$EAFE	TAY
$EAFF	INY
$EB00	PLA
$EB01	STA $00
$EB03	PLA
$EB04	STA $01
$EB06	LDA ($00),Y
$EB08	TAX
$EB09	INY
$EB0A	LDA ($00),Y
$EB0C	STA $01
$EB0E	STX $00
$EB10	JMP ($0000)


$EB13	LDA $FB
$EB15	AND #$f8
$EB17	STA $FB
$EB19	ORA #$05
$EB1B	STA $4016;	[NES] Joypad & I/O port for port #1
$EB1E	NOP
$EB1F	NOP
$EB20	NOP
$EB21	NOP
$EB22	NOP
$EB23	NOP
$EB24	LDX #$08
$EB26	LDA $FB
$EB28	ORA #$04
$EB2A	STA $4016;	[NES] Joypad & I/O port for port #1
$EB2D	LDY #$0a
$EB2F	DEY
$EB30	BNE $EB2F
$EB32	NOP
$EB33	LDY $FB
$EB35	LDA $4017;	[NES] Joypad & I/O port for port #2
$EB38	LSR A
$EB39	AND #$0f
$EB3B	BEQ $EB62
$EB3D	STA $00,X
$EB3F	LDA $FB
$EB41	ORA #$06
$EB43	STA $4016;	[NES] Joypad & I/O port for port #1
$EB46	LDY #$0a
$EB48	DEY
$EB49	BNE $EB48
$EB4B	NOP
$EB4C	NOP
$EB4D	LDA $4017;	[NES] Joypad & I/O port for port #2
$EB50	ROL A
$EB51	ROL A
$EB52	ROL A
$EB53	AND #$f0
$EB55	ORA $00,X
$EB57	EOR #$ff
$EB59	STA $00,X
$EB5B	DEX
$EB5C	BPL $EB26
$EB5E	LDY $FB
$EB60	ORA #$ff
$EB62	STY $4016;	[NES] Joypad & I/O port for port #1
$EB65	RTS


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
Inc00by8:	LDA #$08
Inc00byA:	PHP
$EB69	LDY #$00
$EB6B	CLC
$EB6C	ADC $00
$EB6E	STA $00
$EB70	LDA #$00
$EB72	ADC $01
$EB74	STA $01
$EB76	PLP
$EB77	DEC $02
$EB79	RTS

;move 8 bytes pointed to by word[$00] to video buf.
;move direction	is reversed if carry is set.
Mov8BVid:	LDX #$08
$EB7C	BCS $EB88
$EB7E	LDA ($00),Y
$EB80	STA $2007;	[NES] VRAM data
$EB83	INY
$EB84	DEX
$EB85	BNE $EB7C
$EB87	RTS
$EB88	LDA $2007;	[NES] VRAM data
$EB8B	STA ($00),Y
$EB8D	BCS $EB83

;move the byte at [$03] to the video buffer 8 times.
;if carry is set, then make dummy reads.
FillVidW8B:	LDA $03
$EB91	LDX #$08
$EB93	BCS $EB9C
$EB95	STA $2007;	[NES] VRAM data
$EB98	DEX
$EB99	BNE $EB93
$EB9B	RTS
$EB9C	LDA $2007;	[NES] VRAM data
$EB9F	BCS $EB98

;move 8 bytes pointed to by word[$00] to video buf.
;data is XORed with [$03] before being moved.
Mov8BtoVid:	LDX #$08
$EBA3	LDA $03
$EBA5	EOR ($00),Y
$EBA7	STA $2007;	[NES] VRAM data
$EBAA	INY
$EBAB	DEX
$EBAC	BNE $EBA3
$EBAE	RTS

;load register variables into temporary memory
CPUtoPPUcpy:	STA $04
$EBB1	STX $02
$EBB3	STY $03
$EBB5	JSR GetHCparam;	load hard-coded	param into [$00]&[$01]

;set PPU address increment to 1
$EBB8	LDA $2002;	[NES] PPU status
$EBBB	LDA $FF
$EBBD	AND #$fb
$EBBF	STA $FF
$EBC1	STA $2000;	[NES] PPU setup	#1

;PPUaddrHI:=[$03]
;PPUaddrLO:=[$04]and $F0
$EBC4	LDY $03
$EBC6	STY $2006;	[NES] VRAM address select
$EBC9	LDA $04
$EBCB	AND #$f0
$EBCD	STA $2006;	[NES] VRAM address select

;[$03]:=Bit(0,[$04])	 0 if clear; -1	if set
$EBD0	LDA #$00
$EBD2	STA $03
$EBD4	LDA $04
$EBD6	AND #$0f
$EBD8	LSR A
$EBD9	BCC $EBDD
$EBDB	DEC $03

;if Bit(1,[$04])then Temp:=[$2007]
$EBDD	LSR A
$EBDE	BCC $EBE3
$EBE0	LDX $2007;	dummy read to validate internal	read buffer

;case [$04]and $0C of
$EBE3	TAY
$EBE4	BEQ $EBFB;	00xx
$EBE6	DEY
$EBE7	BEQ $EC09;	01xx
$EBE9	DEY
$EBEA	BEQ $EC15;	02xx
$EBEC	DEY;	Y=0

;$0C: #2 plane copy (plane 1 is	filled with same data, but can be inverted)
$EBED	JSR Mov8BtoVid
$EBF0	LDY #$00
$EBF2	JSR Mov8BVid
$EBF5	JSR Inc00by8
$EBF8	BNE $EBED
$EBFA	RTS

;$00: double plane copy
$EBFB	JSR Mov8BVid
$EBFE	JSR Mov8BVid
$EC01	LDA #$10
$EC03	JSR Inc00byA
$EC06	BNE $EBFB
$EC08	RTS

;$04: #1 plane copy (plane 2 is	filled with [$03])
$EC09	JSR Mov8BVid
$EC0C	JSR FillVidW8B
$EC0F	JSR Inc00by8
$EC12	BNE $EC09
$EC14	RTS

;$08: #2 plane copy (plane 1 is	filled with [$03])
$EC15	JSR FillVidW8B
$EC18	JSR Mov8BVid
$EC1B	JSR Inc00by8
$EC1E	BNE $EC15
$EC20	RTS

;????????????????????????????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????

$EC21	RTS

$EC22	LDY #$0b
$EC24	LDA ($00),Y
$EC26	STA $02
$EC28	LDA #$02
$EC2A	STA $03
$EC2C	DEY
$EC2D	LDA ($00),Y
$EC2F	LSR A
$EC30	LSR A
$EC31	LSR A
$EC32	LSR A
$EC33	BEQ $EC21
$EC35	STA $04
$EC37	STA $0C
$EC39	LDA ($00),Y
$EC3B	AND #$0f
$EC3D	BEQ $EC21
$EC3F	STA $05
$EC41	LDY #$01
$EC43	LDA ($00),Y
$EC45	TAX
$EC46	DEY
$EC47	LDA ($00),Y
$EC49	BEQ $EC4F
$EC4B	BPL $EC21
$EC4D	LDX #$f4
$EC4F	STX $08
$EC51	LDY #$08
$EC53	LDA ($00),Y
$EC55	LSR A
$EC56	AND #$08
$EC58	BEQ $EC5C
$EC5A	LDA #$80
$EC5C	ROR A
$EC5D	STA $09
$EC5F	INY
$EC60	LDA ($00),Y
$EC62	AND #$23
$EC64	ORA $09
$EC66	STA $09
$EC68	LDY #$03
$EC6A	LDA ($00),Y
$EC6C	STA $0A
$EC6E	LDA $05
$EC70	STA $07
$EC72	LDY #$00
$EC74	STY $0B
$EC76	LDA $04
$EC78	STA $06
$EC7A	LDX $08
$EC7C	TXA
$EC7D	STA ($02),Y
$EC7F	CMP #$f4
$EC81	BEQ $EC87
$EC83	CLC
$EC84	ADC #$08
$EC86	TAX
$EC87	INY
$EC88	INY
$EC89	LDA $09
$EC8B	STA ($02),Y
$EC8D	INY
$EC8E	LDA $0A
$EC90	STA ($02),Y
$EC92	INY
$EC93	INC $0B
$EC95	DEC $06
$EC97	BNE $EC7C
$EC99	LDA $0A
$EC9B	CLC
$EC9C	ADC #$08
$EC9E	STA $0A
$ECA0	DEC $07
$ECA2	BNE $EC76
$ECA4	LDY #$07
$ECA6	LDA ($00),Y
$ECA8	STA $07
$ECAA	DEY
$ECAB	LDA ($00),Y
$ECAD	STA $08
$ECAF	LDA #$00
$ECB1	STA $0A
$ECB3	CLC
$ECB4	LDX $0B
$ECB6	DEY
$ECB7	LDA ($00),Y
$ECB9	CLC
$ECBA	ADC $07
$ECBC	STA $07
$ECBE	LDA #$00
$ECC0	ADC $08
$ECC2	STA $08
$ECC4	DEX
$ECC5	BNE $ECB7
$ECC7	INC $02
$ECC9	LDY #$00
$ECCB	LDA $08
$ECCD	BNE $ECD3
$ECCF	DEC $0A
$ECD1	LDY $07
$ECD3	BIT $09
$ECD5	BMI $ECF5
$ECD7	BVS $ECF7
$ECD9	LDA ($07),Y
$ECDB	BIT $0A
$ECDD	BPL $ECE0
$ECDF	TYA
$ECE0	STA ($02,X)
$ECE2	DEY
$ECE3	BIT $09
$ECE5	BMI $ECE9
$ECE7	INY
$ECE8	INY
$ECE9	LDA #$04
$ECEB	CLC
$ECEC	ADC $02
$ECEE	STA $02
$ECF0	DEC $0B
$ECF2	BNE $ECD9
$ECF4	RTS


$ECF5	BVC $ED09
$ECF7	TYA
$ECF8	CLC
$ECF9	ADC $0B
$ECFB	TAY
$ECFC	DEY
$ECFD	BIT $09
$ECFF	BMI $ECD9
$ED01	LDA #$ff
$ED03	EOR $0C
$ED05	STA $0C
$ED07	INC $0C
$ED09	TYA
$ED0A	CLC
$ED0B	ADC $0C
$ED0D	TAY
$ED0E	LDA $04
$ED10	STA $06
$ED12	DEY
$ED13	BIT $09
$ED15	BMI $ED19
$ED17	INY
$ED18	INY
$ED19	LDA ($07),Y
$ED1B	BIT $0A
$ED1D	BPL $ED20
$ED1F	TYA
$ED20	STA ($02,X)
$ED22	LDA #$04
$ED24	CLC
$ED25	ADC $02
$ED27	STA $02
$ED29	DEC $06
$ED2B	BNE $ED12
$ED2D	TYA
$ED2E	CLC
$ED2F	ADC $0C
$ED31	TAY
$ED32	DEC $05
$ED34	BNE $ED09
$ED36	RTS

;copyright text $ED37
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
StartMotor:	ORA #$01
$EE19	STA $4025
$EE1C	AND #$fd
$EE1E	STA $FA
$EE20	STA $4025
$EE23	RTS


;????????????????????????????????????????????????????????????????????????????
;Reset 
vector????????????????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;disable interrupts (just in case resetting the	CPU doesn't!)
Reset:	SEI

;set up PPU ctrl reg #1
$EE25	LDA #$10
$EE27	STA $2000;	[NES] PPU setup	#1
$EE2A	STA $FF

;clear decimal flag (in case this code is executed on a CPU with dec. mode)
$EE2C	CLD

;set up PPU ctrl reg #2 (disable playfield & objects)
$EE2D	LDA #$06
$EE2F	STA $FE
$EE31	STA $2001;	[NES] PPU setup	#2

;wait at least 1 frame
$EE34	LDX #$02;	loop count = 2 iterations
$EE36	LDA $2002;	[NES] PPU status
$EE39	BPL $EE36;	branch if VBL has not been reached
$EE3B	DEX
$EE3C	BNE $EE36;	exit loop when X = 0

$EE3E	STX $4022;	disable timer interrupt
$EE41	STX $4023;	disable sound &	disk I/O
$EE44	LDA #$83
$EE46	STA $4023;	enable sound & disk I/O
$EE49	STX $FD
$EE4B	STX $FC
$EE4D	STX $FB
$EE4F	STX $4016;	[NES] Joypad & I/O port for port #1
$EE52	LDA #$2e
$EE54	STA $FA
$EE56	STA $4025
$EE59	LDA #$ff
$EE5B	STA $F9
$EE5D	STA $4026
$EE60	STX $4010;	[NES] Audio - DPCM control
$EE63	LDA #$c0
$EE65	STA $4017;	[NES] Joypad & I/O port for port #2
$EE68	LDA #$0f
$EE6A	STA $4015;	[NES] IRQ status / Sound enable
$EE6D	LDA #$80
$EE6F	STA $4080
$EE72	LDA #$e8
$EE74	STA $408A
$EE77	LDX #$ff;	set up stack
$EE79	TXS
$EE7A	LDA #$c0
$EE7C	STA $0100
$EE7F	LDA #$80
$EE81	STA $0101

;if ([$102]=$35)and(([$103]=$53)or([$103]=$AC))	then
;  [$103]:=$53
;  CALL RstPPU05
;  CLI
;  JMP [$DFFC]
$EE84	LDA $0102
$EE87	CMP #$35
$EE89	BNE $EEA2
$EE8B	LDA $0103
$EE8E	CMP #$53
$EE90	BEQ $EE9B
$EE92	CMP #$ac
$EE94	BNE $EEA2
$EE96	LDA #$53
$EE98	STA $0103
$EE9B	JSR RstPPU05
$EE9E	CLI;	enable interrupts
$EE9F	JMP ($DFFC)

;for I:=$F8 downto $01 do [I]:=$00
$EEA2	LDA #$00
$EEA4	LDX #$f8
$EEA6	STA $00,X
$EEA8	DEX
$EEA9	BNE $EEA6

;[$300]:=$7D
;[$301]:=$00
;[$302]:=$FF
$EEAB	STA $0301
$EEAE	LDA #$7d
$EEB0	STA $0300
$EEB3	LDA #$ff
$EEB5	STA $0302

;if Ctrlr1 = $30 then
;  [$0102]:=0
;  JMP $F4CC
$EEB8	JSR GetCtrlrSts
$EEBB	LDA $F7;	read ctrlr 1 buttons
$EEBD	CMP #$30;	test if only select & start pressed
$EEBF	BNE $EEC9
$EEC1	LDA #$00
$EEC3	STA $0102
$EEC6	JMP $F4CC

$EEC9	JSR InitGfx
$EECC	JSR $F0FD
$EECF	LDA #$4a
$EED1	STA $A1
$EED3	LDA #$30
$EED5	STA $B1
$EED7	LDA #$e4
$EED9	STA $83
$EEDB	LDA #$a9
$EEDD	STA $FC

;test if disk inserted
$EEDF	LDA $4032
$EEE2	AND #$01
$EEE4	BEQ $EEEA

$EEE6	LDA #$04
$EEE8	STA $E1
$EEEA	LDA #$34
$EEEC	STA $90
$EEEE	JSR $F376
$EEF1	JSR VINTwait
$EEF4	LDA $90
$EEF6	CMP #$32
$EEF8	BNE $EEFE
$EEFA	LDA #$01
$EEFC	STA $E1
$EEFE	JSR $F0B4
$EF01	JSR RstPPU05
$EF04	JSR EnPfOBJ
$EF07	JSR $EFE8
$EF0A	LDX #$60
$EF0C	LDY #$20
$EF0E	JSR RndmNbrGen
$EF11	JSR $F143
$EF14	JSR $F342
$EF17	LDX #$00
$EF19	JSR $F1E5
$EF1C	LDX #$10
$EF1E	JSR $F1E5
$EF21	LDA #$c0
$EF23	STA $00
$EF25	LDA #$00
$EF27	STA $01
$EF29	JSR $EC22
$EF2C	LDA #$d0
$EF2E	STA $00
$EF30	JSR $EC22
$EF33	LDA $4032
$EF36	AND #$01
$EF38	BNE $EEEA
$EF3A	LDA $FC
$EF3C	BEQ $EF42
$EF3E	LDA #$01
$EF40	STA $FC
$EF42	LDA $90
$EF44	BNE $EEEE
$EF46	JSR DisOBJs
$EF49	JSR VINTwait
$EF4C	JSR PPUdataPrsr;,$EFFF fix
.word $EFFF
$EF51	JSR PPUdataPrsr;,$F01C fix
.word $F01C
$EF56	JSR RstPPU05
$EF59	JSR LoadFiles;,$EFF5,$EFF5;load the FDS disk boot files
.word $EFF5, $EFF5
$EF60	BNE $EF6C
$EF62	JSR $F431
$EF65	BEQ $EFAF
$EF67	JSR $F5FB
$EF6A	LDA #$20
$EF6C	STA $23
$EF6E	JSR InitGfx
$EF71	JSR $F0E1
$EF74	JSR $F0E7
$EF77	JSR $F0ED
$EF7A	JSR $F179
$EF7D	LDA #$10
$EF7F	STA $A3
$EF81	LDA $22
$EF83	BEQ $EF8B
$EF85	LDA #$01
$EF87	STA $83
$EF89	DEC $21
$EF8B	JSR $F376
$EF8E	JSR VINTwait
$EF91	JSR $E86A
$EF94	JSR RstPPU05
$EF97	JSR EnPF
$EF9A	JSR $EFE8
$EF9D	LDA #$02
$EF9F	STA $E1
$EFA1	LDA $A3
$EFA3	BNE $EF8B
$EFA5	LDA $4032
$EFA8	AND #$01
$EFAA	BEQ $EFA5
$EFAC	JMP Reset


$EFAF	LDA #$20
$EFB1	STA $A2
$EFB3	JSR VINTwait
$EFB6	JSR RstPPU05
$EFB9	JSR EnPF
$EFBC	LDX $FC
$EFBE	INX
$EFBF	INX
$EFC0	CPX #$b0
$EFC2	BCS $EFC6
$EFC4	STX $FC
$EFC6	JSR $EFE8
$EFC9	LDA $A2
$EFCB	BNE $EFB3
$EFCD	LDA #$35
$EFCF	STA $0102
$EFD2	LDA #$ac
$EFD4	STA $0103
$EFD7	JSR DisPF
$EFDA	LDY #$07
$EFDC	JSR $F48C
$EFDF	LDA #$00
$EFE1	STA $FD
$EFE3	STA $FC
$EFE5	JMP $EE9B


$EFE8	JSR $FF5C
$EFEB	LDX #$80
$EFED	LDA #$9f
$EFEF	LDY #$bf
$EFF1	JSR $E9D3
$EFF4	RTS

;$eff5 seems like load files routine uses tis data. LoadFiles
.byte   $FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$FF,$FF 

$EFFF	
.byte   $21,$A6,$54,$24
.byte   $FF

$F004	
.byte   $21,$A6,$14,$19,$15,$0E,$0A,$1C,$0E,$24,$1C,$0E,$1D,$24,$0D,$12,$1C,$14,$24,$0C,$0A,$1B,$0D
.byte   $FF

$F01C	
.byte $21,$A6,$0E,$17,$18,$20,$24,$15,$18,$0A,$0D,$12,$17,$10,$26,$26,$26
.byte $FF

$F02E
.byte $0D,$12,$1C,$14,$24,$1C,$0E,$1D,$0B,$0A,$1D,$1D,$0E,$1B,$22,$24
.byte $0A,$25,$0B,$24,$1C,$12,$0D,$0E,$0D,$12,$1C,$14,$24,$17,$18,$26
.byte $21,$A6,$14,$0D,$12,$1C,$14,$24,$1D,$1B,$18,$1E,$0B,$15,$0E,$24
.byte $24,$0E,$1B,$1B,$26,$02,$00,$FF,$20,$E8,$10,$19,$1B,$0A,$16,$24
.byte $0C,$1B,$0A,$16,$24,$24,$24,$24,$24,$18,$14,$21,$68,$04,$19,$18
.byte $1B,$1D,$3F,$00,$08,$0F,$20,$0F,$0F,$0F,$0F,$0F,$0F,$2B,$C0,$50
.byte $00,$2B,$D0,$70,$55,$FF

;$F094
.byte $80,$B8,$00,$00,$00,$00,$00,$00,$10,$00,$32,$00,$00,$00,$01,$00
.byte $80,$B8,$00,$F0,$00,$00,$00,$00,$00,$01,$32,$18,$00,$00,$FF,$00


$F0B4	LDA $FC
$F0B6	BEQ $F0C0
$F0B8	DEC $FC
$F0BA	BNE $F0C0
$F0BC	LDA #$10
$F0BE	STA $94
$F0C0	LDX $94
$F0C2	BEQ $F0CD
$F0C4	DEX
$F0C5	BEQ $F0E1
$F0C7	DEX
$F0C8	BEQ $F0E7
$F0CA	DEX
$F0CB	BEQ $F0ED
$F0CD	JSR $E9C8
$F0D0	JSR $E86A
$F0D3	LDA $92
$F0D5	BNE $F0F3
$F0D7	JSR PPUdataPrsr;,$EFFF fix
.word $EFFF
$F0DC	LDA #$40
$F0DE	STA $92
$F0E0	RTS


$F0E1	JSR PPUdataPrsr;,$F716 fix
.word $F716
$F0E6	RTS


$F0E7	JSR PPUdataPrsr;,$F723 fix
.word $F723
$F0EC	RTS


$F0ED	JSR PPUdataPrsr;,$F72C fix
.word $F72C
$F0F2	RTS


$F0F3	CMP #$2e
$F0F5	BNE $F0FC
$F0F7	JSR PPUdataPrsr;,$F004 fix
.word $F004
$F0FC	RTS


;????????????????????????????????????????????????????????????????????????????
;fill $0200-$02FF with $F4
$F0FD	LDA #$f4
$F0FF	LDX #$02
$F101	LDY #$02
$F103	JSR MemFill

;move data
;for I:=0 to $1F do [$C0+I]:=[$F094+I]
$F106	LDY #$20
$F108	LDA $F093,Y
$F10B	STA $00BF,Y
$F10E	DEY
$F10F	BNE $F108

;fill $0230-$02FF with random data
;for I:=$0230 to $02FF do [I]:=Random(256)
$F111	LDA #$d0;	loop count
$F113	STA $60;	load random number target with any data
$F115	STA $01;	save loop count	in [$01]
$F117	LDY #$02
$F119	LDX #$60
$F11B	JSR RndmNbrGen;	[$60] and [$61]	are random number target
$F11E	LDA $60;	get random number
$F120	LDX $01;	load loop count	(and index)
$F122	STA $022F,X;	write out random #
$F125	DEX
$F126	STX $01;	save loop count
$F128	BNE $F117

;fill every 4th	byte in random data area with $33
;for I:=0 to $33 do [I*4+$0231]:=$18
$F12A	LDA #$18
$F12C	LDX #$d0
$F12E	STA $022D,X
$F131	DEX
$F132	DEX
$F133	DEX
$F134	DEX
$F135	BNE $F12E

;and & or every	4th byte in random data
;for I:=0 to $33 do [I*4+$0232]:=([I*4+$0232]-1)and $03 or $20
$F137	LDX #$d0
$F139	STX $24
$F13B	JSR $F156
$F13E	CPX #$d0
$F140	BNE $F13B
$F142	RTS


;????????????????????????????????????????????????????????????????????????????

$F143	LDA $84
$F145	BNE $F156
$F147	LDA #$04
$F149	STA $84
$F14B	LDX #$d0
$F14D	DEC $022C,X
$F150	DEX
$F151	DEX
$F152	DEX
$F153	DEX
$F154	BNE $F14D

;for I:=0 to 3 do
;  [$022E+X]:=([$022E+X]-1)and $03 or $20
;  X-=4
;  if X=0 then X:=$d0
;end
$F156	LDY #$04
$F158	LDX $24
$F15A	DEC $022E,X
$F15D	LDA #$03
$F15F	AND $022E,X
$F162	ORA #$20
$F164	STA $022E,X
$F167	DEX
$F168	DEX
$F169	DEX
$F16A	DEX
$F16B	BNE $F16F
$F16D	LDX #$d0
$F16F	STX $24
$F171	DEY
$F172	BNE $F158
$F174	RTS


.byte  $01,$02,$07,$08


$F179	LDY #$18
$F17B	LDA $F04D,Y
$F17E	STA $003F,Y
$F181	DEY
$F182	BNE $F17B
$F184	LDA $23
$F186	AND #$0f
$F188	STA $56
$F18A	LDA $23
$F18C	LSR A
$F18D	LSR A
$F18E	LSR A
$F18F	LSR A
$F190	STA $55
$F192	CMP #$02
$F194	BEQ $F1BD
$F196	LDY #$0e
$F198	LDA #$24
$F19A	STA $0042,Y
$F19D	DEY
$F19E	BNE $F19A
$F1A0	LDY #$05
$F1A2	LDA $23
$F1A4	DEY
$F1A5	BEQ $F1BD
$F1A7	CMP $F174,Y
$F1AA	BNE $F1A4
$F1AC	TYA
$F1AD	ASL A
$F1AE	ASL A
$F1AF	ASL A
$F1B0	TAX
$F1B1	LDY #$07
$F1B3	DEX
$F1B4	LDA $F02E,X
$F1B7	STA $0043,Y
$F1BA	DEY
$F1BB	BPL $F1B3
$F1BD	JSR PPUdataPrsr;,$0040 fix
.word $0040
$F1C2	RTS


;????????????????????????????????????????????????????????????????????????????
;copy font bitmaps into PPU memory
;src:CPU[$E001]	dest:PPU[$1000]	tiles:41 (41*8 bytes, 1st plane	is inverted)
LoadFonts:	LDA #$0d
$F1C5	LDY #$10
$F1C7	LDX #$29
$F1C9	JSR CPUtoPPUcpy;,$E001 fix
.word $E001

;copy inverted font bitmaps from PPU mem to [$0400]
;src:PPU[$1000]	dest:CPU[$0400]	tiles:41 (41*8 bytes)
$F1CE	LDA #$06
$F1D0	LDY #$10
$F1D2	LDX #$29
$F1D4	JSR CPUtoPPUcpy;,$0400 fix
.word $0400

;copy back fonts & set first plane to all 1's
;src:CPU[$0400]	dest:PPU[$1000]	tiles:41 (41*8 bytes, 1st plane	is all 1's)
$F1D9	LDA #$09
$F1DB	LDY #$10
$F1DD	LDX #$29
$F1DF	JSR CPUtoPPUcpy;,$0400 fix
.word $0400
$F1E4	RTS


;????????????????????????????????????????????????????????????????????????????

$F1E5	JSR $F1F2
$F1E8	JSR $F2EC
$F1EB	JSR $F273
$F1EE	JSR $F2C6
$F1F1	RTS


$F1F2	LDA $20,X
$F1F4	BNE $F227
$F1F6	LDA $C0,X
$F1F8	BNE $F227
$F1FA	LDA $B0
$F1FC	BNE $F227
$F1FE	LDA $81,X
$F200	BNE $F227
$F202	LDA $62,X
$F204	AND #$3c
$F206	STA $81,X
$F208	TXA
$F209	BNE $F228
$F20B	LDA $B2
$F20D	BNE $F236
$F20F	LDA $D0
$F211	BEQ $F23D
$F213	LDA $22
$F215	BNE $F21D
$F217	LDA $C3
$F219	CMP #$78
$F21B	BCC $F24D
$F21D	LDA #$00
$F21F	STA $C8,X
$F221	STA $CF,X
$F223	LDA #$ff
$F225	STA $CE,X
$F227	RTS


$F228	LDA $C0
$F22A	BEQ $F25A
$F22C	LDA $22
$F22E	BNE $F21D
$F230	LDA $63,X
$F232	CMP #$80
$F234	BCS $F24D
$F236	LDA #$00
$F238	STA $CF,X
$F23A	STA $CE,X
$F23C	RTS


$F23D	LDA $C8
$F23F	BNE $F247
$F241	LDA $63,X
$F243	CMP #$c0
$F245	BCC $F21D
$F247	LDA $64,X
$F249	CMP #$80
$F24B	BCC $F236
$F24D	LDA #$10
$F24F	STA $C8,X
$F251	LDA #$00
$F253	STA $CF,X
$F255	LDA #$01
$F257	STA $CE,X
$F259	RTS


$F25A	LDA $64,X
$F25C	LDY $C8
$F25E	BEQ $F264
$F260	CMP #$40
$F262	BCC $F24D
$F264	CMP #$c0
$F266	BCC $F236
$F268	LDA #$40
$F26A	STA $CF,X
$F26C	LDA #$00
$F26E	STA $CE,X
$F270	STA $C8,X
$F272	RTS


$F273	LDA $20,X
$F275	BEQ $F2AA
$F277	BMI $F2AB
$F279	CLC
$F27A	LDA #$30
$F27C	ADC $CD,X
$F27E	STA $CD,X
$F280	LDA #$00
$F282	ADC $CC,X
$F284	STA $CC,X
$F286	CLC
$F287	LDA $CD,X
$F289	ADC $C2,X
$F28B	STA $C2,X
$F28D	LDA $CC,X
$F28F	ADC $C1,X
$F291	CMP #$b8
$F293	BCC $F2A4
$F295	TXA
$F296	BNE $F2B6
$F298	LDA $60,X
$F29A	AND #$30
$F29C	STA $81,X
$F29E	LDA #$00
$F2A0	STA $20,X
$F2A2	LDA #$b8
$F2A4	STA $C1,X
$F2A6	LDA #$03
$F2A8	STA $C5,X
$F2AA	RTS


$F2AB	DEC $20,X
$F2AD	LDA #$fd
$F2AF	STA $CC,X
$F2B1	LDA #$00
$F2B3	STA $CD,X
$F2B5	RTS


$F2B6	STA $C8,X
$F2B8	LDA #$01
$F2BA	STA $CE,X
$F2BC	LDA #$c0
$F2BE	STA $CF,X
$F2C0	LDA #$ff
$F2C2	STA $81,X
$F2C4	BNE $F29E
$F2C6	LDA $B0
$F2C8	BNE $F2E7
$F2CA	LDA $A1,X
$F2CC	BNE $F2E7
$F2CE	LDA $C0,X
$F2D0	BEQ $F2E7
$F2D2	LDA $62,X
$F2D4	ORA #$10
$F2D6	AND #$3c
$F2D8	STA $81,X
$F2DA	LDY #$10
$F2DC	LDA $F094,X
$F2DF	STA $C0,X
$F2E1	INX
$F2E2	DEY
$F2E3	BNE $F2DC
$F2E5	STY $B0,X
$F2E7	RTS


$F2E8
.byte $00,$02,$01,$02 


$F2EC	LDA $C0,X
$F2EE	BNE $F329
$F2F0	CLC
$F2F1	LDA $CF,X
$F2F3	ADC $C4,X
$F2F5	STA $C4,X
$F2F7	LDA $CE,X
$F2F9	ADC $C3,X
$F2FB	LDY $B0
$F2FD	CPY #$20
$F2FF	BCS $F315
$F301	CMP #$f8
$F303	BCC $F32A
$F305	CPY #$1f
$F307	BCS $F315
$F309	LDA $60,X
$F30B	AND #$2f
$F30D	ORA #$06
$F30F	STA $A1,X
$F311	LDA #$80
$F313	STA $C0,X
$F315	STA $C3,X
$F317	LSR A
$F318	LSR A
$F319	AND #$03
$F31B	TAY
$F31C	LDA $CE,X
$F31E	ORA $CF,X
$F320	BNE $F324
$F322	LDY #$01
$F324	LDA $F2E8,Y
$F327	STA $C5,X
$F329	RTS


$F32A	CMP #$78
$F32C	BNE $F315
$F32E	CPX $22
$F330	BNE $F315
$F332	LDY $20,X
$F334	BNE $F315
$F336	LDY #$00
$F338	STY $CE,X
$F33A	STY $CF,X
$F33C	LDY #$80
$F33E	STY $20,X
$F340	BNE $F315
$F342	LDA $B0
$F344	BNE $F36D
$F346	LDA $C0
$F348	ORA $D0
$F34A	BNE $F36D
$F34C	CLC
$F34D	LDA $C3
$F34F	ADC #$19
$F351	CMP $D3
$F353	BCC $F36D
$F355	STA $D3
$F357	LDA #$02
$F359	STA $CE
$F35B	STA $DE
$F35D	LDA #$00
$F35F	STA $CF
$F361	STA $DF
$F363	LDA #$10
$F365	STA $C8
$F367	STA $D8
$F369	LDA #$30
$F36B	STA $B0
$F36D	RTS


.byte $2A,$0A,$25,$05,$21,$01,$27,$16


$F376	LDY #$08
$F378	LDA $83
$F37A	BNE $F3C8
$F37C	LDA $93
$F37E	BNE $F3EF
$F380	LDX #$00
$F382	LDA $C1,X
$F384	CMP #$a4
$F386	BCS $F39E
$F388	LDA #$20
$F38A	LDY $B2
$F38C	BNE $F39C
$F38E	LDA #$08
$F390	LDY $65
$F392	CPY #$18
$F394	BCS $F39C
$F396	LDA #$08
$F398	STA $B2
$F39A	LDA #$20
$F39C	STA $83,X
$F39E	CPX #$10
$F3A0	LDX #$10
$F3A2	BCC $F382
$F3A4	LDA $22
$F3A6	BEQ $F3C7
$F3A8	LDA $82
$F3AA	BNE $F3C7
$F3AC	LDA #$08
$F3AE	STA $82
$F3B0	LDX #$0f
$F3B2	LDA $47
$F3B4	CMP #$0f
$F3B6	BNE $F3BA
$F3B8	LDX #$16
$F3BA	STX $47
$F3BC	LDA #$3f
$F3BE	LDX #$08
$F3C0	LDY #$08
$F3C2	JSR $E8D2;,$0040
.word $0040
$F3C7	RTS


$F3C8	LDA $F634,Y
$F3CB	STA $003F,Y
$F3CE	DEY
$F3CF	BNE $F3C8
$F3D1	INC $21
$F3D3	LDA $21
$F3D5	AND #$06
$F3D7	TAY
$F3D8	LDA $F36E,Y
$F3DB	STA $42
$F3DD	LDA $F36F,Y
$F3E0	STA $43
$F3E2	LDY #$00
$F3E4	LDA $B2
$F3E6	BNE $F3EA
$F3E8	LDY #$10
$F3EA	STY $22
$F3EC	JMP $F3BC


$F3EF	LDA $F63F,Y
$F3F2	STA $003F,Y
$F3F5	DEY
$F3F6	BNE $F3EF
$F3F8	BEQ $F3EA


;????????????????????????????????????????????????????????????????????????????
;initialize graphics?????????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;this subroutine copies pattern	tables from ROM	into the VRAM, and also
;sets up the name & palette tables.

;entry point
InitGfx:	JSR DisPfOBJ;	disable objects	& playfield for	video xfers

;src:CPU[$F735]	dest:PPU[$1300]	xfer:88 tiles
$F3FD	LDA #$00
$F3FF	LDX #$58
$F401	LDY #$13
$F403	JSR CPUtoPPUcpy;,$F735
.word $F735
;src:CPU[$FCA5]	dest:PPU[$0000]	xfer:25 tiles
$F408	LDA #$00
$F40A	LDX #$19
$F40C	LDY #$00
$F40E	JSR CPUtoPPUcpy;,$FCA5
.word $FCA5
$F413	JSR LoadFonts;	load fonts from	ROM into video mem

;dest:PPU[$2000] NTfillVal:=$6D	ATfillVal:=$aa
$F416	LDA #$20
$F418	LDX #$6d
$F41A	LDY #$aa
$F41C	JSR VRAMfill

;dest:PPU[$2800] NTfillVal:=$6D	ATfillVal:=$aa
$F41F	LDA #$28
$F421	LDX #$6d
$F423	LDY #$aa
$F425	JSR VRAMfill

$F428	JSR VINTwait
$F42B	JSR PPUdataPrsr;,InitNT;	initialize name	table
.word InitNT
$F430	RTS


;????????????????????????????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????
;????????????????????????????????????????????????????????????????????????????

$F431	JSR DisPfOBJ
$F434	LDY #$03
$F436	JSR $F48C
$F439	JSR LoadFonts
$F43C	JSR VINTwait
$F43F	JSR PPUdataPrsr;,$F080
.word $F080
$F444	LDA #$20
$F446	LDX #$24
$F448	LDY #$00
$F44A	JSR VRAMfill
$F44D	LDA $FF
$F44F	AND #$fb
$F451	STA $FF
$F453	STA $2000;	[NES] PPU setup	#1
$F456	LDX $2002;	[NES] PPU status
$F459	LDX #$28
$F45B	STX $2006;	[NES] VRAM address select
$F45E	LDA #$00
$F460	STA $2006;	[NES] VRAM address select
$F463	LDA $2007;	[NES] VRAM data
$F466	LDY #$00
$F468	LDA $2007;	[NES] VRAM data
$F46B	CMP $ED37,Y
$F46E	BNE $F483
$F470	INY
$F471	CPY #$e0
$F473	BNE $F468
$F475	STX $2006;	[NES] VRAM address select
$F478	STY $2006;	[NES] VRAM address select
$F47B	LDA #$24
$F47D	STA $2007;	[NES] VRAM data
$F480	INY
$F481	BNE $F47B
$F483	RTS


$F484	
.byte $02,$30,$10,$29,$32,$00,$29,$10


$F48C	LDX #$03
$F48E	LDA $F484,Y
$F491	STA $07,X
$F493	DEY
$F494	DEX
$F495	BPL $F48E
$F497	LDA #$29
$F499	STA $0B
$F49B	LDA $07
$F49D	LDX #$01
$F49F	LDY $09
$F4A1	JSR CPUtoPPUcpy;,$0010
.word $0010
$F4A6	LDA $08
$F4A8	LDX #$01
$F4AA	LDY $0A
$F4AC	JSR CPUtoPPUcpy;,$0010
.word $0010
$F4B1	LDY #$01
$F4B3	CLC
$F4B4	LDA #$10
$F4B6	ADC $0007,Y
$F4B9	STA $0007,Y
$F4BC	LDA #$00
$F4BE	ADC $0009,Y
$F4C1	STA $0009,Y
$F4C4	DEY
$F4C5	BPL $F4B3
$F4C7	DEC $0B
$F4C9	BNE $F49B
$F4CB	RTS


$F4CC	LDA #$20
$F4CE	LDX #$24
$F4D0	LDY #$00
$F4D2	JSR VRAMfill
$F4D5	JSR VINTwait
$F4D8	JSR PPUdataPrsr;,$F066
.word $F066
$F4DD	JSR $F5FB
$F4E0	BNE $F527
$F4E2	LDA #$00
$F4E4	LDX #$00
$F4E6	LDY #$00
$F4E8	JSR CPUtoPPUcpy;,$C000
.word $C000
$F4ED	LDA #$00
$F4EF	LDX #$00
$F4F1	LDY #$10
$F4F3	JSR CPUtoPPUcpy;,$D000
.word $D000
$F4F8	LDA #$02
$F4FA	LDX #$00
$F4FC	LDY #$00
$F4FE	JSR CPUtoPPUcpy;,$C000
.word $C000
$F503	LDA #$02
$F505	LDX #$00
$F507	LDY #$10
$F509	JSR CPUtoPPUcpy;,$D000
.word $D000
$F50E	LDA #$C0
$F510	STA $01
$F512	LDY #$00
$F514	STY $00
$F516	LDX #$20
$F518	LDA #$7f
$F51A	ADC #$02
$F51C	JSR $F61B
$F51F	BEQ $F54E
$F521	LDA $01
$F523	AND #$03
$F525	STA $01
$F527	LDA #$11
$F529	STA $0B
$F52B	LDY #$03
$F52D	LDA $00
$F52F	TAX
$F530	AND #$0F
$F532	STA $0007,Y
$F535	DEY
$F536	TXA
$F537	LSR A
$F538	LSR A
$F539	LSR A
$F53A	LSR A
$F53B	STA $0007,Y
$F53E	LDA $01
$F540	DEY
$F541	BPL $F52F
$F543	LDA #$20
$F545	LDX #$f4
$F547	LDY #$05
$F549	JSR $E8D2;,$0007
.word $0007
$F54E	JSR LoadFonts
$F551	JSR GetCtrlrSts
$F554	LDA $F7
$F556	CMP #$81
$F558	BNE $F5B8
$F55A	JSR PPUdataPrsr;,$F56B
.word $F56B
$F55F	JSR VINTwait
$F562	JSR RstPPU05
$F565	JSR EnPF
$F568	JMP $F568


.byte $20,$E7,$11,$02,$0C,$03,$03,$24,$12,$17,$1D,$0E,$1B,$17,$0A,$15,$24,$1B,$18,$16
.byte $21,$63,$19,$19,$1B,$18,$10,$1B,$0A,$16,$0E,$0D,$24,$0B,$22,$24,$1D,$0A,$14,$0A,$18,$24,$1C,$0A,$20,$0A,$17,$18
.byte $21,$A3,$19,$17,$12,$17,$1D,$0E,$17,$0D,$18,$24,$0C,$18,$27,$15,$1D,$0D,$26,$24,$0D,$0E,$1F,$26,$17,$18,$26,$02
.byte $FF


$F5B8	LDA #$01
$F5BA	STA $0F
$F5BC	LDA #$ff
$F5BE	CLC
$F5BF	PHA
$F5C0	PHP
$F5C1	JSR VINTwait
$F5C4	JSR $E86A
$F5C7	JSR RstPPU05
$F5CA	JSR EnPF
$F5CD	DEC $0F
$F5CF	BNE $F5DD
$F5D1	PLP
$F5D2	PLA
$F5D3	STA $4026
$F5D6	ROL A
$F5D7	PHA
$F5D8	PHP
$F5D9	LDA #$19
$F5DB	STA $0F
$F5DD	LDA $4033
$F5E0	LDX #$07
$F5E2	LDY #$01
$F5E4	ASL A
$F5E5	BCS $F5E8
$F5E7	DEY
$F5E8	STY $07,X
$F5EA	DEX
$F5EB	BPL $F5E2
$F5ED	LDA #$21
$F5EF	LDX #$70
$F5F1	LDY #$08
$F5F3	JSR $E8D2;,$0007
.word $0007
$F5F8	JMP $F5C1


$F5FB	LDA #$60
$F5FD	LDX #$80
$F5FF	STX $03
$F601	PHA
$F602	STA $01
$F604	LDY #$00
$F606	STY $00
$F608	CLV
$F609	JSR $F61B
$F60C	PLA
$F60D	STA $01
$F60F	STY $00
$F611	LDX $03
$F613	LDA #$7f
$F615	ADC #$02
$F617	JSR $F61B
$F61A	RTS


$F61B	STX $02
$F61D	LDA $02
$F61F	BVS $F62E
$F621	STA ($00),Y
$F623	INC $02
$F625	DEY
$F626	BNE $F61D
$F628	INC $01
$F62A	DEX
$F62B	BNE $F61B
$F62D	RTS


$F62E	CMP ($00),Y
$F630	BEQ $F623
$F632	STY $00
$F634	RTS

;$F635
.byte $0F,$30,$27,$16,$0F,$10,$00,$16

;PPU processor data
InitNT:	
.byte $3F,$08,$18,$0F,$21,$01,$0F,$0F,$00,$02,$01,$0F,$27,$16,$01,$0F,$27,$30,$1A,$0F,$0F,$01,$0F,$0F,$0F,$0F,$0F
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

;PATTERN TABLE DATA
;$F735
.byte $FF,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$80,$BF,$BF,$BF,$BF,$BF,$BF,$BF
.byte $C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$BF,$BF,$BF,$BF,$BF,$BF,$BF,$BF
.byte $C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$BF,$BF,$BF,$BF,$BF,$BF,$BF,$BF
.byte $C0,$C0,$C0,$FF,$FF,$FF,$FF,$FF,$BF,$BF,$BF,$FF,$FF,$FF,$FF,$FF
.byte $7F,$7F,$3F,$3F,$1F,$1F,$0F,$0F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.byte $07,$87,$83,$C3,$C1,$E1,$E0,$F0,$FF,$7F,$7F,$BF,$BF,$DF,$DF,$EF
.byte $F0,$F8,$F8,$FC,$FC,$FE,$FE,$FF,$EF,$F7,$F7,$FB,$FB,$FD,$FD,$FE
.byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.byte $FF,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$80,$BF,$BF,$BF,$BF,$BF,$BF,$BF
.byte $00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.byte $00,$80,$80,$FF,$FF,$FF,$FF,$FF,$FF,$7F,$7F,$FF,$FF,$FF,$FF,$FF
.byte $FF,$E0,$E0,$E0,$E0,$FF,$FF,$FF,$C0,$DF,$DF,$DF,$DF,$FF,$FF,$FF
.byte $FF,$E0,$E0,$E0,$E0,$E0,$E0,$E0,$C0,$DF,$DF,$DF,$DF,$DF,$DF,$DF
.byte $E0,$E0,$E0,$E0,$E0,$E0,$E0,$E0,$DF,$DF,$DF,$DF,$DF,$DF,$DF,$DF
.byte $E0,$E0,$E0,$FF,$FF,$FF,$FF,$FF,$DF,$DF,$DF,$FF,$FF,$FF,$FF,$FF
.byte $FF,$7F,$7F,$7F,$7F,$FF,$FF,$FF,$7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.byte $FF,$70,$70,$70,$70,$70,$70,$70,$60,$EF,$EF,$EF,$EF,$EF,$EF,$EF
.byte $70,$70,$70,$70,$70,$70,$70,$70,$EF,$EF,$EF,$EF,$EF,$EF,$EF,$EF
.byte $70,$70,$70,$FF,$FF,$FF,$FF,$FF,$EF,$EF,$EF,$FF,$FF,$FF,$FF,$FF
.byte $FF,$20,$00,$0F,$1F,$1F,$3F,$3F,$20,$DF,$FF,$FE,$FF,$FF,$FF,$FF
.byte $3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.byte $3F,$3F,$3F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.byte $FF,$7F,$1F,$07,$81,$81,$C0,$C0,$7F,$9F,$E7,$FB,$7F,$7F,$BF,$BF
.byte $FF,$FF,$FF,$FF,$FF,$F0,$F0,$F0,$FF,$FF,$FF,$FF,$E0,$EF,$EF,$0F
.byte $80,$90,$F0,$F0,$F0,$F0,$F0,$F0,$7F,$6F,$EF,$EF,$EF,$EF,$EF,$EF
.byte $F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$EF,$EF,$EF,$EF,$EF,$EF,$EF,$EF
.byte $F0,$F0,$F0,$FF,$FF,$FF,$FF,$FF,$EF,$EF,$EF,$FF,$FF,$FF,$FF,$FF
.byte $FF,$FF,$FF,$FF,$FF,$3F,$3F,$3F,$FF,$FF,$FF,$FF,$3F,$FF,$FF,$C7
.byte $07,$07,$3F,$3F,$3E,$3E,$3C,$3C,$FF,$FF,$FF,$FE,$FD,$FD,$FB,$FB
.byte $3C,$3C,$3C,$3C,$3C,$3E,$3E,$3E,$FB,$FB,$FB,$FB,$FB,$FD,$FD,$FF
.byte $FF,$E0,$80,$0F,$1F,$1F,$1F,$3F,$E0,$9F,$7F,$FF,$FF,$FF,$FF,$C0
.byte $00,$00,$1F,$1F,$1F,$1F,$1F,$1F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$EF
.byte $0F,$80,$E0,$FF,$FF,$FF,$FF,$FF,$F0,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.byte $FF,$3F,$0F,$C7,$E1,$E1,$E0,$E0,$3F,$CF,$F7,$BB,$DF,$DF,$DF,$1F
.byte $00,$00,$FF,$FF,$E0,$E1,$E1,$C3,$FF,$FF,$FF,$C0,$DF,$DF,$DF,$BF
.byte $87,$0F,$3F,$FF,$FF,$FF,$FF,$FF,$7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.byte $FF,$40,$00,$1C,$3F,$3F,$7F,$7F,$40,$BF,$FF,$FF,$FE,$FE,$FF,$FF
.byte $7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.byte $7F,$7F,$7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.byte $FF,$FF,$3F,$0F,$03,$03,$81,$81,$FF,$3F,$CF,$F7,$FF,$FF,$7F,$7F
.byte $81,$81,$81,$81,$81,$81,$81,$81,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F
.byte $81,$81,$81,$FF,$FF,$FF,$FF,$FF,$7F,$7F,$7F,$FF,$FF,$FF,$FF,$FF
.byte $FF,$FC,$F0,$E0,$E0,$C0,$C0,$C0,$FC,$F3,$EF,$DF,$DF,$BF,$BF,$BF
.byte $C0,$C0,$C0,$C0,$C0,$C0,$E0,$E0,$BF,$BF,$BF,$BF,$BF,$BF,$DF,$DF
.byte $F0,$F0,$FC,$FF,$FF,$FF,$FF,$FF,$EF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.byte $FF,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FC,$FD,$FD,$FD,$FD,$FD,$FD,$FD
.byte $FE,$06,$02,$00,$7C,$FE,$FE,$FE,$05,$F9,$FD,$FF,$FB,$FD,$FD,$FD
.byte $FE,$FE,$FE,$FE,$FE,$FE,$FC,$78,$FD,$FD,$FD,$FD,$FD,$FD,$7B,$87
.byte $02,$02,$06,$FF,$FF,$FF,$FF,$FF,$FD,$FD,$FD,$FF,$FF,$FF,$FF,$FF
.byte $FF,$07,$07,$07,$07,$07,$07,$07,$07,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.byte $07,$07,$07,$07,$07,$07,$07,$07,$FF,$FF,$FF,$FF,$FF,$FF,$FE,$FE
.byte $07,$07,$07,$07,$07,$07,$07,$07,$FE,$FE,$FE,$FE,$FE,$FF,$FF,$FF
.byte $07,$07,$07,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.byte $FF,$F8,$E0,$C1,$83,$87,$07,$07,$F8,$E7,$DF,$BF,$7F,$7F,$FF,$FF
.byte $07,$07,$07,$07,$07,$87,$83,$C3,$FF,$FF,$FF,$FF,$FF,$7F,$7F,$BD
.byte $E1,$E0,$F8,$FF,$FF,$FF,$FF,$FF,$DE,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.byte $FF,$0F,$03,$C1,$F0,$F8,$F8,$F8,$0F,$F3,$FD,$FE,$EF,$F7,$F7,$F7
.byte $F8,$F8,$F8,$F8,$F8,$F8,$F0,$E0,$F7,$F7,$F7,$F7,$F7,$F7,$EF,$DF
.byte $C1,$03,$0F,$FF,$FF,$FF,$FF,$FF,$3F,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.byte $FF,$FF,$FF,$FF,$7F,$7F,$3F,$3F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.byte $3F,$3F,$3F,$3F,$3F,$7F,$7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
.byte $00,$00,$01,$03,$06,$0C,$18,$10,$00,$03,$06,$0C,$19,$33,$27,$6F
.byte $30,$20,$20,$60,$40,$40,$40,$40,$4F,$5E,$DC,$9C,$B9,$B9,$B9,$B9
.byte $40,$40,$40,$40,$40,$40,$40,$40,$B9,$B9,$B9,$B9,$B9,$B9,$B9,$B9
.byte $40,$40,$40,$40,$60,$20,$20,$20,$B9,$B9,$B9,$B9,$9C,$DE,$5F,$5F
.byte $10,$00,$00,$00,$00,$00,$00,$00,$6F,$3F,$3F,$1F,$0E,$07,$03,$00
.byte $00,$7F,$C0,$00,$00,$00,$00,$00,$FF,$80,$3F,$FF,$FF,$F0,$C0,$8F
.byte $07,$1F,$3F,$7F,$7F,$FF,$FF,$FF,$3F,$7F,$FF,$FF,$FF,$FF,$FF,$FF
.byte $FF,$FF,$FF,$7F,$7F,$3F,$1F,$07,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.byte $10,$0F,$00,$00,$00,$00,$00,$00,$EF,$F0,$FF,$FF,$FF,$00,$80,$FF
.byte $00,$FF,$00,$00,$00,$00,$00,$00,$FF,$00,$FF,$FF,$FF,$00,$00,$FF
.byte $00,$FA,$00,$00,$00,$00,$00,$00,$FF,$05,$FF,$FF,$FF,$3F,$1F,$FF
.byte $E0,$F9,$FC,$FE,$FE,$FF,$FF,$FF,$FF,$FE,$FF,$FF,$FF,$FF,$FF,$FF
.byte $FF,$FF,$FF,$FE,$FE,$FC,$F9,$E3,$FF,$FF,$FF,$FF,$FF,$FF,$FE,$FC
.byte $0E,$F8,$00,$00,$00,$00,$00,$00,$F1,$07,$FF,$FF,$FC,$00,$01,$FF
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$C0,$E0,$F0,$F8,$FC,$FC,$FE
.byte $00,$00,$80,$80,$40,$40,$40,$40,$FE,$FA,$7B,$79,$B9,$B9,$B9,$B9
.byte $40,$40,$40,$40,$C0,$80,$80,$00,$B9,$B9,$B9,$B9,$39,$73,$72,$E2
.byte $00,$00,$00,$00,$00,$00,$00,$00,$E6,$C4,$8C,$18,$30,$60,$C0,$00
.byte $00,$FF,$00,$FF,$00,$FF,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.byte $FF,$00,$FF,$FF,$FF,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.byte $FF,$FF,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.byte $06,$06,$06,$06,$06,$06,$06,$00,$00,$00,$00,$00,$00,$00,$00,$00
.byte $60,$60,$60,$60,$60,$60,$60,$00,$00,$00,$00,$00,$00,$00,$00,$00
.byte $1F,$5F,$50,$57,$57,$50,$1F,$00,$20,$20,$AF,$A7,$A7,$AF,$60,$3F
.byte $F8,$FA,$0A,$EA,$EA,$0A,$F8,$00,$04,$04,$F5,$E5,$E5,$F5,$06,$FC

;$FCA5
.byte $00,$00,$00,$00,$00,$00,$03,$1F,$00,$00,$00,$03,$03,$0F,$00,$02
.byte $3F,$1F,$0F,$07,$20,$70,$70,$20,$04,$1E,$00,$00,$01,$03,$0F,$1F
.byte $00,$04,$0F,$1F,$0F,$0C,$00,$00,$0F,$07,$2F,$3F,$3F,$1C,$18,$00
.byte $00,$00,$00,$00,$00,$00,$F0,$F8,$00,$00,$00,$80,$E0,$F0,$F0,$48
.byte $F8,$FC,$F8,$E0,$10,$10,$32,$26,$48,$9C,$08,$00,$F0,$FC,$FC,$F8
.byte $7C,$F8,$F8,$FC,$FC,$78,$00,$00,$F8,$F8,$F8,$FC,$FC,$7C,$1C,$38
.byte $00,$00,$00,$00,$00,$00,$00,$07,$00,$00,$00,$00,$07,$07,$1F,$01
.byte $3F,$7F,$3F,$1F,$0F,$01,$C2,$C2,$04,$08,$3D,$00,$00,$07,$0F,$1F
.byte $C6,$07,$1F,$1F,$0F,$0F,$00,$00,$3F,$7F,$1D,$1F,$0F,$0F,$07,$0F
.byte $00,$00,$00,$00,$00,$00,$00,$E0,$00,$00,$00,$00,$00,$C0,$E0,$E0
.byte $F0,$F0,$F8,$F0,$C0,$00,$00,$00,$90,$90,$38,$10,$00,$E0,$F0,$F8
.byte $0C,$1C,$FC,$F8,$F8,$78,$00,$00,$F0,$E0,$E0,$F4,$FE,$7E,$02,$00
.byte $00,$00,$00,$00,$00,$00,$03,$1F,$00,$00,$00,$03,$03,$0F,$00,$02
.byte $3F,$1F,$0F,$07,$00,$01,$01,$13,$04,$1E,$00,$00,$03,$07,$0F,$0F
.byte $1F,$1F,$0F,$07,$07,$03,$00,$00,$0F,$0D,$0F,$07,$07,$03,$00,$01
.byte $00,$00,$00,$00,$00,$00,$F0,$F8,$00,$00,$00,$80,$E0,$F0,$F0,$48
.byte $F8,$FC,$F8,$E0,$80,$00,$00,$C0,$48,$9C,$08,$00,$E0,$F0,$F8,$F8
.byte $80,$C0,$F0,$F0,$F0,$E0,$00,$00,$F8,$30,$10,$30,$F0,$E0,$E0,$E0
.byte $00,$1C,$1E,$0E,$04,$00,$00,$07,$00,$00,$00,$10,$18,$3B,$38,$38
.byte $0F,$07,$03,$03,$06,$0C,$09,$0F,$31,$3F,$1C,$1E,$0F,$0F,$4F,$4F
.byte $1F,$1F,$1F,$07,$00,$00,$00,$00,$7E,$7F,$7F,$07,$00,$00,$00,$00
.byte $00,$00,$00,$00,$00,$00,$FC,$FE,$00,$00,$00,$E0,$F8,$FC,$3C,$92
.byte $FE,$FF,$FE,$F8,$60,$C0,$83,$87,$12,$A7,$02,$00,$FC,$FE,$FC,$F0
.byte $D2,$F0,$E0,$F0,$F0,$60,$00,$00,$F0,$F8,$FC,$FE,$F2,$60,$00,$00
.byte $00,$00,$00,$00,$00,$00,$00,$00,$80,$00,$00,$00,$00,$00,$00,$00

$FE35	
.byte $FF

$FE36	LSR A
$FE37	BCS $FE66
$FE39	LSR $E1
$FE3B	BCS $FE47
$FE3D	LSR A
$FE3E	BCS $FEA6
$FE40	LSR $E1
$FE42	BCS $FE7A
$FE44	JMP $FF6A


$FE47	LDA #$10
$FE49	STA $4000;	[NES] Audio - Square 1
$FE4C	LDA #$01
$FE4E	STA $4008;	[NES] Audio - Triangle
$FE51	STY $E3
$FE53	LDA #$20
$FE55	STA $E4
$FE57	LDX #$5c
$FE59	LDY #$7f
$FE5B	STX $4004;	[NES] Audio - Square 2
$FE5E	STY $4005;	[NES] Audio - Square 2
$FE61	LDA #$f9
$FE63	STA $4007;	[NES] Audio - Square 2
$FE66	LDA $E4
$FE68	LSR A
$FE69	BCC $FE6F
$FE6B	LDA #$0d
$FE6D	BNE $FE71
$FE6F	LDA #$7c
$FE71	STA $4006;	[NES] Audio - Square 2
$FE74	JMP $FFC6


$FE77	JMP $FFCA


$FE7A	STY $E3
$FE7C	LDX #$9c
$FE7E	LDY #$7f
$FE80	STX $4000;	[NES] Audio - Square 1
$FE83	STX $4004;	[NES] Audio - Square 2
$FE86	STY $4001;	[NES] Audio - Square 1
$FE89	STY $4005;	[NES] Audio - Square 2
$FE8C	LDA #$20
$FE8E	STA $4008;	[NES] Audio - Triangle
$FE91	LDA #$01
$FE93	STA $400C;	[NES] Audio - Noise control reg
$FE96	LDX #$00
$FE98	STX $E9
$FE9A	STX $EA
$FE9C	STX $EB
$FE9E	LDA #$01
$FEA0	STA $E6
$FEA2	STA $E7
$FEA4	STA $E8
$FEA6	DEC $E6
$FEA8	BNE $FEC1
$FEAA	LDY $E9
$FEAC	INY
$FEAD	STY $E9
$FEAF	LDA $FF1F,Y
$FEB2	BEQ $FE77
$FEB4	JSR $FFE9
$FEB7	STA $E6
$FEB9	TXA
$FEBA	AND #$3e
$FEBC	LDX #$04
$FEBE	JSR $FFD9
$FEC1	DEC $E7
$FEC3	BNE $FEDA
$FEC5	LDY $EA
$FEC7	INY
$FEC8	STY $EA
$FECA	LDA $FF33,Y
$FECD	JSR $FFE9
$FED0	STA $E7
$FED2	TXA
$FED3	AND #$3e
$FED5	LDX #$00
$FED7	JSR $FFD9
$FEDA	DEC $E8
$FEDC	BNE $FEFD
$FEDE	LDA #$09
$FEE0	STA $400E;	[NES] Audio - Noise Frequency reg #1
$FEE3	LDA #$08
$FEE5	STA $400F;	[NES] Audio - Noise Frequency reg #2
$FEE8	LDY $EB
$FEEA	INY
$FEEB	STY $EB
$FEED	LDA $FF46,Y
$FEF0	JSR $FFE9
$FEF3	STA $E8
$FEF5	TXA
$FEF6	AND #$3e
$FEF8	LDX #$08
$FEFA	JSR $FFD9
$FEFD	JMP $FF6A


.byte $03,$57,$00,$00,$08,$D4,$08,$BD,$08,$B2,$09,$AB,$09,$7C,$09,$3F
.byte $09,$1C,$08,$FD,$08,$EE,$09,$FC,$09,$DF,$06,$0C,$12,$18,$08,$48
.byte $CA,$CE,$D4,$13,$11,$0F,$90,$10,$C4,$C8,$07,$05,$15,$C4,$D2,$D4
.byte $8E,$0C,$4F,$00,$D6,$D6,$CA,$0B,$19,$17,$98,$18,$CE,$D4,$15,$13
.byte $11,$D2,$CA,$CC,$96,$18,$57,$CE,$0F,$0F,$0F,$CE,$CE,$CE,$CE,$CE
.byte $0F,$0F,$0F,$CE,$CE,$CE,$CE,$CE,$0F,$0F,$0F,$CE


$FF5C	LDY $E1
$FF5E	LDA $E3
$FF60	LSR $E1
$FF62	BCS $FF7B
$FF64	LSR A
$FF65	BCS $FF9A
$FF67	JMP $FE36


$FF6A	LDA #$00
$FF6C	STA $E1
$FF6E	RTS


$FF6F	
.byte $06,$0C,$12,$47,$5F,$71,$5F,$71,$8E,$71,$8E,$BE


$FF7B	STY $E3
$FF7D	LDA #$12
$FF7F	STA $E4
$FF81	LDA #$02
$FF83	STA $E5
$FF85	LDX #$9f
$FF87	LDY #$7f
$FF89	STX $4000;	[NES] Audio - Square 1
$FF8C	STX $4004;	[NES] Audio - Square 2
$FF8F	STY $4001;	[NES] Audio - Square 1
$FF92	STY $4005;	[NES] Audio - Square 2
$FF95	LDA #$20
$FF97	STA $4008;	[NES] Audio - Triangle
$FF9A	LDA $E4
$FF9C	LDY $E5
$FF9E	CMP $FF6F,Y
$FFA1	BNE $FFC6
$FFA3	LDA $FF72,Y
$FFA6	STA $4002;	[NES] Audio - Square 1
$FFA9	LDX #$58
$FFAB	STX $4003;	[NES] Audio - Square 1
$FFAE	LDA $FF75,Y
$FFB1	STA $4006;	[NES] Audio - Square 2
$FFB4	STX $4007;	[NES] Audio - Square 2
$FFB7	LDA $FF78,Y
$FFBA	STA $400A;	[NES] Audio - Triangle
$FFBD	STX $400B;	[NES] Audio - Triangle
$FFC0	LDA $E5
$FFC2	BEQ $FFC6
$FFC4	DEC $E5
$FFC6	DEC $E4
$FFC8	BNE $FFD6
$FFCA	LDA #$00
$FFCC	STA $E3
$FFCE	LDA #$10
$FFD0	STA $4000;	[NES] Audio - Square 1
$FFD3	STA $4004;	[NES] Audio - Square 2
$FFD6	JMP $FF6A


$FFD9	TAY
$FFDA	LDA $FF01,Y
$FFDD	BEQ $FFE8
$FFDF	STA $4002,X;	[NES] Audio - Square 1
$FFE2	LDA $FF00,Y
$FFE5	STA $4003,X;	[NES] Audio - Square 1
$FFE8	RTS


$FFE9	TAX
$FFEA	ROR A
$FFEB	TXA
$FFEC	ROL A
$FFED	ROL A
$FFEE	ROL A
$FFEF	AND #$07
$FFF1	TAY
$FFF2	LDA $FF1A,Y
$FFF5	RTS

.byte $FF,$FF,$FF,$01

.segment "VECTORS"
$FFF6	
.word  NMI, Reset, IRQ