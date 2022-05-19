

#include "everdrive.h"

void bootError();

int main() {

    u8 *restart;

    std_init();
    sysInit();
    gInit();
 
    restart = malloc(1);

    if (*restart) {
        ppuOFF();
        bi_cmd_reboot();
    } else {
        *restart = 1;
    }

    bootError();
    gRepaint();
    while (1);
    
    return 0;
}

void bootError() {

    SysInfoIO inf;
    u8 resp;

    bi_cmd_sys_inf(&inf);
    resp = inf.boot_status;

    gCleanScreen();


    gSetPal(PAL_G1);
    gFillRect(' ', 0, 0, G_SCREEN_W, G_SCREEN_H);

    gSetXY(G_BORDER_X, G_SCREEN_H - G_BORDER_Y - 1);
    gConsPrint("2022 krikzz");
    gSetX(G_SCREEN_W - G_BORDER_X - 7);
    gAppendString("SN:");
    gAppendHex16(inf.serial_l);

    gSetPal(PAL_B1);
    gFillRect('-', 0, G_BORDER_Y, G_SCREEN_W, 4);
    gFillRect(' ', 0, G_BORDER_Y + 1, G_SCREEN_W, 2);
    gSetXY(G_BORDER_X, G_BORDER_Y);
    gConsPrint("EverDrive N8 bootloader v");
    gAppendNum(inf.sw_ver >> 8);
    gAppendString(".");
    gAppendHex8(inf.sw_ver);
    gConsPrint("ERROR: ");

    if (resp == FAT_DISK_ERR || resp == FAT_NOT_READY) {
        gAppendHex8(inf.disk_status);
    } else {
        gAppendHex8(resp);
    }

    gSetPal(PAL_G2);
    //resp = ERR_FPGA_INIT;

    if (resp == FAT_NO_FILE || resp == FAT_NO_PATH) {

        gSetY(G_SCREEN_H / 2 - 6);
        gConsPrintCX("File not found:");
        gConsPrintCX("SD:/EDN8/nesos.nes");
        gConsPrint("");
        gConsPrint("");
        gConsPrint("");

        gSetX(G_BORDER_X);

        gConsPrint("INSTRUCTIONS:");
        gConsPrint("");
        gConsPrint("1)Go to: http://krikzz.com");
        gConsPrint("");
        gConsPrint("2)Download latest EDN8.zip");
        gConsPrint("");
        gConsPrint("3)Unzip files to hard drive");
        gConsPrint("");
        gConsPrint("4)Copy EDN8 folder to SD card");

        return;
    }

    gSetY(G_SCREEN_H / 2 - 1);

    if (resp == FAT_NOT_READY) {
        gConsPrintCX("SD card not found");
        return;
    }

    if (resp == FAT_DISK_ERR) {
        gConsPrintCX("Disk I/O error");
        return;
    }

    if (resp == ERR_FPGA_INIT) {
        gConsPrintCX("FPGA configuration error");
        return;
    }

    if (resp == FAT_NO_FS) {
        gSetY(G_SCREEN_H / 2 - 2);
        gConsPrintCX("Unknown disk format");
        gConsPrint("");
        gConsPrintCX("Please use FAT32");
        return;
    }


    gConsPrintCX("Unexpected error");

}
