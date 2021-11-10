
#include "edio.h"

BootRam boot_ram;

u8 bootRamLoad() {

    rtcReadBC((u32 *) & boot_ram, ADDR_RTC_BRAM, sizeof (BootRam) / 4);
    if (boot_ram.hdr != 0x45444E38)return 1; //EDN8
    if (crc32(0, (u8 *) & boot_ram, sizeof (BootRam) - 4) != boot_ram.crc)return 1;

    return 0;
}

void bootRamSave() {

    boot_ram.crc = crc32(0, (u8 *) & boot_ram, sizeof (BootRam) - sizeof (u32));
    rtcWriteBC((u32 *) & boot_ram, ADDR_RTC_BRAM, sizeof (BootRam) / 4);
}

void bootRamReset() {

    dbg_print("bram data: ");
    dbg_append_hex(&boot_ram, 32);

    memset(&boot_ram, 0, sizeof (BootRam));
    boot_ram.hdr = 0x45444E38;
    boot_ram.ram_rst = 1;
    boot_ram.boot_ver = BOOT_VER;
    boot_ram.upd_addr = ~0;
    bootRamSave();
}

void bootRamRstAck() {
    
    if (boot_ram.ram_rst == 0)return;
    boot_ram.ram_rst = 0;
    bootRamSave();
}
