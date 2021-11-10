
#include "everdrive.h"


u8 app_mainMenu();

u8 mainMenu() {

    u8 resp;
    u8 bank = REG_APP_BANK;
    REG_APP_BANK = APP_MM;
    resp = app_mainMenu();
    REG_APP_BANK = bank;
    return resp;
}


#pragma codeseg ("BNK11")

u8 mmOptions();
u8 mmInGameCombo();
void mmAbout();
void mmDeviceInfo();
void mmDeviceInfo_full();
void volOptions();
void mmHotKeySetup();
//void mmHotKeyInfo();
void mmAppendKeyCode(u8 joy);

enum {
    MM_OPTIONS = 0,
    MM_RECENT,
    MM_CHEATS,
    MM_DEV_INF,
    MM_DIAGNOSTICS,
    MM_ABOUT,
    MM_SIZE
};

u8 app_mainMenu() {

    u8 resp = 2;
    ListBox box;
    u8 * menu_items[MM_SIZE + 1];

    menu_items[MM_OPTIONS] = "Options";
    menu_items[MM_RECENT] = "Recently Played";
    menu_items[MM_CHEATS] = "Cheats";
    menu_items[MM_DEV_INF] = "Device Info";
    menu_items[MM_DIAGNOSTICS] = "Diagnostics";
    menu_items[MM_ABOUT] = "About";
    menu_items[MM_SIZE] = 0;

    box.hdr = "Main Menu";
    box.items = menu_items;
    box.selector = 0;

    while (1) {

        guiDrawListBox(&box);
        if (box.act == ACT_EXIT)return 0;
        gCleanScreen();

        if (box.selector == MM_RECENT) {
            resp = recentMenu();
            if (resp)return resp;
        }

        if (box.selector == MM_CHEATS) {
            resp = ggEdit(0, registery->cur_game.path);
            if (resp)return resp;
        }

        if (box.selector == MM_OPTIONS) {
            resp = mmOptions();
            if (resp)return resp;
        }

        if (box.selector == MM_ABOUT) {
            mmAbout();
        }

        if (box.selector == MM_DEV_INF) {
            mmDeviceInfo();
        }

        if (box.selector == MM_DIAGNOSTICS) {
            resp = diagnostics();
            if (resp)return resp;
        }


        gCleanScreen();
    }

    return 0;
}

enum {
    OP_IG_MENU = 0,
    OP_CHEATS,
    OP_RST_DELAY,
    OP_FILE_SORT,
    OP_SWAP_AB,
    OP_FDS_AUTO_SWP,
    OP_AUTOSTART,
    OP_IG_COMBO,
    OP_AUDIO_VOL,
    OP_RTC,
    OP_SIZE
};

