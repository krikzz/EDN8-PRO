/* 
 * File:   rom-info.h
 * Author: igor
 *
 * Created on August 17, 2019, 1:41 PM
 */

#ifndef ROM_INFO_H
#define	ROM_INFO_H

#define MIR_HOR 'H'
#define MIR_VER 'V'
#define MIR_4SC '4'
#define MIR_1SC '1'

#define ROM_TYPE_NES    0x01
#define ROM_TYPE_FDS    0x02

typedef struct {
    u32 prg_size;
    u32 chr_size;
    u32 srm_size;
    u32 crc;
    u32 dat_base;
    u8 chr_ram;
    u8 mir_mode;
    u8 bat_ram;
    u8 mapper;
    u8 submap;
    u8 supported;
    u8 map_pack;
    u8 rom_type;
    u8 usb_game;
    u8 prg_save;
    u8 nes20;
    u8 reserved;
} RomInfo;


u8 getRomInfo(RomInfo *inf, u8 *path);

#endif	/* ROM_INFO_H */

