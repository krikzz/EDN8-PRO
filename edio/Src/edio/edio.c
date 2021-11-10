

#include <string.h>

#include "edio.h"
#include "../ff/ff.h"


#define MAP_CTRL_UNLOCK 0x80

typedef struct {
    u16 v50;
    u16 v25;
    u16 v12;
    u16 vbt;
} Vdc;


void edioInit();
u8 nesBoot();
u8 loadOS_sdc();
u8 loadOS_flash();
void sysInfoUpd();

//extern IWDG_HandleTypeDef hiwdg;
//extern SD_HandleTypeDef hsd;
extern BootRam boot_ram;


SysInfoIO sys_inf;

void tst() {

    u8 buff[512];
    u16 crc[4];

    for (int i = 0; i < 512; i++)buff[i] = i;

    u32 time = HAL_GetTick();
    for (int i = 0; i < 0x100000; i += 512) {
        crc16SD_SW(buff, crc);
    }

    time = HAL_GetTick() - time;

    dbg_print("crc time: ");
    dbg_append_num(time);

    dbg_print("crc: ");
    dbg_append_hex(crc, 8);

}

void edio() {

    u8 resp = 0;
    edioInit();

    //u8 buff[512];
    //tst();

    if (sys_inf.rst_src == RST_SRC_WDG) {
        resp = cmd_init_sd();
    } else {
        resp = nesBoot();
    }

    cmdProcessor(resp);

}

void edioInit() {

    spiInit();
    linkInit();

    memset(&sys_inf, 0, sizeof (SysInfoIO));
    sigInit();
    bootRamLoad();
    sysInfoUpd();
    sys_inf.sw_ver = EDIO_VER;
    *((u32 *) & sys_inf.cpu_id[0]) = ((u32 *) UID_BASE)[0];
    *((u32 *) & sys_inf.cpu_id[4]) = ((u32 *) UID_BASE)[1];
    *((u32 *) & sys_inf.cpu_id[8]) = ((u32 *) UID_BASE)[2];

    memcpy(sys_inf.fla_id, signature.flash_uid, sizeof (sys_inf.fla_id));
    sys_inf.asm_date = signature.date;
    sys_inf.asm_time = signature.time;
    sys_inf.serial_g = signature.serial_g;
    sys_inf.serial_l = signature.serial_l;
    sys_inf.hv_ver = signature.hv_rev;
    sys_inf.device_id = signature.device_id;
    sys_inf.manufac_id = signature.manufac_id;


    dbg_print("EDIO v");
    dbg_append_num(EDIO_VER >> 8);
    dbg_append(".");
    dbg_append_h8(EDIO_VER & 0xff);

    dbg_print("DEV mode: ");
    dbg_append_h8(signature.dev_mode);
    if (signature.dev_mode) {
        //dbg_append(".");
        //dbg_append_h8(signature.valid);
    }

    wdogRefresh();


    //__HAL_RCC_CLEAR_RESET_FLAGS();
}

void sysInfoUpd() {

    sys_inf.game_ctr = boot_ram.game_ctr;
    sys_inf.rst_src = boot_ram.rst_src;
    sys_inf.boot_ctr = boot_ram.boot_ctr;
    sys_inf.boot_ver = boot_ram.boot_ver;
    sys_inf.ram_rst = boot_ram.ram_rst;

    sys_inf.cart_form = gpioRD_pin(cart_ff_GPIO_Port, cart_ff_Pin); //0=nes,1=fami
    sys_inf.pwr_sys = gpioRD_pin(pwr_sys_GPIO_Port, pwr_sys_Pin);
    sys_inf.pwr_usb = gpioRD_pin(pwr_usb_GPIO_Port, pwr_usb_Pin);
}

u8 loadOS_sdc() {

    u8 resp;
    FILINFO inf;
    MapConfig cfg = {0};

    cfg.map_idx = 255;

    resp = cmd_init_sd();
    if (resp)return resp;

    resp = f_stat(PATH_MAP, &inf);
    if (resp)return resp;

    resp = fileOpen((u8 *) PATH_MAP, FA_READ);
    if (resp)return resp;

    resp = fpgInitSDC(inf.fsize, &cfg);
    if (resp)return resp;

    resp = fileOpen((u8 *) PATH_OS, FA_READ);
    if (resp)return resp;

    resp = fileRead_mem(ADDR_OS_PRG, 16);
    if (resp)return resp;

    resp = fileRead_mem(ADDR_OS_PRG, SIZE_OS_PRG);
    if (resp)return resp;

    resp = fileRead_mem(ADDR_OS_CHR, SIZE_OS_CHR);
    if (resp)return resp;

    resp = fileClose();
    if (resp)return resp;

    cfg.map_ctrl = MAP_CTRL_UNLOCK;
    memOpenWrite(ADDR_CFG);
    memWrite(&cfg, sizeof (MapConfig));
    memCloseRW();

    return 0;
}

