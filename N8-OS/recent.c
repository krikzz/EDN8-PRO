
#include "main.h"

u8 app_recentMenu();
u8 app_recentAdd(u8 *path);

u8 recentMenu() {

    u8 resp;
    u8 bank = REG_APP_BANK;
    REG_APP_BANK = APP_RP;
    resp = app_recentMenu();
    REG_APP_BANK = bank;
    return resp;
}

u8 recentAdd(u8 *path) {

    u8 resp;
    u8 bank = REG_APP_BANK;
    REG_APP_BANK = APP_RP;
    resp = app_recentAdd(path);
    REG_APP_BANK = bank;
    return resp;
}

#pragma codeseg ("BNK09")

typedef struct {
    u8 path[MAX_PATH_SIZE];
} RecentSlot;

typedef struct {
    RecentSlot slot[MAX_RECENT];
} Recent;

u8 recentLoad(Recent *recent, u8 shift);
u8 recentStart(u8 selector);

#define RECENT_RAM_SIZE 6144
#define RECENT_RAM      (APP_ADDR + (APP_SIZE - RECENT_RAM_SIZE))

#if (MAX_RECENT * MAX_PATH_SIZE) > RECENT_RAM_SIZE
#error Recently playd buffer out of memory
#endif

u8 app_recentMenu() {

    Recent *recent = (Recent *) RECENT_RAM;
    u8 resp;
    u8 i;
    u8 joy;
    u8 selector = 0;
    u8 null_slot[MAX_STR_LEN + 1];
    u8 *file_name;


    gCleanScreen();
    gRepaint();

    resp = recentLoad(recent, 0);
    if (resp)return resp;

    mem_set(null_slot, '.', MAX_STR_LEN);
    null_slot[MAX_STR_LEN] = 0;

    while (1) {

        gCleanScreen();
        gSetPal(PAL_G2);
        gDrawHeader("Recently Played", G_CENTER);
        file_name = str_extract_fname(recent->slot[selector].path);
        gDrawFooter(file_name, 2, G_LEFT);

        gSetY((G_SCREEN_H - MAX_RECENT) / 2 - 2);

        for (i = 0; i < MAX_RECENT; i++) {

            file_name = str_extract_fname(recent->slot[i].path);
            gSetPal(selector == i ? PAL_G2 : PAL_B1);

            if (file_name[0] == 0) {
                gConsPrintCX(null_slot);
            } else {
                gConsPrintCX_ML(file_name, MAX_STR_LEN);
            }

        }

        gRepaint();
        joy = sysJoyWait();
        if (joy == JOY_B)return 0;

        if (joy == JOY_U) {
            selector = dec_mod(selector, MAX_RECENT);
        }

        if (joy == JOY_D) {
            selector = inc_mod(selector, MAX_RECENT);
        }

        if (joy == JOY_A) {

            resp = recentStart(selector);
            if (resp)return resp;
        }

    }

    return 0;
}

u8 app_recentAdd(u8 *path) {

    u8 resp;
    Recent *recent = (Recent *) RECENT_RAM;

    resp = recentLoad(recent, 1);
    if (resp)return resp;

    mem_set(recent->slot[0].path, 0, MAX_PATH_SIZE);
    str_copy(path, recent->slot[0].path);

    resp = fileOpen(PATH_RECENT, FA_WRITE | FA_OPEN_ALWAYS);
    if (resp)return resp;

    resp = fileWrite(recent, sizeof (Recent));
    if (resp)return resp;

    resp = fileClose();
    if (resp)return resp;

    return 0;
}

u8 recentLoad(Recent *recent, u8 shift) {

    u8 resp;
    u32 size;
    u8 i;

    for (i = 0; i < MAX_RECENT; i++) {
        recent->slot[i].path[0] = 0;
    }

    //mem_set(recent, 0, sizeof (Recent));

    resp = fileSize(PATH_RECENT, &size);
    if (resp == FAT_NO_FILE)return 0;

    size = min(size, sizeof (Recent));

    if (shift && size < sizeof (RecentSlot))return 0;

    if (shift) {

        recent = (Recent *) & recent->slot[1];
        size -= sizeof (RecentSlot);
    }

    resp = fileOpen(PATH_RECENT, FA_READ);
    if (resp)return resp;

    resp = fileRead(recent, size);
    if (resp)return resp;

    resp = fileClose();
    if (resp)return resp;

    return 0;
}

u8 recentStart(u8 selector) {

    Recent *recent = (Recent *) RECENT_RAM;
    u8 resp;
    u8 *name_buff;

    if (recent->slot[selector].path[0] == 0) {
        return 0;
    }

    name_buff = malloc(MAX_PATH_SIZE);
    str_copy(recent->slot[selector].path, name_buff);
    resp = edSelectGame(name_buff, 0);
    free(MAX_PATH_SIZE);
    if (resp)return resp;
    return edStartGame(0);

    return 0;
}