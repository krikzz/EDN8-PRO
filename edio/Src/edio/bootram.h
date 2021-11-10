/* 
 * File:   bootram.h
 * Author: igor
 *
 * Created on August 28, 2019, 2:24 PM
 */

#ifndef BOOTRAM_H
#define	BOOTRAM_H

typedef struct {
    u32 hdr; //0x45444E38 "EDN8"
    u32 upd_addr;
    u32 upd_crc;
    u32 boot_ctr;
    u32 game_ctr;
    u8 rst_src;
    u8 ram_rst;
    u16 boot_ver;
    u32 reserved;
    u32 crc;
} BootRam; //8x4 rtc backup registers


void bootRamReset();
u8 bootRamLoad(); 
void bootRamSave();
void bootRamRstAck();

extern BootRam boot_ram;

#endif	/* BOOTRAM_H */

