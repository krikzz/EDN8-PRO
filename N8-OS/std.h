/* 
 * File:   str.h
 * Author: igor
 *
 * Created on April 3, 2019, 4:43 PM
 */

#ifndef STR_H
#define	STR_H

#define SYNC_IDX_OFF    0xff

void std_init();
u8* str_append(u8 *dst, u8 *src);
u8 *str_append_num(u8 *dst, u32 num);
u8 *str_append_hex8(u8 *dst, u8 num);
u8 *str_append_hex16(u8 *dst, u16 num);
u8 *str_append_hex32(u8 *dst, u32 num);
u8 *str_append_bin8(u8 *dst, u8 num);
u16 str_lenght(u8 *str);
u8 str_extension(u8 *target, u8 *str);
u8 str_extension_list(u8 **ext_list, u8 *name);
u8 str_cmp_ncase(u8 *str1, u8 *str2);
u8 str_cmp_len(u8 *str1, u8 *str2, u16 len);
void str_copy(u8 *src, u8 *dst);
u8 *str_extract_fname(u8 *str);
u8 *str_extract_ext(u8 *str);
u8* str_append_date(u8 *dst, u16 date);
u8* str_append_time(u8 *dst, u16 time);
u16 str_last_index_of(u8 *str, u8 val);
void mem_set(void *dst, u8 val, u16 len);
void mem_copy(void *src, void *dst, u16 len);
u8 mem_cmp(void *src, void *dst, u16 len);
u8 mem_tst(void *str, u8 val, u16 len);
void *malloc(u16 size);
void free(u16 size);
u16 crcFast(void *src, u16 len);
u32 max(u32 v1, u32 v2);
u32 min(u32 v1, u32 v2);
u32 inc_mod(u32 val, u32 mod);
u32 dec_mod(u32 val, u32 mod);

u8 decToBcd(u8 val);
u8 bcdToDec(u8 val);

#endif	/* STR_H */

