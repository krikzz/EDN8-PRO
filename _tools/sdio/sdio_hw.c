
#include "edio.h"
#include "diskio.h"
#include <string.h>

#ifdef DISK_HW

#define CMD0    (NORESP | 0) //software reset
#define CMD2    (LORESP | 2) //read cid
#define CMD3    (SHRESP | 3) //get rca
#define CMD6    (SHRESP | 6) //funcs. set hi speed
#define ACMD6   (SHRESP | 6) //set bus width
#define CMD7    (SHRESP | 7) //set transfer mode
#define CMD8    (SHRESP | 8) //read cid
#define CMD9    (LORESP | 9) //read csi
#define CMD12   (SHRESP | 12) //stop transmission
#define CMD13   (SHRESP | 13) //check status
#define CMD16   (SHRESP | 16) //set block size
#define CMD17   (NORESP | 17) //rd single block
#define CMD18   (NORESP | 18) //rd multi block
#define CMD24   (SHRESP | 24) //wr single block
#define CMD25   (SHRESP | 25) //wr multi block
#define	ACMD41  (SHRESP | 41)
#define	ACMD42  (SHRESP | 42)
#define	CMD55   (SHRESP | 55)

//****************************************************************************** hardware config
#define SD_CLK_PORT     GPIOC
#define SD_CLK_PIN      GPIO_PIN_12

#define SD_CMD_PORT     GPIOD
#define SD_CMD_PIN      GPIO_PIN_2
#define SD_CMD_INP      SD_CMD_PORT->MODER &= ~(3 << (2 * 2))
#define SD_CMD_OUT      SD_CMD_PORT->MODER |= (1 << (2 * 2))

#define SD_DAT_PORT     GPIOC
#define SD_DAT_PINS     (SD_DAT_PIN0 | SD_DAT_PIN1 | SD_DAT_PIN2 | SD_DAT_PIN3)
#define SD_DAT_PIN0     GPIO_PIN_8
#define SD_DAT_PIN1     GPIO_PIN_9
#define SD_DAT_PIN2     GPIO_PIN_10
#define SD_DAT_PIN3     GPIO_PIN_11
#define SD_DAT_INP      SD_DAT_PORT->MODER &= ~((3 << (2 * 8)) | (3 << (2 * 9)) | (3 << (2 * 10)) | (3 << (2 * 11)))
#define SD_DAT_OUT      SD_DAT_PORT->MODER |= (1 << (2 * 8)) | (1 << (2 * 9)) | (1 << (2 * 10)) | (1 << (2 * 11))

//****************************************************************************** var
#define SDIO_ICR_STATIC         ((uint32_t)(SDIO_ICR_CCRCFAILC | SDIO_ICR_DCRCFAILC | SDIO_ICR_CTIMEOUTC | \
                                SDIO_ICR_DTIMEOUTC | SDIO_ICR_TXUNDERRC | SDIO_ICR_RXOVERRC  | \
                                SDIO_ICR_CMDRENDC  | SDIO_ICR_CMDSENTC  | SDIO_ICR_DATAENDC  | \
                                SDIO_ICR_DBCKENDC))
#define NORESP  0x00
#define SHRESP  0x40
#define LORESP  0xC0

#define DISK_MODE_NOP   0
#define DISK_MODE_RD    1
#define DISK_MODE_WR    2
#define DISK_INI_TOUT   500 //init tout
#define DISK_RDX_TOUT   (24000000 / 1000 * 200) // 200ms at 24Mhz
#define DISK_WRX_TOUT   (24000000 / 1000 * 500) // 500ms at 24Mhz

#define DIR_MEM_TO_SD   0x00
#define DIR_SD_TO_MEM   0x02
#define BUS_1BIT        0 // 1-bit wide bus (SDIO_D0 used)
#define BUS_4BIT        SDIO_CLKCR_WIDBUS_0 // 4-bit wide bus (SDIO_D[3:0] used)
#define BUS_8BIT        SDIO_CLKCR_WIDBUS_1 // 8-bit wide bus (SDIO_D[7:0] used)

#define STATUS_MSK      0x1E00
#define STATUS_RCV      (0x06 << 9)
#define STATUS_PRG      (0x07 << 9)

#define SDC_DAT_RDY     (1 << 8)
#define OCR_PWR_RDY     (1 << 31)
#define OCR_PWR_CCS     (1 << 30)
#define OCR_VCC_3V3     (1 << 21)
#define OCR_VCC_3V2     (1 << 20)

