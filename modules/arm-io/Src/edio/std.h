/* 
 * File:   std.h
 * Author: igor
 *
 * Created on May 17, 2019, 8:51 PM
 */

#ifndef STD_H
#define	STD_H

u16 str_lenght(u8 *str);
u16 str_copy(u8 *src, u8 *dst, u16 max_len);
void str_to_upcase_ml(u8 *str, u16 max_len);
void str_append(u8 *src, u8 *dst);
void str_append_num(u32 num, u8 *dst);
void str_append_hex8(u8 num, u8 *dst);
void str_append_hex16(u16 num, u8 *dst);
void str_append_hex32(u32 num, u8 *dst);
u32 crc32(u32 crc, u8* buf, u32 len);
u32 crc7(u8 *buff, u32 len);
void crc16SD_SW(void *src, u16 *crc_out);
u16 crcFast(void *src, u16 len);
u8 hexToDex(u8 val);


#endif	/* STD_H */