u8 mmOptions() {

    u8 joy;
    u8 changed = 0;
    InfoBox box;
    u8 * arg[OP_SIZE];
    u8 * val[OP_SIZE];
    u8 swap_ab = registery->options.swap_ab;
    Options *opt = &registery->options;

    static u8 * off_on[] = {"OFF", "ON "};

    arg[OP_IG_MENU] = "In-Game Menu";
    arg[OP_CHEATS] = "Cheats";
    arg[OP_RST_DELAY] = "Reset Delay";
    arg[OP_FILE_SORT] = "File Sorting";
    arg[OP_SWAP_AB] = "Swap A/B";
    arg[OP_AUTOSTART] = "Boot Last Game";
    arg[OP_FDS_AUTO_SWP] = "FDS Auto Swap";
    arg[OP_IG_COMBO] = "[In-Game Combo]";
    arg[OP_AUDIO_VOL] = "[Audio Balance]";
    arg[OP_RTC] = "[RTC Setup]";



    box.hdr = "Options";
    box.arg = arg;
    box.val = val;
    box.selector = 0;
    box.items = OP_SIZE;
    box.skip_init = 0;


    while (1) {

        val[OP_IG_MENU] = off_on[opt->ss_mode];
        val[OP_CHEATS] = off_on[opt->cheats];
        val[OP_RST_DELAY] = off_on[opt->rst_delay];
        val[OP_FILE_SORT] = off_on[opt->sort_files];
        val[OP_SWAP_AB] = off_on[swap_ab];
        val[OP_AUTOSTART] = off_on[opt->autostart];
        val[OP_FDS_AUTO_SWP] = off_on[opt->fds_auto_swp];
        val[OP_IG_COMBO] = 0;
        val[OP_AUDIO_VOL] = 0;
        val[OP_RTC] = 0;

        guiDrawInfoBox(&box);
        joy = sysJoyWait();

        if (joy == JOY_U) {
            box.selector = dec_mod(box.selector, OP_SIZE);
        }

        if (joy == JOY_D) {
            box.selector = inc_mod(box.selector, OP_SIZE);
        }

        if (joy == JOY_B) {
            break;
        }

        if (joy == JOY_A) {

            if (box.selector != OP_RTC)changed = 1;

            if (box.selector == OP_IG_MENU)opt->ss_mode ^= 1;
            if (box.selector == OP_CHEATS)opt->cheats ^= 1;
            if (box.selector == OP_RST_DELAY)opt->rst_delay ^= 1;
            if (box.selector == OP_FILE_SORT)opt->sort_files ^= 1;
            if (box.selector == OP_SWAP_AB)swap_ab ^= 1;
            if (box.selector == OP_AUTOSTART)opt->autostart ^= 1;
            if (box.selector == OP_FDS_AUTO_SWP)opt->fds_auto_swp ^= 1;
            if (box.selector == OP_IG_COMBO)mmHotKeySetup(); //
            if (box.selector == OP_RTC)rtcSetup();
            if (box.selector == OP_AUDIO_VOL)volOptions();

            gCleanScreen();
        }
    }

    if (changed) {
        registery->options.swap_ab = swap_ab;
        return edRegisterySave();
    }

    return 0;
}



static u8 * key_codes[] = {"RIGHT", "LEFT", "DOWN", "UP", "START", "SELECT", "B", "A"};

void mmAppendKeyCode(u8 joy) {

    u8 i;
    u8 c = 0;

    if (joy == SS_COMBO_OFF) {
        gAppendString("OFF");
        return;
    }

    for (i = 0; i < 8; i++) {
        if (((joy >> i) & 1)) {
            if (c > 2) {
                gAppendString("...");
                break;
            }
            if (c)gAppendString("+");
            c++;
            gAppendString(key_codes[i]);
        }
    }
}

void mmHotKeySetup() {

    enum {
        HK_KEY_SAVE = 0,
        HK_KEY_LOAD,
        HK_KEY_MENU,
        //HK_INFO,
        HK_SIZE
    };

    Options *opt = &registery->options;
    ListBox box;
    u8 * items[HK_SIZE]; // = {"Set Save-State HotKey", "Set Load-State HotKey", 0};


    box.hdr = "HotKey Setup";
    box.items = items;
    box.selector = 0;

    items[HK_KEY_SAVE] = "Quick Save-State";
    items[HK_KEY_LOAD] = "Quick Load-State";
    items[HK_KEY_MENU] = "In-Game Menu";
    //items[HK_INFO] = "Information";
    items[HK_SIZE] = 0;

    while (1) {

        gCleanScreen();
        gSetPal(PAL_G2);
        gDrawFooter("Save Key: ", 3, 0);
        mmAppendKeyCode(opt->ss_key_save);
        gConsPrint("Load Key: ");
        mmAppendKeyCode(opt->ss_key_load);
        gConsPrint("Menu Key: ");
        mmAppendKeyCode(opt->ss_key_menu);

        guiDrawListBox(&box);
        if (box.act == ACT_EXIT)return;

        if (box.selector == HK_KEY_SAVE)opt->ss_key_save = mmInGameCombo();
        if (box.selector == HK_KEY_LOAD)opt->ss_key_load = mmInGameCombo();
        if (box.selector == HK_KEY_MENU)opt->ss_key_menu = mmInGameCombo();
        //if (box.selector == HK_INFO)mmHotKeyInfo();
    }
    //
}

