

#include <string.h>

#include "edio.h"


#define MEM_CMD_WR      0xA0
#define MEM_CMD_RD      0xA1
#define MEM_CLOSED      0x00

u8 mem_mode;

void cmd_memWR() {

    u32 addr;
    u32 len;
    u32 block;
    u8 buff[ACK_BLOCK_SIZE];
    u8 ack;

    linkRX(&addr, 4);
    linkRX(&len, 4);
    linkRX(&ack, 1); //exec byte


    while (len) {

        wdogRefresh();
        block = sizeof (buff);
        if (block > len)block = len;
        len -= block;
        linkRX(buff, block);

        if (ack == 0xaa) {
            linkRX(&ack, 1);
            ack = 0;
        }

        if (mem_mode == MEM_CLOSED)memOpenWrite(addr); //in case if link src is fifo.
        memWrite(buff, block);
        addr += block;
    }

    memCloseRW();

}

void cmd_memRD() {

    u32 addr;
    u32 len;
    u32 block;
    u8 buff[512];

    linkRX(&addr, 4);
    linkRX(&len, 4);
    linkRX(buff, 1); //exec byte

    //memOpenRead(addr);

    while (len) {

        wdogRefresh();
        block = sizeof (buff);
        if (block > len)block = len;
        len -= block;

        if (mem_mode == MEM_CLOSED)memOpenRead(addr); //in case if link src is fifo
        memRead(buff, block);
        addr += block;

        linkTX(buff, block);
    }

    memCloseRW();

}

void cmd_memSet() {

    u32 addr;
    u32 len;
    u8 val;
    u32 block;
    u8 buff[1024];

    linkRX(&addr, 4);
    linkRX(&len, 4);
    linkRX(&val, 1);
    linkRX(buff, 1); //exec byte

    for (int i = 0; i < sizeof (buff); i++)buff[i] = val;

    memOpenWrite(addr);

    while (len) {

        wdogRefresh();
        block = sizeof (buff);
        if (block > len)block = len;
        len -= block;
        memWrite(buff, block);
    }

    memCloseRW();
}

void cmd_memTst() {

    u32 addr;
    u32 len;
    u8 val;
    u8 mem_eq = 1;
    u32 block;
    u8 buff[1024];

    linkRX(&addr, 4);
    linkRX(&len, 4);
    linkRX(&val, 1);
    linkRX(buff, 1); //exec byte


    memOpenRead(addr);

    while (len) {

        wdogRefresh();
        block = sizeof (buff);
        if (block > len)block = len;
        len -= block;
        memRead(buff, block);
        for (int i = 0; i < block; i++) {
            if (buff[i] != val)mem_eq = 0;
        }
        if (!mem_eq)break;
    }

    memCloseRW();

    linkTX(&mem_eq, 1);
}

void cmd_memCRC() {

    u32 addr, len, block, crc;
    u8 buff[2048];

    linkRX(&addr, 4);
    linkRX(&len, 4);
    linkRX(&crc, 4);
    linkRX(buff, 1); //exec

    memOpenRead(addr);

    while (len) {

        wdogRefresh();
        block = sizeof (buff);
        if (block > len)block = len;
        len -= block;
        memRead(buff, block);
        crc = crc32(crc, buff, block);
    }

    memCloseRW();

    linkTX(&crc, 4);
}

void memOpenRead(u32 addr) {

    u8 cmd[6];

    if (mem_mode != MEM_CLOSED)memCloseRW();

    mem_mode = MEM_CMD_RD;

    cmd[0] = MEM_CMD_RD;
    cmd[5] = 0; //dummy byte to push first byte from memory to spi
    memcpy(&cmd[1], &addr, 4);

    spiSS(SPI_SS_MEM, 1);
    spiTX(SPI_MEM, cmd, 1); //fix
    spiSS(SPI_SS_MEM, 0);

    spiTX(SPI_MEM, cmd, sizeof (cmd));
}

void memOpenWrite(u32 addr) {

    u8 cmd[5];
    if (mem_mode != MEM_CLOSED)memCloseRW();

    mem_mode = MEM_CMD_WR;

    cmd[0] = MEM_CMD_WR;
    memcpy(&cmd[1], &addr, 4);


    spiSS(SPI_SS_MEM, 1);
    spiTX(SPI_MEM, cmd, 1); //fix
    spiSS(SPI_SS_MEM, 0);

    spiTX(SPI_MEM, cmd, sizeof (cmd));
}

void memCloseRW() {

    u8 tmp = 0;

    spiTXBusy(SPI_MEM);
    if (mem_mode == MEM_CMD_WR) {
        spiTX(SPI_MEM, &tmp, 1);
    }
    spiSS(SPI_SS_MEM, 1);
    spiTX(SPI_MEM, &tmp, 1); //fix

    mem_mode = MEM_CLOSED;
}

void memRead(void *dst, u32 len) {

    spiRX(SPI_MEM, dst, len);
    //spiRX_DMA(SPI_MEM, dst, len);

}

void memWrite(void *src, u32 len) {

    spiTX(SPI_MEM, src, len);
}

void memWriteDMA(void *src, u32 len) {

    spiTXBusy(SPI_MEM);
    spiTX_DMA(SPI_MEM, src, len);
}

