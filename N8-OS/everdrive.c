
#include "everdrive.h"



u8 edMapRoutLoad();
u8 edRegisteryLoad();
u8 edRegisteryReset();
u8 edLoadSysyInfo();
void bootloader(u8 *boot_flag);
u8 edVramBugHandler();

Registery *registery;
SysInfo *sys_inf;
SessionCFG *ses_cfg;

u8 *maprout;

u8 edInit(u8 sst_mode) {

    u8 resp;
    //if (REG_MAP_IDX != 0xff)bi_exit_game();
    std_init();
    sysInit();
    gInit();
    guiInit();


    registery = malloc(sizeof (Registery));
    sys_inf = malloc(sizeof (SysInfo));
    maprout = malloc(256);
    ses_cfg = malloc(sizeof (SessionCFG)); //this memory allocated in OS memory area. It resets to 0x00 only at cold boot.
    fmInitMemory();
    mem_set(sys_inf, 0, sizeof (SysInfo));

    if (sst_mode)return 0; //all memory should be allocated before this point
    ses_cfg->ss_bank = 0;

    //if (*hot_start == 0) {
    bootloader(&ses_cfg->boot_flag);
    //}

    //gConsPrint("init...");
    //gRepaint();


    resp = bi_init();
    if (resp)return resp;

    resp = edLoadSysyInfo();
    if (resp)return resp;

    resp = edMapRoutLoad();
    if (resp)return resp;

    resp = edRegisteryLoad();
    if (resp == ERR_REGI_CRC || resp == FAT_NO_FILE) {
        resp = edRegisteryReset();
        printError(ERR_REGI_CRC);
    }
    if (resp)return resp;


    if (!registery->cur_game.rom_inf.usb_game) {
        //ppuOFF();
        resp = srmBackupFDS();
        if (resp)return resp;

        if (ses_cfg->save_prg) {
            ses_cfg->save_prg = 0;
            resp = srmBackupPRG();
            if (resp)return resp;
        }

        //ppuON();
    }

    resp = edVramBugHandler();
    if (resp)return resp;

    //gConsPrint("ok");
    //gRepaint();

    if (sys_inf->mcu.ram_rst) {
        bi_cmd_mem_set(RAM_NULL, ADDR_SRM, SIZE_SRM);
        rtcReset();
        printError(ERR_BAT_RDY);
    }

    resp = updateCheck();
    if (resp)return resp;

    ses_cfg->hot_start = 1; //should be in the end
    return 0;
}

u8 edLoadSysyInfo() {

    sys_inf->os_ver = OS_VER;
    sys_inf->os_bld_date = *(u16 *) 0xFFF0;
    sys_inf->os_bld_time = *(u16 *) 0xFFF2;
    sys_inf->os_dist_date = *(u16 *) 0xFFF4;
    sys_inf->os_dist_time = *(u16 *) 0xFFF6;
    bi_cmd_sys_inf(&sys_inf->mcu);

    //sys_inf->asm_date = mcu.asm_date; //0x4e66;
    //sys_inf->asm_time = mcu.asm_time; //0x1234;
    return 0;
}

void edRun() {

    u8 resp;

    while (1) {
        resp = fmanager();
        printError(resp);
        if (resp == FAT_DISK_ERR || resp == FAT_NOT_READY) {
            bi_cmd_disk_init();
        }
    }
}

u8 edMapRoutLoad() {

    u8 resp;
    resp = bi_cmd_file_open(PATH_MAPROUT, FA_READ);
    if (resp)return resp;
    resp = bi_cmd_file_read(maprout, 256);
    if (resp)return resp;
    resp = bi_cmd_file_close();
    if (resp)return resp;


    return 0;
}

u8 edRegisteryLoad() {

    u8 resp;
    u16 crc;
    //mem_set(registery, 0, sizeof (Registery));

    resp = bi_cmd_file_open(PATH_REGISTERY, FA_READ);
    if (resp)return resp;

    resp = bi_cmd_file_read(registery, sizeof (Registery));
    if (resp)return resp;

    resp = bi_cmd_file_close();
    if (resp)return resp;

    crc = crcFast(registery, sizeof (Registery) - 2);
    if (crc != registery->crc)return ERR_REGI_CRC;

    return 0;
}

