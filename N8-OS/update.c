
#include "main.h"

u8 app_updateCheck();

u8 updateCheck() {

    u8 resp;
    u8 bank = REG_APP_BANK;
    REG_APP_BANK = APP_UPD;
    resp = app_updateCheck();
    REG_APP_BANK = bank;
    return resp;

}

#pragma codeseg ("BNK06")

u8 updLoadToFlash(u8 *path, u32 addr, u8 crc_check);

u8 app_updateCheck() {


    u8 resp;
    u32 crc;

    if (sys_inf->mcu.sw_ver == EDIO_REQ)return 0;

    gCleanScreen();
    gSetY(G_SCREEN_H / 2 - 3);
    gConsPrintCX("IO core update required");
    gConsPrintCX("");
    gConsPrintCX("Push A to begin");

    gRepaint();
    while (sysJoyWait() != JOY_A);

    gCleanScreen();
    gSetY(G_SCREEN_H / 2 - 1);
    gConsPrintCX("Update...");
    gRepaint();

    resp = updLoadToFlash(PATH_UPD_IOCORE, ADDR_FLA_ICOR, 0);
    if (resp)return resp;
    resp = fileOpen(PATH_UPD_IOCORE, FA_READ);
    if (resp)return resp;
    resp = fileSetPtr(4);
    if (resp)return resp;
    resp = fileRead(&crc, 4);
    if (resp)return resp;
    bi_cmd_upd_exec(ADDR_FLA_ICOR, crc);

    return 0;
}

u8 updLoadToFlash(u8 *path, u32 addr, u8 crc_check) {

    u8 resp;
    u32 crc_fla, crc_file, crc_calc;
    u32 size;
    u32 fsize;

    resp = fileSize(path, &fsize);
    if (resp)return resp;
    if (fsize > MAX_UPD_SIZE)return ERR_BAD_FILE;

    crc_calc = 0;
    resp = fileOpen(path, FA_READ);
    if (resp)return resp;
    resp = fileRead(&size, 4);
    if (resp)return resp;
    resp = fileRead(&crc_file, 4);
    if (resp)return resp;
    resp = bi_cmd_file_crc(fsize - 8, &crc_calc);
    if (resp)return resp;

    resp = fileClose();
    if (resp)return resp;

    if (crc_calc != crc_file && crc_check)return ERR_BAD_FILE;
    if (fsize - 8 != size)return ERR_BAD_FILE;

    bi_cmd_fla_rd(&crc_fla, addr + 4, 4);
    //if (crc_fla == crc_file)return 0;

    resp = fileOpen(path, FA_READ);
    if (resp)return resp;

    resp = bi_cmd_fla_wr_sdc(addr, fsize);
    if (resp)return resp;

    resp = fileClose();
    if (resp)return resp;

    return 0;
}