u8 mmInGameCombo() {

    u8 joy;
    u8 i;
    u8 ctr;
    u16 time;
    u16 delay;
    u8 buff[32];
    u8 *hdr = "Hot Key Configuration";


    while (1) {

        gCleanScreen();
        gSetPal(PAL_G2);
        gDrawHeader(hdr, G_CENTER);
        gDrawFooter("hold two or more buttons", 1, G_CENTER);

        gSetY(G_SCREEN_H / 2 - 2);
        gSetPal(PAL_B2);


        joy = sysJoyRead_raw();
        ctr = 0;
        buff[0] = 0;

        for (i = 0; i < 8; i++) {

            if (((joy >> i) & 1)) {
                if (ctr != 0)str_append(buff, "+");
                str_append(buff, key_codes[i]);
                ctr++;
            }
        }

        if (joy == JOY_STA)ctr = 2;

        if (ctr < 2)time = bi_get_ticks();
        delay = bi_get_ticks() - time;


        gConsPrintCX(buff);
        gRepaint();

        if (ctr > 1 && delay > 480) {

            if (joy == JOY_STA) {
                buff[0] = 0;
                str_append(buff, "OFF");
                joy = SS_COMBO_OFF;
            }

            time = bi_get_ticks();
            while (1) {

                gCleanScreen();
                gSetPal(PAL_G2);
                gDrawHeader(hdr, G_CENTER);
                gDrawFooter("Combination Changed!", 1, G_CENTER);
                gSetY(G_SCREEN_H / 2 - 2);
                gSetPal(PAL_B3);
                delay = bi_get_ticks() - time;
                if (delay % 400 > 200) {
                    gConsPrintCX(buff);
                    if (delay > 800)break;
                }
                gRepaint();
            }
            gRepaint();
            while (sysJoyRead() != 0);
            sysJoyWait();
            return joy;
        }

    }

}

/*
void mmHotKeyInfo() {


    gCleanScreen();

    gSetPal(PAL_G2);
    gConsPrint("     In-Game Menu Mode STD    ");
    gSetPal(PAL_B2);
    gConsPrint("");
    gConsPrint("Save HotKey: Trigers menu");
    gConsPrint("Load HotKey: Do nothing");


    gSetY(G_SCREEN_H / 2 - 1);
    gSetPal(PAL_G2);
    gConsPrint("     In-Game Menu Mode QSS    ");
    gSetPal(PAL_B2);
    gConsPrint("");
    gConsPrint("Save HotKey: Quick save");
    gConsPrint("Load HotKey: Quick load");

    gSetPal(PAL_B3);
    gConsPrint("");
    gConsPrintCX("QSS mode allows to make");
    gConsPrintCX("quick save/load state");
    gConsPrintCX("without entering to menu.");

    gConsPrint("");
    gConsPrintCX("In-Game menu switches ");
    gConsPrintCX("to STD mode if both");
    gConsPrintCX("hotkeys matches.");


    gRepaint();
    sysJoyWait();
}
 */
void mmAbout() {

    gSetPal(PAL_B1);
    //gConsPrint("");
    gConsPrint("EverDrive N8 PRO");
    gConsPrint("");

    gSetPal(PAL_B3);
    gConsPrint("Developed by:");
    gSetPal(PAL_B1);
    gConsPrint("Igor Golubovskiy");
    gConsPrint("");

    gSetPal(PAL_B3);
    gConsPrint("Special thanks:");
    gSetPal(PAL_B1);
    gConsPrint("wiki.nesdev.com");
    gConsPrint("www.mesen.ca - nice debugger");
    gConsPrint("James-F - audio tuning");
    gConsPrint("YM2149 core by Necronomfive");
    gConsPrint("YM2413 core by Necronomfive");
    gConsPrint("");

    gSetPal(PAL_B3);
    gConsPrint("Support:");
    gSetPal(PAL_B1);
    gConsPrint("www.krikzz.com");
    gConsPrint("");


    gConsPrint("");
    gSetPal(PAL_B3);
    gConsPrint("Control:");
    gSetPal(PAL_B1);
    gConsPrint("LEFT/RIGHT : Switch page");
    gConsPrint("START      : Run last game");
    gConsPrint("SELECT     : Main menu");

    if (!registery->options.swap_ab) {
        gConsPrint("B          : File menu");
        gConsPrint("A          : Back");
    } else {
        gConsPrint("A          : File menu");
        gConsPrint("B          : Back");
    }

    gSetY(G_SCREEN_H - G_BORDER_Y - 2);
    gConsPrint("Made in Ukraine");

    gRepaint();
    sysJoyWait();
}

