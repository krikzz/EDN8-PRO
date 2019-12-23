

#include "game-db.h"

u8 mapPack20(RomInfo *inf);
u8 app_getRomInfo(RomInfo *inf, u8 *path);

u8 getRomInfo(RomInfo *inf, u8 *path) {

    u8 resp;
    u8 bank = REG_APP_BANK;
    REG_APP_BANK = APP_CFG;
    resp = app_getRomInfo(inf, path);
    REG_APP_BANK = bank;
    return resp;
}

#pragma codeseg ("BNK05")

typedef struct {
    u8 ines[32];
    u32 size;
    u32 crc;
    u32 dat_base;
} RomID;





u8 romInfoFDS(RomInfo *inf, RomID *id);
u8 getRomID(RomID *id, u8 *path);
void romConfigDB(RomInfo *inf);
void romConfigNES20(RomInfo *inf, u8 *ines);
void romConfigGlobl(RomInfo *inf);

extern u8 *maprout;

u8 app_getRomInfo(RomInfo *inf, u8 *path) {

    u8 resp;
    RomID id;


    mem_set(inf, 0, sizeof (RomInfo));

    if (str_cmp_len("USB:", path, 4)) {
        resp = 0;
        bi_cmd_usb_wr(&resp, 1); //we are ready to receive id
        bi_fifo_rd(&id, sizeof (RomID));
        inf->usb_game = 1;
    } else {
        resp = getRomID(&id, path);
        if (resp)return resp;
    }


    if (str_cmp_len("NES", id.ines, 3) == 0) {
        return romInfoFDS(inf, &id);
    }

    inf->rom_type = ROM_TYPE_NES;
    inf->dat_base = id.dat_base;
    inf->crc = id.crc;

    inf->mapper = ((id.ines[6] >> 4) | (id.ines[7] & 0xf0));
    if ((id.ines[7] & 0x0C) == 0x08)inf->nes20 = 1;

    inf->prg_size = (u32) id.ines[4] * 1024 * 16;
    inf->chr_size = (u32) id.ines[5] * 1024 * 8;
    inf->srm_size = 8192;
    if (inf->prg_size == 0)inf->prg_size = 0x400000;
    inf->mir_mode = (id.ines[6] & 1) == 0 ? MIR_HOR : MIR_VER;
    inf->bat_ram = (id.ines[6] & 2) == 0 ? 0 : 1;

    if (inf->prg_size == 16384 && inf->chr_size == 8192 && id.size == 16400) {
        inf->prg_size = 8192;
    }


    if ((id.ines[6] & 8) != 0) inf->mir_mode = MIR_4SC;

    if (inf->mapper == 30) {
        if ((id.ines[6] & 9) == 0)inf->mir_mode = MIR_HOR;
        if ((id.ines[6] & 9) == 1)inf->mir_mode = MIR_VER;
        if ((id.ines[6] & 9) == 8)inf->mir_mode = MIR_1SC;
        if ((id.ines[6] & 9) == 9)inf->mir_mode = MIR_4SC;
    }

    if (inf->chr_size == 0) {
        inf->chr_ram = 1;
        inf->chr_size = 8192;
    }

    if (inf->nes20) {
        romConfigNES20(inf, id.ines);
    } else {
        romConfigDB(inf);
    }

    if (inf->mapper == 30 && inf->bat_ram)inf->prg_save = 1;
    if (inf->mapper == 111)inf->prg_save = 1;

    //should be in the end
    inf->supported = 1;

    if (inf->mapper < 256) {
        inf->map_pack = maprout[inf->mapper];
    } else {
        mapPack20(inf);
    }

    if (inf->map_pack == 0xff && inf->mapper != 0xff)inf->supported = 0;

    return 0;
}

u8 mapPack20(RomInfo *inf) {

    u8 resp;
    inf->map_pack = 0xff;

    resp = bi_cmd_file_open(PATH_MAPROUT, FA_READ);
    if (resp)return resp;
    resp = bi_cmd_file_set_ptr(inf->mapper);
    resp = bi_cmd_file_read(&inf->map_pack, 1);
    if (resp)return resp;
    resp = bi_cmd_file_close();
    if (resp)return resp;

    return 0;
}

