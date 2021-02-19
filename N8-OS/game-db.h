/* 
 * File:   game-db.h
 * Author: igor
 *
 * Created on August 19, 2019, 3:17 PM
 */

#ifndef GAME_DB_H
#define	GAME_DB_H

#include "everdrive.h"

typedef struct {
    u32 crc;
    u8 target;
    u8 val;
} GameDB;

#define SET_NOP 0
#define SET_MIR 1
#define SET_SUB 2
#define SET_MAP 3
#define SET_SRM 4
#define SET_CHR 5

//{0x317607C3, 141, 0, 0}, //Q Boy (Sachen) [!].nes
const GameDB game_db[] = {
    //****************************************************************************** mirroring
    {0xC47EFC0E, SET_MIR, MIR_HOR}, //Trolls on Treasure Island (AVE) [!].nes
    {0x0E76E4C1, SET_MIR, MIR_VER}, //Magic Kid Googoo.nes
    {0x2A01F9D1, SET_MIR, MIR_VER}, //Wagyan Land (J) [!].nes
    {0xE1526228, SET_MIR, MIR_VER}, //Quest of Ki, The (J)
    {0xAE321339, SET_MIR, MIR_VER}, //Pro Yakyuu - Family Stadium '88 (J) [!]
    {0xDCDF06DE, SET_MIR, MIR_VER}, //Pro Yakyuu - Family Stadium (Japan)
    {0x1300A8B7, SET_MIR, MIR_VER}, //Pro Yakyuu - Family Stadium '87 (Japan)
    {0xE40B4973, SET_MIR, MIR_VER}, //Metro-Cross (J) [!].nes
    {0x9D21FE96, SET_MIR, MIR_VER}, //Lupin Sansei - Pandora no Isan (J)
    {0x22D6D5BD, SET_MIR, MIR_VER}, //Jikuu Yuuden - Debias (J)
    {0xA49253C6, SET_MIR, MIR_VER}, //Family Tennis (J) [!]
    {0x9CBC8253, SET_MIR, MIR_VER}, //Family Circuit (J) [!]
    {0x5B4C6146, SET_MIR, MIR_VER}, //Family Boxing (J) [!]
    {0xA5E6BAF9, SET_MIR, MIR_VER}, //Dragon Slayer 4 - Drasle Family (J) [!]
    {0x243A8735, SET_MIR, MIR_1SC}, //Major League (Japan)
    //****************************************************************************** WRAM size    
    {0x93991433, SET_SRM, 0}, //ram off Low G Man - The Low Gravity Man (U) [!]
    {0xFCBF28B1, SET_SRM, 2}, //ram 2k. Crisis Force
    {0x895037BC, SET_SRM, 2}, //Family BASIC (Revision A1) 
    {0xF7606810, SET_SRM, 2}, //Family BASIC (J) (V2.0a)
    {0xC247CC80, SET_SRM, 2}, //Family Circuit '91 
    {0x5ADBF660, SET_SRM, 2}, //Gradius II 
    {0xFA7E02FA, SET_SRM, 2}, //Hayauchi Super Igo 
    {0xD467C0CC, SET_SRM, 2}, //Parodius Da! 
    {0x912989DC, SET_SRM, 2}, //Playbox BASIC (Prototype) 
    {0xB2530AFC, SET_SRM, 4}, //Family BASIC (J) (V3.0)
    {0x15FE6D0F, SET_SRM, 16}, //Bandit Kings of Ancient China 
    {0xFE3488D1, SET_SRM, 16}, //Daikoukai Jidai 
    {0x1CED086F, SET_SRM, 16}, //Ishin no Arashi 
    {0x9C18762B, SET_SRM, 16}, //L'Empereur nes
    {0x6396B988, SET_SRM, 16}, //L'Empereur fami
    {0xEEE9A682, SET_SRM, 16}, //Nobunaga no Yabou: Sengoku Gunyuuden
    {0xF9B4240F, SET_SRM, 16}, //Nobunaga no Yabou: Sengoku Gunyuuden  Rev A
    {0x8CE478DB, SET_SRM, 16}, //Nobunaga's Ambition II
    {0x39F2CE4B, SET_SRM, 16}, //Suikoden: Tenmei no Chikai
    {0x2225C20F, SET_SRM, 16}, //Genghis Khan
    {0x4642DDA6, SET_SRM, 16}, //Nobunaga's Ambition
    {0xC6182024, SET_SRM, 16}, //Romance of the Three Kingdoms 
    {0xACA15643, SET_SRM, 16}, //Uncharted Waters (U) [!]
    {0xC3DE7C69, SET_SRM, 32}, //Best Play Pro Yakyuu Special, The (Revision A) 
    {0xB8747ABF, SET_SRM, 32}, //Best Play Pro Yakyuu Special (J)
    {0x6F4E4312, SET_SRM, 32}, //Aoki Ookami to Shiroki Mejika - Genchou Hishi
    {0xF540677B, SET_SRM, 32}, //Nobunaga no Yabou: Bushou Fuuunroku
    {0xF011E490, SET_SRM, 32}, //Romance of the Three Kingdoms II
    {0x184C2124, SET_SRM, 32}, //Sangokushi II 
    {0xFDC7C50B, SET_SRM, 64}, //simcity 
    //****************************************************************************** CHR size
    {0x9D048EA4, SET_CHR, 32}, //Oeka Kids: Anpanman to Oekaki Shiyou!! 
    {0x5E66EAEA, SET_CHR, 32}, //Videomation (USA)
    {0xF6A9CB75, SET_CHR, 64}, //Racermate Challenge II (Europe) (v9.03.128) (Unl)
    {0x74920C13, SET_CHR, 64}, //Racermate Challenge II (USA) (v3.11.088) (Unl)
    {0xAAEF2264, SET_CHR, 64}, //Racermate Challenge II (USA) (v5.01.033) (Unl)
    {0x3E59E951, SET_CHR, 64}, //Racermate Challenge II (USA) (v6.02.002) (Unl)
    //****************************************************************************** submappers    
    {0x998422FC, SET_SUB, 1}, //MMC6 Startropics (E) [!].nes
    {0x889129CB, SET_SUB, 1}, //MMC6 Startropics (U) [!].nes
    {0xD054FFB0, SET_SUB, 1}, //MMC6 Startropics II - Zoda's Revenge (U) [!]
    {0x563E394A, SET_SUB, 1}, //Mahjong Academy (Asia) (Unl)
    {0xFCBF28B1, SET_SUB, 2}, //Crisis Force 
    {0xAC8DCDEA, SET_SUB, 2}, //Bus conflicts. Cybernoid - The Fighting Machine (USA)
    {0xA80A0F01, SET_SUB, 3}, //Acclaim MMC3. Incredible Crash Dummies, The (USA)
    {0x982DFB38, SET_SUB, 3}, //Acclaim MMC3. Mickey's Safari in Letterland (USA)
    {0xF312D1DE, SET_SUB, 4}, //MMC3A. 5.MMC3_rev_A.nes
    {0x8A96E00D, SET_SUB, 3}, //VRC2. Wai Wai World (Japan) 
    {0xB27B8CF4, SET_SUB, 3}, //Contra (Japan)
    //****************************************************************************** mappers reloc    
    {0xFB2B6B10, SET_MAP, 241}, //Fan Kong Jing Ying (Ch).nes
    {0xB5E83C9A, SET_MAP, 241}, //Xing Ji Zheng Ba (Ch).nes
    {0x7678F1D5, SET_MAP, 207}, //Fudou Myouou Den (J) [!]
    {0xD1691028, SET_MAP, 154}, //Devil Man (J).nes
    {0x983D8175, SET_MAP, 157}, //Datach - Battle Rush - Build Up Robot Tournament (J)
    {0x58CFE142, SET_MAP, 4}, //Summer Carnival '92 - Recca (U).nes
    {0x282745C5, SET_MAP, 141}, //Q Boy (Asia) (Unl)
    {0x86DBA660, SET_MAP, 0}, //3-D Block (Asia) 
    {0x07EB2C12, SET_MAP, 208}, //Street Fighter IV (Unl)
    {0x1BC0BE6C, SET_MAP, 195}, //Captain Tsubasa Vol. II - Super Striker (Ch) [a3]
    {0x26EF50E3, SET_MAP, 195}, //Captain Tsubasa Vol. II - Super Striker (Ch)
    {0x555A555E, SET_MAP, 191}, //Sugoro Quest - Dice no Senshi Tachi (Ch)
    {0x96CE586E, SET_MAP, 189}, //Street Fighter II - The World Warrior (Unl) [!]
    {0xD5224FDE, SET_MAP, 195}, //Waixing's Chinese translation of SNK's God Slayer/Crystalis.


    {0, 0, 0}//db end
};


#endif	/* GAME_DB_H */


