

#include "everdrive.h"

int main() {

    u8 resp;

    resp = edInit(0);

    if (resp) {
        printError(resp);
        while (1);
    }

    //tst();
    edRun();

    while (1);


    return 0;
}

void printError(u8 code) {

    SysInfoIO inf;
    u8 warning = 0;

    bi_cmd_sys_inf(&inf);
    ppuON();
    gCleanScreen();

    if (code == FAT_NO_FILE && str_cmp_len(PATH_DEF_GAME, registry->cur_game.path, 0)) {
        code = ERR_GAME_NOT_SEL;
    }

    gSetY(G_SCREEN_H / 2 - 2);

    if (code == FAT_NO_PATH) {
        gConsPrintCX("Path not found");
    } else if (code == FAT_NO_FILE) {
        gConsPrintCX("File not found");
    } else if (code == ERR_BAD_FILE) {
        gConsPrintCX("Bad file");
    } else if (code == ERR_BAD_NSF) {
        gConsPrintCX("Unsupported NSF file");
        warning = 1;
    } else if (code == ERR_FPGA_INIT) {
        gConsPrintCX("FPGA configuration error");
    } else if (code == ERR_MAP_NOT_FOUND) {
        gConsPrintCX("Mapper file not found");
    } else if (code == ERR_MAP_NOT_SUPP) {
        gConsPrintCX("Mapper is not supported");
    } else if (code == ERR_UNK_ROM_FORMAT) {
        gConsPrintCX("Unknown ROM format");
    } else if (code == ERR_GAME_NOT_SEL) {
        gConsPrintCX("There is no selected game");
        warning = 1;
    } else if (code == FAT_NOT_READY) {
        gConsPrintCX("SD card not found");
        code = inf.disk_status;
    } else if (code == FAT_DISK_ERR) {
        gConsPrintCX("Disk I/O error");
        code = inf.disk_status;
    } else if (code == FAT_NO_FS) {
        gConsPrintCX("Unknown disk format");
        gConsPrintCX("");
        gConsPrintCX("Please use FAT32");
    } else if (code == ERR_REGI_CRC) {
        gConsPrintCX("Settings were reset to default");
        gConsPrintCX("");
        gConsPrintCX("Press any key");
        warning = 1;
    } else if (code == ERR_BAT_RDY) {
        gSetY(gGetY() - 3);
        gConsPrintCX("Battery has run dry");
        gConsPrintCX("");
        gConsPrintCX("Please replace the battery");
        gConsPrintCX("");
        gConsPrintCX("Your battery type: CR2032");
        gConsPrintCX("");
        gConsPrintCX("");
        gConsPrintCX("Press any key");
        warning = 1;
    } else if (code == ERR_USB_GAME) {
        gConsPrintCX("Game is not selected");
        gConsPrintCX("");
        gConsPrintCX("Last game was loaded via USB");
    } else if (code == ERR_FDS_SIZE) {
        gConsPrintCX("FDS ROM is too large");
    } else if (code == ERR_ROM_SIZE) {
        gConsPrintCX("ROM is too large");
    } else {
        gConsPrintCX("Unexcpected error");
    }


    gSetPal(warning ? PAL_G3 : PAL_G1);
    gDrawHeader("", 0);
    gDrawFooter("", 1, 0);


    if (warning) {
        gSetY(G_BORDER_Y - 1);
        gConsPrintCX("WARNING");
    } else {
        gSetXY((G_SCREEN_W - 8) / 2, G_BORDER_Y);
        gAppendString("ERROR:");
        gAppendHex8(code);
    }


    gRepaint();
    sysJoyWait();

}

