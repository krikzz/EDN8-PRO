
#include "edio.h"


#ifdef DISK_HAL


extern SD_HandleTypeDef hsd;

u8 sdInit() {

    u8 resp;

    hsd.Instance = SDIO;
    hsd.Init.ClockEdge = SDIO_CLOCK_EDGE_RISING;
    hsd.Init.ClockBypass = SDIO_CLOCK_BYPASS_ENABLE;
    hsd.Init.ClockPowerSave = SDIO_CLOCK_POWER_SAVE_DISABLE;
    hsd.Init.BusWide = SDIO_BUS_WIDE_1B;
    hsd.Init.HardwareFlowControl = SDIO_HARDWARE_FLOW_CONTROL_ENABLE;
    hsd.Init.ClockDiv = 0;


    resp = HAL_SD_Init(&hsd);
    if (resp)return DISK_ERR_INIT;

    resp = HAL_SD_ConfigWideBusOperation(&hsd, SDIO_BUS_WIDE_4B);
    if (resp)return DISK_ERR_INIT + 1;


    return 0;
}

u8 sdRead(void *dst, u32 saddr, u32 slen) {


    u8 resp;

    wdogRefresh();

    resp = HAL_SD_ReadBlocks_DMA(&hsd, dst, saddr, slen);
    if (resp) {
        return DISK_ERR_RD1;
    }
    if (hsd.State == HAL_SD_STATE_ERROR)return DISK_ERR_WR2;
    if (hsd.State == HAL_SD_STATE_TIMEOUT)return DISK_ERR_WR3;
    if (hsd.State == HAL_SD_STATE_RESET)return DISK_ERR_WR4;
    while (hsd.State != HAL_SD_STATE_READY);

    return 0;
}

u8 sdWrite(void *src, u32 saddr, u32 slen) {

    u8 resp;
    //resp = HAL_SD_ReadBlocks(&hsd, dst, saddr, slen, 1000);
    wdogRefresh();
    return 0;
    //dbg_print("disk WR");


    resp = HAL_SD_WriteBlocks(&hsd, src, saddr, slen, HAL_MAX_DELAY);
    if (resp) {
        return DISK_ERR_WR1;
    }

    while (1) {
        HAL_SD_CardStateTypeDef state = HAL_SD_GetCardState(&hsd);
        if (state == HAL_SD_CARD_TRANSFER)break;
        if (state != HAL_SD_CARD_PROGRAMMING) {
            return DISK_ERR_WR2;
        }
    }


    return 0;
}

#endif