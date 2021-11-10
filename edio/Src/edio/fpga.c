

#include <string.h>
#include "edio.h"




void fpgReset();
u8 fpgInitEnd();
extern FIL file_io;

MapConfig reboot_cfg;

u8 cmd_fpgInitUSB() {

    u8 resp;
    u32 len;
    u32 block;
    u8 buff[ACK_BLOCK_SIZE];

    linkRX(&len, 4);
    fpgReset();

    while (len) {

        block = sizeof (buff);
        if (block > len)block = len;
        len -= block;

        linkRX_ack(buff, block);
        spiTX(SPI_FPGA, buff, block);
    }

    resp = fpgInitEnd();
    if (resp)return resp;

    memOpenWrite(ADDR_CFG);
    memWrite(&reboot_cfg, sizeof (MapConfig));
    memCloseRW();

    return 0;
}

u8 cmd_fpgInitSDC() {

    u8 ack;
    u32 len;

    linkRX(&len, 4);
    linkRX(&ack, 1); //exec

    return fpgInitSDC(len, &reboot_cfg);
}

u8 cmd_fpgInitFLA() {


    u8 ack;
    u32 addr;

    linkRX(&addr, 4);
    linkRX(&ack, 1); //exec

    return fpgInitFLA(addr, &reboot_cfg);
}

void cmd_fpgInitCFG() {

    linkRX(&reboot_cfg, sizeof (MapConfig));
}

u8 fpgInitEnd() {

    u8 buff[512];
    u8 resp;

    memset(buff, 0xff, sizeof (buff));
    spiBitDir(SPI_FPGA, SPI_MSB);
    spiTX(SPI_FPGA, buff, sizeof (buff));

    HAL_Delay(15);
    resp = gpioRD_pin(cfg_don_GPIO_Port, cfg_don_Pin);
    if (resp != 0)return 0;

    return ERR_FPGA_INIT;
}

void fpgReset() {

    spiBitDir(SPI_FPGA, SPI_LSB);

    gpioWR_port(ncfg_GPIO_Port, ncfg_Pin, 1);
    HAL_Delay(1);
    gpioWR_port(ncfg_GPIO_Port, ncfg_Pin, 0);
    HAL_Delay(5);
    gpioWR_port(ncfg_GPIO_Port, ncfg_Pin, 1);
    HAL_Delay(30);
}

void fpgHalt() {

    gpioWR_port(ncfg_GPIO_Port, ncfg_Pin, 0);
}

u8 fpgInitSDC(u32 len, MapConfig *cfg) {

    u8 resp;
    u32 block;
    u32 readed;
    u8 buff[4096];
    u8 lock1 = 0;
    u8 lock2 = 0;

    if (!signature.valid && cfg->map_idx != 255) {
        lock1 = sys_inf.game_ctr & 1;
        lock2 = lock1 ^ 1;
    }

    if (len > MAX_RBF_SIZE)len = MAX_RBF_SIZE;

    if (lock1) {
        lock1 = 0;
    } else {
        fpgReset();
    }

    while (len) {

        block = sizeof (buff);
        if (block > len)block = len;
        len -= block;

        resp = f_read(&file_io, buff, block, (UINT *) & readed);
        if (resp)return resp;

        if (lock2) {
            if (lock2 == 1)block -= 4;
            if (lock2 == 2)block += 4;
            lock2 = lock2 == 2 ? 0 : lock2 + 1;
        }

        spiTX(SPI_FPGA, buff, block);
    }

    resp = f_close(&file_io);
    if (resp)return resp;

    resp = fpgInitEnd();
    if (resp)return resp;

    memOpenWrite(ADDR_CFG);
    memWrite(cfg, sizeof (MapConfig));
    memCloseRW();


    return resp;
}

u8 fpgInitFLA(u32 addr, MapConfig *cfg) {

    u8 resp;
    u32 block;
    u32 len;
    u8 buff[512 + 1];

    flaOpenRead(addr);
    flaRead((u8 *) & len, 4);
    flaCloseRD();

    flaOpenRead(addr + 8);

    if (len > MAX_RBF_SIZE)len = MAX_RBF_SIZE;

    fpgReset();
    resp = 0;

    buff[sizeof (buff) - 1] = 0xff;

    while (len) {

        block = sizeof (buff) - 1;
        if (block > len)block = len;
        len -= block;

        buff[0] = buff[sizeof (buff) - 1];
        spiTXRX(SPI_FPGA, buff, buff + 1, block);
    }

    flaCloseRD();

    resp = fpgInitEnd();
    if (resp)return resp;

    memOpenWrite(ADDR_CFG);
    memWrite(cfg, sizeof (MapConfig));
    memCloseRW();

    return resp;
}