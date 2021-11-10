/* 
 * File:   gfx.h
 * Author: igor
 *
 * Created on March 28, 2019, 5:02 PM
 */

#ifndef GFX_H
#define	GFX_H

#define G_LEFT          1
#define G_CENTER        2

void gInit();
void gSetPal(u8 pal);
void gSetXY(u8 x, u8 y);
void gSetX(u8 x);
void gSetY(u8 y);
u8 gGetY();
u8 gGetX();
void gCleanScreen();
void gAppendString(u8 *str);
void gAppendString_ML(u8 *str, u8 max_len);
void gAppendHex4(u8 val);
void gAppendHex8(u8 val);
void gAppendHex16(u16 val);
void gAppendHex32(u32 val);
void gAppendNum(u32 num);
void gAppendDate(u16 date);
void gAppendTime(u16 time);
void gConsPrint(u8 *str);
void gConsPrint_ML(u8 *str, u8 maxlen);
void gConsPrintCX(u8 *str);
void gConsPrintCX_ML(u8 *str, u8 maxlen);
void gAppendChar(u8 chr);
void gFillRect(u8 val, u8 x, u8 y, u8 w, u8 h);
void gFillRow(u8 val, u8 x, u8 y, u8 w);
void gFillCol(u8 val, u8 x, u8 y, u8 h);
void gDrawHeader(u8 *str, u8 attr);
void gDrawFooter(u8 *str, u8 rows, u8 attr);
void gAppendHex(void *src, u16 len);
void gRepaint();




#endif	/* GFX_H */

