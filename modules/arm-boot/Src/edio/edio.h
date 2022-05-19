/* 
 * File:   edio.h
 * Author: igor
 *
 * Created on March 13, 2019, 2:11 AM
 */

#ifndef EDIO_H
#define	EDIO_H

#include <string.h> 
#include "cfg.h"
#include "main.h"
#include "usb_device.h"
#include "usbd_cdc.h"
#include "stm-io.h"
#include "stm-spi.h"
#include "dbg.h"
#include "std.h"
#include "flash.h"
#include "link.h"
#include "error.h"
#include "boot.h"
#include "cmd.h"
#include "signature.h"
#include "mcuprog.h"
#include "var.h"
#include "bootram.h"

typedef struct {
    u8 fla_id[8];
    u8 cpu_id[12];
    u32 serial_g;
    u32 serial_l;
    u32 boot_ctr;
    u32 game_ctr;
    u16 asm_date;
    u16 asm_time;
    u16 sw_ver;
    u16 hv_ver;
    u16 boot_ver;
    u8 device_id;
    u8 manufac_id;
    u8 rst_src;
    u8 boot_status;
    u8 ram_rst;
    u8 disk_status;
    u8 cart_form; //cartridge form factor 0-nes, 1-fami
    u8 pwr_sys;
    u8 pwr_usb;
    u8 reserved[9];
} SysInfoIO;


void edio();
u8 strRX(u8 *buff, u16 max_len);
void strTX(u8 *buff, u16 max_len);
void led(u8 val);




void cmd_status(u8 status);
void cmd_fifo_wr();
void cmd_usb_wr();
void cmd_uart_wr();
void cmd_upd_exec();
void cmd_get_vdc();
u8 cmd_reboot();
void cmd_hard_reset();
void cmd_sys_info();
void cmd_game_ctr();
u8 cmd_init_sd();
void cmd_getMode(u8 mode);
void cmd_rtc_get();
void cmd_rtc_set();

extern SysInfoIO sys_inf;
extern Signature signature;

#endif	/* EDIO_H */

