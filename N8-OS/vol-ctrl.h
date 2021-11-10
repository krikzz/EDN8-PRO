/* 
 * File:   vol-ctrl.h
 * Author: igor
 *
 * Created on July 31, 2019, 12:21 AM
 */

#ifndef VOL_CTRL_H
#define	VOL_CTRL_H

#define MAP_FDS         254
#define MAP_VRC6        24
#define MAP_VRC7        85
#define MAP_N163        19
#define MAP_MMC5        5
#define MAP_SU5B        69

void volOptions();
void volSetDefaults();
u8 volGetMasterVol(u8 map_idx);


#endif	/* VOL_CTRL_H */

