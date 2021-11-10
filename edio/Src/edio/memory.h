/* 
 * File:   memory.h
 * Author: igor
 *
 * Created on May 17, 2019, 8:56 PM
 */

#ifndef MEMORY_H
#define	MEMORY_H

void cmd_memWR();
void cmd_memRD();
void cmd_memSet();
void cmd_memTst();
void cmd_memCRC();

void memOpenRead(u32 addr);
void memOpenWrite(u32 addr);
void memCloseRW();
void memRead(void *dst, u32 len);
void memWrite(void *src, u32 len);
void memWriteDMA(void *src, u32 len);


#endif	/* MEMORY_H */

