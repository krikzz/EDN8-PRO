/* 
 * File:   boot.h
 * Author: igor
 *
 * Created on July 12, 2019, 8:08 PM
 */

#ifndef BOOT_H
#define	BOOT_H

#define RST_SRC_POR     0 //power on
#define RST_SRC_WDG     1
#define RST_SRC_SWR     2
#define RST_SRC_PIN     3
#define RST_SRC_PWR     4 //low power or brown out
#define RST_SRC_UNK     5 


void bootloader(u8 usb);
u8 coreUpdate();
void runApp(u32 addr);
u8 isServiceMode();


#endif	/* BOOT_H */

