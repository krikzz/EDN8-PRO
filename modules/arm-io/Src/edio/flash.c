


#include <string.h>

#include "edio.h"

void flaWR_on();
void flaWR_off();
void flaEraseSector4K(u32 addr);
void flaBusy();
void flaProgPage256(u8 *data, u32 addr, u32 len);
void flaWrite(u8 *data, u32 addr, u32 len);

extern FIL file_io;

void cmd_flaRead() {

    u32 addr;
    u32 len;
    u32 block;
    u8 buff[512];

    linkRX(&addr, 4);
    linkRX(&len, 4);

    flaOpenRead(addr);

    while (len) {

        block = sizeof (buff);
        if (block > len)block = len;

        flaRead(buff, block);
        linkTX(buff, block);

        len -= block;
    }

    flaCloseRD();
}

void cmd_flaWrite() {

    u32 addr;
    u32 len;
    u32 block;
    u8 buff[ACK_BLOCK_SIZE];

    linkRX(&addr, 4);
    linkRX(&len, 4);

    while (len) {


        block = sizeof (buff);
        if (block > len)block = len;

        linkRX_ack(buff, block);
        flaWrite(buff, addr, block);

        len -= block;
        addr += block;
    }
}

u8 cmd_flaWriteSDC() {

    u32 addr, len, block, readed;
    u8 resp;
    u8 buff[8192];

    linkRX(&addr, 4);
    linkRX(&len, 4);

    while (len) {

        block = sizeof (buff);
        if (block > len)block = len;

        resp = f_read(&file_io, buff, block, (UINT *) & readed);
        if (resp)return resp;
        flaWrite(buff, addr, block);

        len -= block;
        addr += block;
    }

    return 0;
}

void flaRead_mem(u32 mem_addr, u32 len) {

    u8 buff[8192];
    u32 block;

    memOpenWrite(mem_addr);

    while (len) {
        block = sizeof (buff);
        if (block > len)block = len;
        len -= block;

        flaRead(buff, block);
        memWrite(buff, block);
    }


    memCloseRW();
}

void flaRead(u8 *data, u32 len) {

    wdogRefresh();
    spiRX(SPI_FLA, data, len);

}

void flaOpenRead(u32 addr) {

    u8 cmd[4];

    spiSS(SPI_SS_FLA, 0);

    cmd[0] = 0x03;
    cmd[1] = addr >> 16;
    cmd[2] = addr >> 8;
    cmd[3] = addr;

    spiTX(SPI_FLA, cmd, sizeof (cmd));

}

void flaWrite(u8 *data, u32 addr, u32 len) {

    u32 block;



    while (len) {

        wdogRefresh();
        if (addr % 4096 == 0)flaEraseSector4K(addr);

        block = 256;
        if (block > len)block = len;
        flaProgPage256(data, addr, block);

        len -= block;
        addr += block;
        data += block;
    }

    flaWR_off();
}

void flaCloseRD() {

    spiSS(SPI_SS_FLA, 1);
}

void flaWR_on() {

    u8 cmd = 0x06;

    spiSS(SPI_SS_FLA, 0);
    spiTX(SPI_FLA, &cmd, 1);
    spiSS(SPI_SS_FLA, 1);
}

void flaWR_off() {

    u8 cmd = 0x04;

    spiSS(SPI_SS_FLA, 0);
    spiTX(SPI_FLA, &cmd, 1);
    spiSS(SPI_SS_FLA, 1);
}

void flaBusy() {

    u8 cmd = 0x05;

    spiSS(SPI_SS_FLA, 0);

    spiTX(SPI_FLA, &cmd, 1);

    while (1) {
        spiRX(SPI_FLA, &cmd, 1);
        if ((cmd & 1) == 0)break;
    }

    spiSS(SPI_SS_FLA, 1);
}

//4K sector

void flaEraseSector4K(u32 addr) {


    u8 cmd[4];

    flaWR_on();

    spiSS(SPI_SS_FLA, 0);

    cmd[0] = 0x20;
    cmd[1] = addr >> 16;
    cmd[2] = addr >> 8;
    cmd[3] = addr;

    spiTX(SPI_FLA, cmd, sizeof (cmd));

    spiSS(SPI_SS_FLA, 1);

    flaBusy();

}

//256B page

void flaProgPage256(u8 *data, u32 addr, u32 len) {

    u8 cmd[4];

    flaWR_on();

    spiSS(SPI_SS_FLA, 0);

    cmd[0] = 0x02;
    cmd[1] = addr >> 16;
    cmd[2] = addr >> 8;
    cmd[3] = addr;

    spiTX(SPI_FLA, cmd, sizeof (cmd));
    spiTX(SPI_FLA, data, len);

    spiSS(SPI_SS_FLA, 1);

    flaBusy();

}

void flaGetUID(u8 *uid) {

    u8 cmd[5];
    spiSS(SPI_SS_FLA, 0);

    memset(cmd, 0, sizeof (cmd));
    cmd[0] = 0x4b;
    spiTX(SPI_FLA, cmd, sizeof (cmd));

    spiRX(SPI_FLA, uid, 8);

    spiSS(SPI_SS_FLA, 1);
}