
#include "everdrive.h"

void app_volOptions();
void app_volSetDefaults();
u8 app_volGetMasterVol(u8 map_idx);

void volOptions() {

    u8 bank = REG_APP_BANK;
    REG_APP_BANK = APP_VOL;
    app_volOptions();
    REG_APP_BANK = bank;
}

u8 volGetMasterVol(u8 map_idx) {

    u8 resp;
    u8 bank = REG_APP_BANK;
    REG_APP_BANK = APP_VOL;
    resp = app_volGetMasterVol(map_idx);
    REG_APP_BANK = bank;
    return resp;
}

void volSetDefaults() {

    u8 bank = REG_APP_BANK;
    REG_APP_BANK = APP_VOL;
    app_volSetDefaults();
    REG_APP_BANK = bank;
}


#pragma codeseg ("BNK08")



#define VOL_TBL_SIZE (sizeof(snd_map) / sizeof(snd_map[0]))
#define VOL_PRESETS (sizeof(vol_presets) / sizeof(vol_presets[0]))
#define VOL_PRESET_USR  0xff

u8 volGetPreset(u8 *src);

typedef struct {
    u8 map_idx;
    u8 *map_name;
} SndMap;


const SndMap snd_map[] = {

    {MAP_FDS, "FDS"},
    {MAP_VRC6, "VRC6"},
    {MAP_VRC7, "VRC7"},
    {MAP_N163, "Namco-163"},
    {MAP_MMC5, "MMC5"},
    {MAP_SU5B, "Sunsoft-5B"},
};

typedef struct {
    u8 vol[VOL_TBL_SIZE];
    u8 *name;
} SndSet;
/*
Original Famicom
FDS: 55%
VRC6: 105%
VRC7 160%
163: 60%
MMC5: 60%
5B: 80%

AV Famicom
FDS: 32%
VRC6: 60%
VRC7 100%
163: 35%
MMC5: 35%
5B: 46%
*/
SndSet vol_presets[] = {

    {//  FDS VRC6 VRC7 N163 MMC5 SS5B 
        {32, 60, 100, 35, 35, 46}, "Famicom AV" //-4.7dB
    },
    {
        {55, 105, 150, 60, 60, 80}, "Famicom Original"
    },
    {
        {48, 93, 141, 53, 53, 70}, "NES 47K Mod"//-1.05dB
    }
};

void app_volOptions() {

    InfoBox box;
    u8 * arg[VOL_TBL_SIZE];
    u8 * val[VOL_TBL_SIZE];
    u8 *opt = registery->options.vol_tbl;
    u8 *buff; //[64]; //replace to malloc if VOL_TBL_SIZE will rise
    u8 i;
    u8 joy;
    u32 vol;
    u8 *ptr;
    u8 preset;

    buff = malloc(128);
    gCleanScreen();

    box.hdr = "Volume Control";
    box.arg = arg;
    box.val = val;
    box.selector = 0;
    box.items = VOL_TBL_SIZE;
    box.skip_init = 0;

    //volLoadOptions(registery->options.vol_tbl, opt);

    for (i = 0; i < VOL_TBL_SIZE; i++) {
        arg[i] = snd_map[i].map_name;
    }

    gSetPal(PAL_G2);
    gDrawHeader("Push SELECT to load presets", G_CENTER);
    preset = volGetPreset(opt);

    while (1) {


        gSetPal(PAL_G1);
        gDrawFooter("-Current preset-", 2, G_CENTER);
        gSetPal(PAL_G3);
        if (preset > VOL_PRESETS) {
            gConsPrintCX("User defined");
        } else {
            gConsPrintCX(vol_presets[preset].name);
        }

        ptr = buff;
        for (i = 0; i < VOL_TBL_SIZE; i++) {

            val[i] = ptr;
            *ptr = 0;

            vol = opt[i];

            if (vol == 0) {
                ptr = str_append(ptr, "mute");
            } else {
                if (vol < 10)ptr = str_append(ptr, " ");
                if (vol < 100)ptr = str_append(ptr, " ");
                ptr = str_append_num(ptr, vol);
                ptr = str_append(ptr, "%");
            }
            ptr++;
        }

        guiDrawInfoBox(&box);
        joy = sysJoyWait();


        if (joy == JOY_B) {
            break;
        }

        if (joy == JOY_U) {
            box.selector = dec_mod(box.selector, VOL_TBL_SIZE);
        }

        if (joy == JOY_D) {
            box.selector = inc_mod(box.selector, VOL_TBL_SIZE);
        }

        if (joy == JOY_L) {
            opt[box.selector] = dec_mod(opt[box.selector], 200);
            preset = VOL_PRESET_USR;
        }

        if (joy == JOY_R) {
            opt[box.selector] = inc_mod(opt[box.selector], 200);
            preset = VOL_PRESET_USR;
        }

        if (joy == JOY_SEL) {

            if (preset == VOL_PRESET_USR) {
                preset = 0;
            } else {
                preset = inc_mod(preset, VOL_PRESETS);
            }

            mem_copy(vol_presets[preset].vol, opt, VOL_TBL_SIZE);
            preset = volGetPreset(opt);

        }

    }

    free(128);
    //volSaveOptions(opt, registery->options.vol_tbl);

}

u8 volGetPreset(u8 *src) {

    u8 i;

    for (i = 0; i < VOL_PRESETS; i++) {
        if (mem_cmp(vol_presets[i].vol, src, VOL_TBL_SIZE))return i;
    }

    return VOL_PRESET_USR;
}

void app_volSetDefaults() {

    mem_set(registery->options.vol_tbl, 100, sizeof (registery->options.vol_tbl));
    mem_copy(vol_presets[0].vol, registery->options.vol_tbl, VOL_TBL_SIZE);
}

u8 app_volGetMasterVol(u8 map_idx) {

    u8 i;
    u32 vol = 100;

    if (map_idx == 26)map_idx = 24; //VRC6 variation

    for (i = 0; i < VOL_TBL_SIZE; i++) {
        if (snd_map[i].map_idx == map_idx)vol = registery->options.vol_tbl[i];
    }

    vol = vol * 128 / 100;

    return vol;
}