u8 romInfoFDS(RomInfo *inf, RomID *id) {


    if (!str_cmp_len("HVC", &id->ines[id->dat_base + 11], 3)) {
        return ERR_UNK_ROM_FORMAT;
    }

    inf->dat_base = id->dat_base;
    inf->prg_size = id->size;
    inf->prg_size -= id->dat_base;

    //crop garbage bytes if any exists.
    if (inf->prg_size % SIZE_FDS_DISK != 0 && inf->prg_size % SIZE_FDS_DISK < 1024) {
        inf->prg_size -= inf->prg_size % SIZE_FDS_DISK;
    }

    inf->srm_size = 32768L;
    inf->chr_size = 8192;
    inf->chr_ram = 1;
    inf->mir_mode = MIR_HOR;

    inf->rom_type = ROM_TYPE_FDS;
    inf->mapper = MAP_IDX_FDS;
    inf->crc = id->crc;

    inf->map_pack = maprout[inf->mapper];
    inf->supported = 1;
    if (inf->map_pack == 0xff && inf->mapper != 0xff)inf->supported = 0;

    inf->chr_ram = 1;


    return 0;
}

u8 getRomID(RomID *id, u8 *path) {

    FileInfo finf = {0};
    u8 resp;
    u32 crc_len;

    resp = bi_cmd_file_info(path, &finf);
    if (resp)return resp;

    resp = bi_cmd_file_open(path, FA_READ);
    if (resp)return resp;

    resp = bi_cmd_file_read(id->ines, 32);
    if (resp)return resp;

    id->size = finf.size;
    crc_len = finf.size;

    id->dat_base = 0;
    if (str_cmp_len("NES", id->ines, 3) || str_cmp_len("HVC", &id->ines[0x1B], 3)) {
        id->dat_base = 16;
    }

    crc_len = min(MAX_ID_CALC_LEN, finf.size - id->dat_base);

    resp = bi_cmd_file_set_ptr(id->dat_base);
    if (resp)return resp;

    id->crc = 0;
    resp = bi_cmd_file_crc(crc_len, &id->crc);
    if (resp)return resp;

    resp = bi_cmd_file_close();
    if (resp)return resp;

    return 0;
}

void romConfigDB(RomInfo *inf) {

    u16 i;

    for (i = 0; game_db[i].target != 0; i++) {

        if (game_db[i].crc != inf->crc)continue;
        if (game_db[i].target == SET_MIR)inf->mir_mode = game_db[i].val;
        if (game_db[i].target == SET_SUB)inf->submap = game_db[i].val;
        if (game_db[i].target == SET_MAP)inf->mapper = game_db[i].val;
        if (game_db[i].target == SET_SRM)inf->srm_size = (u32) game_db[i].val * 1024;
        if (game_db[i].target == SET_CHR)inf->chr_size = (u32) game_db[i].val * 1024;
    }

    if (inf->mapper == 30) {
        if (inf->chr_ram) {
            inf->chr_size = 32768L;
        }
    }

    if (inf->mapper == 151) {
        inf->mir_mode = '4';
    }

    if (inf->mapper == 255) {
        if (inf->crc == 0xCCC03440)inf->mapper = 156; //Buzz & Waldog.nes
    }

    romConfigGlobl(inf);
}

void romConfigNES20(RomInfo *inf, u8 *ines) {

    u8 ram_size;

    inf->submap = ines[8] >> 4;
    inf->mapper |= (ines[8] & 0x0F) << 8;

    inf->srm_size = 0;

    ram_size = (ines[10] & 0x0f);
    if (ram_size != 0)inf->srm_size += 64L << ram_size;
    ram_size = (ines[10] >> 4);
    if (ram_size != 0)inf->srm_size += 64L << ram_size;
    if (inf->srm_size != 0 && inf->srm_size < 1024)inf->srm_size = 1024;

    if ((ines[9] & 0xF0) == 0 && ines[5] == 0) {
        inf->chr_ram = 1;
        inf->chr_size = 64L << (ines[11] & 0x0f);
    } else {
        inf->chr_ram = 0;
        inf->chr_size = (u32) (((ines[9] & 0xF0) << 4) | ines[5]) * 8192;
    }

    romConfigGlobl(inf);
}

void romConfigGlobl(RomInfo *inf) {

    //relocate map 254 to unused 253. maps 255 and 254 reserved for system (OS and FDS)
    if (inf->mapper == MAP_IDX_FDS && inf->rom_type != ROM_TYPE_FDS) {
        inf->mapper = 253;
    }

    if (inf->mapper == 30 && inf->bat_ram) {
        inf->submap = 1;
    }

}