u8 edRegisteryReset() {

    mem_set(registery, 0, sizeof (Registery));

    registery->options.cheats = 1;
    registery->options.sort_files = 1;
    registery->options.ss_key_save = JOY_STA | JOY_D;
    registery->options.ss_key_load = JOY_STA | JOY_U;
    registery->options.ss_mode = SS_MOD_STD;
    registery->options.fds_auto_swp = 1;

    volSetDefaults();

    return edRegisterySave();
}

u8 edRegisterySave() {

    u8 resp;

    resp = bi_cmd_file_open(PATH_REGISTERY, FA_WRITE | FA_OPEN_ALWAYS);
    if (resp)return resp;

    registery->crc = crcFast(registery, sizeof (Registery) - 2);

    resp = bi_cmd_file_write(registery, sizeof (Registery));
    if (resp)return resp;


    resp = bi_cmd_file_close();
    if (resp)return resp;

    return 0;
}

u8 edSelectGame(u8 *path, u8 recent_add) {


    u8 resp;

    ppuOFF();

    resp = srmBackup();
    if (resp)return resp;

    mem_set(&registery->cur_game, 0, sizeof (Game));

    resp = getRomInfo(&registery->cur_game.rom_inf, path);
    if (resp)return resp;

    if (registery->cur_game.rom_inf.usb_game) {
        path += 4; //skip "USB:" identificator
    }

    str_copy(path, registery->cur_game.path);

    resp = edRegisterySave();
    if (resp)return resp;

    resp = srmRestore();
    if (resp)return resp;

    if (recent_add) {
        resp = recentAdd(path);
        if (resp)return resp;
    }

    if (recent_add) {
        bi_cmd_game_ctr(); //not count usb games and recently played
        sys_inf->mcu.game_ctr++;
    }

    if (!registery->cur_game.rom_inf.usb_game) {
        gCleanScreen();
        gRepaint();
    }



    ppuON();

    return 0;
}

void edGetMapConfig(RomInfo *inf, MapConfig *cfg) {

    mem_set(cfg, 0, sizeof (MapConfig));

    cfg->prg_msk |= bi_get_rom_mask(inf->prg_size);
    cfg->prg_msk |= bi_get_srm_mask(inf->srm_size) << 4;
    cfg->chr_msk |= bi_get_rom_mask(inf->chr_size) & 15;

    cfg->chr_msk |= (inf->mapper & 0xf00) >> 4;
    cfg->map_idx = inf->mapper & 0xff;


    cfg->ss_key_save = SS_COMBO_OFF;
    cfg->ss_key_load = SS_COMBO_OFF;
    cfg->map_ctrl = MAP_CTRL_UNLOCK;
    cfg->master_vol = volGetMasterVol(cfg->map_idx);
    if (sys_inf->mcu.cart_form) {
        cfg->map_ctrl |= MAP_CTRL_FAMI;
    }

    cfg->map_cfg |= inf->submap << 4;
    if (inf->srm_size == 0)cfg->map_cfg |= MCFG_SRM_OFF;
    if (inf->chr_ram)cfg->map_cfg |= MCFG_CHR_RAM;

    if (inf->mir_mode == MIR_HOR)cfg->map_cfg |= MCFG_MIR_H;
    if (inf->mir_mode == MIR_VER)cfg->map_cfg |= MCFG_MIR_V;
    if (inf->mir_mode == MIR_4SC)cfg->map_cfg |= MCFG_MIR_4;
    if (inf->mir_mode == MIR_1SC)cfg->map_cfg |= MCFG_MIR_1;

    if (inf->prg_size > SIZE_FDS_DISK * 2 && inf->rom_type == ROM_TYPE_FDS) {
        //during disk swap use increment disk mode instead of auto detecion for multi disk games.
        //seems like muulti disk gams does not actualy have correct disk number in file request header
        cfg->map_cfg |= MCFG_FDS_INC | MCFG_FDS_ASW;
    }

}

