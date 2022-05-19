/* 
 * File:   mcuprog.h
 * Author: igor
 *
 * Created on August 28, 2019, 1:56 PM
 */

#ifndef MCUPROG_H
#define	MCUPROG_H

void mcuEraseCore();
void mcuProgCore(u32 fla_addr, u32 len);
void mcuProgData(u8 *src, u32 dst, u32 len);
void mcuSecure();

#endif	/* MCUPROG_H */

