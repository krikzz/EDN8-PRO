

#include "everdrive.h"

void ppuSetAddr(u16 addr);
void ppuSetPal(u8 *pal);
u8 vram_bug;

//black, gray, black, text
static u8 pal_std[] = {
    0x0F, 0x2d, 0x0F, 0x10,
    0x0F, 0x2d, 0x0F, 0x20,
    0x0F, 0x2d, 0x0F, 0x27,
    0x0F, 0x2d, 0x0F, 0x1A,
};
static u8 pal_safe[] = {
    0x0F, 0x1c, 0x0F, 0x20,
    0x0F, 0x0F, 0x0F, 0x0F,
    0x0F, 0x0F, 0x0F, 0x0F,
    0x0F, 0x0F, 0x0F, 0x0F,
};

static u8 pal_black[] = {
    0x0F, 0x0F, 0x0F, 0x0F,
    0x0F, 0x0F, 0x0F, 0x0F,
    0x0F, 0x0F, 0x0F, 0x0F,
    0x0F, 0x0F, 0x0F, 0x0F,
};

void sysInit() {

    u8 i;
    u8 *str = "EDN8";

    sysVsync();
    PPU_CTRL = 0;
    PPU_MASK = 0;

    //check if ppu vram can be switched off
    REG_VRM_ATTR = VRM_MODE_TST;
    ppuSetAddr(0x2000);
    for (i = 0; str[i] != 0; i++) {
        PPU_DATA = str[i];
    }

    vram_bug = 1;
    ppuSetAddr(0x2000);
    i = PPU_DATA;
    for (i = 0; str[i] != 0; i++) {
        if (PPU_DATA != str[i])vram_bug = 0;
    }

    //vram_bug = 1;
    sysPalInit(0);



    ppuSetScroll(0, 0);
    ppuON();
}

void ppuSetPal(u8 *pal) {

    u8 i;
    sysVsync();
    ppuSetAddr(0x3F00);
    for (i = 0; i < 16; i++) {
        PPU_DATA = pal[i];
    }
}

void ppuSetAddr(u16 addr) {
    PPU_ADDR = addr >> 8;
    PPU_ADDR = addr & 0xff;
}

void ppuSetScroll(u8 x, u8 y) {

    PPU_ADDR = 0;
    PPU_ADDR = 0;
    PPU_SCROLL = x;
    PPU_SCROLL = y - 6;
}

void ppuOFF() {
    sysVsync();
    PPU_MASK = 0;
}

void ppuON() {
    sysVsync();
    PPU_MASK = 0x0A;
}

void sysPalInit(u8 fade_to_black) {

    u8 i;
    if (fade_to_black) {

        ppuSetPal(pal_black);

    } else if (vram_bug) {

        REG_VRM_ATTR = VRM_MODE_SAF;
        ppuSetPal(pal_safe);
        //clean attribute area
        ppuSetAddr(0x2300);
        for (i = 0; i < 128; i++) {
            PPU_DATA = 0x00;
            PPU_DATA = 0x00;
        }

    } else {
        REG_VRM_ATTR = VRM_MODE_STD;
        ppuSetPal(pal_std);
    }
}

u8 sysJoyRead() {

    u16 delay;
    u8 joy = 0;
    u8 i;

    delay = bi_get_ticks();
    while (bi_get_ticks() - delay < 10); //antiglitch
    //sysVsync();

    JOY_PORT1 = 0x01;
    JOY_PORT1 = 0x00;

    for (i = 0; i < 8; i++) {
        joy <<= 1;
        if ((JOY_PORT1 | JOY_PORT2) & 3)joy |= 1;
    }

    if (!registery->options.swap_ab) {
        i = joy;
        joy &= ~(JOY_A | JOY_B);
        if ((i & JOY_A))joy |= JOY_B;
        if ((i & JOY_B))joy |= JOY_A;
    }

    usbListener();

    return joy;
}

u8 sysJoyWait() {

    u8 joy;
    static u16 time;

    if (time == 0)time = bi_get_ticks();

    while (1) {

        joy = sysJoyRead();
        if (joy == 0)break;

        if ((bi_get_ticks() - time) > JOY_DELAY) {

            time += JOY_SPEED;
            if ((joy & (JOY_A | JOY_B)) == 0)return joy;
        }


    }

    time = 0;

    while (joy == 0) {

        joy = sysJoyRead();
    }

    return joy;
}

void sysVsync() {

    volatile u8 tmp = PPU_STAT;
    while (PPU_STAT < 128);
}

u8 sysVramBug() {
    return vram_bug;
}