#define CARD_TYPE_V1    0
#define CARD_TYPE_V2    1
#define CARD_TYPE_HC    2

#define SPD_186KHZ      0x0FF
#define SPD_400KHZ      0x076
#define SPD_08MHZ       0x004
#define SPD_16MHZ       0x001
#define SPD_24MHZ       0x000
#define SPD_48MHZ       0x100

typedef struct {
    u32 cur_addr;
    u32 rca;
    u32 resp[4];
    u8 card_type;
    u8 disk_mode;
} SdState;

void sdInitPorts();
void sdSetSpeed(u16 speed);
u8 sdOpenRead(u32 saddr, u32 slen);
u8 sdOpenWrite(u32 saddr, u32 slen);
u8 sdCloseRW();


SdState sd;

u8 sdCmd(u8 cmd, u32 arg) {

    //clear cmd flags
    SDIO->ICR = (SDIO_STA_CCRCFAIL | SDIO_STA_CTIMEOUT | SDIO_STA_CMDREND | SDIO_STA_CMDSENT);


    SDIO->ARG = arg;
    SDIO->CMD = cmd | SDIO_CMD_CPSMEN; // | SDIO_CMD_NIEN;

    while ((SDIO->STA & SDIO_STA_CMDACT));

    if ((SDIO->STA & SDIO_STA_CTIMEOUT)) {
        return DISK_ERR_CTO;
    } else if ((SDIO->STA & SDIO_FLAG_CCRCFAIL) && (cmd != ACMD41)) {
        return DISK_ERR_CCR;
    }

    sd.resp[0] = SDIO->RESP1;
    sd.resp[1] = SDIO->RESP2;
    sd.resp[2] = SDIO->RESP2;
    sd.resp[3] = SDIO->RESP3;

    return 0;
}

void sdInitPorts() {

    GPIO_InitTypeDef GPIO_InitStruct = {0};
    __HAL_RCC_SDIO_CLK_ENABLE();

    GPIO_InitStruct.Pin = SD_CLK_PIN | SD_DAT_PINS;
    GPIO_InitStruct.Mode = GPIO_MODE_AF_PP;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_VERY_HIGH;
    GPIO_InitStruct.Alternate = GPIO_AF12_SDIO;
    HAL_GPIO_Init(SD_CLK_PORT, &GPIO_InitStruct);


    GPIO_InitStruct.Pin = SD_CMD_PIN;
    GPIO_InitStruct.Mode = GPIO_MODE_AF_PP;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_VERY_HIGH;
    GPIO_InitStruct.Alternate = GPIO_AF12_SDIO;
    HAL_GPIO_Init(SD_CMD_PORT, &GPIO_InitStruct);

    //__HAL_SD_ENABLE(hsd);

    SDIO->CLKCR = SDIO_CLKCR_CLKEN | SPD_400KHZ | BUS_1BIT; // | SDIO_CLKCR_PWRSAV;
    SDIO->POWER = 3;

}

void sdSetSpeed(u16 speed) {

    u32 clk = SDIO->CLKCR & ~(SDIO_CLKCR_CLKDIV | SDIO_CLKCR_BYPASS);

    clk |= speed & SDIO_CLKCR_CLKDIV;

    if (speed == SPD_48MHZ) {
        clk |= SDIO_CLKCR_BYPASS;
    }

    SDIO->CLKCR = clk;
}

