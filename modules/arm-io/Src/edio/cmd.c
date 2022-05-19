

#include "edio.h"


void mcuBusy(u8 state);
u8 cmdRX();

extern SysInfoIO sys_inf;

u8 sys_pwr_initial;

void cmdProcessor(u8 status) {

    u8 cmd = 0;
    u8 link_src = LINK_SRC_FIFO;

    sys_pwr_initial = gpioRD_pin(pwr_sys_GPIO_Port, pwr_sys_Pin);


    while (1) {

        led(0);
        if (link_src == LINK_SRC_FIFO)mcuBusy(0);
        cmd = cmdRX();
        link_src = linkGetSrc();
        if (link_src == LINK_SRC_FIFO)mcuBusy(1); //cmd_ok flag should triger only on fifo operations
        led(1);

        //dbg_print("cmd: ");
        //dbg_append_h8(cmd);

        wdogRefresh();


        switch (cmd) {

            case CMD_STATUS:
                cmd_status(status);
                break;
            case CMD_FPG_USB:
                status = cmd_fpgInitUSB();
                break;
            case CMD_FPG_SDC:
                status = cmd_fpgInitSDC();
                break;
            case CMD_FPG_FLA:
                status = cmd_fpgInitFLA();
                break;
            case CMD_FPG_CFG:
                cmd_fpgInitCFG();
                break;
            case CMD_USB_WR:
                cmd_usb_wr();
                break;
            case CMD_FIFO_WR:
                cmd_fifo_wr();
                break;
            case CMD_UART_WR:
                cmd_uart_wr();
                break;

            case CMD_DISK_INIT:
                status = cmd_init_sd();
                break;
            case CMD_DISK_RD:
                status = cmd_diskRead();
                break;
            case CMD_DISK_WR:
                status = cmd_diskWrite();
                break;

            case CMD_F_DIR_MK:
                status = cmd_dirMake();
                break;

            case CMD_F_DEL:
                status = cmd_delRecord();
                break;

            case CMD_F_DIR_OPN:
                status = cmd_dirOpen();
                break;
            case CMD_F_DIR_RD:
                status = cmd_dirRead();
                break;
            case CMD_F_DIR_LD:
                status = cmd_dirLoad();
                break;
            case CMD_F_DIR_SIZE:
                cmd_dirGetSize();
                break;
            case CMD_F_DIR_PATH:
                cmd_dirGetPath(); //fat engine has internal path string?
                break;
            case CMD_F_DIR_GET:
                status = cmd_dirGetRecs();
                break;
            case CMD_F_FOPN:
                status = cmd_fileOpen();
                break;
            case CMD_F_FRD:
                status = cmd_fileRead();
                break;
            case CMD_F_FRD_MEM:
                status = cmd_fileRead_mem();
                break;
            case CMD_F_FWR:
                status = cmd_fileWrite();
                break;
            case CMD_F_FWR_MEM:
                status = cmd_fileWrite_mem();
                break;
            case CMD_F_FCLOSE:
                status = cmd_fileClose();
                break;
            case CMD_F_FPTR:
                status = cmd_fileSetPtr();
                break;
            case CMD_F_FINFO:
                status = cmd_fileInfo();
                break;
            case CMD_F_FCRC:
                status = cmd_fileCRC();
                break;
            case CMD_F_AVB:
                cmd_fileAvailable();
                break;
            case CMD_F_FCP:
                status = cmd_fileCopy();
                break;
            case CMD_F_FMV:
                status = cmd_fileMove();
                break;

            case CMD_MEM_WR:
                cmd_memWR();
                break;
            case CMD_MEM_RD:
                cmd_memRD();
                break;
            case CMD_MEM_SET:
                cmd_memSet();
                break;
            case CMD_MEM_TST:
                cmd_memTst();
                break;
            case CMD_MEM_CRC:
                cmd_memCRC();
                break;

            case CMD_FLA_RD:
                cmd_flaRead();
                break;
            case CMD_FLA_WR:
                cmd_flaWrite();
                status = 0; //for timeout check
                break;
            case CMD_FLA_WR_SDC:
                status = cmd_flaWriteSDC();
                break;
            case CMD_UPD_EXEC:
                cmd_upd_exec();
                break;

            case CMD_GET_VDC:
                cmd_get_vdc();
                break;

            case CMD_RTC_GET:
                cmd_rtc_get();
                break;

            case CMD_RTC_SET:
                bootRamRstAck();
                cmd_rtc_set();
                break;

            case CMD_SYS_INF:
                cmd_sys_info();
                break;

            case CMD_REINIT:
                status = cmd_reboot();
                break;

            case CMD_GAME_CTR:
                cmd_game_ctr();
                break;

            case CMD_GET_MODE:
                cmd_getMode(0xA2);
                break;

            case CMD_HARD_RESET:
                cmd_hard_reset();
                break;
        }
    }
}

u8 cmdRX() {

    u8 cmd, tmp, tout, sys_pwr, cmd_rx;


    cmd_rx = 0;
    while (1) {

        wdogRefresh();

        if (cmd_rx) {
            dbg_print("cmd timeout");
            cmd_rx = 0;
        }

        sys_pwr = gpioRD_pin(pwr_sys_GPIO_Port, pwr_sys_Pin);

        if (sys_pwr == 0 && sys_pwr_initial != 0) {
            NVIC_SystemReset();
        }

        linkToutSet(100);
        linkResetSrc();

        tout = linkRX(&tmp, 1);
        if (tout)continue;
        if (tmp != '+')continue;
        cmd_rx = 1;

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

void mcuBusy(u8 state) {

    gpioWR_port(mcu_busy_GPIO_Port, mcu_busy_Pin, state);
}