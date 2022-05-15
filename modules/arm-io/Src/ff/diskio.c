/*-----------------------------------------------------------------------*/
/* Low level disk I/O module skeleton for FatFs     (C)ChaN, 2016        */
/*-----------------------------------------------------------------------*/
/* If a working storage control module is available, it should be        */
/* attached to the FatFs via a glue function rather than modifying it.   */
/* This is an example of glue functions to attach various exsisting      */
/* storage control modules to the FatFs module with a defined API.       */
/*-----------------------------------------------------------------------*/

#include "ff.h"			/* Obtains integer types */
#include "diskio.h"		/* Declarations of disk functions */
#include "main.h"
#include "edio.h"


/* Definitions of physical drive number for each drive */
#define DEV_RAM		0	/* Example: Map Ramdisk to physical drive 0 */
#define DEV_MMC		1	/* Example: Map MMC/SD card to physical drive 1 */
#define DEV_USB		2	/* Example: Map USB MSD to physical drive 2 */

//extern SD_HandleTypeDef hsd;
/*-----------------------------------------------------------------------*/
/* Get Drive Status                                                      */

/*-----------------------------------------------------------------------*/
DSTATUS dstat;

DSTATUS disk_status(
        BYTE pdrv /* Physical drive nmuber to identify the drive */
        ) {

    return dstat;
}

/*-----------------------------------------------------------------------*/
/* Inidialize a Drive                                                    */

/*-----------------------------------------------------------------------*/

DSTATUS disk_initialize(
        BYTE pdrv /* Physical drive nmuber to identify the drive */
        ) {
    BYTE resp;

    resp = diskInit();
    dstat = 0;
    if (resp)dstat = STA_NOINIT;

    return dstat;
}



/*-----------------------------------------------------------------------*/
/* Read Sector(s)                                                        */

/*-----------------------------------------------------------------------*/

DRESULT disk_read(
        BYTE pdrv, /* Physical drive nmuber to identify the drive */
        BYTE *buff, /* Data buffer to store read data */
        DWORD sector, /* Start sector in LBA */
        UINT count /* Number of sectors to read */
        ) {

    BYTE resp = diskRD(buff, sector, count);
    if (resp)return RES_ERROR;
    return RES_OK;
}



/*-----------------------------------------------------------------------*/
/* Write Sector(s)                                                       */
/*-----------------------------------------------------------------------*/

#if FF_FS_READONLY == 0

DRESULT disk_write(
        BYTE pdrv, /* Physical drive nmuber to identify the drive */
        const BYTE *buff, /* Data to be written */
        DWORD sector, /* Start sector in LBA */
        UINT count /* Number of sectors to write */
        ) {


    BYTE resp = diskWR((BYTE *) buff, sector, count);
    if (resp)return RES_ERROR;
    return RES_OK;
}

#endif


/*-----------------------------------------------------------------------*/
/* Miscellaneous Functions                                               */

/*-----------------------------------------------------------------------*/

DRESULT disk_ioctl(
        BYTE pdrv, /* Physical drive nmuber (0..) */
        BYTE cmd, /* Control code */
        void *buff /* Buffer to send/receive control data */
        ) {
    DRESULT res = RES_ERROR;

    switch (cmd) {
        case CTRL_SYNC:
            res = diskSync();
            res = res == 0 ? RES_OK : RES_ERROR;
            break;

        case GET_SECTOR_COUNT:
            *(DWORD*) buff = 0;
            res = RES_OK;
            break;

        case GET_SECTOR_SIZE:
            *(DWORD*) buff = 512;
            res = RES_OK;
            break;

        case GET_BLOCK_SIZE:
            *(DWORD*) buff = 512;
            res = RES_OK;
            break;
    }

    return res;
}