u8 sdInit() {

    u8 resp;

    wdogRefresh();

    sd.disk_mode = DISK_MODE_NOP;
    sd.card_type = CARD_TYPE_V1;

    sdInitPorts();
    HAL_Delay(10);
    sdSetSpeed(SPD_400KHZ);


    resp = sdCmd(CMD0, 0);
    if (resp)return resp;

    resp = sdCmd(CMD8, 0x1aa);
    if (resp == 0) {
        sd.card_type |= CARD_TYPE_V2;
    }

    u32 time_base = HAL_GetTick();
    u32 time;

    while (1) {

        time = HAL_GetTick() - time_base;
        if (time > DISK_INI_TOUT)return DISK_ERR_INIT + 0;

        resp = sdCmd(CMD55, 0); //app cmd
        if (resp)return DISK_ERR_INIT + 1;
        if ((sd.resp[0] & SDC_DAT_RDY) == 0)continue; //wait for "DATA_READY" card status 

        resp = sdCmd(ACMD41, OCR_PWR_CCS | OCR_VCC_3V2 | OCR_VCC_3V3); //set voltage and read back OCR
        if (resp)return DISK_ERR_INIT + 2;
        if ((sd.resp[0] & OCR_PWR_RDY) != 0)break; //wait for end of power on routine
    }

    if ((sd.resp[0] & OCR_PWR_CCS) && sd.card_type == CARD_TYPE_V2) {
        sd.card_type |= CARD_TYPE_HC;
    }

    resp = sdCmd(CMD2, 0); //get cid
    if (resp)return DISK_ERR_INIT + 3;

    resp = sdCmd(CMD3, 0); //get rca
    if (resp)return DISK_ERR_INIT + 4;

    sd.rca = sd.resp[0] & 0xffff0000;

    resp = sdCmd(CMD9, sd.rca); //get csd
    if (resp)return DISK_ERR_INIT + 5;

    resp = sdCmd(CMD7, sd.rca); //trans mode
    if (resp)return DISK_ERR_INIT + 6;


    resp = sdCmd(CMD55, sd.rca); //turn off pullups
    if (resp)return DISK_ERR_INIT + 7;
    resp = sdCmd(ACMD42, 0x00);
    if (resp)return DISK_ERR_INIT + 8;

    resp = sdCmd(CMD16, 512);
    if (resp)return DISK_ERR_INIT + 9;

    resp = sdCmd(CMD55, sd.rca); //set bus width
    if (resp)return DISK_ERR_INIT + 10;
    resp = sdCmd(ACMD6, 0x02);
    if (resp)return DISK_ERR_INIT + 11;
    SDIO->CLKCR = (SDIO->CLKCR & ~SDIO_CLKCR_WIDBUS) | BUS_4BIT;


    //resp = sdCmd(CMD6, 0x80000001); //hi speed mode. csd[3] should be 0x5A
    //if (resp)return DISK_ERR_INIT + 9;
    sdSetSpeed(SPD_24MHZ);


    HAL_Delay(10);

    return 0;
}
//****************************************************************************** var

u8 sdOpenRead(u32 saddr, u32 slen) {

    u8 resp;
    if (sd.disk_mode == DISK_MODE_RD && saddr == sd.cur_addr)return 0;

    sdCloseRW();
    sd.cur_addr = saddr;
    if ((sd.card_type & CARD_TYPE_HC) == 0)saddr *= 512;

    if (slen > 1) {
        resp = sdCmd(CMD18, saddr);
        if (resp != 0)return DISK_ERR_RD1;
        sd.disk_mode = DISK_MODE_RD;
    } else {
        resp = sdCmd(CMD17, saddr);
        if (resp != 0)return DISK_ERR_RD1;
        sd.disk_mode = DISK_MODE_NOP;
    }


    return 0;
}

u8 sdOpenWrite(u32 saddr, u32 slen) {

    u8 resp;
    if (sd.disk_mode == DISK_MODE_WR && saddr == sd.cur_addr)return 0;

    sdCloseRW();
    sd.cur_addr = saddr;
    if ((sd.card_type & CARD_TYPE_HC) == 0)saddr *= 512;

    if (slen > 1) {
        resp = sdCmd(CMD25, saddr);
        if (resp != 0)return DISK_ERR_RD1;
        sd.disk_mode = DISK_MODE_WR;
    } else {
        resp = sdCmd(CMD24, saddr);
        if (resp != 0)return DISK_ERR_RD1;
        sd.disk_mode = DISK_MODE_NOP;
    }


    return 0;
}

u8 sdCloseRW() {

    u8 resp;
    if (sd.disk_mode == DISK_MODE_NOP)return 0;

    resp = sdCmd(CMD12, 0);
    sd.disk_mode = DISK_MODE_NOP;
    if (resp)return resp;

    return 0;
}
#endif
//****************************************************************************** read/write sw
#if defined(DISK_HW) && !defined(DISK_DMA)

