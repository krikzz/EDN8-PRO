

#include "main.h"

u8 app_fileMenu(u8 *path);

u8 fileMenu(u8 *path) {

    u8 resp;
    u8 bank = REG_APP_BANK;
    REG_APP_BANK = APP_FMN;
    resp = app_fileMenu(path);
    REG_APP_BANK = bank;
    return resp;
}


#pragma codeseg ("BNK10")

u8 fimeTextMenu(u8 *path);
u8 fimeRomMenu(u8 *path);
u8 fimeRomInfo(u8 *path);
u8 fileHexView(u8 *path);
u8 fileSrmMenu(u8 *path);
u8 fileBinMenu(u8 *path);
u8 fileInfo(u8 *path);
u8 fileDelMenu(u8 *path);
u8 fimeNsfMenu(u8 *path);

u8 app_fileMenu(u8 *path) {

    static u8 * gam_list[] = {"nes", "fds", 0};

    if (str_extension_list(gam_list, path)) {
        return fimeRomMenu(path);
    }

    if (str_extension("txt", path)) {
        return fimeTextMenu(path);
    }

    if (str_extension("srm", path)) {
        return fileSrmMenu(path);
    }

    if (str_extension("nsf", path)) {
        return fimeNsfMenu(path);
    }

    return fileBinMenu(path);


    return 0;
}

enum {
    TXT_HEX = 0,
    TXT_LOAD,
    TXT_INFO,
    TXT_DEL,
    TXT_SIZE
};

u8 fimeTextMenu(u8 *path) {

    u8 resp;
    static u8 * items[TXT_SIZE + 1];
    ListBox box;

    items[TXT_HEX] = "Hex View";
    items[TXT_LOAD] = "Load Cheats";
    items[TXT_INFO] = "File Info";
    items[TXT_DEL] = "Delete";
    items[TXT_SIZE] = 0;

    box.hdr = "File Menu";
    box.items = items;
    box.selector = 0;

    guiDrawListBox(&box);
    if (box.act == ACT_EXIT)return 0;

    if (box.selector == TXT_HEX) {
        return fileHexView(path);
    }

    if (box.selector == TXT_LOAD) {
        resp = ggEdit(path, registry->cur_game.path);
        if (resp)return resp;
    }

    if (box.selector == TXT_INFO) {
        resp = fileInfo(path);
        if (resp)return resp;
    }

    if (box.selector == TXT_DEL) {
        resp = fileDelMenu(path);
        if (resp)return resp;
    }

    return 0;
}

u8 fimeRomMenu(u8 *path) {

    enum {
        RM_SEL_START = 0,
        RM_SEL_ONLY,
        RM_CHEATS,
        RM_ROM_INF,
        RM_HEX,
        RM_JUMPERS,
        RM_DEL,
        RM_SIZE
    };

    ListBox box;
    u8 resp;

    static u8 * items[RM_SIZE + 1];

    box.hdr = "File Menu";
    box.items = items;
    box.selector = 0;

    items[RM_SEL_START] = "Select And Start";
    items[RM_SEL_ONLY] = "Select Only";
    items[RM_CHEATS] = "Cheats";
    items[RM_ROM_INF] = "Rom Info";
    items[RM_HEX] = "Hex View";
    items[RM_JUMPERS] = "Jumper Setup";
    items[RM_DEL] = "Delete";
    items[RM_SIZE] = 0;

    if (jmpSupported(path) == 0) {
        items[RM_JUMPERS] = GUI_HIDE;
    }

    guiDrawListBox(&box);
    if (box.act == ACT_EXIT)return 0;

    if (box.selector == RM_SEL_START || box.selector == RM_SEL_ONLY) {
        resp = edSelectGame(path, 1);
        if (resp)return resp;
        if (box.selector == RM_SEL_START) {
            return edStartGame(0);
        }
        return 0;
    }

    if (box.selector == RM_CHEATS) {
        return ggEdit(0, path);
    }

    if (box.selector == RM_ROM_INF) {
        return fimeRomInfo(path);
    }

    if (box.selector == RM_HEX) {
        return fileHexView(path);
    }

    if (box.selector == RM_JUMPERS) {
        return jmpSetup(path);
    }

    if (box.selector == RM_DEL) {
        return fileDelMenu(path);
    }

    return 0;
}

