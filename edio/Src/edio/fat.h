/* 
 * File:   fat.h
 * Author: igor
 *
 * Created on May 17, 2019, 8:48 PM
 */

#ifndef FAT_H
#define	FAT_H

u8 fatInit();
u8 cmd_dirOpen();
u8 cmd_dirRead();
u8 cmd_dirLoad();
void cmd_dirGetSize();
void cmd_dirGetPath();
u8 cmd_dirGetRecs();
u8 cmd_dirMake();
u8 cmd_fileOpen();
u8 cmd_fileRead();
u8 cmd_fileWrite();
u8 cmd_fileWrite_mem();
u8 cmd_fileRead_mem();
u8 cmd_fileClose();
u8 cmd_fileSetPtr();
u8 cmd_fileInfo();
u8 cmd_fileCRC();
u8 cmd_delRecord();
u8 fileRead_mem(u32 addr, u32 len);
u8 fileOpen(u8 *path, u8 mode);
u8 fileClose();


#endif	/* FAT_H */