u8 sdRead(void *dst, u32 saddr, u32 slen) {

    u8 resp = 0;
    u32 *dst32 = dst;
    u32 stop_flags = SDIO_STA_RXOVERR | SDIO_STA_DCRCFAIL | SDIO_STA_DTIMEOUT | SDIO_STA_STBITERR | SDIO_STA_DATAEND;

    wdogRefresh();

    resp = sdOpenRead(saddr, slen);
    if (resp)return resp;
    sd.cur_addr += slen;


    SDIO->DCTRL = 0;
    SDIO->ICR = SDIO_ICR_STATIC;
    SDIO->DTIMER = DISK_RDX_TOUT;
    SDIO->DLEN = slen * 512;
    SDIO->DCTRL = DIR_SD_TO_MEM | (9 << 4) | SDIO_DCTRL_DTEN;


    u32 sta = SDIO->STA; //update latched value
    do {

        sta = SDIO->STA;

        if ((sta & SDIO_STA_RXDAVL)) {
            *dst32++ = SDIO->FIFO;
        }

    } while ((sta & stop_flags) == 0);


    resp = sdCloseRW();
    if (resp)return resp;

    if ((sta & SDIO_STA_DTIMEOUT)) return DISK_ERR_RD2;
    if ((sta & SDIO_STA_STBITERR)) return DISK_ERR_RD2;
    if ((sta & SDIO_STA_DCRCFAIL)) return DISK_ERR_RD3;
    if ((sta & SDIO_STA_RXOVERR)) return DISK_ERR_RD4;

    while ((SDIO->STA & SDIO_STA_RXDAVL)) {
        *dst32++ = SDIO->FIFO;
    }

    return 0;
}

u8 sdWrite(void *src, u32 saddr, u32 slen) {

    u8 resp;
    u32 *src32 = src;
    u32 stop_flags = SDIO_STA_TXUNDERR | SDIO_STA_DCRCFAIL | SDIO_STA_DTIMEOUT | SDIO_STA_STBITERR | SDIO_STA_DATAEND;

    resp = sdOpenWrite(saddr, slen);
    if (resp != 0)return resp; //DISK_ERR_WR1;
    sd.cur_addr += slen;

    SDIO->DCTRL = 0;
    SDIO->ICR = SDIO_ICR_STATIC;
    SDIO->DTIMER = DISK_WRX_TOUT;
    SDIO->DLEN = slen * 512;
    SDIO->DCTRL = DIR_MEM_TO_SD | (9 << 4) | SDIO_DCTRL_DTEN;

    u32 len = slen * 512;
    u32 sta = SDIO->STA; //update latched value
    do {

        sta = SDIO->STA;

        if ((sta & SDIO_STA_TXFIFOHE) && len) {
            SDIO->FIFO = *src32++;
            SDIO->FIFO = *src32++;
            SDIO->FIFO = *src32++;
            SDIO->FIFO = *src32++;
            SDIO->FIFO = *src32++;
            SDIO->FIFO = *src32++;
            SDIO->FIFO = *src32++;
            SDIO->FIFO = *src32++;
            len -= 32;
        }

    } while ((sta & stop_flags) == 0);

    resp = sdCloseRW();
    if (resp)return resp;


    while (1) {
        resp = sdCmd(CMD13, sd.rca);
        if (resp)break;
        u32 status = sd.resp[0] & STATUS_MSK;
        if (status != STATUS_RCV && status != STATUS_PRG)break;
    }

    if (sta & SDIO_STA_TXUNDERR) return DISK_ERR_WR3;
    if (sta & SDIO_STA_DTIMEOUT) return DISK_ERR_WR4;
    if (sta & SDIO_STA_STBITERR) return DISK_ERR_WR4;
    if (sta & SDIO_STA_DCRCFAIL) return DISK_ERR_WR5;

    return 0;
}
#endif
//******************************************************************************read write dma
#if defined(DISK_HW) && defined(DISK_DMA)

#define SDIO_DMA_CHN DMA2
#define SDIO_DMA_STR DMA2_Stream3

#define DMA_CHA_SEL     (0x04 << 25)//ch4
#define DMA_MEM_BRS     (0x01 << 23)
#define DMA_PER_BRS     (0x01 << 21)
#define DMA_BUF_OFF     (0x00 << 18)//Disable double buffer
#define DMA_PRIORTY     (0x03 << 16)//Priority very_high
#define DMA_PER_INC     (0x00 << 15)
#define DMA_MEM_DSZ     (0x02 << 13)//mem dat size
#define DMA_PER_DSZ     (0x02 << 11)//per dat size
#define DMA_MEM_ENI     (0x01 << 10)//enable mem inc
#define DMA_PER_OFI     (0x00 << 9)//disable per inc
#define DMA_CIR_OFF     (0x00 << 8)//Disable Circular mode
#define DMA_DIR_M2P     (0x01 << 6)
#define DMA_DIR_P2M     (0x00 << 6)
#define DMA_PER_CFL     (0x01 << 5)//Peripheral controls flow

#define DMA_CMF_SDC     DMA_CHA_SEL | DMA_MEM_BRS | DMA_PER_BRS | DMA_BUF_OFF |\
                        DMA_PRIORTY | DMA_PER_INC | DMA_MEM_DSZ | DMA_PER_DSZ |\
                        DMA_MEM_ENI | DMA_PER_OFI | DMA_CIR_OFF | DMA_PER_CFL