enum {
    FINF_MAPPER = 0,
    FINF_PRG_SIZE,
    FINF_CHR_SIZE,
    FINF_SRM_SIZE,
    FINF_MIRRORING,
    FINF_BAT_RAM,
    FINF_ROM_ID,
    FINF_DATE,
    FINF_TIME,
    FINF_SUPPORT,
    FINF_SIZE
};

u8 fimeRomInfo(u8 *path) {

    InfoBox box;
    RomInfo inf;
    u8 resp;
    u8 * args[FINF_SIZE];
    u8 * vals[FINF_SIZE];
    //u8 str_buff[80];
    u8 *ptr;
    FileInfo finf = {0};

    gCleanScreen();
    gRepaint();

    resp = getRomInfo(&inf, path);
    if (resp)return resp;

    resp = fileGetInfo(path, &finf);
    if (resp)return resp;

    box.hdr = "Rom Info";
    box.items = FINF_SIZE;
    box.arg = args;
    box.val = vals;
    box.selector = SEL_OFF;
    box.skip_init = 0;

    args[FINF_MAPPER] = "Mapper";
    args[FINF_PRG_SIZE] = "PRG Size";
    args[FINF_CHR_SIZE] = "CHR Size";
    args[FINF_SRM_SIZE] = "SRM Size";
    args[FINF_MIRRORING] = "Mirroring";
    args[FINF_BAT_RAM] = "Battery RAM";
    args[FINF_ROM_ID] = "ROM CRC32";
    args[FINF_SUPPORT] = "Supported";
    args[FINF_DATE] = "Date";
    args[FINF_TIME] = "Time";


    //ptr = str_buff;
    ptr = malloc(128);
    *ptr = 0;

    vals[FINF_MAPPER] = ptr;


    if (inf.rom_type == ROM_TYPE_FDS) {
        ptr = str_append(ptr, "FDS");
    } else {
        ptr = str_append_num(ptr, inf.mapper);
        ptr = str_append(ptr, " sub.");
        ptr = str_append_num(ptr, inf.submap);
    }


    *++ptr = 0;
    vals[FINF_PRG_SIZE] = ptr;
    ptr = str_append_num(ptr, inf.prg_size / 1024);
    ptr = str_append(ptr, "K");


    *++ptr = 0;
    vals[FINF_CHR_SIZE] = ptr;
    ptr = str_append_num(ptr, inf.chr_size / 1024);
    ptr = str_append(ptr, "K");
    if ((inf.chr_ram)) {
        ptr = str_append(ptr, " RAM");
    }

    *++ptr = 0;
    vals[FINF_SRM_SIZE] = ptr;
    if (inf.srm_size == 0) {
        ptr = str_append(ptr, "Off");
    } else if (inf.srm_size < 1024) {
        ptr = str_append_num(ptr, inf.srm_size);
        ptr = str_append(ptr, "B");
    } else {
        ptr = str_append_num(ptr, inf.srm_size / 1024);
        ptr = str_append(ptr, "K");
    }


    *++ptr = 0;
    vals[FINF_MIRRORING] = ptr;
    *ptr++ = inf.mir_mode;
    *ptr++ = 0;


    vals[FINF_BAT_RAM] = inf.bat_ram ? "Yes" : "No";

    *++ptr = 0;
    vals[FINF_ROM_ID] = ptr;
    ptr = str_append_hex32(ptr, inf.crc);


    *++ptr = 0;
    vals[FINF_DATE] = ptr;
    ptr = str_append_date(ptr, finf.date);

    *++ptr = 0;
    vals[FINF_TIME] = ptr;
    ptr = str_append_time(ptr, finf.time);

    vals[FINF_SUPPORT] = inf.supported ? "Yes" : "No";


    gCleanScreen();
    guiDrawInfoBox(&box);
    sysJoyWait();

    free(128);

    return 0;
}

