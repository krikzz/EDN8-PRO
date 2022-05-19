/* 
 * File:   signature.h
 * Author: igor
 *
 * Created on August 8, 2019, 1:09 PM
 */

#ifndef SIGNATURE_H
#define	SIGNATURE_H

typedef struct {
    u8 uid_number[8];
    u8 flash_uid[8];
    u32 serial_l;
    u32 serial_g;
    u16 date;
    u16 time;
    u8 manufac_id;
    u8 hv_rev;
    u8 device_id;
    u8 valid;
    u8 dev_mode;
} Signature;

void sigInit();

#endif	/* SIGNATURE_H */

