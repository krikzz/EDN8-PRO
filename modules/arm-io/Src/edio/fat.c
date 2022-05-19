
#include <string.h>

#include "edio.h"

typedef struct {
    u8 path[MAX_STR_LEN + 1];
    u16 sort_idx[MAX_SORT_FILES];
    u16 dir_size;
    u8 sorted;
} DirLoader;



FATFS fs;
DIR dir_rdr;
FIL file_io;
DirLoader dir_loader;


void fatTxFileInfo(FILINFO *inf, u16 max_name_len);
void fatFrameOrder(u16 *sort_tbl, u16 *order_tbl, u16 len);
u8 fatCmpRecs(u8 *str1, u8 *str2);
void fatSortRecs(u16 len, u8 **sort_names, u16 *order);

u8 fatDirLoadSort();
u8 fatDirLoad();
u8 fatGetRecs(u16 start_idx, u16 amount, u16 max_name_len);
u8 fatGetRecsSorted(u16 start_idx, u16 amount, u16 max_name_len);
u8 fatReadDir(DIR *dp, FILINFO *inf);
u8 fileCopy(u8 *src, u8 *dst, u8 dst_mode);

u8 fatInit() {

    u8 resp;
    memset(&fs, 0, sizeof (fs));
    memset(&dir_rdr, 0, sizeof (dir_rdr));
    memset(&file_io, 0, sizeof (file_io));
    memset(&dir_loader, 0, sizeof (dir_loader));

    resp = f_mount(&fs, "", 1);
    return resp;
}

//****************************************************************************** commands
//****************************************************************************** 
//****************************************************************************** 

u8 cmd_dirOpen() {

    u8 resp;
    u8 path[MAX_STR_LEN + 1];

    resp = strRX(path, MAX_STR_LEN);
    if (resp)return resp;

    return f_opendir(&dir_rdr, (TCHAR *) path);
}

u8 cmd_dirRead() {

    u8 resp;
    u16 max_len;
    FILINFO inf;

    linkRX(&max_len, 2);

    resp = fatReadDir(&dir_rdr, &inf);
    linkTX(&resp, 1);
    if (resp)return resp;

    fatTxFileInfo(&inf, max_len);

    return 0;
}

u8 cmd_dirLoad() {

    u8 resp;


    linkRX(&dir_loader.sorted, 1);


    resp = strRX(dir_loader.path, MAX_STR_LEN);
    if (resp)return resp;

    dir_loader.dir_size = 0;


    if (dir_loader.sorted) {
        resp = fatDirLoadSort();
    } else {
        resp = fatDirLoad();
    }
    if (resp)return resp;


    return 0;
}

void cmd_dirGetSize() {

    linkTX(&dir_loader.dir_size, 2);
}

void cmd_dirGetPath() {

    strTX(dir_loader.path, MAX_STR_LEN);
}

u8 cmd_dirGetRecs() {

    u8 resp;
    u16 start_idx;
    u16 amount;
    u16 max_name_len;

    linkRX(&start_idx, 2);
    linkRX(&amount, 2);
    linkRX(&max_name_len, 2);


    if (start_idx + amount > dir_loader.dir_size) {
        resp = ERR_OUT_OF_DIR;
        linkTX(&resp, 1);
        return resp;
    }

    if (dir_loader.sorted) {
        resp = fatGetRecsSorted(start_idx, amount, max_name_len);
    } else {
        resp = fatGetRecs(start_idx, amount, max_name_len);
    }


    if (resp) {
        linkTX(&resp, 1);
        return resp;
    }



    return 0;
}

u8 cmd_dirMake() {

    u8 resp;
    u8 path[MAX_STR_LEN + 1];

    resp = strRX(path, MAX_STR_LEN);
    if (resp)return resp;

    return f_mkdir((TCHAR *) path);
}

u8 cmd_fileOpen() {

    u8 resp;
    u8 mode;
    u8 path[MAX_STR_LEN + 1];

    linkRX(&mode, 1);
    resp = strRX(path, MAX_STR_LEN);
    if (resp)return resp;

    return fileOpen(path, mode);
}

u8 cmd_fileRead() {

    u8 buff[4096];
    u32 len;
    u32 block;
    u32 readed;
    u8 resp;

    linkRX(&len, 4);

    while (len) {

        block = sizeof (buff);
        if (block > len)block = len;
        len -= block;

        resp = f_read(&file_io, buff, block, (UINT *) & readed);
        linkTX(&resp, 1);
        if (resp)return resp;
        linkTX(buff, block);

    }


    return 0;
}

