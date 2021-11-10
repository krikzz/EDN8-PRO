
#include "everdrive.h"

u8 app_diagnostics();

u8 diagnostics() {

    u8 resp;
    u8 bank = REG_APP_BANK;
    REG_APP_BANK = APP_TST;
    resp = app_diagnostics();
    REG_APP_BANK = bank;
    return resp;
}

#pragma codeseg ("BNK07")

u8 testRamBackup();
u8 testRamRestore();
void testPrintResp(u8 resp);
u8 testMEM(u8 *name, u32 addr, u32 size);
u8 testSDC();
u8 testSDC_spd();
void testVDC();
u8 testRTC();
void printVDC(u8 *name, u16 vdc, u16 min, u16 max);
void testPrintSpeed(u16 time, u32 size);
void testRepaint();
void testVramBug();

//app call handling should be implemented if run outside of main menu bank

u8 app_diagnostics() {

    u8 resp;

    //gCleanScreen();
    //gSetY(G_SCREEN_H / 2);

    gCleanScreen();
    gSetY(G_SCREEN_H / 2 - 4);
    gConsPrintCX("Mass graphics glitches will");
    gConsPrintCX("shown during the test");
    gConsPrintCX("This is normal");
    gConsPrintCX("");
    gConsPrintCX("Press any key to begin");
    gRepaint();
    sysJoyWait();

    gCleanScreen();
    gConsPrint("EverDrive N8 diagnostics menu");
    gFillRect('-', G_BORDER_X, gGetY() + 1, MAX_STR_LEN, 1);
    gRepaint();

    gSetY(gGetY() + 1);


    resp = testRamBackup();
    if (resp)return resp;

    resp = testMEM("PRG", ADDR_PRG, SIZE_PRG);
    testPrintResp(resp);

    resp = testMEM("CHR", ADDR_CHR, SIZE_CHR);
    testPrintResp(resp);

    resp = testMEM("SRM", ADDR_SRM, SIZE_SRM);
    testPrintResp(resp);

    resp = testSDC();
    testPrintResp(resp);

    resp = testRTC();
    testPrintResp(resp);

    testVDC();

    testVramBug();

    resp = testSDC_spd();
    if (resp) {
        testPrintResp(resp);
    }

    //testRepaint();


    gConsPrint("");
    gFillRect('-', G_BORDER_X, gGetY() + 1, MAX_STR_LEN, 1);
    gConsPrint("Press any key");
    
    resp = testRamRestore();
    if (resp)return resp;


    gRepaint();
    sysJoyWait();

    return 0;
}

u8 testRamBackup() {

    u8 resp;

    resp = bi_cmd_file_open(PATH_RAMDUMP, FA_OPEN_ALWAYS | FA_WRITE);
    if (resp)return resp;

    resp = bi_cmd_file_write_mem(ADDR_SRM, SIZE_SRM);
    if (resp)return resp;

    resp = bi_cmd_file_close();
    if (resp)return resp;

    return 0;
}

u8 testRamRestore() {

    u8 resp;

    resp = bi_cmd_file_open(PATH_RAMDUMP, FA_READ);
    if (resp)return resp;

    resp = bi_cmd_file_read_mem(ADDR_SRM, SIZE_SRM);
    if (resp)return resp;

    resp = bi_cmd_file_close();
    if (resp)return resp;

    return 0;
}

void testPrintResp(u8 resp) {

    //ppuON();

    gSetPal(resp ? PAL_B1 : PAL_BG);
    if (resp) {
        gAppendString(" ERROR: ");
        gAppendHex8(resp);
    } else {
        gAppendString(" OK");
    }
    gSetPal(PAL_B2);


    gRepaint();
}