u8 edApplyOptions(MapConfig *cfg) {

    u8 resp;
    Options *opt = &registery->options;

    if (opt->cheats) {
        resp = ggLoadCodes(&cfg->gg, registery->cur_game.path);
        if (resp)return resp;
        cfg->map_ctrl |= MAP_CTRL_GG_ON;
    }

    if (opt->rst_delay) {
        cfg->map_ctrl |= MAP_CTRL_RDELAY;
    }

    if (opt->ss_mode) {

        cfg->ss_key_save = registery->options.ss_key_save;
        if (opt->ss_mode == SS_MOD_QSS) {
            cfg->ss_key_load = registery->options.ss_key_load;
        }
        cfg->map_ctrl |= MAP_CTRL_SS_ON;
        if (cfg->map_idx != MAP_IDX_FDS)cfg->map_ctrl |= MAP_CTRL_SS_BTN;
    }

    if (opt->fds_auto_swp && registery->cur_game.rom_inf.rom_type == ROM_TYPE_FDS) {
        cfg->map_cfg |= MCFG_FDS_ASW;
    }

    return 0;
}

u8 edStartGame(u8 usb_mode) {

    //u8 *ptr;
    u8 resp;
    u16 i;
    MapConfig cfg;
    RomInfo *cur_game = &registery->cur_game.rom_inf;

    if (registery->cur_game.path[0] == 0)return ERR_GAME_NOT_SEL;
    if (registery->cur_game.rom_inf.supported == 0 && !usb_mode)return ERR_MAP_NOT_SUPP;
    if (cur_game->usb_game && !usb_mode)return ERR_USB_GAME;


    ppuOFF();

    if (usb_mode) {
        //do nothing
    } else if (cur_game->rom_type == ROM_TYPE_FDS) {

        resp = srmRestoreFDS();
        if (resp)return resp;

    } else {

        resp = bi_cmd_file_open(registery->cur_game.path, FA_READ);
        if (resp)return resp;

        resp = bi_cmd_file_set_ptr(cur_game->dat_base);
        if (resp)return resp;

        resp = bi_cmd_file_read_mem(ADDR_PRG, cur_game->prg_size);
        if (resp)return resp;

        if (!cur_game->chr_ram) {
            resp = bi_cmd_file_read_mem(ADDR_CHR, cur_game->chr_size);
            if (resp)return resp;
        }

        resp = bi_cmd_file_close();
        if (resp)return resp;

        if (cur_game->prg_save) {
            ses_cfg->save_prg = 1;
        }

    }

    edGetMapConfig(cur_game, &cfg);
    resp = edApplyOptions(&cfg);
    if (resp)return resp;


    PPU_CTRL = 0x00;
    //PPU_ADDR = 0x3f;
    //PPU_ADDR = 0x00;
    //PPU_DATA = 0x30;

    //apu initialize
    for (i = 0; i < 0x13; i++) {
        ((u8 *) 0x4000)[i] = 0;
    }

    *(u8 *) 0x4015 = 0x00;
    *(u8 *) 0x4017 = 0x40;


    bi_cmd_fpg_init_cfg(&cfg);

    if (usb_mode) {
        bi_reboot_usb();
    } else {
        return bi_cmd_fpg_init(cur_game->map_pack); //reconfigure fpga and reboot
    }

}

u8 edVramBugHandler() {

    u8 resp;
    u8 i;

    u8 * msg[] = {
        //"00000000000000000000000000000000",
        "",
        "",
        "!WARNING!",
        "PPU VRAM bug detected.",
        "",
        "",
        "Such bug presents only in ",
        "poorly made console clones.",
        "",
        "Due this bug some advanced",
        "mappers can not work properly",
        "For example mappers with",
        "4-screen mirroring or advanced",
        "graphics features in MMC5.",
        "",
        "",
        "Also this bug effects N8 menu.",
        "In safe mode menu working slow",
        "and with another color scheme.",
        0
        //"00000000000000000000000000000000",
    };


    if (sysVramBug() != 0 && registery->vram_bug_msg == 0) {

        registery->vram_bug_msg = 1;
        resp = edRegisterySave();
        if (resp)return resp;

        gCleanScreen();

        for (i = 0; msg[i] != 0; i++) {
            gConsPrintCX(msg[i]);
        }
        gRepaint();
        for (i = 0; i < 60; i++)sysVsync();
        sysJoyWait();

    }

    if (sysVramBug() == 0 && registery->vram_bug_msg != 0) {
        registery->vram_bug_msg = 0;
        resp = edRegisterySave();
        if (resp)return resp;
    }

    return 0;
}