u8 cmd_fileRead_mem() {

    u32 addr;
    u32 len;
    u8 ack;

    linkRX(&addr, 4);
    linkRX(&len, 4);
    linkRX(&ack, 1); //exec byte

    return fileRead_mem(addr, len);
}

u8 cmd_fileWrite() {

    u8 buff[ACK_BLOCK_SIZE];
    u32 len;
    u32 block;
    u32 written;
    u8 resp = 0;

    linkRX(&len, 4);

    while (len) {

        block = sizeof (buff);
        if (block > len)block = len;
        len -= block;

        if (resp) {
            linkTX(&resp, 1);
            if (resp)return resp;
        }

        linkRX_ack(buff, block);
        resp = f_write(&file_io, buff, block, (UINT *) & written);

    }

    return resp;
}

u8 cmd_fileWrite_mem() {

    u8 buff[16384];
    u32 addr;
    u32 len;
    u32 block;
    u32 written = 0;
    u8 resp = 0;

    linkRX(&addr, 4);
    linkRX(&len, 4);
    linkRX(buff, 1); //exec byte

    memOpenRead(addr);

    while (len) {

        block = sizeof (buff);
        if (block > len)block = len;
        len -= block;

        memRead(buff, block);

        resp = f_write(&file_io, buff, block, (UINT *) & written);
        if (resp) break;

    }

    memCloseRW();

    return resp;
}

u8 cmd_fileClose() {

    return f_close(&file_io);
}

u8 cmd_fileSetPtr() {

    u32 len;
    linkRX(&len, 4);
    return f_lseek(&file_io, len);
}

u8 cmd_fileInfo() {

    u8 path[MAX_STR_LEN + 1];
    FILINFO inf;
    u8 resp;

    resp = strRX(path, MAX_STR_LEN);
    if (resp)return resp;
    resp = f_stat((TCHAR *) path, &inf);

    linkTX(&resp, 1);
    if (resp)return resp;

    fatTxFileInfo(&inf, 0);

    return 0;
}

u8 cmd_fileCRC() {

    u32 len, block, crc, readed;
    u8 resp = 0;
    u8 buff[16384];

    linkRX(&len, 4);
    linkRX(&crc, 4);

    while (len) {

        block = sizeof (buff);
        if (block > len)block = len;
        len -= block;
        resp = f_read(&file_io, buff, block, (UINT *) & readed);
        if (resp)break;
        crc = crc32(crc, buff, block);
    }

    linkTX(&resp, 1);
    linkTX(&crc, 4);

    return resp;
}

void cmd_fileAvailable() {

    u64 avb = file_io.obj.objsize - file_io.fptr;
    linkTX(&avb, 8);
}

u8 cmd_fileCopy() {

    u8 resp;
    u8 dst_mode;
    u8 src[MAX_STR_LEN + 1];
    u8 dst[MAX_STR_LEN + 1];

    linkRX(&dst_mode, 1); //dst mode
    resp = strRX(src, MAX_STR_LEN);
    if (resp)return resp;
    resp = strRX(dst, MAX_STR_LEN);
    if (resp)return resp;

    resp = fileCopy(src, dst, dst_mode);
    if (resp)return resp;

    return 0;
}

u8 cmd_fileMove() {

    u8 resp;
    u8 dst_mode;
    u8 src[MAX_STR_LEN + 1];
    u8 dst[MAX_STR_LEN + 1];

    linkRX(&dst_mode, 1); //dst mode
    resp = strRX(src, MAX_STR_LEN);
    if (resp)return resp;
    resp = strRX(dst, MAX_STR_LEN);
    if (resp)return resp;

    resp = fileCopy(src, dst, dst_mode);
    if (resp)return resp;

    resp = f_unlink((TCHAR *) src);
    if (resp)return resp;

    return 0;
}

u8 cmd_delRecord() {

    u8 resp;
    u8 path[MAX_STR_LEN + 1];

    resp = strRX(path, MAX_STR_LEN);
    if (resp)return resp;

    return f_unlink((TCHAR *) path);
}

//****************************************************************************** disk browsing
//****************************************************************************** 
//****************************************************************************** 

