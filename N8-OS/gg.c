
#include "everdrive.h"

u8 app_ggEdit(u8 *src, u8 *game);
u8 app_ggLoadCodes(CheatList *gg, u8 *game);

u8 ggEdit(u8 *src, u8 *game) {

    u8 resp;
    u8 bank = REG_APP_BANK;
    REG_APP_BANK = APP_GG;
    resp = app_ggEdit(src, game);
    REG_APP_BANK = bank;
    return resp;
}

u8 ggLoadCodes(CheatList *gg, u8 *game) {

    u8 resp;
    u8 bank = REG_APP_BANK;
    REG_APP_BANK = APP_GG;
    resp = app_ggLoadCodes(gg, game);
    REG_APP_BANK = bank;
    return resp;
}

#pragma codeseg ("BNK05")

typedef struct {
    u8 chars[8 + 2];
} TextSlot;

typedef struct {
    TextSlot slot[GG_SLOTS];
} CheatText;

u8 ggGetVal(u8 *code, u8 n1, u8 n2, u8 n3);
void ggParse(u8 *data, CheatText *gg_txt);
u8 ggValidChar(u8 val);
u8 ggTextLoad(u8 *src, u8 *game, CheatText *gg_txt);
u8 ggEditor(CheatText *gg_txt, u8 *game_path);
u8 ggEditSlot(TextSlot *slot);
u8 ggTextSave(CheatText *gg_txt, u8 *game);
u8 ggGetCode(CheatSlot *code, u8* str);

static const u8 gg_tbl[26] = {
    0x00, 0xff, 0xff, 0xff, 0x08, 0xff, 0x04, 0xff,
    0x05, 0xff, 0x0C, 0x03, 0xff, 0x0F, 0x09, 0x01,
    0xff, 0xff, 0x0D, 0x06, 0x0B, 0x0E, 0xff, 0x0A, 0x07, 0x02,
};

static const u8 gg_chars[] = {
    'A', 'P', 'Z', 'L', 'G', 'I', 'T', 'Y', 'E', 'O', 'X', 'U', 'K', 'S', 'V', 'N', '-'
};

u8 app_ggEdit(u8 *src, u8 *game) {

    u8 changed;
    u8 resp = 0;
    CheatText *gg_txt;

    gCleanScreen();
    gRepaint();

    /*
    if (game[0] == 0) {
        printError(ERR_GAME_NOT_SEL);
        return 0;
    }*/

    gg_txt = malloc(sizeof (CheatText));

    resp = ggTextLoad(src, game, gg_txt);
    if (resp) {
        free(sizeof (CheatText));
        return resp;
    }

    changed = ggEditor(gg_txt, game);

    if (src != 0) {
        gCleanScreen();
        changed = guiConfirmBox("Apply Cheats?", 1);
    }

    if (changed) {
        resp = ggTextSave(gg_txt, game);
    }

    free(sizeof (CheatText));

    return resp;
}

u8 app_ggLoadCodes(CheatList *gg, u8 *game) {

    u8 resp;
    u8 i;
    CheatText gg_txt;


    resp = ggTextLoad(0, game, &gg_txt);
    if (resp)return resp;

    for (i = 0; i < GG_SLOTS; i++) {

        ggGetCode(&gg->slot[i], gg_txt.slot[i].chars);
    }

    return 0;

}

u8 ggGetCode(CheatSlot *code, u8* str) {

    u8 i;
    u8 clen;
    u8 buff[8];


    for (i = 0; i < 8; i++) {
        if (str[i] == 0 || str[i] == '-')break;
        if (!ggValidChar(str[i]))return ERR_INCORRECT_GG;
        buff[i] = gg_tbl[str[i] - 'A'];
    }
    clen = i;

    //if (clen == 6 && str[7] != '-')clen = 0;

    if (clen != 6 && clen != 8) {
        mem_set(code, 0, sizeof (CheatSlot));
        return ERR_INCORRECT_GG;
    }

    code->addr = 0x8000;
    code->addr |= ((buff[3] & 7) << 12) | ((buff[5] & 7) << 8);
    code->addr |= ((buff[4] & 8) << 8) | ((buff[2] & 7) << 4);
    code->addr |= ((buff[1] & 8) << 4) | (buff[4] & 7) | (buff[3] & 8);



    if (clen == 6) {
        code->new_val = ggGetVal(buff, 1, 0, 5);
        code->cmp_val = code->new_val;
    } else {
        code->new_val = ggGetVal(buff, 1, 0, 7);
        code->cmp_val = ggGetVal(buff, 7, 6, 5);
    }

    return 0;
}

