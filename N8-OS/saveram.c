
#include "main.h"



u32 savGetUsedMemory(u32 addr, u32 max_size);
u32 srmCalcFdsCrc(u32 addr, u32 len);
void srmGetPathSS(u8 *path, u8 bank);
void srmGetPathSRM(u8 *path);

u8 srmBackup() {

    u8 *path;
    u8 resp;
    u32 srm_size;

    if (registry->cur_game.path[0] == 0)return 0;
    if (registry->cur_game.rom_inf.bat_ram == 0)return 0;
    if (registry->cur_game.rom_inf.rom_type == ROM_TYPE_FDS)return 0;

    srm_size = savGetUsedMemory(ADDR_SRM, SIZE_SRM_GAME);
    if (srm_size == 0)return 0;

    path = malloc(MAX_PATH_SIZE);
    //str_make_sync_name(registery->cur_game.path, path, PATH_SAVE_DIR, "srm", SYNC_IDX_OFF);
    //fatMakeSyncPath(path, PATH_SAVE_DIR, registry->cur_game.path, "srm");
    srmGetPathSRM(path);
    resp = srmMemToFile(path, ADDR_SRM, srm_size);
    free(MAX_PATH_SIZE);

    return resp;
}

u8 srmRestore() {

    u8 resp;
    u8 *path;
    if (registry->cur_game.rom_inf.rom_type == ROM_TYPE_FDS)return 0;

    bi_cmd_mem_set(RAM_NULL, ADDR_SRM, SIZE_SRM_GAME);

    path = malloc(MAX_PATH_SIZE);
    //str_make_sync_name(registery->cur_game.path, path, PATH_SAVE_DIR, "srm", SYNC_IDX_OFF);
    //fatMakeSyncPath(path, PATH_SAVE_DIR, registry->cur_game.path, "srm");
    srmGetPathSRM(path);
    resp = srmFileToMem(path, ADDR_SRM, SIZE_SRM_GAME);
    free(MAX_PATH_SIZE);

    if (resp == FAT_NO_FILE || resp == FAT_NO_PATH)resp = 0;

    return resp;
}

void srmGetPathSRM(u8 *path) {

    fatMakeSyncPath(path, PATH_GAMEDATA, registry->cur_game.path, 0);
    path = str_append(path, "/");
    str_append(path, PATH_GD_SRAM);
}

u8 srmBackupSS(u8 bank) {

    u8 resp;
    u8 *path;

    if (registry->cur_game.path[0] == 0)return 0;

    path = malloc(MAX_PATH_SIZE);
    srmGetPathSS(path, bank);
    resp = fileOpen(path, FA_OPEN_ALWAYS | FA_WRITE | FS_MAKEPATH);
    free(MAX_PATH_SIZE);
    if (resp)return resp;

    resp = fileWrite_mem(ADDR_SST_HW, SIZE_SST_HW); //internal system memory and hardware registers
    if (resp)return resp;

    if (registry->cur_game.rom_inf.rom_type == ROM_TYPE_FDS) {
        resp = fileWrite_mem(ADDR_SST_FDS, 0x8000); //fds work ram 32K
    } else {
        resp = fileWrite_mem(ADDR_SRM, SIZE_SST_ERAM); //extended memory (on board ram)
    }
    if (resp)return resp;

    resp = fileClose();
    if (resp)return resp;

    return 0;
}

u8 srmRestoreSS(u8 bank) {

    u8 resp;
    u8 *path;

    path = malloc(MAX_PATH_SIZE);
    srmGetPathSS(path, bank);
    //resp = srmFileToMem(path, ADDR_SST, SIZE_SST);
    resp = fileOpen(path, FA_READ);
    free(MAX_PATH_SIZE);
    if (resp == FAT_NO_FILE || resp == FAT_NO_PATH)return 0;
    if (resp)return resp;

    resp = fileRead_mem(ADDR_SST_HW, SIZE_SST_HW); //internal system memory and hardware registers
    if (resp)return resp;

    if (registry->cur_game.rom_inf.rom_type == ROM_TYPE_FDS) {
        resp = fileRead_mem(ADDR_SST_FDS, 0x8000); //fds work ram 32K
    } else {
        resp = fileRead_mem(ADDR_SRM, SIZE_SST_ERAM); //extended memory (on board ram)
    }
    if (resp)return resp;

    resp = fileClose();
    if (resp)return resp;

    return 0;
}

