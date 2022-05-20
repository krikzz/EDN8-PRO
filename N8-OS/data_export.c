
#include "main.h"

u8 app_dataExport();

u8 dataExport() {

    u8 resp;
    u8 bank = REG_APP_BANK;

    if (registry->ss_export_done)return 0;

    REG_APP_BANK = APP_SSE;
    resp = app_dataExport();
    REG_APP_BANK = bank;
    if (resp)return resp;

    registry->ss_export_done = 1; //exporting check performs just once
    return edRegistrySave();
}

#pragma codeseg ("BNK05")

#define PATH_SAVE_DIR   "EDN8/SAVE"
#define PATH_SNAP_DIR   "EDN8/SNAP"
#define PATH_CHEATS     "EDN8/CHEATS"

#define EXP_TYPE_SST    0
#define EXP_TYPE_SRM    1
#define EXP_TYPE_TXT    2

u8 dataExpFolder(u8 *home, u8 *ext, u8 *src);
u8 dataExpFile(u8 *src, u8 *ext);
u8 dataExpValid(FileInfo *inf, u8 *ext);
u8 dataExpSeek(u8 *home, u8 *ext, u8 *valid);
void dataExpMakePath(u8 *src, u8 *dst);
u8 dataExpSST(u8 *src, u8 *dst);
u8 dataExpSRM(u8 *src, u8 *dst);
u8 dataExpTXT(u8 *src, u8 *dst);
u8 dataExpLock(u8 *target);
u8 dataExpIsLocked(u8 *target);
u8 dataExpOpenLock(u8 *target, u8 fmode);

u8 app_dataExport() {

    u8 resp;
    u8 valid_sst, valid_srm, valid_txt;
    ListBox box = {0};
    static u8 * text[] = {"Game data exporting...", "It may take few minutes", 0};

    resp = dataExpSeek(PATH_SNAP_DIR, "sav", &valid_sst);
    if (resp)return resp;
    resp = dataExpSeek(PATH_SAVE_DIR, "srm", &valid_srm);
    if (resp)return resp;
    resp = dataExpSeek(PATH_CHEATS, "txt", &valid_txt);
    if (resp)return resp;
    if (valid_sst == 0 && valid_srm == 0 && valid_txt == 0)return 0; //return if nothing to export

    gCleanScreen();
    resp = guiConfirmBox("Export old save files?", 1);
    if (resp == 0)return 0;

    gCleanScreen();
    box.hdr = "";
    box.items = text;
    box.selector = SEL_JSKIP;
    guiDrawListBox(&box);


    if (valid_sst) {
        resp = dataExpFolder(PATH_SNAP_DIR, "sav", 0);
        if (resp)return resp;

    }

    if (valid_srm) {
        resp = dataExpFolder(PATH_SAVE_DIR, "srm", 0);
        if (resp)return resp;
    }

    if (valid_txt) {
        resp = dataExpFolder(PATH_CHEATS, "txt", 0);
        if (resp)return resp;
    }

    return 0;
}

u8 dataExpLock(u8 *target) {

    u8 resp;
    resp = dataExpOpenLock(target, FA_WRITE | FA_CREATE_ALWAYS);
    if (resp)return resp;
    resp = fileWrite(&resp, 1);
    if (resp)return resp;
    resp = fileClose();
    if (resp)return resp;

    return 0;
}

u8 dataExpIsLocked(u8 *target) {

    u8 resp;
    
    resp = dataExpOpenLock(target, FA_READ);
    if (resp == 0) {
        fileClose();
        return 1; //locked
    }

    return 0;
}

u8 dataExpOpenLock(u8 *target, u8 fmode) {

    u8 path[48];

    str_copy(target, path);
    str_append(path, "/exported");

    return fileOpen(path, fmode);
}

u8 dataExpFolder(u8 *home, u8 *ext, u8 *src) {

    u16 i;
    u8 resp;
    u16 dir_size;
    FileInfo inf = {0};

    if (src == 0) {
        src = malloc(MAX_PATH_SIZE + 1);
        resp = dataExpFolder(home, ext, src);
        free(MAX_PATH_SIZE + 1);
        return resp;
    }

    src[0] = 0;
    inf.file_name = str_append(src, home);
    inf.file_name = str_append(inf.file_name, "/");

    resp = bi_cmd_dir_load(home, 0);
    if (resp)return resp;
    bi_cmd_dir_get_size(&dir_size);

    for (i = 0; i < dir_size; i++) {

        bi_cmd_dir_get_recs(i, 1, MAX_NAME_SIZE + 1);
        resp = bi_rx_next_rec(&inf);
        if (resp)return resp;

        if (!dataExpValid(&inf, ext))continue;

        resp = dataExpFile(src, ext);
        if (resp)return resp;
    }

    resp = dataExpLock(home);
    if (resp)return resp;

    return 0;
}

