/* 
 * File:   disk.h
 * Author: igor
 *
 * Created on May 18, 2019, 2:45 AM
 */

#ifndef DISK_H
#define	DISK_H

u8 diskInit();
u8 cmd_diskRead();
u8 cmd_diskWrite();
u8 diskRD(void *dst, u32 saddr, u32 slen);
u8 diskWR(void *src, u32 saddr, u32 slen);
u8 diskSync();


#endif	/* DISK_H */

