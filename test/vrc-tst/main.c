
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

u8 ctr = 0;

void main() {

    u16 i;
    u16 u;
    u8 *ram;
    u16 *ram16;



    gfx_init();



    *((u8 *) 0xB000) = 0;
    *((u8 *) 0xB001) = 0;

    *((u8 *) 0xB002) = 1;
    *((u8 *) 0xB003) = 0;


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

    ram = (u8 *) 0x6000;
    ram16 = (u16 *) 0x6000;
    /*
        ram[0] = 0xaa;
        for (i = 1; i < 8192; i++) {
            ram[i] = 0;
            if (ram[0] != 0xaa)break;
        }

        ppuSetAddr(0x2000 + 32 * 1);
        strCopy("MEM SISE ");
        printHex(i >> 8);
        printHex(i);



        for (i = 0; i < 8192; i++) {
            ram[i] = 0xaa;
            if (ram[i] != 0xaa)break;
            ram[i] = 0x55;
            if (ram[i] != 0x55)break;
        }

        ppuSetAddr(0x2000 + 32 * 2);
        strCopy("MIR SISE ");
        printHex(i >> 8);
        printHex(i);


        for (i = 0; i < 4096; i++) {
            ram16[4095 - i] = 4095 - i;
        }

        for (i = 0; i < 4096; i++) {
            if (ram16[i] != i)break;
        }

        i *= 2;

        ppuSetAddr(0x2000 + 32 * 3);
        strCopy("MEM SISE ");
        printHex(i >> 8);
        printHex(i);*/

    ppuSetAddr(0x2000 + 32 * 3);
    strCopy("IRQ TESTING");



    setScroll(0, 0);
    gfxOn();

    i = 16;

    *((u8 *) 0xB000) = i;
    *((u8 *) 0xB002) = i + 1;
    *((u8 *) 0xC000) = i + 2;
    *((u8 *) 0xC002) = i + 3;
    *((u8 *) 0xD000) = i + 4;
    *((u8 *) 0xD002) = i + 5;
    *((u8 *) 0xE000) = i + 6;
    *((u8 *) 0xE002) = i + 7;

    
    *((u8 *) 0xF000) = 15;
    *((u8 *) 0xF004) = 15;
    *((u8 *) 0xF008) = 3;
    asm("cli");

    i = 0;
    for (;;) {

        i++;
        for (u = 0; u < 8; u++)gfx_vsync();
        //*((u8 *) 0xF002) = 0;
        //gfx_vsync();
        ppuSetAddr(0x2000 + 32 * 3);
        PPU_DATA = '0' + i;
         setScroll(0, 0);

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