/* 
 * File:   error.h
 * Author: igor
 *
 * Created on May 18, 2019, 2:51 AM
 */

#ifndef ERROR_H
#define	ERROR_H

#define ERR_STR_SIZE    0x80
#define ERR_OUT_OF_DIR  0x81
#define ERR_OUT_OF_PAGE 0x82
#define ERR_BOOT_FAULT  0x83
#define ERR_FPGA_INIT   0x84
#define ERR_SPI_STATE   0x85

#define ERR_LINK_TOUT   0x86
#define ERR_UPD_SIZE    0x87
#define ERR_UPD_SAME    0x88
#define ERR_UPD_CORUPT  0x89
#define ERR_UPD_BT_CRC  0x8A
#define ERR_UPD_VERIFY  0x8B
#define ERR_WDG_TOUT    0x8C
#define ERR_SIG_NBLA    0x8D

#define DISK_ERR_INIT   0xC0
#define DISK_ERR_RD1    0xD0
#define DISK_ERR_RD2    0xD1 
#define DISK_ERR_RD3    0xD2
#define DISK_ERR_RD4    0xD3

#define DISK_ERR_WR1    0xD4
#define DISK_ERR_WR2    0xD5
#define DISK_ERR_WR3    0xD6
#define DISK_ERR_WR4    0xD7
#define DISK_ERR_WR5    0xD8

#define DISK_ERR_CTO    0xD9//cmd timeout
#define DISK_ERR_CCR    0xDA//cmd crc error

#endif	/* ERROR_H */

