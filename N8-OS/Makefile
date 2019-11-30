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
CFLAGS		:= -Oi
AFLAGS		:= -t $(SYS)
BDIR		:=build

vpath %.o $(BDIR)/


SRC_S := crt0.s bios_asm.s ss.s
SRC_C :=  $(wildcard *.c)
#SRC_C := $(filter-out app-%.c, $(SRC_C))

OBJ = $(SRC_S:.s=.o)
OBJ += $(SRC_C:.c=.o)
OFILES = $(OBJ:%.o=$(BDIR)/%.o)
	
SRC_B := boot1.s	
OBJ_B = $(SRC_B:.s=.o)
OFILES_B = $(OBJ_B:%.o=$(BDIR)/%.o)

# --------------------------------------------------------------------------

	
all: $(OBJ) boot
	$(LD) -C nes.cfg -o nesos.nes $(OFILES) nes.lib -m $(BDIR)/mem.map
	$(TS) -f nesos.nes -a 0x20000
	$(MR) nesos.nes
	

boot: $(OBJ_B) 
	$(LD) -C boot.cfg -o boot.nes $(OFILES_B)



%.o: %.s
	$(AS) $(AFLAGS) -o $(basename $(BDIR)/$<).o $<

%.o: %.c
	$(CC) $(CFLAGS) -o $(basename $(BDIR)/$<).s $<
	$(AS) $(AFLAGS) $(basename $(BDIR)/$<).s



clean:
	$(RM) $(BDIR)/*.o
	$(RM) $(BDIR)/*.s
	$(RM) $(APDIR)/*.o
