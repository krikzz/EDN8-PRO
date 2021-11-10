/* 
 * File:   var.h
 * Author: igor
 *
 * Created on August 19, 2019, 3:50 PM
 */

#ifndef VAR_H
#define	VAR_H

u8 fmanager();
void fmInitMemory();
void fmForceUpdate();

u8 mainMenu();
u8 fileMenu(u8 *path);
u8 recentMenu();
u8 recentAdd(u8 *path);

u8 ggEdit(u8 *src, u8 *game);
u8 ggLoadCodes(CheatList *gg, u8 *game);

void rtcSetup();
void rtcReset();

#endif	/* VAR_H */

