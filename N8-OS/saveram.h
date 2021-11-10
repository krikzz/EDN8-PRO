/* 
 * File:   saveram.h
 * Author: igor
 *
 * Created on April 14, 2019, 2:36 PM
 */

#ifndef SAVERAM_H
#define	SAVERAM_H

u8 srmBackup();
u8 srmRestore();
u8 srmBackupSS(u8 bank);
u8 srmRestoreSS(u8 bank);
u8 srmGetInfoSS(FileInfo *inf, u8 bank);
u8 srmFileToMem(u8 *path, u32 addr, u32 max_size);
u8 srmMemToFile(u8 *path, u32 addr, u32 len);
u8 srmRestoreFDS();
u8 srmBackupFDS();
u8 srmBackupPRG();

#endif	/* SAVERAM_H */

