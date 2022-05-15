/* 
 * File:   stm.h
 * Author: igor
 *
 * Created on September 13, 2019, 5:42 PM
 */

#ifndef STM_H
#define	STM_H

typedef struct {
    u8 yar;
    u8 mon;
    u8 dom;
    u8 hur;
    u8 min;
    u8 sec;
} RtcTime;

void gpioWR_port(GPIO_TypeDef *port, u16 pins, u8 state);
u16 gpioRD_port(GPIO_TypeDef *port, u16 pins);
u16 gpioRD_pin(GPIO_TypeDef *port, u16 pin);
void uartTX(USART_TypeDef *port, u8 *data, u32 len);
u16 adcRead(u32 chan, u8 samples);
u16 adcToHex(u16 val);
void wdogRefresh();
void rtcGetTime(RtcTime *rtc);
void rtcSetTime(RtcTime *rtc);
void rtcPrint();
void rtcReadBC(u32 *dst, u32 base, u32 num);
void rtcWriteBC(u32 *src, u32 base, u32 num);

#endif	/* STM_H */

