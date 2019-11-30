/* 
 * File:   cfg.h
 * Author: igor
 *
 * Created on March 28, 2019, 5:03 PM
 */

#ifndef CFG_H
#define	CFG_H

#include "bios.h"


#define OS_VER          0x0200


#define PATH_OS         "EDN8/nesos.nes"
#define PATH_MAP        "EDN8/MAPS"
#define PATH_MAPROUT    "EDN8/MAPROUT.BIN"
#define PATH_REGISTERY  "EDN8/registery.bin"
#define PATH_SAVE_DIR   "EDN8/SAVE"
#define PATH_SNAP_DIR   "EDN8/SNAP"
#define PATH_CHEATS     "EDN8/CHEATS"
#define PATH_RECENT     "EDN8/recent.bin"
#define PATH_RAMDUMP    "EDN8/ramdump01.srm"
#define PATH_TESTFILE   "EDN8/tstfile01.bin"
#define PATH_SDC_FILE   "EDN8/MAPS/255.RBF"
#define PATH_NSF_PLAYER "EDN8/n8nsf.nes"
#define PATH_UPD_FPGA   "EDN8/UPDATE/menu-fpg.bin"
#define PATH_UPD_MENU   "EDN8/UPDATE/menu-cpu.bin"
#define PATH_UPD_IOCORE "EDN8/UPDATE/iocore.bin"

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

#define RAM_NULL        0x00 //fill sram by this value

#endif	/* CFG_H */

