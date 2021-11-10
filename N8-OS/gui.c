
#include "everdrive.h"

void app_guiInit();
void app_guiDrawInfoBox(InfoBox *box);
void app_guiDrawListBox(ListBox *box);
u8 app_guiConfirmBox(u8 *str, u8 def);

void guiInit() {

    u8 bank = REG_APP_BANK;
    REG_APP_BANK = APP_GUI;
    app_guiInit();
    REG_APP_BANK = bank;
}

void guiDrawInfoBox(InfoBox *box) {

    u8 bank = REG_APP_BANK;
    REG_APP_BANK = APP_GUI;
    app_guiDrawInfoBox(box);
    REG_APP_BANK = bank;
}

void guiDrawListBox(ListBox *box) {

    u8 bank = REG_APP_BANK;
    REG_APP_BANK = APP_GUI;
    app_guiDrawListBox(box);
    REG_APP_BANK = bank;
}

u8 guiConfirmBox(u8 *str, u8 def) {

    u8 resp;
    u8 bank = REG_APP_BANK;
    REG_APP_BANK = APP_GUI;
    resp = app_guiConfirmBox(str, def);
    REG_APP_BANK = bank;
    return resp;
}

#pragma codeseg ("BNK06")

enum {
    GS_AR_L = 'z' + 5,
    GS_AR_R,
    GS_AR_U,
    GS_AR_D,
    GS_WIN_H,
    GS_WIN_V,
    GS_WIN_UL,
    GS_WIN_UR,
    GS_WIN_DL,
    GS_WIN_DR,
    GS_WIN_TL,
    GS_WIN_TR,
    GS_WIN_TU,
    GS_WIN_TD,
    GS_LBAR
} g_symbols;

void guiDrawWindow(u8 *hdr, u8 w, u8 h);

u8 PAL_SEL0;
u8 PAL_SEL1;
u8 PAL_INFO;
u8 PAL_BORDER;

void app_guiInit() {

    if (sysVramBug()) {
        PAL_SEL0 = PAL_G1;
        PAL_SEL1 = PAL_B3;
        PAL_INFO = PAL_G3;
        PAL_BORDER = PAL_G1;
    } else {
        PAL_SEL0 = PAL_G1;
        PAL_SEL1 = PAL_G3;
        PAL_INFO = PAL_G3;
        PAL_BORDER = PAL_G1;
    }
}

void guiDrawWindow(u8 *hdr, u8 w, u8 h) {


    u8 x = (G_SCREEN_W - w) / 2;
    u8 y = (G_SCREEN_H - INF_ROWS - h) / 2 + 1; // - ((G_INF_BAR_H - 1) / 2);


    gFillRect(' ', x, y, w, h);

    gFillRow(GS_WIN_H, x, y - 1, w);
    gFillRow(GS_WIN_H, x, y + h, w);

    gFillCol(GS_WIN_V, x - 1, y, h);
    gFillCol(GS_WIN_V, x + w, y, h);

    gSetXY(x - 1, y - 1);
    gAppendChar(GS_WIN_UL);
    gSetX(x + w);
    gAppendChar(GS_WIN_UR);
    gSetY(y + h);
    gAppendChar(GS_WIN_DR);
    gSetX(x - 1);
    gAppendChar(GS_WIN_DL);


    if (hdr != 0) {
        gSetY(y - 2);
        gConsPrintCX(hdr);
    }

    gSetXY(x, y);
}

