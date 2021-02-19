/* 
 * File:   sys.h
 * Author: igor
 *
 * Created on March 28, 2019, 5:24 PM
 */

#ifndef SYS_H
#define	SYS_H

#define JOY_PORT1       *((u8 *)0x4016)
#define JOY_PORT2       *((u8 *)0x4017)
#define PPU_CTRL        *((u8 *)0x2000)
#define PPU_MASK        *((u8 *)0x2001)
#define PPU_STAT        *((u8 *)0x2002)
#define PPU_OAMA        *((u8 *)0x2003)
#define PPU_OAMD        *((u8 *)0x2004)
#define PPU_ADDR        *((u8 *)0x2006)
#define PPU_DATA        *((u8 *)0x2007)
#define PPU_SCROLL      *((u8 *)0x2005)

#define JOY_U           0x08
#define JOY_D           0x04
#define JOY_L           0x02
#define JOY_R           0x01
#define JOY_SEL         0x20
#define JOY_STA         0x10
#define JOY_B           0x40
#define JOY_A           0x80


void sysInit();
void ppuOFF();
void ppuON();
void ppuSetScroll(u8 x, u8 y);
void sysPalInit(u8 fade_to_black);
void sysVsync();
u8 sysVramBug();
u8 sysJoyRead();
u8 sysJoyRead_raw();
u8 sysJoyWait();

#endif	/* SYS_H */

