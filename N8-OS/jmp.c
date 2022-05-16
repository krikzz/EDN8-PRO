
#include "everdrive.h"

u8 app_jmpSetup(u8 *path);
u8 app_jmpGetVal(u8 *game, u8 map_idx, u8 *val);

u8 jmpSetup(u8 *path) {

    u8 resp;
    u8 bank = REG_APP_BANK;
    REG_APP_BANK = APP_JMP;
    resp = app_jmpSetup(path);
    REG_APP_BANK = bank;
    return resp;
}

u8 jmpGetVal(u8 *game, u8 map_idx, u8 *val) {
    u8 resp;
    u8 bank = REG_APP_BANK;
    REG_APP_BANK = APP_JMP;
    resp = app_jmpGetVal(game, map_idx, val);
    REG_APP_BANK = bank;
    return resp;
}

u8 jmpGetSize(u8 map_idx) {

    if (map_idx == 105) {
        return 4;
    }

    return 0;
}

#pragma codeseg ("BNK07")

u8 jmpGetDefault(u16 map_idx);
u8 jmpOpen(u8 *game, u8 fmode);
void jmpGetPath(u8 *cfg_path, u8 *game_path);
void jmpDrawJumper(u8 jmp_num, u8 jmp_val, u8 selector, u8 x, u8 y);

u8 app_jmpSetup(u8 *path) {

    u8 resp;
    u8 selector = 0;
    u8 joy;
    u8 jmp_val, jmp_val_old;
    u8 jmp_num;
    RomInfo inf;
    u8 x, y;

    gCleanScreen();
    gRepaint();

    resp = getRomInfo(&inf, path);
    if (resp)return resp;

    jmp_num = jmpGetSize(inf.mapper);


    if (jmp_num == 0) {

        gSetY(G_SCREEN_H / 2);
        gConsPrintCX("Not supported for this game");
        gRepaint();
        sysJoyWait();
        return 0;
    }

    resp = jmpGetVal(path, inf.mapper, &jmp_val);
    if (resp)return resp;
    jmp_val_old = jmp_val;


    x = (G_SCREEN_W / 2) - jmp_num;
    y = G_SCREEN_H / 2;

    while (1) {

        jmpDrawJumper(jmp_num, jmp_val, selector, x, y);

        gRepaint();
        joy = sysJoyWait();

        if (joy == JOY_L) {
            selector = dec_mod(selector, jmp_num);
        }

        if (joy == JOY_R) {
            selector = inc_mod(selector, jmp_num);
        }


        if (joy == JOY_U) {
            jmp_val |= (1 << selector);
        }

        if (joy == JOY_D) {
            jmp_val &= ~(1 << selector);
        }

        if (joy == JOY_B) {
            break;
        }
    }


    if (jmp_val != jmp_val_old) {

        gCleanScreen();
        gRepaint();

        resp = jmpOpen(path, FA_OPEN_ALWAYS | FA_WRITE | FS_MAKEPATH);
        if (resp)return resp;
        resp = fileWrite(&jmp_val, 1);
        if (resp)return resp;
        resp = fileClose();

        if (resp)return resp;
    }

    return 0;
}

u8 app_jmpGetVal(u8 *game, u8 map_idx, u8 *val) {

    u8 resp;

    *val = jmpGetDefault(map_idx);

    resp = jmpOpen(game, FA_READ);
    if (resp == FAT_NO_FILE || resp == FAT_NO_PATH) {
        return 0;
    }
    if (resp)return resp;
    resp = fileRead(val, 1);
    if (resp)return resp;
    resp = fileClose();
    if (resp)return resp;

    return 0;
}

u8 jmpGetDefault(u16 map_idx) {

    if (map_idx == 105) {

        return 4;
    }

    return 0;
}

u8 jmpOpen(u8 *game, u8 fmode) {

    u8 *path;
    u8 resp;

    path = malloc(MAX_PATH_SIZE);
    jmpGetPath(path, game);
    resp = fileOpen(path, fmode);
    free(MAX_PATH_SIZE);

    return resp;
}

void jmpGetPath(u8 *cfg_path, u8 *game_path) {

    fatMakeSyncPath(cfg_path, PATH_GAMEDATA, game_path, 0);
    cfg_path = str_append(cfg_path, "/");
    str_append(cfg_path, PATH_GD_JUMPER);
}

void jmpDrawJumper(u8 jmp_num, u8 jmp_val, u8 selector, u8 x, u8 y) {

    u8 i;

    gSetPal(PAL_G1);
    gFillRect(131, x - 1, y - 1, jmp_num * 2 + 1, 3); //floor and roof

    gFillRect(133, x - 1, y - 1, 1, 1); //corn UL
    gFillRect(132, x - 1, y, 1, 1); //wall L
    gFillRect(135, x - 1, y + 1, 1, 1); //corn DL
    gFillRect(134, x - 1 + jmp_num * 2, y - 1, 1, 1); //corn UR
    gFillRect(132, x - 1 + jmp_num * 2, y, 1, 1); //wall R
    gFillRect(136, x - 1 + jmp_num * 2, y + 1, 1, 1); //corn DR

    gSetPal(PAL_B1);
    gSetXY(x, y + 2);
    for (i = 0; i < jmp_num; i++) {
        gAppendChar('1' + i);
        gAppendChar(' ');
    }

    gSetXY(x + jmp_num * 2 + 1, y - 2);
    gConsPrint("ON");
    gConsPrint("");
    gConsPrint("OFF");

    gSetXY(x, y);

    for (i = 0; i < jmp_num; i++) {

        if (i != 0) {
            gAppendChar(' ');
        }
        gSetPal(selector == i ? PAL_G3 : PAL_G1);
        gAppendChar(((jmp_val >> i) & 1) ? 24 : 25);

    }
}