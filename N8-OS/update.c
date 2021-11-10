
#include "everdrive.h"

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
/*
    u8 resp;
    u32 crc;

    if (sys_inf->os_ver >= 0x0100)return 0;

    gCleanScreen();
    gSetY(G_SCREEN_H / 2 - 3);
    gConsPrintCX("Firmware update required");
    gConsPrintCX("");
    gConsPrintCX("Press any key to start update");
    
    gRepaint();
    sysJoyWait();

    gCleanScreen();
    gSetY(G_SCREEN_H / 2 - 1);
    gConsPrintCX("Processing...");
    gRepaint();

    resp = updLoadToFlash(PATH_UPD_IOCORE, ADDR_FLA_ICOR, 0);
    if (resp)return resp;
    resp = bi_cmd_file_open(PATH_UPD_IOCORE, FA_READ);
    if (resp)return resp;
    resp = bi_cmd_file_set_ptr(4);
    if (resp)return resp;
    resp = bi_cmd_file_read(&crc, 4);
    if (resp)return resp;
    bi_cmd_upd_exec(ADDR_FLA_ICOR, crc);*/

    return 0;
}

u8 updLoadToFlash(u8 *path, u32 addr, u8 crc_check) {

    u8 resp;
    u32 crc_fla, crc_file, crc_calc;
    u32 size;
    FileInfo inf;

    resp = bi_cmd_file_info(path, &inf);
    if (resp)return resp;
    if (inf.size > MAX_UPD_SIZE)return ERR_BAD_FILE;

    crc_calc = 0;
    resp = bi_cmd_file_open(path, FA_READ);
    if (resp)return resp;
    resp = bi_cmd_file_read(&size, 4);
    if (resp)return resp;
    resp = bi_cmd_file_read(&crc_file, 4);
    if (resp)return resp;
    resp = bi_cmd_file_crc(inf.size - 8, &crc_calc);
    if (resp)return resp;

    resp = bi_cmd_file_close();
    if (resp)return resp;

    if (crc_calc != crc_file && crc_check)return ERR_BAD_FILE;
    if (inf.size - 8 != size)return ERR_BAD_FILE;

    bi_cmd_fla_rd(&crc_fla, addr + 4, 4);
    //if (crc_fla == crc_file)return 0;

    resp = bi_cmd_file_open(path, FA_READ);
    if (resp)return resp;

    resp = bi_cmd_fla_wr_sdc(addr, inf.size);
    if (resp)return resp;

    resp = bi_cmd_file_close();
    if (resp)return resp;

    return 0;
}