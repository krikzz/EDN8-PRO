
#define u8 unsigned char
#define u16 unsigned short
#define u32 unsigned long

#define JOY_PORT *((u8 *)0x4016)
#define PPU_CTRL *((u8 *)0x2000)
#define PPU_MASK *((u8 *)0x2001)
#define PPU_ADDR *((u8 *)0x2006)
#define PPU_DATA *((u8 *)0x2007)
#define PPU_SCROLL *((u8 *)0x2005)

#define JOY_UP          0x08
#define JOY_DOWN        0x04
#define JOY_LEFT        0x02
#define JOY_RIGHT       0x01
#define JOY_SEL         0x20
#define JOY_START       0x10
#define JOY_B           0x40
#define JOY_A           0x80


void gfx_vsync();
void gfx_init();

void gfxOn();
void gfxOff();
void setScroll(u8 x, u8 y);
void ppuSetAddr(u16 addr);
void strCopy(u8 *src);
u8 joyRead();
void printHex(u8 val);

#define CHR_MODE *((u8 *)0x5101)
#define EXRAM_MODE *((u8 *)0x5104)
#define NT_MAP *((u8 *)0x5105)
#define FILL_TILE *((u8 *)0x5106)
#define FILL_COLOR *((u8 *)0x5107)
#define IRQ_CTR *((u8 *)0x5203)
#define IRQ_STAT *((u8 *)0x5204)

#define SPLIT_MODE *((u8 *)0x5200)
#define SPLIT_SCRL *((u8 *)0x5201)
#define SPLIT_BANK *((u8 *)0x5202)

#define APU_PLSE ((u8 *)0x4000)
#define APU_STAT *((u8 *) 0x4015)
#define APU_FCTR *((u8 *) 0x4017)

void beepAPU(u8 on) {

    if (on == 0) {
        APU_STAT = 0;
        return;
    }

    APU_FCTR = 0;
    APU_STAT = 0xff;

    APU_PLSE[1] = 8;
    APU_PLSE[2] = 0xfd;
    APU_PLSE[3] = 0;
    APU_PLSE[0] = 0xBF;
}


#define MMC5_PLSE ((u8 *)0x5000)
#define MMC5_STAT *((u8 *) 0x5015)

void beepEVD(u8 on) {

    if (on == 0) {
        MMC5_STAT = 0;
        return;
    }


    MMC5_STAT = 0xff;

    MMC5_PLSE[1] = 8;
    MMC5_PLSE[2] = 0xfd;
    MMC5_PLSE[3] = 0;
    MMC5_PLSE[0] = 0xBF;

}

void beepTest() {

    u8 joy;
    u8 old_joy = 0xff;
    u8 master_vol = 100;




    while (1) {
        gfx_vsync();


        old_joy = joy;
        joy = joyRead();
        if (old_joy == joy)continue;



        if (joy == 0) {
            beepAPU(0);
            beepEVD(0);
        }

        if (joy == JOY_B && old_joy == 0) {
            beepAPU(1);
        }

        if (joy == JOY_A && old_joy == 0) {
            beepEVD(1);
        }

        if ((joy & JOY_LEFT) && !(old_joy & JOY_LEFT)) {
            master_vol--;
            if (master_vol > 200)master_vol = 199;
        }

        if ((joy & JOY_RIGHT) && !(old_joy & JOY_RIGHT)) {
            master_vol++;
            if (master_vol > 200)master_vol = 0;
        }

    }

}

void main() {

    u16 i;
    u8 *exram = (u8 *) 0x5C00;
    u8 *chr_banks = (u8 *) 0x55120;
    u8 joy;



    CHR_MODE = 0;
    NT_MAP = 0x80;
    EXRAM_MODE = 0;
    FILL_TILE = 'E';
    FILL_COLOR = 0xff;

    for (i = 0; i < 12; i++)chr_banks[i] = 0;



    gfx_init();

    ppuSetAddr(0x3F03);
    PPU_DATA = 0x27; //0x05;
    ppuSetAddr(0x3F07);
    PPU_DATA = 0x09;
    ppuSetAddr(0x3F0B);
    PPU_DATA = 0x01;
    ppuSetAddr(0x3F0F);
    PPU_DATA = 0x27;


    PPU_CTRL = 1 << 4; //select bg pattern

    ppuSetAddr(0x2000);
    for (i = 0; i < 960; i++)PPU_DATA = ' ';
    for (i = 0; i < 64; i++)PPU_DATA = 0;
    for (i = 0; i < 960; i++)PPU_DATA = ' ';
    for (i = 0; i < 64; i++)PPU_DATA = 0;
    for (i = 0; i < 960; i++)PPU_DATA = ' ';
    for (i = 0; i < 64; i++)PPU_DATA = 0;
    for (i = 0; i < 960; i++)PPU_DATA = ' ';
    for (i = 0; i < 64; i++) {
        if (i == 8) {
            PPU_DATA = 0x45;
            continue;
        }
        if (i == 16) {
            PPU_DATA = 0x2a;
            continue;
        }
        PPU_DATA = 0;
    }



    ppuSetAddr(0x2000 + 32);
    strCopy("SPLITTTTTTTTTTTTHHHH");
    ppuSetAddr(0x2000 + 64);
    for (i = 0; i < 16; i++)printHex(i);

    for (i = 0; i < 30; i++) {
        ppuSetAddr(0x2000 + 1024 * 3 + i * 32);

        strCopy("HELL");
        printHex(i);
    }


    setScroll(0, 0);
    gfxOn();

    SPLIT_MODE = 0x80 | 0x00 | 16;
    SPLIT_BANK = 1;
    SPLIT_SCRL = 0;
    i = 0;

    beepTest();
    
    for (;;) {

        gfx_vsync();
        

        while (joyRead() != 0);
        while (joyRead() == 0);
        if (joyRead() == JOY_UP) {
            i += 8;
        }

        if (joyRead() == JOY_DOWN) {
            i -= 8;
        }
        SPLIT_SCRL = i;
    }
}

void printHex(u8 val) {

    u8 buff[3];
    buff[0] = val >> 4;
    buff[1] = val & 15;
    buff[2] = 0;

    buff[0] = buff[0] < 10 ? buff[0] + '0' : buff[0] - 10 + 'A';
    buff[1] = buff[1] < 10 ? buff[1] + '0' : buff[1] - 10 + 'A';

    strCopy(buff);
}

void strCopy(u8 *src) {

    while (*src)PPU_DATA = *src++;
}

/*
 * после доступа к памяти ппу нужно возвращать значения скролинга в исходное значение 
 */
void ppuSetAddr(u16 addr) {
    PPU_ADDR = addr >> 8;
    PPU_ADDR = addr & 0xff;
}

void setScroll(u8 x, u8 y) {

    PPU_ADDR = 0;
    PPU_SCROLL = y;
    PPU_SCROLL = x;
}

void gfxOff() {
    gfx_vsync();
    PPU_MASK = 0;
    //PPU_CTRL = 0;
}

void gfxOn() {
    gfx_vsync();
    //PPU_CTRL = 0x80;
    PPU_MASK = 0x0A;
}

u8 joyRead() {

    u8 joy = 0;
    u8 i;

    JOY_PORT = 0x01;
    JOY_PORT = 0x00;

    for (i = 0; i < 8; i++) {
        joy <<= 1;
        joy |= JOY_PORT & 1;
    }

    return joy;
}