u8 testMEM(u8 *name, u32 addr, u32 size) {

    u32 i;
    u32 v;
    u8 resp;
    static const u8 tst_vals[] = {0x00, 0xff, 0xaa, 0x55};

    gConsPrint("Testing ");
    gAppendString(name);
    gAppendString("... ");
    gRepaint();

    //ppuOFF();

    //test memory size
    for (i = size / 2, v = 0;; i /= 2, v++) {
        bi_cmd_mem_set(v, addr + i, 1);
        if (i == 0)break;
    }

    for (i = size / 2, v = 0;; i /= 2, v++) {
        resp = bi_cmd_mem_test(v, addr + i, 1);
        if (resp == 0)return 1;
        if (i == 0)break;
    }


    //stability test 1
    for (i = 0; i < 256; i++) {
        bi_cmd_mem_set(i, addr, 512);
        resp = bi_cmd_mem_test(i, addr, 512);
        if (resp == 0)return 2;
    }

    //stability test 2
    for (i = 0; i < 128; i++) {
        v = tst_vals[i & 3];
        bi_cmd_mem_set(v, addr, 1024);
        resp = bi_cmd_mem_test(v, addr, 1024);
        if (resp == 0)return 3;
    }


    v = 0xAA5500FF;
    bi_cmd_mem_wr(addr, &v, 4);
    bi_cmd_mem_rd(addr, &v, 4);
    if (v != 0xAA5500FF)return 4;

    return 0;
}

u8 testSDC() {

    u8 resp;
    u8 i, u;
    u32 crc1, crc2, addr;
    const u8 retry = 16;
    const u32 tst_file_len = 0x10000;

    gConsPrint("Testing SDC... ");
    gRepaint();

    resp = bi_cmd_file_open(PATH_SDC_FILE, FA_READ);
    if (resp)return resp;

    crc1 = 0;
    resp = bi_cmd_file_crc(tst_file_len, &crc1);
    if (resp)return resp;
    resp = bi_cmd_file_close();
    if (resp)return resp;


    for (i = 0; i < retry; i++) {
        resp = bi_cmd_file_open(PATH_SDC_FILE, FA_READ);
        if (resp)return resp;

        crc2 = 0;
        resp = bi_cmd_file_crc(tst_file_len, &crc2);
        if (resp)return resp;
        resp = bi_cmd_file_close();
        if (resp)return resp;
        if (crc1 != crc2)return 1;
    }

    for (u = 0; u < 3; u++) {//returns errors 2,3,4

        if (u == 0)addr = ADDR_PRG;
        if (u == 1)addr = ADDR_CHR;
        if (u == 2)addr = ADDR_SRM;

        for (i = 0; i < retry; i++) {

            resp = bi_cmd_file_open(PATH_SDC_FILE, FA_READ);
            if (resp)return resp;
            resp = bi_cmd_file_read_mem(addr, tst_file_len);
            if (resp)return resp;
            resp = bi_cmd_file_close();
            if (resp)return resp;

            crc2 = 0;
            bi_cmd_mem_crc(addr, tst_file_len, &crc2);
            if (crc1 != crc2)return u + 2;
        }
    }

    for (u = 0; u < 8; u++) {

        resp = bi_cmd_file_open(PATH_TESTFILE, FA_OPEN_ALWAYS | FA_WRITE);
        if (resp)return resp;

        resp = bi_cmd_file_write_mem(ADDR_PRG, tst_file_len);
        if (resp)return resp;

        resp = bi_cmd_file_close();
        if (resp)return resp;

        resp = bi_cmd_file_open(PATH_TESTFILE, FA_READ);
        if (resp)return resp;

        crc2 = 0;
        resp = bi_cmd_file_crc(tst_file_len, &crc2);
        if (resp)return resp;

        resp = bi_cmd_file_close();
        if (resp)return resp;

        if (crc1 != crc2)return 5;
    }

    return 0;
}

