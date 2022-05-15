
#include "edio.h"
#include "main.h"

typedef struct {
    u32 fla_size;
    u32 fla_crc_calc;
    u32 fla_crc_read;
    u32 mcu_crc;
} UpdInfo;


u8 getUpdInfo(UpdInfo *inf, u32 fla_addr);
u8 coreUpdate_int();

#define RST_SRC_POR     0 //power on
#define RST_SRC_WDG     1
#define RST_SRC_SWR     2
#define RST_SRC_PIN     3
#define RST_SRC_PWR     4 //low power or brown out
#define RST_SRC_UNK     5 

u8 usb_service;

void bootloader(u8 usb) {

    u8 resp;
    static char * rst_src_str[] = {"POR", "WDG", "SWR", "PIN", "PWR", "UNK"};
    usb_service = usb;

    dbg_print("--------------------------------");
    dbg_print("N8 Bootloader v");
    dbg_append_num(BOOT_VER >> 8);
    dbg_append(".");
    dbg_append_h8(BOOT_VER & 0xff);
    dbg_print("System time: ");
    rtcPrint();

    resp = bootRamLoad();
    if (resp) {
        dbg_print("bram reset");
        bootRamReset();
    }

    //rtc_bc_wr((u32 *) ADDR_PFL_EDSG, ADDR_RTC_EDSG, 8);

    if (__HAL_RCC_GET_FLAG(RCC_FLAG_LPWRRST)) {
        boot_ram.rst_src = RST_SRC_PWR;
    } else if (__HAL_RCC_GET_FLAG(RCC_FLAG_WWDGRST)) {
        boot_ram.rst_src = RST_SRC_WDG;
    } else if (__HAL_RCC_GET_FLAG(RCC_FLAG_IWDGRST)) {
        boot_ram.rst_src = RST_SRC_WDG;
    } else if (__HAL_RCC_GET_FLAG(RCC_FLAG_SFTRST)) {
        boot_ram.rst_src = RST_SRC_SWR;
    } else if (__HAL_RCC_GET_FLAG(RCC_FLAG_PORRST)) {
        boot_ram.rst_src = RST_SRC_POR;
    } else if (__HAL_RCC_GET_FLAG(RCC_FLAG_PINRST)) {
        boot_ram.rst_src = RST_SRC_PIN;
    } else if (__HAL_RCC_GET_FLAG(RCC_FLAG_BORRST)) {
        boot_ram.rst_src = RST_SRC_PWR;
    } else {
        boot_ram.rst_src = RST_SRC_UNK;
    }
    __HAL_RCC_CLEAR_RESET_FLAGS();

    if (boot_ram.rst_src == RST_SRC_POR) boot_ram.boot_ctr++;

    if (boot_ram.rst_src != RST_SRC_SWR) {
        boot_ram.upd_crc = 0;
        boot_ram.upd_addr = ~0;
    }

    bootRamSave();

    dbg_print("rset src: ");
    dbg_append(rst_src_str[boot_ram.rst_src]);
    dbg_print("boot ctr: ");
    dbg_append_num(boot_ram.boot_ctr);
    dbg_print("game ctr: ");
    dbg_append_num(boot_ram.game_ctr);

    dbg_print("--------------------------------");


    if (usb_service) {
        usbService();
    }

    //recovery();


    if (boot_ram.upd_crc != 0) {
        spiInit();
        coreUpdate();
        runApp(ADDR_PFL_APP);
    } else {
        runApp(ADDR_PFL_APP);
    }
}

u8 coreUpdate() {

    u8 resp;

    led(1);

    __disable_irq();

    resp = coreUpdate_int();
    if (resp) {
        dbg_print("upd error: 0x");
        dbg_append_h8(resp);
    }
    __enable_irq();

    return resp;
}

u8 coreUpdate_int() {

    UpdInfo inf;
    u8 resp;
    u32 upd_addr = boot_ram.upd_addr;
    u32 upd_crc = boot_ram.upd_crc;

    boot_ram.upd_crc = 0;
    boot_ram.upd_addr = ~0;
    bootRamSave();

    dbg_print("Update core...");
    dbg_print("upd adr: 0x");
    dbg_append_h32(upd_addr);

    resp = getUpdInfo(&inf, upd_addr);
    if (resp)return resp;

    dbg_print("upd siz: 0x");
    dbg_append_h32(inf.fla_size);
    dbg_print("cur crc: 0x");
    dbg_append_h32(inf.mcu_crc);
    dbg_print("new crc: 0x");
    dbg_append_h32(inf.fla_crc_calc);
    dbg_print("req crc: 0x");
    dbg_append_h32(upd_crc);


    if (inf.fla_crc_calc != upd_crc)return ERR_UPD_BT_CRC;

    dbg_print("mcu erase...");

    mcuEraseCore();

    dbg_print("mcu prog...");
    mcuProgCore(upd_addr + 8, inf.fla_size);


    u32 mcu_crc = crc32(0, (u8 *) ADDR_PFL_APP, inf.fla_size);
    dbg_print("mcu crc : 0x");
    dbg_append_h32(mcu_crc);
    if (inf.fla_crc_calc != mcu_crc)return ERR_UPD_VERIFY;
    //add crc chech here

    dbg_print("update complete");

    return 0;

}

u8 getUpdInfo(UpdInfo *inf, u32 fla_addr) {

    u32 block;
    u8 buff[256];
    u32 len;

    flaOpenRead(fla_addr);
    flaRead((u8 *) & inf->fla_size, 4);
    flaRead((u8 *) & inf->fla_crc_read, 4);
    flaCloseRD();

    if (inf->fla_size > MAX_UPD_SIZE)return ERR_UPD_SIZE;

    flaOpenRead(fla_addr + 8);
    cryptInit();
    len = inf->fla_size;
    inf->fla_crc_calc = 0;
    while (len) {
        block = sizeof (buff);
        if (block > len)block = len;
        flaRead(buff, block);
        decrypt(buff);
        inf->fla_crc_calc = crc32(inf->fla_crc_calc, buff, block);
        len -= block;
    }

    flaCloseRD();

    if (inf->fla_crc_read != inf->fla_crc_calc)return ERR_UPD_CORUPT;

    inf->mcu_crc = crc32(0, (u8 *) ADDR_PFL_APP, inf->fla_size);

    if (inf->fla_crc_calc == inf->mcu_crc)return ERR_UPD_SAME;

    return 0;
}

extern USBD_HandleTypeDef hUsbDeviceFS;

void runApp(u32 addr) {

    u32 *rst_addr = (u32 *) (addr + 4);
    void (*jmp) (void) = (void *) *rst_addr;

    if (usb_service) {
        USBD_Stop(&hUsbDeviceFS);
    }

    jmp();
}

u8 isServiceMode() {
    u8 sys_pwr = gpioRD_pin(pwr_sys_GPIO_Port, pwr_sys_Pin);
    u8 usb_pwr = gpioRD_pin(pwr_usb_GPIO_Port, pwr_usb_Pin);
    if (sys_pwr == 0 && usb_pwr != 0)return 1;
    return 0;
}