u8 dataExpFile(u8 *src, u8 *ext) {

    if (str_cmp_ncase(ext, "sav")) {
        return dataExpSST(src, 0);
    } else if (str_cmp_ncase(ext, "srm")) {
        return dataExpSRM(src, 0);
    } else if (str_cmp_ncase(ext, "txt")) {
        return dataExpTXT(src, 0);
    }

    return 0;
}

u8 dataExpValid(FileInfo *inf, u8 *ext) {//valid ss file check

    u16 dot_ptr;
    u8 is_sst;

    if (inf->is_dir) {
        return 0; //skip dirs
    }

    dot_ptr = str_last_index_of(inf->file_name, '.');

    if (dot_ptr < 3) {
        return 0; //name is too short
    }

    is_sst = str_cmp_ncase(ext, "sav");

    if (is_sst && inf->file_name[dot_ptr - 3] != '.') {
        return 0; //incorrect file name 
    }

    if (str_extension(ext, inf->file_name) == 0) {
        return 0;
    }

    return 1;
}

u8 dataExpSeek(u8 *home, u8 *ext, u8 *valid) {//valid ss files seek

    u16 i;
    u8 resp;
    u16 dir_size;
    FileInfo inf = {0};
    u8 fname[MAX_NAME_SIZE + 1];

    *valid = 0;
    inf.file_name = fname;

    if (dataExpIsLocked(home)) {
        return 0;
    }

    resp = bi_cmd_dir_load(home, 0);
    if (resp == FAT_NO_PATH)return 0;
    if (resp)return resp;
    bi_cmd_dir_get_size(&dir_size);

    for (i = 0; i < dir_size; i++) {

        bi_cmd_dir_get_recs(i, 1, MAX_NAME_SIZE + 1);
        resp = bi_rx_next_rec(&inf);
        if (resp)return resp;

        if (dataExpValid(&inf, ext)) {
            *valid = 1;
            return 0;
        }
    }

    return 0;
}

void dataExpMakePath(u8 *src, u8 *dst) {

    u16 dot_ptr;
    fatMakeSyncPath(dst, PATH_GAMEDATA, src, 0);
    dot_ptr = str_last_index_of(dst, '.');
    dst[dot_ptr] = 0;
    str_append(dst, ".nes/");
}

u8 dataExpSST(u8 *src, u8 *dst) {

    //u16 i;
    u8 *aptr;
    u8 resp;
    u16 dot_ptr;
    u8 slot[2];

    if (dst == 0) {
        dst = malloc(MAX_PATH_SIZE + 1);
        resp = dataExpSST(src, dst);
        free(MAX_PATH_SIZE + 1);
        return resp;
    }

    dataExpMakePath(src, dst);
    dot_ptr = str_last_index_of(dst, '.') - 2;
    aptr = &dst[dot_ptr];
    slot[0] = aptr[0];
    slot[1] = aptr[1];
    *aptr = 0;
    aptr = str_append(dst, "nes/");
    *aptr++ = slot[0];
    *aptr++ = slot[1];
    *aptr++ = 0;
    aptr = str_append(dst, ".sav");

    resp = fileCopy(src, dst, FA_CREATE_ALWAYS | FA_WRITE | FS_MAKEPATH);
    if (resp)return resp;
    return 0;
}

u8 dataExpSRM(u8 *src, u8 *dst) {

    u8 resp;

    if (dst == 0) {
        dst = malloc(MAX_PATH_SIZE + 1);
        resp = dataExpSRM(src, dst);
        free(MAX_PATH_SIZE + 1);
        return resp;
    }

    dataExpMakePath(src, dst);
    str_append(dst, PATH_GD_SRAM);

    resp = fileCopy(src, dst, FA_CREATE_ALWAYS | FA_WRITE | FS_MAKEPATH);
    if (resp)return resp;

    return 0;
}

u8 dataExpTXT(u8 *src, u8 *dst) {

    u8 resp;

    if (dst == 0) {
        dst = malloc(MAX_PATH_SIZE + 1);
        resp = dataExpTXT(src, dst);
        free(MAX_PATH_SIZE + 1);
        return resp;
    }

    dataExpMakePath(src, dst);
    str_append(dst, PATH_GD_CHEAT);

    /*
    gCleanScreen();
    gConsPrint("src: ");
    gConsPrint(src);
    gConsPrint("");
    gConsPrint("dst: ");
    gConsPrint(dst);
    gRepaint();
    sysJoyWait();*/

    resp = fileCopy(src, dst, FA_CREATE_ALWAYS | FA_WRITE | FS_MAKEPATH);
    if (resp)return resp;

    return 0;
}