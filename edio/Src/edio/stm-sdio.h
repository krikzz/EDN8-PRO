/* 
 * File:   stm-sdio.h
 * Author: igor
 *
 * Created on September 15, 2019, 4:50 PM
 */

#ifndef STM_SDIO_H
#define	STM_SDIO_H

u8 sdInit();
u8 sdRead(void *dst, u32 saddr, u32 slen);
u8 sdWrite(void *src, u32 saddr, u32 slen);
u8 sdCloseRW();

#endif	/* STM_SDIO_H */