u8 loadOS_flash() {

    u8 resp;
    MapConfig cfg = {0};
    cfg.map_idx = 255;

    resp = fpgInitFLA(ADDR_FLA_FPGA, &cfg);
    if (resp)return resp;

    flaOpenRead(ADDR_FLA_MENU + 8 + 16);
    //flaRead_mem(ADDR_OS_PRG, 16);
    flaRead_mem(ADDR_OS_PRG, SIZE_OS_PRG);
    flaRead_mem(ADDR_OS_CHR, SIZE_OS_CHR);
    flaCloseRD();

    cfg.map_ctrl = MAP_CTRL_UNLOCK;
    memOpenWrite(ADDR_CFG);
    memWrite(&cfg, sizeof (MapConfig));
    memCloseRW();

    return 0;
}

u8 nesBoot() {

    u8 resp;

    resp = loadOS_sdc();
    dbg_print("SDC boot: ");
    dbg_append_h8(resp);
    dbg_append(".");
    dbg_append_h8(sys_inf.disk_status);

    sys_inf.boot_status = resp;
    if (resp)resp = ERR_BOOT_FAULT;

    if (resp) {
        u8 fresp;
        fresp = loadOS_flash();
        dbg_print("FLA boot: ");
        dbg_append_h8(fresp);
    }

    return resp;
}

u8 cmd_init_sd() {

    u8 resp;

    //resp = diskInit();
    //if (resp)return resp;

    resp = fatInit();
    if (resp)return resp;

    return 0;
}

u8 strRX(u8 *buff, u16 max_len) {

    u16 len = 0;
    linkRX(&len, 2);
    if (len > max_len)return ERR_STR_SIZE;
    linkRX(buff, len);
    buff[len] = 0;

    return 0;
}

void strTX(u8 *buff, u16 max_len) {

    u16 str_len = str_lenght(buff);

    if (str_len > max_len)str_len = max_len;
    linkTX(&str_len, 2);
    linkTX(buff, str_len);
}

void led(u8 val) {

    //HAL_GPIO_WritePin(led_GPIO_Port, led_Pin, val);
    if (val) {
        led_GPIO_Port->ODR |= GPIO_PIN_5;
    } else {
        led_GPIO_Port->ODR &= ~GPIO_PIN_5;
    }
    //HAL_GPIO_WritePin(gpio1_GPIO_Port, gpio1_Pin, val);
}



//******************************************************************************
//******************************************************************************

void cmd_status(u8 status) {

    u16 val = 0xA500 | status;
    linkTX(&val, 2);
}

void cmd_fifo_wr() {

    u16 len;
    u32 block;
    u8 buff[512];

    linkRX(&len, 2);

    while (len) {

        block = sizeof (buff);

        if (block > len)block = len;
        len -= block;
        linkRX(buff, block);
        fifoWR(buff, block);
    }

}

void cmd_usb_wr() {

    u16 len;
    u32 block;
    u8 buff[512];

    linkRX(&len, 2);

    while (len) {

        block = sizeof (buff);

        if (block > len)block = len;
        len -= block;
        linkRX(buff, block);
        usbWR(buff, block);
    }
}

void cmd_uart_wr() {

    u16 len;
    u32 block;
    u8 buff[512];

    linkRX(&len, 2);

    while (len) {

        block = sizeof (buff);
        if (block > len)block = len;
        len -= block;
        linkRX(buff, block);
        dbg_tx_data(buff, block);
    }
}

void cmd_upd_exec() {

    u8 tmp;
    u32 addr, crc;

    linkRX(&addr, 4);
    linkRX(&crc, 4);
    linkRX(&tmp, 1); //exec

    boot_ram.upd_addr = addr;
    boot_ram.upd_crc = crc;
    bootRamSave();

    NVIC_SystemReset();
}

void cmd_get_vdc() {

    Vdc vdc;
    u8 samples = 10;

    memset(&vdc, 0, sizeof (Vdc));

    //HAL_ADC_Init(&hadc1);


    vdc.v50 = adcRead(LL_ADC_CHANNEL_3, samples);
    vdc.v25 = adcRead(LL_ADC_CHANNEL_11, samples);
    vdc.v12 = adcRead(LL_ADC_CHANNEL_10, samples);
    vdc.vbt = adcRead(LL_ADC_CHANNEL_VBAT, samples);

    ADC->CCR &= ~ADC_CCR_VBATE;

    vdc.v50 = adcToHex(vdc.v50 * 2);
    vdc.v25 = adcToHex(vdc.v25);
    vdc.v12 = adcToHex(vdc.v12);
    vdc.vbt = adcToHex(vdc.vbt * 4);

    linkTX(&vdc, sizeof (Vdc));

}

u8 cmd_reboot() {

    u8 ack;
    linkRX(&ack, 1); //exec
    return nesBoot();
}

void cmd_hard_reset() {
    u8 ack;
    linkRX(&ack, 1); //exec
    NVIC_SystemReset();
}

void cmd_sys_info() {

    sysInfoUpd();
    linkTX(&sys_inf, sizeof (SysInfoIO));
}

void cmd_game_ctr() {

    boot_ram.game_ctr++;
    bootRamSave();
    sysInfoUpd();
}

void cmd_getMode(u8 mode) {

    linkTX(&mode, 1);
}

void cmd_rtc_get() {

    RtcTime rtc;
    rtcGetTime(&rtc);
    linkTX(&rtc, sizeof (RtcTime));
}

void cmd_rtc_set() {

    RtcTime rtc;
    linkRX(&rtc, sizeof (RtcTime));
    rtcSetTime(&rtc);
}