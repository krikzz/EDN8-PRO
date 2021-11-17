
#include "everdrive.h"

u8 fileOpen(u8 *path, u8 mode) {
    return bi_cmd_file_open(path, mode);
}

u8 fileRead_mem(u32 dst, u32 len) {

    return bi_cmd_file_read_mem(dst, len);
}

u8 fileRead(void *dst, u32 len) {
    return bi_cmd_file_read(dst, len);
}

u8 fileWrite_mem(u32 src, u32 len) {

    return bi_cmd_file_write_mem(src, len);
}

u8 fileWrite(void *src, u32 len) {

    return bi_cmd_file_write((void *) src, len);
}

u8 fileClose() {
    return bi_cmd_file_close();
}

u8 fileCopy(u8 *src, u8 *dst) {

    u8 resp;
    u32 size;

    resp = fileOpen(src, FA_READ);
    if (resp)return resp;

    resp = bi_file_get_size(src, &size);
    if (resp)return resp;

    if (size > SIZE_FBUFF)return ERR_FBUFF_SIZE;

    resp = fileRead_mem(ADDR_FBUFF, size);
    if (resp)return resp;

    resp = fileClose();
    if (resp)return resp;

    resp = fileOpen(dst, FA_OPEN_ALWAYS | FA_WRITE);
    if (resp)return resp;

    resp = fileWrite_mem(ADDR_FBUFF, size);
    if (resp)return resp;

    resp = fileClose();
    if (resp)return resp;

    return 0;
}

u8 fileOpenSync(u8 *dirname, u8 *fname, u8 *ext, u8 mode) {

    u8 resp;
    u8 *path = malloc(MAX_PATH_SIZE + 1);

    fatMakeSyncPath(path, dirname, fname, ext);

    resp = fileOpen(path, mode);
    free(MAX_PATH_SIZE + 1);

    return resp;
}

void fatMakeSyncPath(u8 *path, u8 *dirname, u8 *fname, u8 *ext) {

    path[0] = 0;

    if (dirname != 0) {
        fname = str_extract_fname(fname);
    }

    if (dirname != 0) {
        path = str_append(path, dirname);
        path = str_append(path, "/");
    }
    str_append(path, fname);

    path = str_extract_ext(path);
    if (*path == 0) {
        *path++ = '.';
    }
    *path = 0;

    str_append(path, ext);

}

void fatAppenIdx(u8 *path, u8 idx) {

    u8 ext[8];

    path = str_extract_ext(path);
    str_copy(path, ext);

    if (*path == 0) {
        str_append(path, ".");
        str_append_hex8(path, idx);
        return;
    }

    *path = 0;
    path = str_append_hex8(path, idx);
    path = str_append(path, ".");
    str_append(path, ext);
}

u8 fileGetInfo(u8 *path, FileInfo *inf) {
    return bi_cmd_file_info(path, inf);
}
