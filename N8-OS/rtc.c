
#include "main.h"



void app_rtcSetup();
void app_rtcReset();

void rtcSetup() {

    u8 bank = REG_APP_BANK;
    REG_APP_BANK = APP_RTC;
    app_rtcSetup();
    REG_APP_BANK = bank;
}

void rtcReset() {

    u8 bank = REG_APP_BANK;
    REG_APP_BANK = APP_RTC;
    app_rtcReset();
    REG_APP_BANK = bank;
}


#pragma codeseg ("BNK08")

u8 rtcIncHex(u8 val, u8 min, u8 max);
u8 rtcDecHex(u8 val, u8 min, u8 max);

void app_rtcReset() {
    
    RtcTime rtc;
    
    rtc.dom = 0x01;
    rtc.mon = 0x01;
    rtc.yar = 0x18;
    
    rtc.hur = 0x00;
    rtc.min = 0x00;
    rtc.sec = 0x00;
    
    bi_cmd_rtc_set(&rtc);
}

void app_rtcSetup() {

    u8 changed = 0;
    RtcTime rtc;
    u8 *ptr;
    u8 idx;
    u8 selector = 0;
    u16 old_joy = 0;
    u8 joy;
    u8 i;

    static u8 max_val[] = {0x31, 0x12, 0x99, 0x23, 0x59, 0x59};
    static u8 min_val[] = {0x01, 0x01, 0x00, 0x00, 0x00, 0x00};
    static u8 idx_tbl[] = {2, 1, 0, 3, 4, 5};
    static u8 * sep[] = {".", ".20", "-", ":", ":", ""};


    ptr = (u8 *) & rtc;
    while (1) {

        if (!changed) {
            bi_cmd_rtc_get(&rtc);
        }

        gCleanScreen();
        gSetPal(PAL_B2);
        gSetPal(PAL_G1);
        gDrawHeader("RTC setup", G_CENTER);
        gDrawFooter("Push UP/DOWN to change", 1, G_CENTER);

        gSetXY((G_SCREEN_W - 19) / 2, G_SCREEN_H / 2);


        for (i = 0; i < 6; i++) {

            gSetPal(selector == i ? PAL_B3 : PAL_B1);

            idx = idx_tbl[i];
            gAppendHex8(ptr[idx]);
            gSetPal(PAL_B1);

            gAppendString(sep[i]);
        }

        gRepaint();


        if (!changed) {
            old_joy = joy;
            joy = sysJoyRead();
            if (old_joy == joy)continue;
        } else {
            joy = sysJoyWait();
        }


        if (joy == JOY_R) {
            selector = selector == 5 ? 0 : selector + 1;
        }

        if (joy == JOY_L) {
            selector = selector == 0 ? 5 : selector - 1;
        }


        if (joy == JOY_D) {
            idx = idx_tbl[selector];
            ptr[idx] = rtcDecHex(ptr[idx], min_val[selector], max_val[selector]);
            changed = 1;
        }

        if (joy == JOY_U) {
            idx = idx_tbl[selector];
            ptr[idx] = rtcIncHex(ptr[idx], min_val[selector], max_val[selector]);
            changed = 1;
        }

        if (joy == JOY_B || joy == JOY_STA) {
            break;
        }

    }

    if (changed) {
        bi_cmd_rtc_set(&rtc);
    }

}

u8 rtcIncHex(u8 val, u8 min, u8 max) {

    if (val >= max) {
        return min;
    }

    if ((val & 0x0f) == 9) {
        val = (val & 0xf0) + 0x10;
    } else {
        val++;
    }
    return val;
}

u8 rtcDecHex(u8 val, u8 min, u8 max) {

    if (val == min) {
        return max;
    }

    if ((val & 0x0f) == 0) {
        val = ((val & 0xf0) - 0x10) | 0x09;
    } else {
        val--;
    }
    return val;
}