
#include "edio.h"

void mcuEraseSector(u32 sector);
void mcuProgBlock(u8 *src, u32 dst, u32 len);

void mcuProgCore(u32 fla_addr, u32 len) {

    u32 block;
    u8 buff[256];

    HAL_FLASH_Unlock();

    cryptInit();
    flaOpenRead(fla_addr);
    u32 prog_addr = ADDR_PFL_APP;

    while (len) {
        block = sizeof (buff);
        if (block > len)block = len;
        flaRead(buff, block);
        decrypt(buff);
        mcuProgBlock(buff, prog_addr, block);
        len -= block;
        prog_addr += block;
    }
    flaCloseRD();

    HAL_FLASH_Lock();
}

void mcuEraseCore() {

    HAL_FLASH_Unlock();
    for (int i = 2; i < 6; i++) {
        mcuEraseSector(i);
        wdogRefresh();
    }
    HAL_FLASH_Lock();
}

void mcuEraseSector(u32 sector) {

    uint32_t error = 0;
    FLASH_EraseInitTypeDef FLASH_EraseInitStruct = {
        .TypeErase = FLASH_TYPEERASE_SECTORS,
        .Sector = (uint32_t) sector,
        .NbSectors = 1,
        .VoltageRange = FLASH_VOLTAGE_RANGE_3
    };

    HAL_FLASHEx_Erase(&FLASH_EraseInitStruct, &error);
}

void mcuProgBlock(u8 *src, u32 dst, u32 len) {

    while (len) {
        HAL_FLASH_Program(FLASH_TYPEPROGRAM_WORD, dst, *(uint64_t *) src);
        src += 4;
        dst += 4;
        len = len < 4 ? 0 : len - 4;
    }
}

void mcuSecure() {

    FLASH_OBProgramInitTypeDef OBInit = {0};
    HAL_FLASHEx_OBGetConfig(&OBInit);

    if (OBInit.RDPLevel != OB_RDP_LEVEL_1) {

        dbg_print("mcu secure...");

        __disable_irq();


        HAL_FLASH_Unlock();
        HAL_FLASH_OB_Unlock();

        OBInit.OptionType = OPTIONBYTE_WRP | OPTIONBYTE_RDP;
        OBInit.RDPLevel = OB_RDP_LEVEL_1;
        OBInit.WRPState = WRPSTATE_ENABLE;
        OBInit.Banks = FLASH_BANK_1;
        OBInit.WRPSector = 0x03;
        HAL_FLASHEx_OBProgram(&OBInit);
        HAL_FLASH_OB_Launch();

        HAL_FLASH_OB_Lock();
        HAL_FLASH_Lock();

        __enable_irq();

        dbg_append("ok");
    }

}


void mcuProgData(u8 *src, u32 dst, u32 len) {

    __disable_irq();
    HAL_FLASH_Unlock();

    mcuProgBlock(src, dst, len);

    HAL_FLASH_Lock();
    __enable_irq();
}