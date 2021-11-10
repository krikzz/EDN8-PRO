
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

#define EEP_DIR 0x80
#define EEP_DAT 0x40 
#define EEP_CLK 0x20

#define EEP_WR  *((u8 *)0x800D)
#define EEP_RD  *((u8 *)0x6000)
u8 eep;

void eep_start() {
    EEP_WR = EEP_DAT | EEP_CLK;
    EEP_WR = EEP_CLK;
    eep = EEP_CLK;
}

void eep_stop() {
    EEP_WR = EEP_CLK;
    EEP_WR = EEP_CLK | EEP_DAT;
    eep = EEP_CLK | EEP_DAT;
}

u8 eep_tx(u8 dat) {

    u8 i;
    u8 bit;

    for (i = 0; i < 8; i++) {

        bit = (dat & 0x80) ? EEP_DAT : 0;
        EEP_WR = bit;
        EEP_WR = bit | EEP_CLK;
        EEP_WR = bit;
        dat <<= 1;
    }
    
    EEP_WR = EEP_DAT;
    EEP_WR = EEP_DAT | EEP_CLK;
    EEP_WR = EEP_DAT | EEP_DIR;
    bit = EEP_RD & 0x10;
    EEP_WR = EEP_DAT;
    return bit;
}

void main() {

    u16 i;
    u16 u;
    u8 *ptr;
    eep = EEP_DAT | EEP_CLK;

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

    ptr = (u8 *) 0x6000;
    for (i = 0; i < 8; i++)ptr[i] = i;

    ppuSetAddr(0x2000 + 32 * 2);
    strCopy("MEM SISE ");
    *(u8 *) 0x800D = 0xff;
    printHex(*(u8 *) 0x800D);






    setScroll(0, 0);
    gfxOn();

    i = 16;


    i = 0;
    for (;;) {

        i++;
        for (u = 0; u < 60; u++)gfx_vsync();

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