/* 
 * File:   jmp.h
 * Author: igor
 *
 * Created on May 16, 2022, 6:25 PM
 */

#ifndef JMP_H
#define	JMP_H

#include "rom-config.h"


u8 jmpSetup(u8 *path);
u8 jmpGetVal(u8 *game, RomInfo *inf, u8 *val);
u8 jmpSupported(u8 *path);

#endif	/* JMP_H */