u8 ggGetVal(u8 *code, u8 n1, u8 n2, u8 n3) {

    u8 val;
    val = ((code[n1] & 7) << 4) | ((code[n2] & 8) << 4);
    val |= (code[n2] & 7) | (code[n3] & 8);
    return val;
    //return ((code[n1] & 7) << 4) | ((code[n2] & 8) << 4) | (code[n2] & 7) | (code[n3] & 8);
}
extern u16 malloc_ptr;

u8 ggTextLoad(u8 *src, u8 *game, CheatText *gg_txt) {

    u16 buff_size;
    u8 *buff;
    u8 resp;
    u32 fsize;

    buff_size = max(MAX_PATH_SIZE, MAX_GG_FSIZE);
    buff = malloc(buff_size);

    while (1) {

        if (src == 0) {
            src = buff;
            //str_make_sync_name(game, src, PATH_CHEATS, "txt", SYNC_IDX_OFF);
            fatMakeSyncPath(src, PATH_CHEATS, game, "txt");
        }

        resp = bi_file_get_size(src, &fsize);
        if (resp != 0 && resp != FAT_NO_FILE)break;

        if (resp == 0) {//if file exist

            if (fsize > MAX_GG_FSIZE)fsize = MAX_GG_FSIZE;

            resp = bi_cmd_file_open(src, FA_READ);
            if (resp)break;

            mem_set(buff, 0, MAX_GG_FSIZE);

            resp = bi_cmd_file_read(buff, fsize);
            if (resp)break;

            resp = bi_cmd_file_close();
            if (resp)break;

        } else {
            resp = 0;
            mem_set(buff, 0, MAX_GG_FSIZE);
        }

        ggParse(buff, gg_txt);

        break;
    }

    free(buff_size);

    return resp;

}

u8 ggTextSave(CheatText *gg_txt, u8 *game) {

    u8 i;
    u8 resp;
    u8 *buff;
    u8 empty = 1;

    for (i = 0; i < GG_SLOTS; i++) {
        gg_txt->slot[i].chars[8] = 0x0D; //insert new line
        gg_txt->slot[i].chars[9] = 0x0A;
        if (mem_tst(gg_txt->slot[i].chars, '-', 8) == 0)empty = 0;
    }

    buff = malloc(MAX_PATH_SIZE);
    //str_make_sync_name(game, buff, PATH_CHEATS, "txt", SYNC_IDX_OFF);
    fatMakeSyncPath(buff, PATH_CHEATS, game, "txt");

    if (empty) {

        resp = bi_cmd_file_del(buff);
        if (resp == FAT_NO_FILE)resp = 0;

    } else {

        resp = bi_cmd_file_open(buff, FA_WRITE | FA_OPEN_ALWAYS);

        if (resp == 0) {
            resp = bi_cmd_file_write(gg_txt, sizeof (CheatText));
        }

        if (resp == 0) {
            resp = bi_cmd_file_close();
        }
    }


    free(MAX_PATH_SIZE);

    return resp;
}

u8 ggValidChar(u8 val) {

    if (val == '-')return 1;
    if (val >= 'A' && val <= 'Z' && gg_tbl[val - 'A'] != 0xff)return 1;

    return 0;
}

void ggParse(u8 *data, CheatText *gg_txt) {

    u16 len;
    u8 i;
    u8 slot = 0;


    mem_set(gg_txt, '-', sizeof (CheatText));


    len = MAX_GG_FSIZE;

    while (len && slot < GG_SLOTS) {

        while (!ggValidChar(*data)) {
            data++;
            len--;
            if (len < 6)break;
        }

        for (i = 0; i < 9 && i < len && ggValidChar(data[i]); i++);

        if (i != 8 && i != 6) {
            data++;
            len--;

            continue;
        }

        mem_copy(data, gg_txt->slot[slot].chars, i);

        slot++;
        len -= i;
        data += i;
    }

}

enum {
    GE_EDIT = 0,
    GE_CLR,
    GE_BACK,
    GE_SIZE
};

