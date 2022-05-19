
#include <string.h>
#include "edio.h"


u8 strRX(u8 *buff, u16 max_len) {

    u16 len = 0;
    linkRX(&len, 2);
    if (len > max_len)return ERR_STR_SIZE;
    linkRX(buff, len);
    buff[len] = 0;

    return 0;
}

void strTX(u8 *buff, u16 max_len) {

    u16 str_len = str_lenght(buff);

    if (str_len > max_len)str_len = max_len;
    linkTX(&str_len, 2);
    linkTX(buff, str_len);
}

void led(u8 val) {

    if (val) {
        led_GPIO_Port->ODR |= GPIO_PIN_5;
    } else {
        led_GPIO_Port->ODR &= ~GPIO_PIN_5;
    }
}

//******************************************************************************
//******************************************************************************

void cmd_status(u8 status) {

    u16 val = 0xA500 | status;
    linkTX(&val, 2);
}

void cmd_hard_reset() {
    u8 ack;
    linkRX(&ack, 1); //exec
    NVIC_SystemReset();
}

void cmd_getMode(u8 mode) {

    linkTX(&mode, 1);
}
