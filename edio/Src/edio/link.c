

#include "edio.h"
#include "usbd_cdc_if.h"



u8 fifoBusy();
void usbFlush();
u8 linkTout();


u8 usb_rx_buff[USB_BUFF_SIZE];
volatile u32 usb_buff_sta;
volatile u32 usb_buff_end;

u8 link_src;
u32 link_to_start;
u32 link_to_time;

void linkInit() {
    usbFlush();
    link_src = LINK_SRC_AUTO;
}
//****************************************************************************** USB

void usbFlush() {
    usb_buff_sta = 0;
    usb_buff_end = 0;
}

void usbCallback(u8 *buff, u32 len) {

    
    u32 block;

    while (len) {

        block = len;
        block = MIN(len, (USB_BUFF_SIZE - usb_buff_end));
        memcpy(&usb_rx_buff[usb_buff_end], buff, block);//not sure if memcopy working safe in terms os dma colision

        len -= block;
        buff += block;
        usb_buff_end += block;
        usb_buff_end &= (USB_BUFF_SIZE - 1);
    }

    /*
    while (len--) {

        usb_rx_buff[usb_buff_end++] = *buff++;
        usb_buff_end %= USB_BUFF_SIZE;
    }*/

}

int usbAvailable() {

    volatile int end = usb_buff_end;

    if (end != usb_buff_end)end = usb_buff_end;


    if (usb_buff_sta <= end) {
        return end - usb_buff_sta;
    } else {
        return end + (USB_BUFF_SIZE - usb_buff_sta);
    }
}

u8 usbRD(u8 *buff, u32 len) {

    u32 block;

    while (len) {

        block = 0;
        while (block == 0) {
            block = usbAvailable();
            if (linkTout())return ERR_LINK_TOUT;
        }

        if (block > len)block = len;
        len -= block;

        while (block--) {
            *buff++ = usb_rx_buff[usb_buff_sta++];
            usb_buff_sta %= USB_BUFF_SIZE;
        }

    }

    return 0;
}

void usbWR(u8 *buff, u32 len) {

    if (len == 0)return;
    int block;
    u32 wait_time = 100;
    u32 start_time;

    while (len) {

        block = 56;
        if (block > len)block = len;

        start_time = HAL_GetTick();
        while (1) {
            if (CDC_Transmit_FS(buff, block) == 0)break;
            if ((HAL_GetTick() - start_time) > wait_time)return;
        }

        len -= block;
        buff += block;
    }



}


//****************************************************************************** FIFO

u8 fifoBusy() {

    return gpioRD_pin(fifo_rxf_GPIO_Port, fifo_rxf_Pin);
}

u8 fifoRD(void *data, u16 len) {


    if (len == 0)return 0;

    //HAL_Delay(1);
    while (fifoBusy()) { //wait before open read. first byte will be moved to spi register at opening
        if (linkTout())return ERR_LINK_TOUT;
    }
    memOpenRead(ADDR_FIFO + (SIZE_FIFO - len));

    while (len--) {


        while (len != 0 && fifoBusy()) {

            if (linkTout()) {
                memCloseRW();
                return ERR_LINK_TOUT;
            }
        }

        memRead(data, 1);

        data++;

    }

    memCloseRW();

    return 0;
}

void fifoWR(void *data, u16 len) {

    memOpenWrite(ADDR_FIFO);
    memWrite(data, len);
    memCloseRW();
}


//****************************************************************************** link 

u8 linkRX(void *data, u16 len) {

    u8 resp = 0;
    if (len == 0)return 0;


    if (link_src == LINK_SRC_AUTO) {

        while (fifoBusy() && !usbAvailable()) {
            if (linkTout())return ERR_LINK_TOUT;
        }

        if (!fifoBusy()) {
            link_src = LINK_SRC_FIFO;
        } else {
            link_src = LINK_SRC_USB;
        }
    }


    if (link_src == LINK_SRC_FIFO) {
        resp = fifoRD(data, len);
    } else {
        resp = usbRD(data, len);
    }

    return resp;

}

u8 linkRX_ack(void *data, u16 len) {
    u8 ack = 0;
    linkTX(&ack, 1);
    return linkRX(data, len);
}

void linkTX(void *data, u16 len) {

    if (len == 0)return;

    if (link_src == LINK_SRC_FIFO) {
        fifoWR(data, len);
    } else {
        usbWR(data, len);
    }
}

void linkResetSrc() {

    link_src = LINK_SRC_AUTO;
}

u8 linkGetSrc() {

    return link_src;
}

//****************************************************************************** timeout

void linkToutSet(u32 timeout) {

    link_to_start = HAL_GetTick();
    link_to_time = timeout;
}

u8 linkTout() {

    if (link_to_time == 0)return 0;
    if ((HAL_GetTick() - link_to_start) < link_to_time)return 0;
    return 1;
}