u8 ggEditor(CheatText *gg_txt, u8 *game_path) {

    u8 i;
    u8 *game_name;
    u8 changed = 0;
    ListBox box;
    ListBox sel;
    u8 * items[GG_SLOTS + 1];
    static u8 * sle_items[] = {"Edit", "Clear", "Back", 0};

    for (i = 0; i < GG_SLOTS; i++) {
        gg_txt->slot[i].chars[8] = 0;
        items[i] = gg_txt->slot[i].chars;
    }
    items[GG_SLOTS] = 0;


    box.hdr = "Cheat Editor";
    box.selector = 0;
    box.items = items;

    sel.hdr = "Code Menu";
    sel.items = sle_items;

    game_name = str_extract_fname(game_path);

    while (1) {

        gCleanScreen();

        gSetPal(PAL_G1);
        gDrawHeader("", G_CENTER);
        gFillRect(' ', 0, G_SCREEN_H - G_BORDER_Y - 2, G_SCREEN_W, 2);
        gAppendString(" This codes will be applied to");
        gSetPal(PAL_G3);
        if (str_lenght(game_name) > MAX_STR_LEN) {
            gSetX(G_BORDER_X);
            gConsPrint_ML(game_name, MAX_STR_LEN - 3);
            gAppendString("...");
        } else {
            gConsPrintCX_ML(game_name, MAX_STR_LEN);
        }



        guiDrawListBox(&box);
        if (box.act == ACT_EXIT)break;

        gCleanScreen();

        sel.selector = 0;
        guiDrawListBox(&sel);
        if (sel.act == ACT_EXIT || sel.selector == GE_BACK)continue;

        if (sel.selector == GE_CLR) {
            changed = 1;
            mem_set(gg_txt->slot[box.selector].chars, '-', 8);
        }

        if (sel.selector == GE_EDIT) {

            changed |= ggEditSlot(&gg_txt->slot[box.selector]);
        }
    }

    return changed;
}

u8 ggEditSlot(TextSlot *slot) {

    u8 changed = 0;
    u8 i;
    u8 x;
    u8 y;
    u8 joy;
    u8 code_pos = 0;
    u8 tbl_pos;
    u8 *code;

    code = slot->chars;
    x = (G_SCREEN_W - 8) / 2;
    y = G_SCREEN_H / 2;

    gCleanScreen();

    while (1) {

        for (i = 0; i < 17; i++) {

            if (code[code_pos] == gg_chars[i]) {
                tbl_pos = i;
                break;
            }
        }

        gSetPal(PAL_G1);
        gFillRect(' ', 0, G_BORDER_Y, G_SCREEN_W, 1);
        gSetY(G_BORDER_Y - 1);
        gConsPrintCX("Press UP/DOWN to change symbol");

        gFillRect(' ', 0, G_SCREEN_H - G_BORDER_Y - 1, G_SCREEN_W, 1);
        gSetXY((G_SCREEN_W - 16) / 2 - 1, G_SCREEN_H - G_BORDER_Y - 1);

        gSetPal(PAL_G3);
        gAppendChar('<');
        for (i = 0; i < 16; i++) {
            gSetPal(i == tbl_pos ? PAL_G2 : PAL_G3);
            gAppendChar(gg_chars[i]);
        }
        gSetPal(PAL_G3);
        gAppendChar('>');

        gSetXY(x, y);

        for (i = 0; i < 8; i++) {
            gSetPal(i == code_pos ? PAL_G2 : PAL_B3);
            gAppendChar(code[i]);
        }

        gRepaint();
        joy = sysJoyWait();

        if (joy == JOY_B)return changed;

        if (joy == JOY_L && code_pos != 0) {
            code_pos--;
        }

        if (joy == JOY_R && code_pos != 7) {
            code_pos++;
        }


        if (joy == JOY_U) {
            tbl_pos = tbl_pos == 16 ? 0 : tbl_pos + 1;
            code[code_pos] = gg_chars[tbl_pos];
            changed = 1;
        }

        if (joy == JOY_D) {
            tbl_pos = tbl_pos == 0 ? 16 : tbl_pos - 1;
            code[code_pos] = gg_chars[tbl_pos];
            changed = 1;
        }

    }



    return 0;
}
