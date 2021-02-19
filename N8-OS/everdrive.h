/* 
 * File:   everdrive.h
 * Author: igor
 *
 * Created on March 28, 2019, 5:03 PM
 */

#ifndef EVERDRIVE_H
#define	EVERDRIVE_H

#include "types.h"
#include "gfx.h"
#include "cfg.h"
#include "sys.h"
#include "bios.h"
#include "std.h"
#include "errors.h"
#include "gui.h"
#include "saveram.h"
#include "app.h"
#include "vol-ctrl.h"
#include "rom-config.h"
#include "var.h"


#define CART_ID_PRO     0x17

#define SS_MOD_OFF      0x00    //in-game menu and save state dissabled
#define SS_MOD_STD      0x01    //standard in-game menu
#define SS_MOD_QSS      0x02    //quick save/load state without in-game menu
#define MAP_IDX_FDS     254

typedef struct {
    u8 ss_mode;
    u8 ss_key_save;
    u8 ss_key_load;
    u8 ss_key_menu;
    u8 cheats;
    u8 swap_ab;
    u8 rst_delay;
    u8 fds_auto_swp;
    u8 sort_files;
    u8 autostart;
    u8 vol_tbl[16]; //max
} Options;

typedef struct {
    u8 path[MAX_PATH_SIZE + 1];
    RomInfo rom_inf;
} Game;

typedef struct {
    Game cur_game;
    Options options;
    u8 vram_bug_msg;
    u8 ram_backup_req;
    u16 crc;
} Registery;

typedef struct {
    SysInfoIO mcu;
    u16 os_ver;
    u16 os_bld_date;
    u16 os_bld_time;
    u16 os_dist_date;
    u16 os_dist_time;
} SysInfo;

typedef struct {
    u8 ss_bank;
    u8 hot_start;
    u8 boot_flag;
    u8 save_prg;
    MapConfig cfg;
} SessionCFG;

extern Registery *registery;
extern SysInfo *sys_inf;
extern SessionCFG *ses_cfg;

u8 edInit(u8 sst_mode);
void edRun();
u8 edSelectGame(u8 *path, u8 recent_add);
void edGetMapConfig(RomInfo *inf, MapConfig *cfg);
u8 edApplyOptions(MapConfig *cfg);
u8 edStartGame(u8 usb_mode);
u8 edRegisterySave();
void edGetMapPath(u8 map_pack, u8 *path);
u8 edBramBackup();
void edRebootGame();

void usbListener();
void printError(u8 code);

u8 diagnostics();

u8 updateCheck();
u8 nsfPlay(u8 *path);

#endif	/* EVERDRIVE_H */

