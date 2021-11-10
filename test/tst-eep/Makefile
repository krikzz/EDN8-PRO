#
# Makefile for cc65 samples
#
# This Makefile requires GNU make
#

CC65_HOME = E:/devtools/cc65
# Enter the target system here
SYS	= nes

# Determine the path to the executables and libraries. If the samples
# directory is part of a complete source tree, use the stuff from that
# source tree; otherwise, use the "install" directories.

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
# Generic rules

.c.o:
	
	$(AS) crt0.s
	$(CC) -O3 main.c --add-source
	$(AS) main.s

.o:
	$(LD) -C nes.cfg -o nesboot.nes crt0.o main.o nes.lib
	
	


# --------------------------------------------------------------------------
# List of executables. This list could be made target dependent by checking
# $(SYS).

EXELIST	= os



# --------------------------------------------------------------------------
# Rules how to make each one of the binaries

.PHONY:	all
all:   	main

main:	main.o



# --------------------------------------------------------------------------
# Cleanup rules

.PHONY:	clean
clean:
	$(RM) *~ *.map *.o *.lbl boot.bin

.PHONY:	zap
zap:	clean
	$(RM) $(EXELIST) overlaydemo.* samples.d64




#@echo $<