enum {
    DI_CART_TYPE = 0,
    DI_OS_VER,
    DI_OS_DATE,
    DI_IO_CORE,
    DI_ASM_DATE,
    DI_ASM_TIME,
    DI_SERIAL,
    //DI_VOLTAGE,
    DI_VBAT,
    DI_BOOT_CTR,
    DI_GAME_CTR,
    DI_SIZE
};

void mmDeviceInfo() {

    InfoBox box;
    u8 * arg[DI_SIZE];
    u8 * val[DI_SIZE];
    u8 i;
    u8 *buff;
    Vdc vdc;

    buff = malloc(DI_SIZE * 16);


    box.hdr = "Device Info";
    box.arg = arg;
    box.val = val;
    box.selector = SEL_OFF;
    box.items = DI_SIZE;
    box.skip_init = 0;


    //for(i = 0;i < 8;i++)bi_cmd_get_vdc(&vdc);
    bi_cmd_get_vdc(&vdc);



    for (i = 0; i < DI_SIZE; i++) {
        val[i] = &buff[i * 16];
        buff[i * 16] = 0;
    }


    arg[DI_CART_TYPE] = "Cart Type";
    arg[DI_OS_VER] = "OS Version";
    arg[DI_OS_DATE] = "OS Date";
    arg[DI_IO_CORE] = "IO Core";
    arg[DI_ASM_DATE] = "Build Date";
    arg[DI_ASM_TIME] = "Build Time";
    arg[DI_SERIAL] = "Serial Num";
    //arg[DI_VOLTAGE] = "----Voltage Monotor----";
    arg[DI_VBAT] = "Battery";
    arg[DI_BOOT_CTR] = "Boot Counter";
    arg[DI_GAME_CTR] = "Games Played";

    /*
    if (sys_inf->mcu.device_id == CART_ID_PRO) {
        str_append(val[DI_CART_TYPE], "ED-N8-PRO");
    } else {
        str_append(val[DI_CART_TYPE], "???");
    }*/

    if (sys_inf->mcu.cart_form == 0) {
        str_append(val[DI_CART_TYPE], "N8-PRO-NES");
    } else {
        str_append(val[DI_CART_TYPE], "N8-PRO-FC");
    }

    str_append_num(val[DI_OS_VER], sys_inf->os_ver >> 8);
    str_append(val[DI_OS_VER], ".");
    str_append_hex8(val[DI_OS_VER], sys_inf->os_ver);

    str_append_date(val[DI_OS_DATE], sys_inf->os_bld_date);

    str_append_num(val[DI_IO_CORE], sys_inf->mcu.sw_ver >> 8);
    str_append(val[DI_IO_CORE], ".");
    str_append_hex8(val[DI_IO_CORE], sys_inf->mcu.sw_ver);

    str_append_date(val[DI_ASM_DATE], sys_inf->mcu.asm_date);
    str_append_time(val[DI_ASM_TIME], sys_inf->mcu.asm_time);

    str_append_hex8(val[DI_SERIAL], sys_inf->mcu.serial_g >> 16);
    str_append_hex16(val[DI_SERIAL], sys_inf->mcu.serial_g);
    //str_append(val[DI_SERIAL], ":");
    str_append_hex16(val[DI_SERIAL], sys_inf->mcu.serial_l);

    //val[DI_VOLTAGE] = 0;

    str_append_num(val[DI_VBAT], vdc.vbt >> 8);
    str_append(val[DI_VBAT], ".");
    str_append_hex8(val[DI_VBAT], vdc.vbt);
    str_append(val[DI_VBAT], "v");

    str_append_num(val[DI_BOOT_CTR], sys_inf->mcu.boot_ctr);

    str_append_num(val[DI_GAME_CTR], sys_inf->mcu.game_ctr);


    gDrawFooter("Press START for details", 1, G_CENTER);
    guiDrawInfoBox(&box);


    free(DI_SIZE * 16);
    i = sysJoyWait();
    if (i == JOY_STA) {
        mmDeviceInfo_full();
    }
}

