
#include <string.h>

#include "edio.h"

#ifdef DISK_SW

#define CMD0  0x40    // software reset
#define CMD1  0x41    // brings card out of idle state
#define CMD8  0x48    // Reserved
#define CMD12 0x4C    // stop transmission on multiple block read
#define CMD17 0x51    // read single block
#define CMD18 0x52    // read multiple block
#define CMD58 0x7A    // reads the OCR register
#define CMD55 0x77
#define CMD41 0x69
#define CMD24 0x58    // writes a single block
#define CMD25 0x59    // writes a multi block
#define	ACMD41 0x69
#define	ACMD6 0x46


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

#define CLK0    SD_CLK_PORT->BSRR = SD_CLK_PIN << 16
#define CLK1    SD_CLK_PORT->BSRR = SD_CLK_PIN

//******************************************************************************
#define SD_V2 2
#define SD_HC 1

#define CMD2 0x42 //read cid
#define CMD3 0x43 //read rca
#define CMD7 0x47
#define CMD9 0x49
#define CMD6 0x46 //set hi speed


#define DISK_MODE_NOP   0
#define DISK_MODE_RD    1
#define DISK_MODE_WR    2
#define DISK_DAT_TOUT       800 //0.8sec
#define DISK_CMD_TOUT       100

#define TMR_RST         1
#define TMR_READ        0

typedef struct {
    u32 cur_addr;
    u8 card_type;
    u8 disk_mode;
    u8 cmd_delay;
    u8 resp[18];
} SdState;

u8 sdCmd(u8 cmd, u32 arg);
u8 sdReadResp(u8 cmd);
void sdCmd_wr(u8 val);
u8 sdCmd_rd(u8 bits);
void sdDat_wr(u8 val);
u8 sdDat_rd(u8 bits);
void sdInitPorts();
u8 sdOpenRead(u32 saddr);
void sdSectorRead(u8 *dst);
u8 sdOpenWrite(u32 saddr);
void sdSectorWrite(u8 *src);
u8 sdCloseRW();
u32 toutTimer(u8 rst);

SdState sd;

u8 sdCmd(u8 cmd, u32 arg) {


    u8 p = 0;
    u8 buff[6];

    u8 crc;
    buff[p++] = cmd;
    buff[p++] = (arg >> 24);
    buff[p++] = (arg >> 16);
    buff[p++] = (arg >> 8);
    buff[p++] = (arg >> 0);
    crc = crc7(buff, 5) | 1;

    sdCmd_wr(0xff);
    sdCmd_wr(cmd);
    sdCmd_wr(arg >> 24);
    sdCmd_wr(arg >> 16);
    sdCmd_wr(arg >> 8);
    sdCmd_wr(arg);
    sdCmd_wr(crc);


    if (cmd == CMD0)return 0;

    return sdReadResp(cmd);
}

u8 sdReadResp(u8 cmd) {

    u16 i;

    u8 resp_len = cmd == CMD2 || cmd == CMD9 ? 17 : 6;

    sd.resp[0] = sdCmd_rd(8);

    toutTimer(TMR_RST);
    while ((sd.resp[0] & 0xC0) != 0) {//wait for resp begin. first two bits should be zeros
        sd.resp[0] = sdCmd_rd(1);
        if (toutTimer(TMR_READ) > DISK_CMD_TOUT)return DISK_ERR_CTO;
    }

    for (i = 1; i < resp_len; i++) {

        sd.resp[i] = sdCmd_rd(8); //8
    }


    return 0;
}

void sdCmd_wr(u8 val) {

    u8 bits = 8;
    SD_CMD_OUT;

    while (bits--) {

        if ((val & 0x80)) {
            SD_CMD_PORT->BSRR = SD_CMD_PIN;
        } else {
            SD_CMD_PORT->BSRR = SD_CMD_PIN << 16;
        }

        for (int i = 0; i < sd.cmd_delay; i++)asm("nop");
        CLK1;

        for (int i = 0; i < sd.cmd_delay; i++)asm("nop");
        CLK0;
        val <<= 1;
    }

    //SD_CMD_INP;
}

u8 sdCmd_rd(u8 bits) {

    static u8 val;
    SD_CMD_INP;

    while (bits--) {

        for (int i = 0; i < sd.cmd_delay; i++)asm("nop");
        val <<= 1;

        CLK1;

        if ((SD_CMD_PORT->IDR & SD_CMD_PIN)) {
            val |= 1;
        }

        for (int i = 0; i < sd.cmd_delay; i++)asm("nop");
        CLK0;
    }

    return val;
}

