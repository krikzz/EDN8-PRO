/* 
 * File:   fs.h
 * Author: igor
 *
 * Created on November 17, 2021, 3:23 PM
 */

#ifndef FS_H
#define	FS_H



u8 fileOpen(u8 *path, u8 mode);
u8 fileRead_mem(u32 dst, u32 len);
u8 fileRead(void *dst, u32 len);
u8 fileWrite_mem(u32 src, u32 len);
u8 fileWrite(void *src, u32 len);
u8 fileClose();
u8 fileCopy(u8 *src, u8 *dst);
u8 fileOpenSync(u8 *dirname, u8 *fname, u8 *ext, u8 mode);
void fatMakeSyncPath(u8 *path, u8 *dirname, u8 *fname, u8 *ext);
void fatAppenIdx(u8 *path, u8 idx);
u8 fileGetInfo(u8 *path, FileInfo *inf);

#endif	/* FS_H */

