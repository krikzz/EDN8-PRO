/* 
 * File:   link.h
 * Author: igor
 *
 * Created on May 17, 2019, 8:55 PM
 */

#ifndef LINK_H
#define	LINK_H

#define LINK_SRC_AUTO    0
#define LINK_SRC_FIFO    1
#define LINK_SRC_USB     2

void linkInit();
int usbAvailable();
u8 usbRD(u8 *buff, u32 len);
void usbWR(u8 *buff, u32 len);
void usbCallback(u8 *buff, u32 len);
void usbReset();
u8 fifoRD(void *data, u16 len);
void fifoWR(void *data, u16 len);
u8 linkRX(void *data, u16 len);
u8 linkRX_ack(void *data, u16 len);
void linkTX(void *data, u16 len);
void linkResetSrc();
u8 linkGetSrc();
void linkToutSet(u32 timeout);

#endif	/* LINK_H */