void sdDat_wr(u8 val) {

    u8 bits = 8;
    u32 dat;

    while (bits) {

        dat = (SD_DAT_PORT->ODR & ~SD_DAT_PINS) | (val & 0xF0) << 4;
        SD_DAT_PORT->ODR = dat;
        asm("nop");
        CLK1;
        //asm("nop");
        CLK0;
        val <<= 4;
        bits -= 4;
    }
}

u8 sdDat_rd(u8 bits) {

    static u8 val;

    while (bits) {

        val <<= 4;
        CLK1;
        //asm("nop");
        val |= (SD_DAT_PORT->IDR & SD_DAT_PINS) >> 8;
        CLK0;
        //asm("nop");
        bits -= 4;
    }

    return val;
}
//******************************************************************************

u8 sdInit() {

    sdInitPorts();

    u16 i;
    volatile u8 resp = 0;
    u32 rca;
    u32 wait_len = 1024;

    wdogRefresh();

    sd.cmd_delay = 64;
    sd.card_type = 0;
    sd.disk_mode = DISK_MODE_NOP;

    HAL_Delay(10);

    for (i = 0; i < 40; i++)sdCmd_wr(0xff);
    sdCmd(CMD0, 0x1aa);


    for (i = 0; i < 40; i++)sdCmd_wr(0xff);

    resp = sdCmd(CMD8, 0x1aa);



    if (resp == 0)sd.card_type |= SD_V2;


    if (sd.card_type == SD_V2) {

        for (i = 0; i < wait_len; i++) {

            resp = sdCmd(CMD55, 0);
            if (resp)return DISK_ERR_INIT + 0;
            if ((sd.resp[3] & 1) != 1)continue;
            resp = sdCmd(CMD41, 0x40300000);
            if ((sd.resp[1] & 128) == 0)continue;

            break;
        }
    } else {

        i = 0;
        do {
            resp = sdCmd(CMD55, 0);
            if (resp)return DISK_ERR_INIT + 1;
            resp = sdCmd(CMD41, 0x40300000);
            if (resp)return DISK_ERR_INIT + 2;

        } while (sd.resp[1] < 1 && i++ < wait_len);

    }

    if (i == wait_len)return DISK_ERR_INIT + 3;

    if ((sd.resp[1] & 64) && sd.card_type != 0)sd.card_type |= SD_HC;

    resp = sdCmd(CMD2, 0);
    if (resp)return DISK_ERR_INIT + 4;

    resp = sdCmd(CMD3, 0);
    if (resp)return DISK_ERR_INIT + 5;

    //resp = sdCmd(CMD7, 0);
    
    rca = (sd.resp[1] << 24) | (sd.resp[2] << 16);// | (sd.resp[3] << 8) | (sd.resp[4] << 0);


    resp = sdCmd(CMD9, rca); //get csd
    if (resp)return DISK_ERR_INIT + 6;


    resp = sdCmd(CMD7, rca);
    if (resp)return DISK_ERR_INIT + 7;


    resp = sdCmd(CMD55, rca);
    if (resp)return DISK_ERR_INIT + 8;


    resp = sdCmd(CMD6, 2);
    if (resp)return DISK_ERR_INIT + 9;


    sd.cmd_delay = 0;
    //bi_sd_speed(BI_DISK_SPD_HI);
    HAL_Delay(10);

    return 0;
}

void sdInitPorts() {

    GPIO_InitTypeDef GPIO_InitStruct = {0};

    SD_CMD_PORT->ODR |= SD_CMD_PIN;
    SD_DAT_PORT->ODR |= SD_DAT_PINS;
    CLK0;

    GPIO_InitStruct.Pin = SD_CLK_PIN;
    GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_VERY_HIGH;
    HAL_GPIO_Init(SD_CLK_PORT, &GPIO_InitStruct);

    GPIO_InitStruct.Pin = SD_CMD_PIN;
    GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_VERY_HIGH;
    HAL_GPIO_Init(SD_CMD_PORT, &GPIO_InitStruct);

    GPIO_InitStruct.Pin = SD_DAT_PINS;
    GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_VERY_HIGH;
    HAL_GPIO_Init(SD_DAT_PORT, &GPIO_InitStruct);

}



//****************************************************************************** read op

