MAKEFLAGS= -j8

CC65_HOME = E:/devtools/cc65
SYS	= nes

croper = $(CC65_HOME)/bin/croper
CL   = $(CC65_HOME)/bin/cl65
CC   = $(CC65_HOME)/bin/cc65
AS   = $(CC65_HOME)/bin/ca65
LD   = $(CC65_HOME)/bin/ld65
MR   = ./tools/memreport	
TS   = ./tools/timestamp	

INC = $(CC65_HOME)/include
ASMINC = $(CC65_HOME)/asminc
# This one comes with VICE

# --static-locals
CFLAGS		:= -O
AFLAGS		:= -t $(SYS)
BDIR		:=build

vpath %.o $(BDIR)/


SRC_S := crt0.s bios_asm.s
SRC_C :=  $(wildcard *.c)

OBJ = $(SRC_S:.s=.o)
OBJ += $(SRC_C:.c=.o)
OFILES = $(OBJ:%.o=$(BDIR)/%.o)
	
# --------------------------------------------------------------------------
all: $(OBJ) 
	$(LD) -C nes.cfg -o boot2.nes $(OFILES) nes.lib -m $(BDIR)/mem.map
	$(TS) -f boot2.nes -a 0x20000
	$(MR) boot2.nes
	

%.o: %.s
	$(AS) $(AFLAGS) -o $(basename $(BDIR)/$<).o $<

%.o: %.c
	$(CC) $(CFLAGS) -o $(basename $(BDIR)/$<).s $<
	$(AS) $(AFLAGS) $(basename $(BDIR)/$<).s



clean:
	$(RM) $(BDIR)/*.o
	$(RM) $(BDIR)/*.s
	$(RM) $(APDIR)/*.o
