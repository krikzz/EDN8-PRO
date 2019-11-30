

CC65_HOME = E:/devtools/cc65
SYS	= nes

croper = $(CC65_HOME)/bin/croper
CL   = $(CC65_HOME)/bin/cl65
CC   = $(CC65_HOME)/bin/cc65
AS   = $(CC65_HOME)/bin/ca65
LD   = $(CC65_HOME)/bin/ld65

INC = $(CC65_HOME)/include
ASMINC = $(CC65_HOME)/asminc
# This one comes with VICE
C1541  	= c1541

# --------------------------------------------------------------------------
# Rules how to make each one of the binaries
all:   	
	$(AS) nsf.s
	$(LD) -C nes.cfg -o n8nsf.nes nsf.o 


clean:
	$(RM) *~ *.map *.o n8nsf.nes

