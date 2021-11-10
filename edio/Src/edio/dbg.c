

#include "edio.h"


//extern UART_HandleTypeDef huart1;

void dbg_print(void *str) {

    static u8 end[2] = {0x0D, 0x0A};
    dbg_tx_data(end, 2);
    dbg_append(str);

}

void dbg_append(void *str) {

    int str_len = str_lenght((u8 *) str);
    if (str_len > 255)str_len = 255;
    dbg_tx_data(str, str_len);
}

void dbg_append_h8(u8 val) {

    u8 buff[16];
    buff[0] = 0;
    str_append_hex8(val, buff);
    dbg_append(buff);
}

void dbg_append_h16(u16 val) {

    u8 buff[16];
    buff[0] = 0;
    str_append_hex16(val, buff);
    dbg_append(buff);
}

void dbg_append_h32(u32 val) {

    u8 buff[16];
    buff[0] = 0;
    str_append_hex32(val, buff);
    dbg_append(buff);
}

void dbg_append_hex(void *data, u32 len) {

    while (len--)dbg_append_h8(*((u8 *) data++));
}

void dbg_append_num(u32 val) {

    u8 buff[16];
    buff[0] = 0;

    str_append_num(val, buff);
    dbg_append(buff);
}

void dbg_tx_data(u8 *data, u32 len) {
    uartTX(USART1, data, len);
}