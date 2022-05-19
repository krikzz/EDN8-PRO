
#include "everdrive.h"



u8 edMapRoutLoad();
u8 edRegistryLoad();
u8 edRegistryReset();
u8 edLoadSysyInfo();
void bootloader(u8 *boot_flag);
u8 edVramBugHandler();
u8 edLoadFdsBios();
u8 edBramBackup();
u8 edBramRestore();
u8 edApplyGameData(MapConfig *cfg, RomInfo *inf, u8 *path);

Registry *registry;
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


    registry = malloc(sizeof (Registry));
    sys_inf = malloc(sizeof (SysInfo));
    maprout = malloc(256);
    ses_cfg = malloc(sizeof (SessionCFG)); //this memory allocated in OS memory area. It resets to 0x00 only at cold boot.
    fmInitMemory();
    mem_set(sys_inf, 0, sizeof (SysInfo));

    if (sst_mode)return 0; //all memory should be allocated before this point
    ses_cfg->ss_bank = 0;
    ses_cfg->ss_selector = 0;

    bootloader(&ses_cfg->boot_flag);

    resp = bi_init();
    if (resp)return resp;

    resp = edLoadSysyInfo();
    if (resp)return resp;

    resp = edMapRoutLoad();
    if (resp)return resp;

    resp = edRegistryLoad();
    if (resp == ERR_REGI_CRC || resp == FAT_NO_FILE) {
        resp = edRegistryReset();
        printError(ERR_REGI_CRC);
    }
    if (resp)return resp;

    resp = edVramBugHandler();
    if (resp)return resp;

    //gConsPrint("ok");
    //gRepaint();

    if (sys_inf->mcu.ram_rst) {
        bi_cmd_mem_set(RAM_NULL, ADDR_SRM, SIZE_SRM);
        registry->ram_backup_req = 0;
        resp = edRegistrySave();
        if (resp)return resp;
        rtcReset();
        printError(ERR_BAT_RDY);
    }

    if (ses_cfg->hot_start == 0) {
        resp = updateCheck();
        if (resp)return resp;
    }

    resp = edBramBackup();
    if (resp)return resp;

    resp = ssExport();
    if (resp)return resp;

    if (ses_cfg->hot_start == 0) {
        ses_cfg->hot_start = 1; //should be in the end
        if (registry->options.autostart) {
            edStartGame(0);
        }
    }

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
    resp = fileOpen(PATH_MAPROUT, FA_READ);
    if (resp)return resp;
    resp = fileRead(maprout, 256);
    if (resp)return resp;
    resp = fileClose();
    if (resp)return resp;


    return 0;
}

u8 edRegistryLoad() {

    u8 resp;
    u16 crc;
    //mem_set(registery, 0, sizeof (Registery));

    resp = fileOpen(PATH_REGISTRY, FA_READ);
    if (resp)return resp;

    resp = fileRead(registry, sizeof (Registry));
    if (resp)return resp;

    resp = fileClose();
    if (resp)return resp;

    crc = crcFast(registry, sizeof (Registry) - 2);
    if (crc != registry->crc)return ERR_REGI_CRC;

    if (registry->regi_ver != REGI_VER) {
        return ERR_REGI_CRC;
    }

    return 0;
}

u8 edRegistryReset() {

    mem_set(registry, 0, sizeof (Registry));

    registry->options.cheats = 1;
    registry->options.sort_files = 1;
    registry->options.ss_key_menu = JOY_STA | JOY_D;
    registry->options.ss_key_save = SS_COMBO_OFF;
    registry->options.ss_key_load = SS_COMBO_OFF;
    registry->options.ss_mode = 1;
    registry->options.fds_auto_swp = 1;

    volSetDefaults();

    str_copy(PATH_DEF_GAME, registry->cur_game.path);
    registry->cur_game.rom_inf.supported = 1;

    registry->regi_ver = REGI_VER;
    return edRegistrySave();
}

u8 edRegistrySave() {

    u8 resp;

    resp = fileOpen(PATH_REGISTRY, FA_WRITE | FA_OPEN_ALWAYS);
    if (resp)return resp;

    registry->crc = crcFast(registry, sizeof (Registry) - 2);

    resp = fileWrite(registry, sizeof (Registry));
    if (resp)return resp;

    resp = fileClose();
    if (resp)return resp;

    return 0;
}

u8 edSelectGame(u8 *path, u8 recent_add) {


    u8 resp;

    ppuOFF();

    //in case if file to ram been used before change the game
    resp = edBramBackup();
    if (resp)return resp;
    //resp = srmBackup();
    //if (resp)return resp;


    mem_set(&registry->cur_game, 0, sizeof (Game));

    resp = getRomInfo(&registry->cur_game.rom_inf, path);
    if (resp)return resp;

    if (registry->cur_game.rom_inf.usb_game) {
        path += 4; //skip "USB:" identificator
    }

    str_copy(path, registry->cur_game.path);

    resp = edRegistrySave();
    if (resp)return resp;

    //resp = srmRestore();
    //if (resp)return resp;

    if (recent_add) {
        resp = recentAdd(path);
        if (resp)return resp;
    }

    if (recent_add) {
        bi_cmd_game_ctr(); //not count usb games and recently played
        sys_inf->mcu.game_ctr++;
    }

    if (!registry->cur_game.rom_inf.usb_game) {
        gCleanScreen();
        gRepaint();
    }

    ppuON();

    return 0;
}