void fatTxFileInfo(FILINFO *inf, u16 max_name_len) {


    linkTX(&inf->fsize, 4);
    linkTX(&inf->fdate, 2);
    linkTX(&inf->ftime, 2);
    linkTX(&inf->fattrib, 1);

    strTX((u8 *) inf->fname, max_name_len);

}

u8 fatDirLoad() {

    FILINFO inf;
    DIR dir;
    u8 resp;

    //f_closedir(&dir);
    resp = f_opendir(&dir, (TCHAR *) dir_loader.path);
    if (resp)return resp;

    while (1) {
        resp = fatReadDir(&dir, &inf);
        if (resp)return resp;

        if (inf.fname[0] == 0)break;
        dir_loader.dir_size++;
    }

    return 0;
}

u8 fatDirLoadSort() {

    FILINFO file_inf;
    u8 str_buff[(MAX_SORT_NAME + 2) * MAX_SORT_FILES];
    u8 * rec_names[MAX_SORT_FILES];
    u8 resp;
    DIR dir;

    for (int i = 0; i < MAX_SORT_FILES; i++) {
        rec_names[i] = &str_buff[i * (MAX_SORT_NAME + 2)];
    }

    //f_closedir(&dir);
    resp = f_opendir(&dir, (TCHAR *) dir_loader.path);
    if (resp)return resp;

    for (int i = 0; i < MAX_SORT_FILES; i++) {

        resp = fatReadDir(&dir, &file_inf);
        if (resp)return resp;
        if (file_inf.fname[0] == 0)break;

        str_copy((u8 *) file_inf.fname, &rec_names[dir_loader.dir_size][1], MAX_SORT_NAME);
        rec_names[dir_loader.dir_size][0] = file_inf.fattrib & AM_DIR ? '0' : '1';
        str_to_upcase_ml(rec_names[dir_loader.dir_size], MAX_SORT_NAME + 1);

        dir_loader.dir_size++;

    }

    fatSortRecs(dir_loader.dir_size, rec_names, dir_loader.sort_idx);

    return 0;
}

u8 fatGetRecs(u16 start_idx, u16 amount, u16 max_name_len) {


    FILINFO inf;
    u8 resp;
    DIR dir;


    resp = f_opendir(&dir, (TCHAR *) dir_loader.path);
    if (resp)return resp;


    while (start_idx--) {

        resp = fatReadDir(&dir, &inf);
        if (resp)return resp;
    }


    while (amount--) {
        resp = fatReadDir(&dir, &inf);
        if (resp)return resp;

        linkTX(&resp, 1);
        fatTxFileInfo(&inf, max_name_len);
    }

    return 0;
}

u8 fatGetRecsSorted(u16 start_idx, u16 amount, u16 max_name_len) {

    FILINFO inf[MAX_SORT_PAGE]; //crashes with O2 optimization
    u16 order_tbl[MAX_SORT_PAGE];
    DIR dir;
    u8 resp;


    if (start_idx + amount > MAX_SORT_FILES)return ERR_OUT_OF_DIR;
    if (amount > MAX_SORT_PAGE)return ERR_OUT_OF_PAGE;

    fatFrameOrder(&dir_loader.sort_idx[start_idx], order_tbl, amount);


    //f_closedir(&dir);
    resp = f_opendir(&dir, (TCHAR *) dir_loader.path);
    if (resp)return resp;


    for (int i = 0, u = 0; i < amount; u++) {

        u16 page_idx = order_tbl[i];
        u16 rec_idx = dir_loader.sort_idx[page_idx + start_idx];

        resp = fatReadDir(&dir, &inf[page_idx]);
        if (resp)return resp;
        if (inf[page_idx].fname[0] == 0)return ERR_OUT_OF_DIR;

        if (rec_idx == u)i++;
    }


    resp = 0;
    for (int i = 0; i < amount; i++) {

        linkTX(&resp, 1);
        fatTxFileInfo(&inf[i], max_name_len);
    }

    return 0;
}

void fatFrameOrder(u16 *sort_tbl, u16 *order_tbl, u16 len) {

    u16 j, d, i;
    u32 t;

    for (int i = 0; i < len; i++) {
        order_tbl[i] = i;
    }

    for (d = len / 2; d >= 1; d /= 2) {
        for (i = d; i < len; i++) {

            for (j = i; j >= d; j -= d) {

                if (sort_tbl[order_tbl[j]] > sort_tbl[order_tbl[j - d]])break;

                t = order_tbl[j];
                order_tbl[j] = order_tbl[j - d];
                order_tbl[j - d] = t;

            }
        }
    }
}

