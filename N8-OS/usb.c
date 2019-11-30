

#include "everdrive.h"

void app_usbListener();

void usbListener() {

    u8 bank = REG_APP_BANK;
    REG_APP_BANK = APP_USB;
    app_usbListener();
    REG_APP_BANK = bank;
}

#pragma codeseg ("BNK06")


#define USB_CMD_TEST            't'
#define USB_CMD_REBOOT          'r'
#define USB_CMD_HALT            'h'
#define USB_CMD_SEL_GAME        'n'
#define USB_CMD_RUN_GAME        's'

void usbSelectGame();

void app_usbListener() {

    u8 cmd;
    u8 resp;

    while (1) {

        if (bi_fifo_busy())return;
        bi_fifo_rd(&cmd, 1);
        if (cmd != '*')continue;

        bi_fifo_rd(&cmd, 1);

        if (cmd == USB_CMD_TEST) {
            resp = 'k';
            bi_cmd_usb_wr(&resp, 1);
            return;
        }

        if (cmd == USB_CMD_REBOOT) {
            ppuOFF();
            bi_reboot_usb();
        }

        if (cmd == USB_CMD_HALT) {
            ppuOFF();
            bi_halt_usb(); //wait till usb access memory
            ppuON();
            return;
        }

        if (cmd == USB_CMD_SEL_GAME) {
            usbSelectGame();
        }

        if (cmd == USB_CMD_RUN_GAME) {
            resp = edStartGame(1);
            printError(resp);
        }

    }

}

void usbSelectGame() {

    u8 resp;
    u8 *path = malloc(MAX_PATH_SIZE);

    bi_rx_string(path);

    resp = edSelectGame(path, 0);
    free(MAX_PATH_SIZE);
    bi_cmd_usb_wr(&resp, 1);


    if (resp == 0) {
        bi_cmd_usb_wr(&registery->cur_game.rom_inf.mapper, 1);
    }
}