u8 testSDC_spd() {

    u16 time;
    u8 resp;
    u8 buff[128];
    u16 i;

    gConsPrint("SD RD speed... ");
    gRepaint();


    resp = bi_cmd_file_open(PATH_TESTFILE, FA_OPEN_ALWAYS | FA_WRITE);
    if (resp)return resp;
    resp = bi_cmd_file_write_mem(ADDR_PRG, SIZE_SRM);
    if (resp)return resp;
    resp = bi_cmd_file_close();
    if (resp)return resp;


    resp = bi_cmd_file_open(PATH_TESTFILE, FA_READ);
    if (resp)return resp;

    time = bi_get_ticks();
    resp = bi_cmd_file_read_mem(ADDR_PRG, SIZE_SRM);
    if (resp)return resp;
    time = bi_get_ticks() - time;

    resp = bi_cmd_file_close();
    if (resp)return resp;

    testPrintSpeed(time, SIZE_SRM);


    gConsPrint("SD WR speed... ");
    gRepaint();

    resp = bi_cmd_file_open(PATH_TESTFILE, FA_OPEN_ALWAYS | FA_WRITE);
    if (resp)return resp;

    time = bi_get_ticks();
    resp = bi_cmd_file_write_mem(ADDR_PRG, SIZE_SRM);
    if (resp)return resp;
    time = bi_get_ticks() - time;

    resp = bi_cmd_file_close();
    if (resp)return resp;

    testPrintSpeed(time, SIZE_SRM);

    //test communication speed between cpu and mcu
    gConsPrint("IO RD speed... ");
    gRepaint();
    time = bi_get_ticks();
    for (i = 0; i < 256; i++) {
        bi_cmd_mem_rd(ADDR_PRG, buff, 128);
    }
    time = bi_get_ticks() - time;
    testPrintSpeed(time, sizeof (buff) * 256);


    gConsPrint("IO WR speed... ");
    gRepaint();
    time = bi_get_ticks();
    for (i = 0; i < 256; i++) {
        bi_cmd_mem_wr(ADDR_PRG, buff, 128);
        bi_cmd_status((u16 *) buff); //preven fifo overflow
    }
    time = bi_get_ticks() - time;
    testPrintSpeed(time, sizeof (buff) * 256);

    return 0;
}

void testVDC() {

    Vdc vdc;

    bi_cmd_get_vdc(&vdc);
    bi_cmd_get_vdc(&vdc);

    printVDC("Battery ", vdc.vbt, 0x200, 0x345);
    printVDC("VCC 5.0v", vdc.v50, 0x440, 0x510);
    printVDC("VCC 2.5v", vdc.v25, 0x240, 0x260);
    printVDC("VCC 1.2v", vdc.v12, 0x110, 0x130);

}

u8 testRTC() {

    RtcTime time;
    u16 ticks;
    u8 sec;

    gConsPrint("Testing RTC... ");
    gRepaint();

    ticks = bi_get_ticks();

    bi_cmd_rtc_get(&time);
    sec = time.sec;

    while (sec == time.sec) {
        if (bi_get_ticks() - ticks > 1200)return 1;
        bi_cmd_rtc_get(&time);
    }

    ticks = bi_get_ticks();

    sec = time.sec;
    while (sec == time.sec) {
        bi_cmd_rtc_get(&time);
    }

    ticks = bi_get_ticks() - ticks;


    if (ticks > 1100)return 2;
    if (ticks < 950)return 3;

    return 0;
}

void printVDC(u8 *name, u16 vdc, u16 min, u16 max) {

    gSetPal(PAL_B2);
    gConsPrint(name);
    gAppendString(" - ");
    gAppendNum(vdc >> 8);
    gAppendString(".");
    gAppendHex8(vdc);

    if (vdc >= min && vdc <= max) {
        gSetPal(PAL_BG);
        gAppendString(" OK");
    } else {
        gSetPal(PAL_B1);
        gAppendString(" ERROR");
    }

    gSetPal(PAL_B2);
    gRepaint();

}

void testPrintSpeed(u16 time, u32 size) {


    u32 speed = size / 1024 * 1000 / time;
    u8 y = gGetY();

    //gSetXY(14, y - 1);

    if (speed < 100)gAppendString(" ");
    if (speed < 1000)gAppendString(" ");



    gAppendNum(speed);
    gAppendString(" KB/s");
    gRepaint();

    //gSetXY(G_BORDER_X, y);
    //gSetPal(PAL_B1);
}

void testRepaint() {

    u8 i;
    u16 time;
    gConsPrint("Repaint time.. ");
    gRepaint();

    time = bi_get_ticks();
    for (i = 0; i < 10; i++) {
        gRepaint();
    }
    time = bi_get_ticks() - time;

    gAppendNum(time / 10);
    gAppendString("ms");

}

void testVramBug() {


    gConsPrint("PPU Vram bug..  ");
    if (sysVramBug()) {
        gSetPal(PAL_B1);
        gAppendString("Bug detected");
    } else {
        gSetPal(PAL_BG);
        gAppendString("Not Detected");
    }

    gRepaint();
}