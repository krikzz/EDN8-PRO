
#include "everdrive.h"

void app_inGameMenu();

void inGameMenu() {

    u8 bank = REG_APP_BANK;
    REG_APP_BANK = APP_SS;
    app_inGameMenu();
    REG_APP_BANK = bank;

}


#pragma codeseg ("BNK08")

void ss_return();
void ss_reset();
u8 ssCheats();

void app_inGameMenu() {

    enum {
        SS_SAVE,
        SS_LOAD,
        SS_BANK,
        SS_CHEATS,
        SS_RESET,
        SS_EXIT,
        SS_SWAP_DISK,
        SS_SIZE
    };

    u8 resp;
    FileInfo inf = {0};
    ListBox box;
    u8 * items[SS_SIZE + 1];
    u8 buff[16];
    u8 ss_src;
    u8 ss_bank_hex;
    u8 update_info = 1;

    edInit(1);


    REG_SST_ADDR = 0xff; //ss hit byte
    ss_src = REG_SST_DATA;

    //mem_set(&box, 0, sizeof (ListBox));
    box.hdr = 0;
    box.items = items;
    box.selector = ses_cfg->ss_selector;
    items[SS_SAVE] = "Save State";
    items[SS_LOAD] = "Load State";
    items[SS_CHEATS] = "Cheats";
    items[SS_RESET] = "Reset Game";
    items[SS_EXIT] = "Exit Game";
    items[SS_SWAP_DISK] = 0; //"Swap Disk";
    items[SS_SIZE] = 0;

    if (registry->options.cheats == 0) {
        items[SS_CHEATS] = GUI_HIDE;
    }

    ss_bank_hex = decToBcd(ses_cfg->ss_bank);

    //quick ss section
    if (ss_src != 0x00 && ss_src == registry->options.ss_key_load) {
        ppuOFF();
        resp = srmRestoreSS(ss_bank_hex);
        if (resp)printError(resp);
        ss_return();
    }

    if (ss_src != 0x00 && ss_src == registry->options.ss_key_save) {
        ppuOFF();

        resp = srmSSrpoint(ss_bank_hex);
        if (resp)printError(resp);

        resp = srmBackupSS(ss_bank_hex);
        if (resp)printError(resp);
        ss_return();
    }


    while (1) {

        if (update_info) {
            resp = srmGetInfoSS(&inf, ss_bank_hex);
            update_info = 0;
        }

        gSetPal(PAL_G2);
        if (resp == 0) {
            gDrawFooter("Save Time: ", 1, 0);
            gAppendDate(inf.date);
            gAppendString(" ");
            gAppendTime(inf.time);
        } else {
            gDrawFooter("Empty Slot", 1, G_CENTER);
        }

        buff[0] = 0;


        str_append(buff, "Slot: ");
        if (ss_bank_hex == 0x99) {
            str_append(buff, "RC");
        } else {
            str_append_hex8(buff, ss_bank_hex);
        }

        items[SS_BANK] = buff;

        box.selector |= SEL_DPD;
        guiDrawListBox(&box);
        ses_cfg->ss_selector = box.selector;

        if (box.act == ACT_EXIT) {
            ss_return();
        }

        if (box.act == JOY_L) {
            ses_cfg->ss_bank = dec_mod(ses_cfg->ss_bank, MAX_SS_SLOTS);
            ss_bank_hex = decToBcd(ses_cfg->ss_bank);
            update_info = 1;
        }

        if (box.act == JOY_R) {
            ses_cfg->ss_bank = inc_mod(ses_cfg->ss_bank, MAX_SS_SLOTS);
            ss_bank_hex = decToBcd(ses_cfg->ss_bank);
            update_info = 1;
        }

        //gCleanScreen();
        if (box.selector == SS_BANK)continue;

        if (box.selector == SS_CHEATS & box.act == ACT_OPEN) {
            resp = ssCheats();
            if (resp)printError(resp);
            gCleanScreen();
            continue;
        }

        if (box.act == ACT_OPEN) {
            break;
        }
    }

    ppuOFF();

    if (box.selector == SS_SWAP_DISK) {
        REG_FDS_SWAP = 1;
        ss_return();
    }

    if (box.selector == SS_SAVE) {

        resp = srmSSrpoint(ss_bank_hex);
        if (resp)printError(resp);

        resp = srmBackupSS(ss_bank_hex);
        if (resp)printError(resp);
        ss_return();
    }

    if (box.selector == SS_LOAD) {
        resp = srmRestoreSS(ss_bank_hex);
        if (resp)printError(resp);
        ss_return();
    }

    if (box.selector == SS_RESET) {

        edRebootGame();
    }

    if (box.selector == SS_EXIT) {

        bi_exit_game();
    }

}

u8 ssCheats() {

    u8 resp;
    resp = ggEdit(0, registry->cur_game.path);
    if (resp)return resp;

    resp = ggLoadCodes(&ses_cfg->cfg.gg, registry->cur_game.path);
    if (resp)return resp;

    bi_cmd_mem_wr(ADDR_CFG, &ses_cfg->cfg, sizeof (MapConfig));

    return 0;
}