u8 sdRead(void *dst, u32 saddr, u32 slen) {

    u8 resp = 0;

    resp = sdOpenRead(saddr);
    if (resp)return resp;
    sd.cur_addr += slen;

    while (slen--) {
        wdogRefresh();

        toutTimer(TMR_RST);
        while (sdDat_rd(4) != 0xf0) {
            if (toutTimer(TMR_READ) > DISK_DAT_TOUT)return DISK_ERR_RD2;
        }

        sdSectorRead(dst);

        dst += 512;
    }

    return 0;
}

u8 sdOpenRead(u32 saddr) {

    u8 resp;
    if (sd.disk_mode == DISK_MODE_RD && saddr == sd.cur_addr)return 0;

    sdCloseRW();
    sd.cur_addr = saddr;
    if ((sd.card_type & SD_HC) == 0)saddr *= 512;
    resp = sdCmd(CMD18, saddr);
    if (resp != 0)return DISK_ERR_RD1;

    sd.disk_mode = DISK_MODE_RD;

    return 0;
}

void sdSectorRead(u8 *dst) {

    u8 val;

    for (int i = 0; i < 512; i++) {


        CLK1;
        val = (SD_DAT_PORT->IDR & SD_DAT_PINS) >> 4;
        CLK0;

        asm("nop");

        CLK1;
        val |= (SD_DAT_PORT->IDR & SD_DAT_PINS) >> 8;
        CLK0;

        dst[i] = val;
    }

    //skip crc 8 bytes
    for (int i = 0; i < 16; i++) {
        CLK1;
        asm("nop");
        CLK0;
    }
}

//****************************************************************************** write op

u8 sdWrite(void *src, u32 saddr, u32 slen) {

    u8 resp;



    resp = sdOpenWrite(saddr);
    if (resp != 0)return resp; //DISK_ERR_WR1;
    sd.cur_addr += slen;

    while (slen--) {

        wdogRefresh();

        sdSectorWrite(src);
        src += 512;

        //sdioDat_rd(4); //check this in case of problems
        toutTimer(TMR_RST);
        while ((sdDat_rd(4) & 1) != 0) {
            if (toutTimer(TMR_READ) > DISK_DAT_TOUT)return DISK_ERR_WR3;
        }

        resp = 0;
        for (u32 i = 0; i < 3; i++) {
            resp <<= 1;
            resp |= sdDat_rd(4) & 1;
        }

        resp &= 7;
        if (resp != 0x02) {
            if (resp == 5)return DISK_ERR_WR4; //crc error
            return DISK_ERR_WR5;
        }

        toutTimer(TMR_RST);
        while (sdDat_rd(4) != 0xFF) {
            if (toutTimer(TMR_READ) > DISK_DAT_TOUT)return DISK_ERR_WR2;
        }

    }

    return 0;
}

u8 sdOpenWrite(u32 saddr) {

    u8 resp;
    if (sd.disk_mode == DISK_MODE_WR && saddr == sd.cur_addr)return 0;

    sdCloseRW();
    sd.cur_addr = saddr;
    if ((sd.card_type & SD_HC) == 0)saddr *= 512;
    resp = sdCmd(CMD25, saddr);
    if (resp != 0)return DISK_ERR_WR1;

    sd.disk_mode = DISK_MODE_WR;

    return 0;
}

void sdSectorWrite(u8 *src) {

    u8 crc[8];
    SD_DAT_OUT;

    crc16SD_SW(src, (u16 *) crc);

    sdDat_wr(0xff);
    sdDat_wr(0xf0);

    for (int i = 0; i < 512; i++) {

        sdDat_wr(src[i]);
    }

    for (int i = 0; i < 8; i++) {
        sdDat_wr(crc[i ^ 1]);
    }

    //sdioDat_wr(0xff); //check it in case of problems

    SD_DAT_PORT->ODR |= SD_DAT_PINS; //check it in case of problems
    CLK1;
    asm("nop");
    CLK0;

    SD_DAT_INP;

    //sdioDat_rd(4);//check it in case of problems
}
//****************************************************************************** var

u8 sdCloseRW() {

    u8 resp;
    u16 i;

    if (sd.disk_mode == DISK_MODE_NOP)return 0;

    resp = sdCmd(CMD12, 0);
    sd.disk_mode = DISK_MODE_NOP;
    if (resp)return resp;

    sdDat_rd(4);
    sdDat_rd(4);
    sdDat_rd(4);

    i = 65535;
    while (--i) {
        if (sdDat_rd(8) == 0xff)break;
    }

    return 0;
}

u32 toutTimer(u8 rst) {

    static u32 time_base;

    if (rst) {
        time_base = HAL_GetTick();
        return 0;
    }
    return HAL_GetTick() - time_base;
}

#endif