u8 srmSSrpoint(u8 bank) {

    u8 *src, *dst;
    u8 resp;

    if (bank == 0x99)return 0;

    src = malloc(MAX_PATH_SIZE);
    dst = malloc(MAX_PATH_SIZE);

    srmGetPathSS(src, bank);
    srmGetPathSS(dst, 0x99);

    resp = fileCopy(src, dst, FA_OPEN_ALWAYS | FA_WRITE);
    free(MAX_PATH_SIZE * 2);
    if (resp == FAT_NO_FILE || resp == FAT_NO_PATH)return 0;
    if (resp)return resp;

    return 0;
}

u8 srmGetInfoSS(FileInfo *inf, u8 bank) {

    u8 *path;
    u8 resp;

    path = malloc(MAX_PATH_SIZE);
    srmGetPathSS(path, bank);
    resp = fileGetInfo(path, inf);
    free(MAX_PATH_SIZE);

    return resp;
}

void srmGetPathSS(u8 *path, u8 bank) {

    //fatMakeSyncPath(path, PATH_SNAP_DIR, registery->cur_game.path, "sav");
    //fatAppenIdx(path, bank);

    fatMakeSyncPath(path, PATH_GAMEDATA, registry->cur_game.path, 0);
    //str_trim(path);
    path = str_append(path, "/");
    path = str_append_hex8(path, bank);
    str_append(path, ".sav");
}

u8 srmFileToMem(u8 *path, u32 addr, u32 max_size) {

    u8 resp;
    u32 size;

    //resp = fileSize(path, &size);
    //if (resp)return resp;

    resp = fileOpen(path, FA_READ);
    if (resp)return resp;

    size = fileAvailable();

    size = min(size, max_size);

    resp = fileRead_mem(addr, size);
    if (resp)return resp;

    resp = fileClose();
    if (resp)return resp;

    return 0;
}

u8 srmMemToFile(u8 *path, u32 addr, u32 len) {

    u8 resp;

    resp = fileOpen(path, FA_OPEN_ALWAYS | FA_WRITE | FS_MAKEPATH);
    if (resp)return resp;

    resp = fileWrite_mem(addr, len);
    if (resp)return resp;

    resp = fileClose();
    if (resp)return resp;

    return 0;
}

u32 savGetUsedMemory(u32 addr, u32 max_size) {

    u32 srm_size;
    u32 i;

    if (bi_cmd_mem_test(RAM_NULL, addr, max_size))return 0;

    srm_size = 256;
    for (i = srm_size; i < max_size; i *= 2) {

        if (bi_cmd_mem_test(RAM_NULL, addr + i, i) == 0) {
            srm_size = i * 2;
        }
    }

    return srm_size;
}

typedef struct {
    u32 crc;
    u32 size;
} FdsSignature;

u32 srmCalcFdsCrc(u32 addr, u32 len) {

    u32 crc = 0;
    u32 block;

    while (len) {
        block = SIZE_FDS_DISK;
        if (block > len)block = len;
        bi_cmd_mem_crc(addr, SIZE_FDS_DISK, &crc);
        len -= block;
        addr += 0x10000;
    }

    return crc;
}