u8 fatCmpRecs(u8 *str1, u8 *str2) {


    u8 val1;
    u8 val2;

    if (*str1 != *str2) {
        if (*str1 < *str2)return 1;
        return 2;
    }
    str1++;
    str2++;


    while (1) {

        val1 = *str1++;
        val2 = *str2++;

        if (val1 == val2) {
            if (val1 == 0)return 0;
            continue;
        }

        if (val1 != val2) {
            if (val1 < val2)return 1;

            return 2;
        }

    }

}

void fatSortRecs(u16 len, u8 **sort_names, u16 *order) {

    u16 j, d, i;
    u32 t;
    u8 *st;

    for (int i = 0; i < len; i++)order[i] = i;

    for (d = len / 2; d >= 1; d /= 2) {
        for (i = d; i < len; i++) {

            for (j = i; j >= d; j -= d) {

                if (fatCmpRecs(sort_names[j], sort_names[j - d]) != 1)break;
                t = order[j];
                order[j] = order[j - d];
                order[j - d] = t;

                st = sort_names[j];
                sort_names[j] = sort_names[j - d];
                sort_names[j - d] = st;
            }
        }
    }
}

u8 fileRead_mem(u32 addr, u32 len) {

    u8 buff[16384];
    u32 bank = 0;
    u32 block;
    u32 readed = 0;
    u8 resp = 0;

    memOpenWrite(addr);

    while (len) {

        block = sizeof (buff) / 2;
        if (block > len)block = len;
        len -= block;

        resp = f_read(&file_io, &buff[bank * sizeof (buff) / 2], block, (UINT *) & readed);
        if (resp) break;

        //memWriteDMA(&buff[bank * sizeof (buff) / 2], block);
        memWriteDMA(&buff[bank * sizeof (buff) / 2], block);

        bank ^= 1;
    }

    memCloseRW();

    return resp;
}

u8 fileOpen(u8 *path, u8 mode) {

    return f_open(&file_io, (TCHAR *) path, mode);
}

u8 fileClose() {
    return f_close(&file_io);
}

u8 fileCopy(u8 *src, u8 *dst, u8 dst_mode) {

    u8 resp, ra, rb;
    u8 buff[16384];
    FIL fsrc = {0};
    FIL fdst = {0};
    FILINFO inf;
    u64 size;
    u32 block, rw;

    resp = f_open(&fsrc, (TCHAR *) src, FA_READ);
    if (resp)return resp;

    resp = f_open(&fdst, (TCHAR *) dst, dst_mode);
    if (resp) {
        f_close(&fsrc);
        return resp;
    }

    size = fsrc.obj.objsize - fsrc.fptr;

    while (size) {

        block = sizeof (buff);
        if (block > size) {
            block = size;
        }

        resp = f_read(&fsrc, buff, block, (UINT *) & rw);
        if (resp)break;

        resp = f_write(&fdst, buff, block, (UINT *) & rw);
        if (resp)break;

        size -= block;
    }

    ra = f_close(&fsrc);
    rb = f_close(&fdst);

    if (resp)return resp;
    if (ra)return ra;
    if (rb)return rb;

    resp = f_stat((TCHAR *) src, &inf);
    if (resp)return resp;

    resp = f_utime((TCHAR *) dst, &inf);
    if (resp)return resp;

    return 0;
}

u8 fatReadDir(DIR *dp, FILINFO *inf) {

    u8 resp;

    do {

        resp = f_readdir(dp, inf);
        if (resp)return resp;
        if (inf->fname[0] == 0)return 0;

    } while (inf->fname[0] == '.' || (inf->fattrib & AM_HID));

    return 0;
}

u32 fatGetIme(void) {

    u32 dt = 0;
    RtcTime rtc;

    rtcGetTime(&rtc);
    rtc.yar = hexToDex(rtc.yar);
    rtc.mon = hexToDex(rtc.mon);
    rtc.dom = hexToDex(rtc.dom);
    rtc.hur = hexToDex(rtc.hur);
    rtc.min = hexToDex(rtc.min);
    rtc.sec = hexToDex(rtc.sec);

    dt |= (rtc.yar + 20) << 25;
    dt |= rtc.mon << 21;
    dt |= rtc.dom << 16;
    dt |= rtc.hur << 11;
    dt |= rtc.min << 5;
    dt |= rtc.sec / 2;

    return dt;
}

