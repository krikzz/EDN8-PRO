MAKEFLAGS= -j8

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

# --static-locals
CFLAGS		:= -O
AFLAGS		:= -t $(SYS)
BDIR		:=build

vpath %.o $(BDIR)/

	
SRC_B := boot1.s	
OBJ_B = $(SRC_B:.s=.o)
OFILES_B = $(OBJ_B:%.o=$(BDIR)/%.o)

# --------------------------------------------------------------------------

all: $(OBJ_B) 
	$(LD) -C boot.cfg -o boot1.nes $(OFILES_B)



%.o: %.s
	$(AS) $(AFLAGS) -o $(basename $(BDIR)/$<).o $<

%.o: %.c
	$(CC) $(CFLAGS) -o $(basename $(BDIR)/$<).s $<
	$(AS) $(AFLAGS) $(basename $(BDIR)/$<).s



clean:
	$(RM) $(BDIR)/*.o
	$(RM) $(BDIR)/*.s
	$(RM) $(APDIR)/*.o