u8 srmRestoreFDS() {

    u8 skip_header = 0;
    u8 resp;
    u8 *path;
    u32 len;
    u32 block;
    u32 mem_addr;
    FdsSignature s;

    if (registry->cur_game.rom_inf.rom_type != ROM_TYPE_FDS)return 0;

    path = malloc(MAX_PATH_SIZE);
    //str_make_sync_name(registery->cur_game.path, path, PATH_SAVE_DIR, "srm", SYNC_IDX_OFF);
    //fatMakeSyncPath(path, PATH_SAVE_DIR, registry->cur_game.path, "srm");
    srmGetPathSRM(path);

    s.size = registry->cur_game.rom_inf.prg_size;
    resp = fileOpen(path, FA_READ);

    if (resp == FAT_NO_FILE || resp == FAT_NO_PATH) {//load source disk image if no saved image. 
        resp = fileOpen(registry->cur_game.path, FA_READ);
        skip_header = 1; //skip header if exists
    }

    free(MAX_PATH_SIZE);
    if (resp)return resp;

    if (skip_header) {
        resp = fileSetPtr(registry->cur_game.rom_inf.dat_base);
    }

    mem_addr = ADDR_FDS;
    len = s.size;
    while (len) {

        block = min(SIZE_FDS_DISK, len);

        resp = fileRead_mem(mem_addr, block);
        if (resp)return resp;

        len -= block;
        mem_addr += 0x10000;
    }

    resp = fileClose();
    if (resp)return resp;

    s.crc = srmCalcFdsCrc(ADDR_FDS, s.size);
    bi_cmd_mem_wr(ADDR_FDS_SIG, &s, sizeof (FdsSignature));

    /* this is condition for sd bug. VERICO-32GB
    resp = fileOpen(PATH_RAMDUMP, FA_OPEN_ALWAYS | FA_WRITE);
    if (resp)return resp;
    resp = fileWrite_mem(ADDR_SRM, SIZE_SRM);
    if (resp)return resp;
    resp = fileClose();
    if (resp)return resp;*/

    return 0;
}

u8 srmBackupFDS() {

    FdsSignature s;
    u32 crc;
    u32 len;
    u32 block;
    u32 mem_addr;
    u8 *path;
    u8 resp;
    if (registry->cur_game.rom_inf.rom_type != ROM_TYPE_FDS)return 0;

    bi_cmd_mem_rd(ADDR_FDS_SIG, &s, sizeof (FdsSignature));
    if (s.size == 0)return 0;
    bi_cmd_mem_set(0, ADDR_FDS_SIG, sizeof (FdsSignature));
    if (s.size > MAX_FDS_SIZE)return ERR_FDS_SIZE;

    crc = srmCalcFdsCrc(ADDR_FDS, s.size);

    if (s.crc == crc)return 0;

    path = malloc(MAX_PATH_SIZE);
    //str_make_sync_name(registery->cur_game.path, path, PATH_SAVE_DIR, "srm", SYNC_IDX_OFF);
    //fatMakeSyncPath(path, PATH_SAVE_DIR, registry->cur_game.path, "srm");
    srmGetPathSRM(path);

    resp = fileOpen(path, FA_OPEN_ALWAYS | FA_WRITE | FS_MAKEPATH);
    free(MAX_PATH_SIZE);
    if (resp)return resp;

    mem_addr = ADDR_FDS;
    len = s.size;
    while (len) {

        block = min(SIZE_FDS_DISK, len);

        resp = fileWrite_mem(mem_addr, block);
        if (resp)return resp;

        len -= block;
        mem_addr += 0x10000;
    }

    resp = fileClose();
    if (resp)return resp;


    return 0;
}

u8 srmBackupPRG() {

    u8 resp;

    resp = fileOpen(registry->cur_game.path, FA_WRITE);
    if (resp)return resp;

    resp = fileSetPtr(16);
    if (resp)return resp;

    resp = fileWrite_mem(ADDR_PRG, registry->cur_game.rom_inf.prg_size);
    if (resp)return resp;

    resp = fileClose();
    if (resp)return resp;

    return 0;

}