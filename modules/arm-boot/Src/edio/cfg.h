/* 
 * File:   cfg.h
 * Author: igor
 *
 * Created on May 18, 2019, 2:47 AM
 */

#ifndef CFG_H
#define	CFG_H

#define u8 uint8_t
#define u16 uint16_t
#define u32 uint32_t
#define u64 uint64_t

#define BOOT_VER        0x0101

#define SPI_FLA         SPI2
#define SPI_FPGA        SPI2
#define SPI_MEM         SPI1

#define SPI_SS_MEM      1
#define SPI_SS_FLA      2


#define USB_BUFF_SIZE   2048
#define ACK_BLOCK_SIZE  1024 //used for streaming operation in case if data comes faster than it can be used. buff overflow protection

#define MAX_STR_LEN     1024
#define MAX_SORT_FILES  1024
#define MAX_SORT_NAME   32
#define MAX_SORT_PAGE   32
#define MAX_RBF_SIZE    368011
#define MAX_UPD_SIZE    0x38000

#define ADDR_PRG        0x000000
#define ADDR_CHR        0x800000
#define ADDR_SRM        0x1000000
#define ADDR_CFG        0x1800000
#define ADDR_FIFO       0x1810000

#define ADDR_OS_PRG     (ADDR_PRG + SIZE_PRG - SIZE_OS_PRG)
#define ADDR_OS_CHR     (ADDR_CHR + SIZE_CHR - SIZE_OS_PRG)

#define ADDR_FLA_MENU   0x00000 //boot fails mos6502 code
#define ADDR_FLA_FPGA   0x40000 //boot fails fpga code
#define ADDR_FLA_ICOR   0x80000 //mcu firmware update
#define ADDR_PFL_BOOT   0x8000000 //bootloader
#define ADDR_PFL_EDSG   0x8007FC0 //signature
#define ADDR_PFL_APP    0x8008000 //main app
#define ADDR_RTC_BRAM   0 //boot ram start


#define SIZE_SRM        0x20000
#define SIZE_PRG        0x800000
#define SIZE_CHR        0x800000
#define SIZE_OS_PRG     0x20000
#define SIZE_OS_CHR     0x4000
#define SIZE_SST        0x6000
#define SIZE_FIFO       0x10000




#endif	/* CFG_H */

