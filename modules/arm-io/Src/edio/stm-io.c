
#include "edio.h"

void gpioWR_port(GPIO_TypeDef *port, u16 pins, u8 state) {



    if (state) {
        port->BSRR = pins;
    } else {
        port->BSRR = (u32) pins << 16;
    }
}

u16 gpioRD_port(GPIO_TypeDef *port, u16 pins) {

    return port->IDR & pins;
}

u16 gpioRD_pin(GPIO_TypeDef *port, u16 pin) {

    if ((port->IDR & pin)) {
        return 1;
    } else {
        return 0;
    }
}

void uartTX(USART_TypeDef *port, u8 *data, u32 len) {

    while (len--) {
        port->DR = *data++;
        while (!(port->SR & USART_SR_TXE));
    }
}

u16 adcToHex(u16 val) {

    u32 dval = val * 3300 / 4095;
    u16 hval = 0;
    u32 tmp;

    tmp = dval % 10000 / 1000;
    hval |= tmp << 8;

    tmp = dval % 1000 / 100;
    hval |= tmp << 4;

    tmp = dval % 100 / 10;
    hval |= tmp;

    return hval;
}

u16 adcRead(u32 chan, u8 samples) {

    u32 val = 0;

    if (chan == LL_ADC_CHANNEL_VBAT) {
        ADC->CCR |= ADC_CCR_VBATE;
        HAL_Delay(25);
    }

    LL_ADC_REG_SetSequencerRanks(ADC1, LL_ADC_REG_RANK_1, chan);
    LL_ADC_SetChannelSamplingTime(ADC1, chan, LL_ADC_SAMPLINGTIME_480CYCLES);
    LL_ADC_Enable(ADC1);

    for (int i = 0; i < samples; i++) {
        LL_ADC_REG_StartConversionSWStart(ADC1);
        while (!LL_ADC_IsActiveFlag_EOCS(ADC1));
        LL_ADC_ClearFlag_EOCS(ADC1);
        val += LL_ADC_REG_ReadConversionData12(ADC1);
    }

    LL_ADC_Disable(ADC1);

    if (chan == LL_ADC_CHANNEL_VBAT) {
        ADC->CCR &= ~ADC_CCR_VBATE;
    }

    val /= samples;
    return val;

}

void wdogRefresh() {

    //HAL_IWDG_Refresh(&hiwdg);
    LL_IWDG_ReloadCounter(IWDG);
}

void rtcGetTime(RtcTime *rtc) {

    volatile u32 time;
    volatile u32 date;


    do {
        time = RTC->TR;
        date = RTC->DR;
    } while (time != RTC->TR || date != RTC->DR);

    rtc->yar = (date >> RTC_DR_YU_Pos) & 0xFF;
    rtc->mon = (date >> RTC_DR_MU_Pos) & 0x1F;
    rtc->dom = (date >> RTC_DR_DU_Pos) & 0x3F;

    rtc->hur = (time >> RTC_TR_HU_Pos) & 0x3F;
    rtc->min = (time >> RTC_TR_MNU_Pos) & 0x7F;
    rtc->sec = (time >> RTC_TR_SU_Pos) & 0x7F;

}

void rtcSetTime(RtcTime *rtc) {

    volatile u32 time = 0;
    volatile u32 date = 0;

    date |= (u32) (rtc->yar & 0xFF) << RTC_DR_YU_Pos;
    date |= (u32) (rtc->mon & 0x1F) << RTC_DR_MU_Pos;
    date |= (u32) (rtc->dom & 0x3F) << RTC_DR_DU_Pos;

    time |= (u32) (rtc->hur & 0x3F) << RTC_TR_HU_Pos;
    time |= (u32) (rtc->min & 0x7F) << RTC_TR_MNU_Pos;
    time |= (u32) (rtc->sec & 0x7F) << RTC_TR_SU_Pos;


    LL_RTC_DisableWriteProtection(RTC);
    LL_RTC_EnterInitMode(RTC);

    LL_RTC_SetHourFormat(RTC, LL_RTC_HOURFORMAT_24HOUR);
    LL_RTC_SetAsynchPrescaler(RTC, 127);
    LL_RTC_SetSynchPrescaler(RTC, 255);

    RTC->TR = time;
    RTC->DR = date;

    LL_RTC_DisableInitMode(RTC);
    LL_RTC_EnableWriteProtection(RTC);
}

void rtcReadBC(u32 *dst, u32 base, u32 num) {

    u32 *rtc_bc_regs = (u32 *) & RTC->BKP0R;

    while (num--) {
        *dst++ = rtc_bc_regs[base++];
    }
}

void rtcWriteBC(u32 *src, u32 base, u32 num) {

    //RTC->WPR = RTC_WRITE_PROTECTION_ENABLE_1;
    //RTC->WPR = RTC_WRITE_PROTECTION_ENABLE_2;
    LL_RTC_DisableWriteProtection(RTC);

    u32 *rtc_bc_regs = (u32 *) & RTC->BKP0R;

    while (num--) {
        rtc_bc_regs[base++] = *src++;
    }

    //RTC->WPR = RTC_WRITE_PROTECTION_DISABLE;
    LL_RTC_EnableWriteProtection(RTC);
}

void rtcPrint() {

    RtcTime rtc;
    rtcGetTime(&rtc);

    dbg_append_h8(rtc.dom);
    dbg_append(".");
    dbg_append_h8(rtc.mon);
    dbg_append(".20");
    dbg_append_h8(rtc.yar);
    dbg_append(" ");

    dbg_append_h8(rtc.hur);
    dbg_append(":");
    dbg_append_h8(rtc.min);
    dbg_append(":");
    dbg_append_h8(rtc.sec);
}