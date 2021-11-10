
#include <string.h>

#include "edio.h"

u8 cmd_diskRead() {

    u32 addr;
    u32 slen;
    u8 resp;
    u8 buff[512];

    linkRX(&addr, 4);
    linkRX(&slen, 4);

    for (int i = 0; i < slen; i++) {

        resp = diskRD(buff, addr, 1);
        linkTX(&resp, 1);
        if (resp)return resp;
        linkTX(buff, 512);

        addr++;
    }

    return 0;

}

u8 cmd_diskWrite() {

    u32 addr;
    u32 slen;
    u32 block;
    u8 resp = 0;
    u8 buff[ACK_BLOCK_SIZE];

    linkRX(&addr, 4);
    linkRX(&slen, 4);

    while (slen) {

        block = sizeof (buff) / 512;
        if (block > slen)block = slen;
        slen -= block;

        if (resp) {
            linkTX(&resp, 1);
            if (resp)return resp;
        }

        linkRX_ack(buff, block * 512);
        resp = diskWR(buff, addr, block);

        addr += block;
    }

    return 0;

}

u8 diskInit() {

    u8 resp;

    wdogRefresh();

    resp = sdInit();
    sys_inf.disk_status = resp;

    if (resp) {
        dbg_print("disk init error: ");
        dbg_append_h8(resp);
    }

    return resp;
}

u8 diskRD(void *dst, u32 saddr, u32 slen) {

    u8 resp;
    wdogRefresh();

    resp = sdRead(dst, saddr, slen);
    sys_inf.disk_status = resp;

    if (resp) {
        dbg_print("disk rd error: ");
        dbg_append_h8(resp);
    }
    return resp;
}

u8 diskWR(void *src, u32 saddr, u32 slen) {

    u8 resp;
    wdogRefresh();

    resp = sdWrite(src, saddr, slen);
    sys_inf.disk_status = resp;

    if (resp) {
        dbg_print("disk wr error: ");
        dbg_append_h8(resp);
    }
    return resp;
}

u8 diskSync() {

    u8 resp;
    wdogRefresh();

    resp = sdCloseRW();
    sys_inf.disk_status = resp;

    if (resp) {
        dbg_print("disk sync error: ");
        dbg_append_h8(resp);
    }
    return resp;
}