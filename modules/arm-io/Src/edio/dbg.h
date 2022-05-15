/* 
 * File:   dbg.h
 * Author: igor
 *
 * Created on May 17, 2019, 8:46 PM
 */

#ifndef DBG_H
#define	DBG_H

void dbg_print(void *str);
void dbg_append(void *str);
void dbg_append_h8(u8 val);
void dbg_append_h16(u16 val);
void dbg_append_h32(u32 val);
void dbg_append_hex(void *data, u32 len);
void dbg_append_num(u32 val);
void dbg_tx_data(u8 *data, u32 len);

#endif	/* DBG_H */

