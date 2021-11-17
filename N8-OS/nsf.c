
#include "everdrive.h"

u8 app_nsfPlay(u8 *path);

u8 nsfPlay(u8 *path) {

    u8 resp;
    u8 bank = REG_APP_BANK;
    REG_APP_BANK = APP_NSF;
    resp = app_nsfPlay(path);
    REG_APP_BANK = bank;
    return resp;
}

#pragma codeseg ("BNK06")

typedef struct {
    u8 nesm[5];
    u8 ver;
    u8 songs_num;
    u8 songs_one;
    u16 addr_load;
    u16 addr_init;
    u16 addr_play;
    u8 name_song[32];
    u8 name_arti[32];
    u8 name_copy[32];
    u16 speed_ntsc;
    u8 banks[8];
    u16 speed_pal;
    u8 mode;
    u8 snd_chips;
    u8 reserved;
    u8 len[3];
} Nsf;

#define NSF_VRC6        0x01
#define NSF_VRC7        0x02
#define NSF_FDS         0x04
#define NSF_MMC5        0x08
#define NSF_N163        0x10
#define NSF_SU5B        0x20

u8 app_nsfPlay(u8 *path) {

    u8 resp;
    Nsf hdr;
    RomInfo inf;
    FileInfo finf = {0};
    MapConfig cfg;
    u32 addr, size;
    u8 i, banks_on;


    gCleanScreen();
    gRepaint();
    ppuOFF();


    resp = getRomInfo(&inf, PATH_NSF_PLAYER);
    if (resp)return resp;

    resp = fileOpen(PATH_NSF_PLAYER, FA_READ);
    if (resp)return resp;

    resp = fileSetPtr(16);
    if (resp)return resp;

    resp = fileRead_mem(ADDR_PRG + 0x100000 - inf.prg_size, inf.prg_size);
    if (resp)return resp;

    resp = fileRead_mem(ADDR_CHR, inf.chr_size);
    if (resp)return resp;

    resp = fileClose();
    if (resp)return resp;

    fileGetInfo(path, &finf);
    if (resp)return resp;

    resp = fileOpen(path, FA_READ);
    if (resp)return resp;

    //hdr = malloc(sizeof (Nsf));
    resp = fileRead(&hdr, sizeof (Nsf));

    addr = hdr.addr_load;
    banks_on = 0;
    for (i = 0; i < 8; i++) {
        if (hdr.banks[i] != 0)banks_on = 1;
    }

    if (banks_on) {
        addr &= 0xfff;
    } else {
        addr &= 0x7FFF;
    }

    //free(sizeof (Nsf));
    if (resp)return resp;

    size = min(finf.size - 0x80, 0x100000 - 4096 - addr);

    resp = fileSetPtr(0);
    if (resp)return resp;

    resp = fileRead_mem(ADDR_PRG + 0x100000 - 4096, 0x80);
    if (resp)return resp;

    resp = fileRead_mem(ADDR_PRG + addr, size);
    if (resp)return resp;

    resp = fileClose();
    if (resp)return resp;

    //tune should not use last 32 bytes in address space
    //if (hdr->addr_init >= 0xffD0)return ERR_BAD_NSF;
    //if (hdr->addr_play >= 0xffD0)return ERR_BAD_NSF;
    //if ((hdr->addr_load + size) > 0xFFE0 && !banks_on)return ERR_BAD_NSF;

    edGetMapConfig(&inf, &cfg);
    resp = edApplyOptions(&cfg);
    if (resp)return resp;
    cfg.chr_msk = 0x0f;
    cfg.prg_msk = 0xff;
    cfg.map_ctrl &= ~MAP_CTRL_RDELAY;
    cfg.ss_key_load = SS_COMBO_OFF;
    cfg.ss_key_save = SS_COMBO_OFF;

    i = 0;
    if ((hdr.snd_chips & NSF_SU5B))i = MAP_SU5B;
    if ((hdr.snd_chips & NSF_N163))i = MAP_N163;
    if ((hdr.snd_chips & NSF_MMC5))i = MAP_MMC5;
    if ((hdr.snd_chips & NSF_FDS))i = MAP_FDS;
    if ((hdr.snd_chips & NSF_VRC7))i = MAP_VRC7;
    if ((hdr.snd_chips & NSF_VRC6))i = MAP_VRC6;


    cfg.master_vol = volGetMasterVol(i);

    //bi_cmd_fpg_init_cfg(&cfg);
    //return bi_cmd_fpg_init_sdc(0);//inf.map_pack
    if (1) {
        u8 map_path[24];
        edGetMapPath(inf.map_pack, map_path);
        resp = bi_cmd_fpg_init_sdc(map_path); //reconfigure fpga
        if (resp)return resp;
    }
    bi_start_app(&cfg);

    return 0;
}