void sdSetupDMA(u8 dir, u32 *mem);

u8 sdRead(void *dst, u32 saddr, u32 slen) {

    u8 resp = 0;
    u32 stop_flags = SDIO_STA_RXOVERR | SDIO_STA_DCRCFAIL | SDIO_STA_DTIMEOUT | SDIO_STA_STBITERR | SDIO_STA_DATAEND;

    wdogRefresh();

    resp = sdOpenRead(saddr, slen);
    if (resp)return resp;
    sd.cur_addr += slen;

    sdSetupDMA(DMA_DIR_P2M, dst);

    SDIO->DCTRL = 0;
    SDIO->ICR = SDIO_ICR_STATIC;
    SDIO->DTIMER = DISK_RDX_TOUT;
    SDIO->DLEN = slen * 512;
    SDIO->DCTRL = DIR_SD_TO_MEM | (9 << 4) | SDIO_DCTRL_DTEN | SDIO_DCTRL_DMAEN;

    u32 sta = SDIO->STA;
    do {
        sta = SDIO->STA;
    } while ((sta & stop_flags) == 0);

    SDIO_DMA_STR->CR &= ~DMA_SxCR_EN;

    resp = sdCloseRW();
    if (resp)return resp;

    if ((sta & SDIO_STA_DTIMEOUT)) return DISK_ERR_RD2;
    if ((sta & SDIO_STA_STBITERR)) return DISK_ERR_RD2;
    if ((sta & SDIO_STA_DCRCFAIL)) return DISK_ERR_RD3;
    if ((sta & SDIO_STA_RXOVERR)) return DISK_ERR_RD4;

    return 0;
}

u8 sdWrite(void *src, u32 saddr, u32 slen) {

    u8 resp;
    u32 stop_flags = SDIO_STA_TXUNDERR | SDIO_STA_DCRCFAIL | SDIO_STA_DTIMEOUT | SDIO_STA_STBITERR | SDIO_STA_DATAEND;

    resp = sdOpenWrite(saddr, slen);
    if (resp != 0)return resp; //DISK_ERR_WR1;
    sd.cur_addr += slen;

    sdSetupDMA(DMA_DIR_M2P, src);

    SDIO->DCTRL = 0;
    SDIO->ICR = SDIO_ICR_STATIC;
    SDIO->DTIMER = DISK_WRX_TOUT;
    SDIO->DLEN = slen * 512;
    SDIO->DCTRL = DIR_MEM_TO_SD | (9 << 4) | SDIO_DCTRL_DTEN | SDIO_DCTRL_DMAEN;

    u32 sta = SDIO->STA;
    do {
        sta = SDIO->STA;
    } while ((sta & stop_flags) == 0);

    SDIO_DMA_STR->CR &= ~DMA_SxCR_EN;


    resp = sdCloseRW();
    if (resp)return resp;


    while (1) {
        resp = sdCmd(CMD13, sd.rca);
        if (resp)break;
        u32 status = sd.resp[0] & STATUS_MSK;
        if (status != STATUS_RCV && status != STATUS_PRG)break;
    }

    if (sta & SDIO_STA_TXUNDERR) return DISK_ERR_WR3;
    if (sta & SDIO_STA_DTIMEOUT) return DISK_ERR_WR4;
    if (sta & SDIO_STA_STBITERR) return DISK_ERR_WR4;
    if (sta & SDIO_STA_DCRCFAIL) return DISK_ERR_WR5;


    return 0;
}

void sdSetupDMA(u8 dir, u32 *mem) {

    SDIO_DMA_STR->CR = 0;

    //Clear all flags
    SDIO_DMA_CHN->LIFCR = DMA_LIFCR_CTCIF3 | DMA_LIFCR_CTEIF3 | DMA_LIFCR_CDMEIF3 | DMA_LIFCR_CFEIF3 | DMA_LIFCR_CHTIF3;

    //Set DMA src/dst
    SDIO_DMA_STR->PAR = (u32) & SDIO->FIFO;
    SDIO_DMA_STR->M0AR = (u32) mem;

    //number of data transfers. ignored due perepherial flow control
    SDIO_DMA_STR->NDTR = 0;

    //Fifo mode, full fifo threshold;
    SDIO_DMA_STR->FCR = 0x21 | (1 << 2) | 3;

    SDIO_DMA_STR->CR = DMA_CMF_SDC | DMA_SxCR_EN | dir;

}

#endif
