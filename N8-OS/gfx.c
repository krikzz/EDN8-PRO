
#include "main.h"




u16 g_addr;
u16 g_base;

void gInit() {

    g_base = 0;
    gCleanScreen();
    gRepaint();
}

void gSetPal(u8 pal) {
    REG_VRM_ATTR = pal;
}

void gSetXY(u8 x, u8 y) {

    g_addr = (u16) y * G_SCREEN_W + x;
    REG_VRM_ADDR = g_base + g_addr;
}

void gSetX(u8 x) {

    g_addr = g_addr / G_SCREEN_W * G_SCREEN_W + x;
    REG_VRM_ADDR = g_base + g_addr;
}

void gSetY(u8 y) {

    g_addr = (u16) y * G_SCREEN_W + g_addr % G_SCREEN_W;
    REG_VRM_ADDR = g_base + g_addr;
}

u8 gGetY() {
    return g_addr / G_SCREEN_W;
}

u8 gGetX() {
    return g_addr % G_SCREEN_W;
}

void gCleanScreen() {

    gSetPal(0);
    g_addr = 0;
    REG_VRM_ADDR = g_base;
    bi_clean_screen();
    REG_VRM_ADDR = g_base;
    gSetXY(G_BORDER_X, G_BORDER_Y);
    gSetPal(PAL_B2);
}

void gAppendString(u8 *str) {

    //while (*str != 0)REG_VRM_DATA = *str++;
    zp_len = 255;
    zp_src = str;
    bi_put_str();
}

void gAppendString_ML(u8 *str, u8 max_len) {

    zp_len = max_len;
    zp_src = str;
    bi_put_str();
}

void gAppendHex4(u8 val) {

    val += (val < 10 ? '0' : '7');
    REG_VRM_DATA = val;
}

void gAppendHex8(u8 val) {

    gAppendHex4(val >> 4);
    gAppendHex4(val & 15);
}

void gAppendHex16(u16 val) {

    gAppendHex8(val >> 8);
    gAppendHex8(val);
}

void gAppendHex32(u32 val) {

    gAppendHex16(val >> 16);
    gAppendHex16(val);

}

void gAppendNum(u32 num) {

    u16 i;
    u8 buff[11];
    u8 *str = (u8 *) & buff[10];


    *str = 0;
    if (num == 0)*--str = '0';
    for (i = 0; num != 0; i++) {

        *--str = num % 10 + '0';
        num /= 10;
    }

    gAppendString(str);

}

void gAppendDate(u16 date) {

    u8 buff[16];
    buff[0] = 0;
    str_append_date(buff, date);
    gAppendString(buff);
}

void gAppendTime(u16 time) {

    u8 buff[16];
    buff[0] = 0;
    str_append_time(buff, time);
    gAppendString(buff);
}

void gConsPrint(u8 *str) {

    g_addr += G_SCREEN_W;
    REG_VRM_ADDR = g_base + g_addr;
    gAppendString(str);
}

void gConsPrint_ML(u8 *str, u8 maxlen) {

    g_addr += G_SCREEN_W;
    REG_VRM_ADDR = g_base + g_addr;
    gAppendString_ML(str, maxlen);
}

void gConsPrintCX(u8 *str) {

    gConsPrintCX_ML(str, MAX_STR_LEN);
}

void gConsPrintCX_ML(u8 *str, u8 maxlen) {

    u8 str_len = str_lenght(str);
    if (str_len > maxlen)str_len = maxlen;
    gSetX((G_SCREEN_W - str_len) / 2);
    gConsPrint_ML(str, maxlen);
}

void gAppendChar(u8 chr) {
    REG_VRM_DATA = chr;
}

void gFillRect(u8 val, u8 x, u8 y, u8 w, u8 h) {

    //u8 i;
    u16 addr;
    gSetXY(x, y++);
    addr = REG_VRM_ADDR;

    zp_arg = val;
    zp_len = w;
    while (h--) {

        /*for (i = 0; i < w; i++) {
            REG_VRM_DATA = val;
        }*/
        bi_vram_fill();
        REG_VRM_ADDR += G_SCREEN_W - w;
    }

    REG_VRM_ADDR = addr;
}

void gFillRow(u8 val, u8 x, u8 y, u8 w) {

    gSetXY(x, y);
    //while (w--)REG_VRM_DATA = data;
    zp_arg = val;
    zp_len = w;
    bi_vram_fill();
}

void gFillCol(u8 val, u8 x, u8 y, u8 h) {

    gSetXY(x, y);

    while (h--) {
        REG_VRM_DATA = val;
        REG_VRM_ADDR += G_SCREEN_W - 1;
    }
}

void gDrawHeader(u8 *str, u8 attr) {

    gFillRow(' ', 0, G_BORDER_Y, G_SCREEN_W);
    gSetY(G_BORDER_Y - 1);

    if ((attr & G_CENTER)) {
        gConsPrintCX(str);
    } else {
        gSetX(G_BORDER_X);
        gConsPrint(str);
    }

}

void gDrawFooter(u8 *str, u8 rows, u8 attr) {


    gFillRect(' ', 0, G_SCREEN_H - G_BORDER_Y - rows, G_SCREEN_W, rows);
    gSetY(G_SCREEN_H - G_BORDER_Y - rows - 1);

    while (1) {
        if ((attr & G_CENTER)) {
            gConsPrintCX_ML(str, MAX_STR_LEN);
        } else {
            gSetX(G_BORDER_X);
            gConsPrint_ML(str, MAX_STR_LEN);
        }
        if (str_lenght(str) < MAX_STR_LEN) break;
        str += MAX_STR_LEN;
    }
}

void gAppendHex(void *src, u16 len) {

    while (len--) {
        gAppendHex8(*((u8 *) src)++);
    }
}

void gRepaint() {

    u8 scroll = 0;
    u16 addr = REG_VRM_ADDR & 1023;

    if (sysVramBug()) {

        zp_dst = (void *) 0x2000;
        zp_arg = 0xfa; //scroll
        REG_VRM_ADDR = g_base ^ 1024;
        bi_copy_screen_safe();

        REG_VRM_ADDR = g_base ^ 1024;
        bi_copy_screen();
        REG_VRM_ADDR = g_base + addr;

        return;
    }


    g_base ^= 1024;
    if (g_base == 0)scroll = 240;
    

    sysVsync();
    ppuSetScroll(0, scroll);

    REG_VRM_ADDR = g_base;
    bi_copy_screen();
    REG_VRM_ADDR = g_base + addr;

}

