/* 
 * File:   cfg.h
 * Author: igor
 *
 * Created on March 28, 2019, 5:03 PM
 */

#ifndef CFG_H
#define	CFG_H

#include "bios.h"

#define PATH_OS         "EDN8/nesos.nes"

#define G_SCREEN_W      32
#define G_SCREEN_H      28

#define MAX_PATH_SIZE   512
#define MAX_NAME_SIZE   208

#define MAX_ROWS        (G_SCREEN_H - G_BORDER_Y * 2 - INF_ROWS - 3)
#define MAX_STR_LEN     (G_SCREEN_W - G_BORDER_X * 2)
#define MAX_SEL_STACK   32
#define MAX_GG_FSIZE    512
#define MAX_RECENT      12
#define MAX_SS_SLOTS    100
#define MAX_ID_CALC_LEN 0x100000
#define MAX_FDS_SIZE    (SIZE_FDS_DISK * 4)
#define MAX_UPD_SIZE    0x40000

#define MALLOC_BASE     (0x5000+16)//first 16 bytes reserved. at least for save state
#define MALLOC_SIZE     (0x1000-16)

#define G_BORDER_X      1
#define G_BORDER_Y      1

#define JOY_DELAY       250 
#define JOY_SPEED       70

#define INF_ROWS        2



#endif	/* CFG_H */

