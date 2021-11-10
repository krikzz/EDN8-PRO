/* 
 * File:   fpga.h
 * Author: igor
 *
 * Created on May 17, 2019, 8:49 PM
 */

#ifndef FPGA_H
#define	FPGA_H

typedef struct {
    u8 cheats[32];
    u8 map_idx;
    u8 prg_msk;
    u8 chr_msk;
    u8 master_vol;
    u8 map_cfg;
    u8 ss_key_save;
    u8 ss_key_load;
    u8 map_ctrl;
} MapConfig;

u8 cmd_fpgInitUSB();
u8 cmd_fpgInitSDC();
u8 cmd_fpgInitFLA();
void cmd_fpgInitCFG();
u8 fpgInitSDC(u32 len, MapConfig *cfg);
u8 fpgInitFLA(u32 addr, MapConfig *cfg);
void fpgHalt();

#endif	/* FPGA_H */

