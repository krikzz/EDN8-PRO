

#include "edio.h"


u8 cmdRX_smod();
u8 cmd_setSignature();
u8 cmd_usbRecovery();
void cmd_getUID();
void cmd_mcuSecure();


void usbService() {

    u8 cmd, status;
    dbg_print("USB service mode");
    fpgHalt();



    spiInit();
    linkInit();

    status = 0;

    while (1) {

        led(0);
        cmd = cmdRX_smod();
        led(1);

        switch (cmd) {

            case CMD_STATUS:
                cmd_status(status);
                break;
            case CMD_FLA_RD:
                cmd_flaRead();
                break;
            case CMD_FLA_WR:
                cmd_flaWrite();
                status = 0;
                break;
            case CMD_GET_MODE:
                cmd_getMode(0xA1);
                break;

            case CMD_USB_RECOV:
                status = cmd_usbRecovery();
                break;
            case CMD_RUN_APP:
                runApp(ADDR_PFL_APP);
                break;
            case CMD_SET_SIGNA:
                status = cmd_setSignature();
                break;
            case CMD_GET_UID:
                cmd_getUID();
                break;
            case CMD_MCU_SECURE:
                cmd_mcuSecure();
                break;
            case CMD_GET_SIGNA:
                linkTX((u8 *) ADDR_PFL_EDSG, 64);
                break;
        }
    }

}

u8 cmdRX_smod() {

    u8 cmd, tmp, tout;

    while (1) {

        wdogRefresh();

        if (!isServiceMode()) {
            runApp(ADDR_PFL_APP);
        }

        linkToutSet(50);
        linkResetSrc();

        tout = linkRX(&tmp, 1);
        if (tout)continue;
        if (tmp != '+')continue;

        linkToutSet(100);

        tout = linkRX(&tmp, 1);
        if (tout)continue;
        if ((tmp ^ 0xff) != '+')continue;

        tout = linkRX(&cmd, 1);
        if (tout)continue;

        tout = linkRX(&tmp, 1);
        if (tout)continue;
        if ((tmp ^ 0xff) != cmd)continue;

        linkToutSet(0);
        wdogRefresh();
        return cmd;

    }
}

u8 cmd_setSignature() {

    u8 buff[64];
    linkRX(buff, sizeof (buff));
    return sigSet(buff);
}

u8 cmd_usbRecovery() {

    u32 crc;
    u32 addr;

    linkRX(&addr, 4);
    linkRX(&crc, 4);

    boot_ram.upd_addr = addr;
    boot_ram.upd_crc = crc;

    return coreUpdate();
}

void cmd_getUID() {

    u8 uid[8];
    flaGetUID(uid);
    linkTX(uid, sizeof (uid));
}

void cmd_mcuSecure() {

    u8 resp = 0;
    mcuSecure();
    linkTX(&resp, 1);
}