u8 fileHexView(u8 *path) {

    u32 size;
    u8 resp;
    u8 joy;
    u8 rd_req;
    u8 *buff;
    static u8 *ptr;
    u32 addr = 0;
    u16 i;
    u16 block;

    //resp = fileSize(path, &size);
    //if (resp)return resp;

    resp = fileOpen(path, FA_READ);
    if (resp)return resp;

    size = fileAvailable();

    buff = malloc(256);

    rd_req = 1;
    gCleanScreen();
    while (1) {



        if (joy == JOY_U && addr >= 256) {

            addr -= 256;
            resp = fileSetPtr(addr);
            if (resp)break;
            rd_req = 1;
        }

        if (joy == JOY_D && (addr + 256) < size) {
            addr += 256;
            rd_req = 1;
        }

        if (joy == JOY_L) {
            addr = 0;
            resp = fileSetPtr(addr);
            if (resp)break;
            rd_req = 1;
        }

        if (joy == JOY_R) {
            addr = size / 256 * 256;
            if (addr == size && addr != 0)addr -= 256;
            resp = fileSetPtr(addr);
            if (resp)break;
            rd_req = 1;
        }

        if (rd_req) {

            block = 256;
            if (addr + block > size) {
                block = size - addr;
                mem_set(buff, 0, 256);
            }
            resp = fileRead(buff, block);
            if (resp)break;
            rd_req = 0;
        }

        gSetXY(0, 0);

        gSetPal(PAL_G2);
        gFillRow(' ', 0, G_BORDER_Y, G_SCREEN_W);
        gSetY(G_BORDER_Y - 1);
        //gConsPrint(" address: ");
        gConsPrint("");
        gAppendHex32(addr);
        gAppendString(" of ");
        gAppendHex32(size);
        gConsPrint("");
        gSetPal(PAL_B2);
        ptr = buff;

        for (i = 0; i < block; i++) {
            REG_VRM_ATTR = PAL_B1;
            gAppendHex8(*ptr++);
        }

        for (i = block; i < 256; i++) {
            gAppendString("..");
        }

        gSetPal(PAL_G2);
        ptr = buff;
        for (i = 0; i < block; i++) {
            REG_VRM_DATA = *ptr++;
        }

        for (i = block; i < 256; i++) {
            REG_VRM_DATA = 0;
        }

        gRepaint();
        joy = sysJoyWait();
        if (joy == JOY_B)break;
    }

    fileClose();
    free(256);
    return resp;
}

enum {
    SR_CANCEL = 0,
    SR_TO_RAM,
    SR_TO_FILE,
    SR_INFO,
    SR_HEX,
    SR_DEL,
    SR_SIZE
};

u8 fileSrmMenu(u8 *path) {

    ListBox box;
    u8 resp;
    u8 * menu_items[SR_SIZE + 1];

    menu_items[SR_CANCEL] = "Cancel";
    menu_items[SR_TO_RAM] = "Copy File To RAM";
    menu_items[SR_TO_FILE] = "Copy RAM To File";
    menu_items[SR_INFO] = "File Info";
    menu_items[SR_HEX] = "Hex View";
    menu_items[SR_DEL] = "Delete";
    menu_items[SR_SIZE] = 0;

    box.hdr = "Save RAM";
    box.items = menu_items;
    box.selector = 0;

    guiDrawListBox(&box);
    if (box.act == ACT_EXIT)return 0;

    if (box.selector == SR_TO_RAM) {
        gCleanScreen();
        gRepaint();
        resp = srmFileToMem(path, ADDR_SRM, SIZE_SRM);
        if (resp)return resp;
        registry->ram_backup_req = 1;
        resp = edBramBackup();
        if (resp)return resp;
        fmForceUpdate();
        return 0;
        //return edRegisterySave();
    }

    if (box.selector == SR_TO_FILE) {

        u32 size;
        gCleanScreen();
        gRepaint();
        resp = fileSize(path, &size);
        if (resp)return resp;
        size = min(SIZE_SRM, size);
        resp = srmMemToFile(path, ADDR_SRM, size);
        return resp;
    }

    if (box.selector == SR_INFO) {
        return fileInfo(path);
    }

    if (box.selector == SR_HEX) {
        return fileHexView(path);
    }

    if (box.selector == SR_DEL) {
        return fileDelMenu(path);
    }

    return 0;
}

enum {
    BIN_INF = 0,
    BIN_HEX,
    BIN_DEL,
    BIN_SIZE
};

u8 fileBinMenu(u8 *path) {

    ListBox box;
    static u8 * items[BIN_SIZE + 1];

    box.hdr = "File Menu";
    box.items = items;
    box.selector = 0;

    items[BIN_INF] = "File Info";
    items[BIN_HEX] = "Hex View";
    items[BIN_DEL] = "Delete";
    items[BIN_SIZE] = 0;

    guiDrawListBox(&box);
    if (box.act == ACT_EXIT)return 0;


    if (box.selector == BIN_INF) {
        return fileInfo(path);
    }

    if (box.selector == BIN_HEX) {
        return fileHexView(path);
    }

    if (box.selector == BIN_DEL) {
        return fileDelMenu(path);
    }

    return 0;
}