void app_guiDrawInfoBox(InfoBox *box) {

    u8 i;
    u8 y;
    u8 x;
    u8 str_len;


    if (!box->skip_init) {

        box->max_arg_len = 0;
        box->max_val_len = 0;

        for (i = 0; i < box->items; i++) {

            if (box->val[i] == 0)continue;
            str_len = str_lenght(box->arg[i]);
            if (box->max_arg_len < str_len)box->max_arg_len = str_len;
            str_len = str_lenght(box->val[i]);
            if (box->max_val_len < str_len)box->max_val_len = str_len;
        }

        box->max_arg_len += 1;
        box->max_val_len += 2;
        box->skip_init = 1;
    }

    gSetPal(PAL_BORDER);
    guiDrawWindow(box->hdr, box->max_arg_len + box->max_val_len, box->items * 2 + 1);
    gSetPal(PAL_INFO);

    x = gGetX();
    y = gGetY();

    for (i = 0; i < box->items; i++) {

        if (box->selector != SEL_OFF) {
            gSetPal(box->selector == i ? PAL_SEL1 : PAL_SEL0);
        }

        gConsPrint(box->arg[i]);
        gConsPrint("");
    }

    gSetXY(x + box->max_arg_len, y);
    for (i = 0; i < box->items; i++) {

        if (box->selector != SEL_OFF) {
            gSetPal(box->selector == i ? PAL_SEL1 : PAL_SEL0);
        }

        if (box->val[i] != 0) {
            gConsPrint(": ");
            gAppendString(box->val[i]);
        } else {
            gConsPrint("");
        }
        gConsPrint("");
    }

    gRepaint();


}

void app_guiDrawListBox(ListBox *box) {

    u8 items = 0;
    u8 max_str_len = 0;
    u8 str_len;
    u8 h;
    u8 i;
    u8 joy;
    u8 sel_dpd = box->selector & SEL_DPD;

    box->selector &= ~SEL_DPD;

    while (box->items[items] != 0) {
        str_len = str_lenght(box->items[items]);
        if (max_str_len < str_len)max_str_len = str_len;
        items++;
    }

    str_len = str_lenght(box->hdr);
    if (max_str_len < str_len)max_str_len = str_len;

    h = items * 2 + 1;


    while (1) {

        gSetPal(PAL_BORDER);
        guiDrawWindow(box->hdr, max_str_len, h);

        for (i = 0; i < items; i++) {

            if (box->selector == i) {
                gSetPal(PAL_SEL1);
            } else {
                gSetPal(PAL_SEL0);
            }
            gConsPrintCX(box->items[i]);
            gConsPrint("");
        }

        gRepaint();

        joy = sysJoyWait();

        if (joy == JOY_A) {
            box->act = ACT_OPEN;
            return;
        }

        if (joy == JOY_B) {
            box->act = ACT_EXIT;
            return;
        }

        if ((joy == JOY_L || joy == JOY_R) && sel_dpd) {
            box->act = joy;
            return;
        }

        if (joy == JOY_U) {
            box->selector = box->selector == 0 ? items - 1 : box->selector - 1;
        }

        if (joy == JOY_D) {
            box->selector = box->selector == items - 1 ? 0 : box->selector + 1;
        }


    }

}

u8 app_guiConfirmBox(u8 *str, u8 def) {

    u8 selector = def;
    u8 y, str_len;
    u16 joy;


    str_len = str_lenght(str);


    gSetPal(PAL_BORDER);

    guiDrawWindow(0, str_len, 2 + 1 + 3);

    gSetPal(PAL_G2);
    gConsPrintCX(str);
    gConsPrint("");

    y = gGetY() + 2;
    gSetY(y);

    for (;;) {

        gSetX(G_SCREEN_W / 2 - 4);
        gSetPal(PAL_G1);
        gSetPal((selector == 1 ? PAL_B2 : PAL_G1));
        gAppendString("YES");
        gSetX(G_SCREEN_W / 2);
        gSetPal((selector == 0 ? PAL_B2 : PAL_G1));
        gAppendString("NO");

        gRepaint();
        joy = sysJoyWait();

        if ((joy & JOY_B))return 0;
        if ((joy & JOY_A))return selector;

        if (joy == JOY_R && selector == 1)selector--;
        if (joy == JOY_L && selector == 0)selector++;
    }


}
