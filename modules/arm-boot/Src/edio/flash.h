/* 
 * File:   flash.h
 * Author: igor
 *
 * Created on May 17, 2019, 8:53 PM
 */

#ifndef FLASH_H
#define	FLASH_H

void cmd_flaRead();
void cmd_flaWrite();
void flaRead(u8 *data, u32 len);
void flaOpenRead(u32 addr);
void flaCloseRD();
void flaGetUID(u8 *uid);


#endif	/* FLASH_H */