enum {
    BINF_FILE_SIZE = 0,
    BINF_DATE,
    BINF_TIME,
    BINF_SIZE
};

u8 fileInfo(u8 *path) {

    InfoBox box;
    u8 resp;
    u8 * args[BINF_SIZE];
    u8 * vals[BINF_SIZE];
    u8 *str_buff;
    u8 *ptr;
    FileInfo finf = {0};

    str_buff = malloc(128);


    resp = fileGetInfo(path, &finf);
    if (resp)return resp;

    box.hdr = "File Info";
    box.items = BINF_SIZE;
    box.arg = args;
    box.val = vals;
    box.selector = SEL_OFF;
    box.skip_init = 0;

    args[BINF_FILE_SIZE] = "Size";
    args[BINF_DATE] = "Date";
    args[BINF_TIME] = "Time";


    ptr = str_buff;
    *ptr = 0;

    vals[BINF_FILE_SIZE] = ptr;
    if (finf.size < 1024) {
        ptr = str_append_num(ptr, finf.size);
        ptr = str_append(ptr, "B");
    } else {
        ptr = str_append_num(ptr, finf.size / 1024);
        ptr = str_append(ptr, "K");
    }


    *++ptr = 0;
    vals[BINF_DATE] = ptr;
    ptr = str_append_date(ptr, finf.date);

    *++ptr = 0;
    vals[BINF_TIME] = ptr;
    ptr = str_append_time(ptr, finf.time);

    gCleanScreen();
    guiDrawInfoBox(&box);
    sysJoyWait();

    free(128);

    return 0;
}

enum {
    NSF_PLAY = 0,
    NSF_INFO,
    NSF_HEX,
    NSF_DEL,
    NSF_SIZE
};

u8 fimeNsfMenu(u8 *path) {

    u8 resp;
    static u8 * items[NSF_SIZE + 1];
    ListBox box;

    items[NSF_PLAY] = "Play";
    items[NSF_INFO] = "File Info";
    items[NSF_HEX] = "Hex View";
    items[NSF_DEL] = "Delete";
    items[NSF_SIZE] = 0;

    box.hdr = "File Menu";
    box.items = items;
    box.selector = 0;

    guiDrawListBox(&box);
    if (box.act == ACT_EXIT)return 0;

    if (box.selector == NSF_PLAY) {
        resp = nsfPlay(path);
        if (resp)return resp;
    }

    if (box.selector == NSF_INFO) {
        resp = fileInfo(path);
        if (resp)return resp;
    }

    if (box.selector == NSF_HEX) {
        return fileHexView(path);
    }

    if (box.selector == NSF_DEL) {
        resp = fileDelMenu(path);
        if (resp)return resp;
    }

    return 0;
}

u8 fileDelMenu(u8 *path) {

    u8 resp;

    gCleanScreen();
    resp = guiConfirmBox("Delete This File?", 0);
    if (resp == 0)return 0;

    resp = fileDel(path);
    if (resp)return resp;

    fmForceUpdate();

    return 0;
}

/*
u8 fileJmpSetup(u8 *path) {

    u8 i;
    u8 jmp_num = 4;
    u8 jmp_val = 2;
    u8 selector = 0;
    u8 joy;

    gCleanScreen();

    while (1) {

        gSetXY((G_SCREEN_W / 2) - jmp_num, G_SCREEN_H / 2);


        for (i = 0; i < jmp_num; i++) {

            gSetPal(selector == i ? PAL_B3 : PAL_B1);

            gAppendChar('0' + ((jmp_val >> i) & 1));
            gAppendChar(' ');
        }

        gRepaint();
        joy = sysJoyWait();

        if (joy == JOY_L) {
            selector = dec_mod(selector, jmp_num);
        }

        if (joy == JOY_R) {
            selector = inc_mod(selector, jmp_num);
        }


        if (joy == JOY_U || joy == JOY_D) {
            jmp_val ^= 1 << selector;
        }
    }

    return 0;
}

void fileGetJmpPath() {
}*/