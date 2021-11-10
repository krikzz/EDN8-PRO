/* 
 * File:   gui.h
 * Author: igor
 *
 * Created on April 13, 2019, 1:39 PM
 */

#ifndef GUI_H
#define	GUI_H

#define ACT_EXIT        0xFF
#define ACT_OPEN        0xFE
#define SEL_OFF         0xff
#define SEL_DPD         0x80

typedef struct {
    u8 *hdr;
    u8 ** arg;
    u8 ** val;
    u8 items;
    u8 selector;
    u8 max_arg_len;
    u8 max_val_len;
    u8 skip_init;
} InfoBox;

typedef struct {
    u8 *hdr;
    u8 **items;
    u8 selector;
    u8 act;
} ListBox;

void guiInit();
void guiDrawInfoBox(InfoBox *box);
void guiDrawListBox(ListBox *box);
u8 guiConfirmBox(u8 *str, u8 def);

#endif	/* GUI_H */