void mmDeviceInfo_full() {

    u8 buff[32];
    Vdc vdc;
    u32 srm_crc;

    gCleanScreen();
    gRepaint();

    sysPalInit(1);
    bi_cmd_get_vdc(&vdc);
    srm_crc = 0;
    bi_cmd_mem_crc(ADDR_SRM, SIZE_SRM, &srm_crc);
    sysPalInit(0);
    gRepaint();

    gSetPal(PAL_G2);
    gDrawHeader("EverDrive system information", G_CENTER);
    gSetPal(PAL_B1);
    gConsPrint("");
    gConsPrint("");

    gConsPrint("DEVICE ID  ");
    gAppendHex8(sys_inf->mcu.device_id);

    gConsPrint("CART FORM  ");
    if (sys_inf->mcu.cart_form == 0) {
        gAppendString("NES");
    } else {
        gAppendString("FAMICOM");
    }


    gConsPrint("CART DATE  ");
    buff[0] = 0;
    str_append_date(buff, sys_inf->mcu.asm_date);
    str_append(buff, " ");
    str_append_time(buff, sys_inf->mcu.asm_time);
    gAppendString(buff);

    gConsPrint("OS BUILD   ");
    buff[0] = 0;
    str_append_date(buff, sys_inf->os_bld_date);
    str_append(buff, " ");
    str_append_time(buff, sys_inf->os_bld_time);
    gAppendString(buff);

    gConsPrint("OS DIST    ");
    buff[0] = 0;
    str_append_date(buff, sys_inf->os_dist_date);
    str_append(buff, " ");
    str_append_time(buff, sys_inf->os_dist_time);
    gAppendString(buff);


    gConsPrint("OS VERSION ");
    gAppendHex16(sys_inf->os_ver);

    gConsPrint("BOOTLOADER ");
    gAppendHex16(sys_inf->mcu.boot_ver);

    gConsPrint("IO-CORE    ");
    gAppendHex16(sys_inf->mcu.sw_ver);

    gConsPrint("HW REV     ");
    gAppendHex16(sys_inf->mcu.hv_ver);

    gConsPrint("SERIAL     ");
    gAppendHex32(sys_inf->mcu.serial_g);
    gAppendHex16(sys_inf->mcu.serial_l);

    gConsPrint("GAME CTR   ");
    gAppendNum(sys_inf->mcu.game_ctr);

    gConsPrint("BOOT CTR   ");
    gAppendNum(sys_inf->mcu.boot_ctr);

    gConsPrint("VCC 1.2V   ");
    gAppendHex16(vdc.v12);
    gConsPrint("VCC 2.5V   ");
    gAppendHex16(vdc.v25);
    gConsPrint("VCC 5.0V   ");
    gAppendHex16(vdc.v50);
    gConsPrint("VCC VBAT   ");
    gAppendHex16(vdc.vbt);

    gConsPrint("PWR SRC    ");
    gAppendString("SYS[");
    gAppendNum(sys_inf->mcu.pwr_sys);
    gAppendString("], ");
    gAppendString("USB[");
    gAppendNum(sys_inf->mcu.pwr_usb);
    gAppendString("]");

    gConsPrint("SRAM CRC   ");
    gAppendHex32(srm_crc);
    if (srm_crc == 0xE20EEA22) {
        gAppendString(" (BLANK)");
    }

    gConsPrint("");
    gConsPrint("MCUID:");
    gAppendHex(sys_inf->mcu.cpu_id, 12);
    gConsPrint("FLAID:");
    gAppendHex(sys_inf->mcu.fla_id, 8);

    gRepaint();
    sysJoyWait();
}