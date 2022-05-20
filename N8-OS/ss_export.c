


#include "main.h"

u8 app_ssExport();

u8 ssExport() {


    u8 resp;
    u8 bank = REG_APP_BANK;

    if (registry->ss_export_done)return 0;

    REG_APP_BANK = APP_SSE;
    resp = app_ssExport();
    REG_APP_BANK = bank;
    if (resp)return resp;

    registry->ss_export_done = 1; //exporting check performs just once
    return edRegistrySave();
}

#pragma codeseg ("BNK05")

u8 ssExportFolder(u8 *home, u8 *ext, u8 *src);
u8 ssExportFile(u8 *src, u8 *dst);
u8 ssExportValid(FileInfo *inf, u8 *ext);
u8 ssExportSeek(u8 *home, u8 *ext, u8 *valid);
u8 ssExportBackup(u8 *src, u8 *home);

u8 app_ssExport() {

    u8 resp, valid;
    ListBox box = {0};
    static u8 * text[] = {"Save-state files exporting...", "It may take few minutes", 0};

    resp = ssExportSeek(PATH_SNAP_DIR, "sav", &valid);
    if (resp)return resp;
    if (valid == 0)return 0; //return if nothing to export

    gCleanScreen();
    resp = guiConfirmBox("Export old save-state files?", 1);
    if (resp == 0)return 0;

    gCleanScreen();
    box.hdr = "";
    box.items = text;
    box.selector = SEL_JSKIP;
    guiDrawListBox(&box);

    resp = ssExportFolder(PATH_SNAP_DIR, "sav", 0);
    if (resp)return resp;

    return 0;
}

u8 ssExportFolder(u8 *home, u8 *ext, u8 *src) {

    u16 i;
    u8 resp;
    u16 dir_size;
    FileInfo inf;

    if (src == 0) {
        src = malloc(MAX_PATH_SIZE + 1);
        resp = ssExportFolder(home, ext, src);
        free(MAX_PATH_SIZE + 1);
        return resp;
    }

    src[0] = 0;
    inf.file_name = str_append(src, home);
    inf.file_name = str_append(inf.file_name, "/");

    while (1) {

        u8 reload = 0;

        resp = bi_cmd_dir_load(home, 0);
        if (resp)return resp;
        bi_cmd_dir_get_size(&dir_size);

        for (i = 0; i < dir_size; i++) {

            bi_cmd_dir_get_recs(i, 1, MAX_NAME_SIZE + 1);
            resp = bi_rx_next_rec(&inf);
            if (resp)return resp;

            if (!ssExportValid(&inf, ext))continue;

            resp = ssExportFile(src, 0);
            if (resp)return resp;

            resp = fileDel(src);
            if (resp)return resp;
            reload = 1; //dir must be reloaded after file removing
            break;

        }

        if (!reload)break; //whole dir was scanned but nothing to export
    }


    return 0;
}

u8 ssExportValid(FileInfo *inf, u8 *ext) {//valid ss file check

    u16 dot_ptr;

    if (inf->is_dir)return 0; //skip dirs

    dot_ptr = str_last_index_of(inf->file_name, '.');
    if (dot_ptr < 3)return 0; //name is too short
    if (inf->file_name[dot_ptr - 3] != '.')return 0; //incorrect file name 
    if (str_extension(ext, inf->file_name) == 0)return 0;

    return 1;
}

u8 ssExportFile(u8 *src, u8 *dst) {

    u16 i;
    u8 *aptr;
    u8 resp;
    u16 dot_ptr;

    if (dst == 0) {
        dst = malloc(MAX_PATH_SIZE + 1);
        resp = ssExportFile(src, dst);
        free(MAX_PATH_SIZE + 1);
        return resp;
    }

    str_copy(src, dst);
    dot_ptr = str_last_index_of(dst, '.');
    if (dot_ptr < 3)return ERR_PATH_SIZE; //should be tested at ssExportValid level, but just in case

    dst[dot_ptr - 3] = 0;
    aptr = str_append(dst, "/");

    for (i = 0; i < 6; i++) {
        *aptr++ = src[dot_ptr - 2 + i];
    }
    *aptr++ = 0;

    resp = fileCopy(src, dst, FA_OPEN_ALWAYS | FA_WRITE | FS_MAKEPATH);
    if (resp)return resp;


    return 0;
}

u8 ssExportSeek(u8 *home, u8 *ext, u8 *valid) {//valid ss files seek

    u16 i;
    u8 resp;
    u16 dir_size;
    FileInfo inf;
    u8 fname[MAX_NAME_SIZE + 1];

    *valid = 0;
    inf.file_name = fname;

    resp = bi_cmd_dir_load(home, 0);
    if (resp == FAT_NO_PATH)return 0;
    if (resp)return resp;
    bi_cmd_dir_get_size(&dir_size);

    for (i = 0; i < dir_size; i++) {

        bi_cmd_dir_get_recs(i, 1, MAX_NAME_SIZE + 1);
        resp = bi_rx_next_rec(&inf);
        if (resp)return resp;

        if (ssExportValid(&inf, ext)) {
            *valid = 1;
            return 0;
        }
    }


    return 0;
}