void edApplyRomInf(MapConfig *cfg, RomInfo *inf) {

    mem_set(cfg, 0, sizeof (MapConfig));

    cfg->prg_msk |= bi_get_rom_mask(inf->prg_size);
    cfg->prg_msk |= bi_get_srm_mask(inf->srm_size) << 4;
    cfg->chr_msk |= bi_get_rom_mask(inf->chr_size) & 15;

    cfg->chr_msk |= (inf->mapper & 0xf00) >> 4;
    cfg->map_idx = inf->mapper & 0xff;

    cfg->ss_key_menu = SS_COMBO_OFF;
    cfg->ss_key_save = SS_COMBO_OFF;
    cfg->ss_key_load = SS_COMBO_OFF;
    cfg->map_ctrl = MAP_CTRL_UNLOCK;

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

    //forcing simple incremental swap method instead smart swap. Smart method may not work for some games
    if (inf->prg_size > SIZE_FDS_DISK * 2 && inf->rom_type == ROM_TYPE_FDS) {
        //during disk swap use increment disk mode instead of auto detecion for multi disk games.
        //seems like muulti disk gams does not actualy have correct disk number in file request header
        cfg->map_cfg |= MCFG_FDS_ASW;
    }

}

void edApplyOptions(MapConfig *cfg) {

    Options *opt = &registry->options;

    cfg->master_vol = volGetMasterVol(cfg->map_idx);

    if (opt->rst_delay) {
        cfg->map_ctrl |= MAP_CTRL_RDELAY;
    }

    if (opt->ss_mode) {

        cfg->ss_key_save = registry->options.ss_key_save;
        cfg->ss_key_load = registry->options.ss_key_load;
        cfg->ss_key_menu = registry->options.ss_key_menu;

        if (cfg->map_idx != MAP_IDX_FDS)cfg->map_ctrl |= MAP_CTRL_SS_BTN;
        cfg->map_ctrl |= MAP_CTRL_SS_ON;
    }

    if (opt->fds_auto_swp && registry->cur_game.rom_inf.rom_type == ROM_TYPE_FDS) {
        cfg->map_cfg |= MCFG_FDS_ASW;
    }

}

u8 edApplyGameData(MapConfig *cfg, RomInfo *inf, u8 *path) {

    u8 resp;
    Options *opt = &registry->options;

    if (opt->cheats) {
        resp = ggLoadCodes(&cfg->gg, path);
        if (resp)return resp;
        cfg->map_ctrl |= MAP_CTRL_GG_ON;
    }

    resp = jmpGetVal(path, inf, &cfg->jmp_val);
    if (resp)return resp;


    return 0;
}

u8 edStartGame(u8 usb_mode) {

    u8 ext_bios = 0;
    u8 resp;
    u16 i;
    MapConfig *cfg = &ses_cfg->cfg;
    RomInfo *cur_game = &registry->cur_game.rom_inf;

    //if (registery->cur_game.path[0] == 0)return ERR_GAME_NOT_SEL;
    if (registry->cur_game.rom_inf.supported == 0 && !usb_mode)return ERR_MAP_NOT_SUPP;
    if (cur_game->usb_game && !usb_mode)return ERR_USB_GAME;

    if (cur_game->prg_size > SIZE_MAX_PRG)return ERR_ROM_SIZE;
    if (cur_game->chr_size > SIZE_MAX_CHR)return ERR_ROM_SIZE;

    ppuOFF();
    resp = edBramRestore();
    if (resp)return resp;

    if (cur_game->rom_type == ROM_TYPE_FDS) {//load fds bios if exists
        resp = edLoadFdsBios();
        if (resp == 0)ext_bios = 1;
    }

    if (usb_mode) {
        //do nothing
    } else if (cur_game->rom_type == ROM_TYPE_FDS) {

        resp = srmRestoreFDS();
        if (resp)return resp;

    } else {

        resp = fileOpen(registry->cur_game.path, FA_READ);
        if (resp)return resp;

        resp = fileSetPtr(cur_game->dat_base);
        if (resp)return resp;

        resp = fileRead_mem(ADDR_PRG, cur_game->prg_size);
        if (resp)return resp;

        if (!cur_game->chr_ram) {
            resp = fileRead_mem(ADDR_CHR, cur_game->chr_size);
            if (resp)return resp;
        }

        resp = fileClose();
        if (resp)return resp;

        if (cur_game->prg_save) {
            ses_cfg->save_prg = 1;
        }
    }

    edApplyRomInf(cfg, cur_game);
    edApplyOptions(cfg);
    resp = edApplyGameData(cfg, cur_game, registry->cur_game.path);
    if (resp)return resp;

    if (ext_bios) {
        cfg->map_cfg |= MCFG_FDS_EBI;
    }

    PPU_CTRL = 0x00;

    //apu initialize
    for (i = 0; i < 0x13; i++) {
        ((u8 *) 0x4000)[i] = 0;
    }

    *(u8 *) 0x4015 = 0x00;
    *(u8 *) 0x4017 = 0x40;


    if (usb_mode) {
        bi_cmd_fpg_init_usb();
    } else {
        u8 map_path[32];
        edGetMapPath(cur_game->map_pack, map_path);
        resp = bi_cmd_fpg_init_sdc(map_path); //reconfigure fpga
        if (resp)return resp;
    }

    //mem_copy(&cfg, &ses_cfg->cfg, sizeof (MapConfig));
    bi_start_app(cfg);

    return 0;
}

