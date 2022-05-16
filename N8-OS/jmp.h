/* 
 * File:   jmp.h
 * Author: igor
 *
 * Created on May 16, 2022, 6:25 PM
 */

#ifndef JMP_H
#define	JMP_H

u8 jmpSetup(u8 *path);
u8 jmpGetSize(u8 map_idx);
u8 jmpGetVal(u8 *game, u8 map_idx, u8 *val);

#endif	/* JMP_H */