void edRebootGame() {

    u16 i;

    gCleanScreen();
    gRepaint();
    ppuOFF();
    PPU_CTRL = 0x00;

    //apu initialize
    for (i = 0; i < 0x13; i++) {
        ((u8 *) 0x4000)[i] = 0;
    }

    *(u8 *) 0x4015 = 0x00;
    *(u8 *) 0x4017 = 0x40;

    REG_SST_ADDR = 0;
    for (i = 0; i < 256; i++) {
        REG_SST_DATA = 0;
    }

    bi_cmd_mem_set(0, ADDR_CFG, sizeof (MapConfig));
    bi_start_app(&ses_cfg->cfg);
}

void edGetMapPath(u8 map_pack, u8 *path) {

    path[0] = 0;
    str_append(path, PATH_MAP);
    str_append(path, "/");
    if (map_pack < 128)str_append(path, "0");
    if (map_pack < 10)str_append(path, "0");
    str_append_num(path, map_pack);
    str_append(path, ".RBF");
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


    if (sysVramBug() != 0 && registry->vram_bug_msg == 0) {

        registry->vram_bug_msg = 1;
        resp = edRegistrySave();
        if (resp)return resp;

        gCleanScreen();

        for (i = 0; msg[i] != 0; i++) {
            gConsPrintCX(msg[i]);
        }
        gRepaint();
        for (i = 0; i < 60; i++)sysVsync();
        sysJoyWait();

    }

    if (sysVramBug() == 0 && registry->vram_bug_msg != 0) {
        registry->vram_bug_msg = 0;
        resp = edRegistrySave();
        if (resp)return resp;
    }

    return 0;
}

u8 edLoadFdsBios() {

    u8 resp;
    u16 i;
    u16 addr;
    u8 len;
    static const u8 fix[] = {
        0x05, 0x01, 0xCE,
        0x8D, 0x24, 0x40, 0xAE, 0x31,
        0x06, 0x05, 0x7A,
        0xEA, 0xEA, 0xEA, 0xEA, 0xEA, 0xEA,
        0x0A, 0x06, 0xCA,
        0xA5, 0x07, 0x20, 0x94, 0xE7, 0xEA, 0xEA, 0xEA, 0xEA, 0xEA,
        0x03, 0x07, 0x06,
        0xEA, 0xEA, 0xEA,
        0x1A, 0x07, 0x1B,
        0xEA, 0xEA, 0xEA, 0xA2, 0x27, 0xAD, 0x30, 0x40,
        0x29, 0x10, 0xD0, 0x5A, 0xF0, 0x23, 0xEA, 0xEA,
        0xEA, 0xEA, 0xEA, 0xEA, 0xEA, 0xEA, 0xEA, 0xEA, 0xEA, 0xEA,
        0x00
    };

    resp = fileOpen(PATH_FDS_BIOS, FA_READ);
    if (resp)return resp;

    resp = fileRead_mem(ADDR_FDS_BIOS, 8192);
    if (resp)return resp;

    resp = fileClose();
    if (resp)return resp;

    for (i = 0; fix[i] != 0; i += len + 3) {
        len = fix[i];
        addr = (fix[i + 1] << 8) | fix[i + 2];
        bi_cmd_mem_wr(ADDR_FDS_BIOS + addr, &fix[i + 3], len);
    }

    return 0;
}

u8 edBramBackup() {

    u8 resp;
    if (!registry->ram_backup_req)return 0;

    //for loaded via usb games skip save types which going to write back to the rom file
    if (registry->cur_game.rom_inf.usb_game == 0) {

        resp = srmBackupFDS();
        if (resp)return resp;

        if (ses_cfg->save_prg) {
            ses_cfg->save_prg = 0;
            resp = srmBackupPRG();
            if (resp)return resp;
        }
    }

    resp = srmBackup();
    if (resp)return resp;

    registry->ram_backup_req = 0;
    return edRegistrySave();
}

u8 edBramRestore() {

    u8 resp;
    if (registry->ram_backup_req)return 0;

    resp = srmRestore();
    if (resp)return resp;

    registry->ram_backup_req = 1;
    return edRegistrySave();
}