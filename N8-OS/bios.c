
#include "everdrive.h"

#define CMD_STATUS      0x10
#define CMD_GET_MODE    0x11
#define CMD_HARD_RESET  0x12
#define CMD_GET_VDC     0x13
#define CMD_RTC_GET     0x14
#define CMD_RTC_SET     0x15
#define CMD_FLA_RD      0x16
#define CMD_FLA_WR      0x17
#define CMD_FLA_WR_SDC  0x18
#define CMD_MEM_RD      0x19
#define CMD_MEM_WR      0x1A
#define CMD_MEM_SET     0x1B
#define CMD_MEM_TST     0x1C
#define CMD_MEM_CRC     0x1D
#define CMD_FPG_USB     0x1E
#define CMD_FPG_SDC     0x1F
#define CMD_FPG_FLA     0x20
#define CMD_FPG_CFG     0x21
#define CMD_USB_WR      0x22
#define CMD_FIFO_WR     0x23
#define CMD_UART_WR     0x24
#define CMD_REINIT      0x25
#define CMD_SYS_INF     0x26
#define CMD_GAME_CTR    0x27
#define CMD_UPD_EXEC    0x28


#define CMD_DISK_INIT   0xC0
#define CMD_DISK_RD     0xC1
#define CMD_DISK_WR     0xC2
#define CMD_F_DIR_OPN   0xC3
#define CMD_F_DIR_RD    0xC4
#define CMD_F_DIR_LD    0xC5
#define CMD_F_DIR_SIZE  0xC6
#define CMD_F_DIR_PATH  0xC7
#define CMD_F_DIR_GET   0xC8
#define CMD_F_FOPN      0xC9
#define CMD_F_FRD       0xCA
#define CMD_F_FRD_MEM   0xCB
#define CMD_F_FWR       0xCC
#define CMD_F_FWR_MEM   0xCD
#define CMD_F_FCLOSE    0xCE
#define CMD_F_FPTR      0xCF
#define CMD_F_FINFO     0xD0
#define CMD_F_FCRC      0xD1
#define CMD_F_DIR_MK    0xD2
#define CMD_F_DEL       0xD3



#define ACK_BLOCK_SIZE  1024


void bi_reboot_exec();
void bi_halt_exec();
void bi_reboot(u8 status);
void bi_halt(u8 status);

void bi_cmd_make(u8 cmd, u8 *buff);
void bi_cmd_tx(u8 cmd);
void bi_rx_file_info(FileInfo *inf);
u8 bi_fifo_rd_skip(u16 len);

void bi_fifo_read();
void bi_fifo_write();
void bi_run_dma();

u8 bi_init() {

    u8 resp;
    FileInfo inf = {0};

    REG_APP_BANK = 0;

    //flush fifo buffer
    while (!bi_fifo_busy()) {
        bi_fifo_rd_skip(1);
    }

    resp = bi_check_status();

    if (resp == 0) {
        resp = bi_cmd_file_info(PATH_OS, &inf);
    }

    if (resp) {

        resp = bi_cmd_disk_init();
        if (resp)return resp;

    }

    return 0;
}
//****************************************************************************** edio commands

void bi_cmd_make(u8 cmd, u8 *buff) {

    buff[0] = '+';
    buff[1] = '+' ^ 0xff;
    buff[2] = cmd;
    buff[3] = cmd ^ 0xff;
}

void bi_cmd_tx(u8 cmd) {

    u8 buff[4];

    buff[0] = '+';
    buff[1] = '+' ^ 0xff;
    buff[2] = cmd;
    buff[3] = cmd ^ 0xff;

    bi_fifo_wr(buff, sizeof (buff));
}

void bi_cmd_status(u16 *status) {

    bi_cmd_tx(CMD_STATUS);
    bi_fifo_rd(status, 2);
}

u8 bi_cmd_disk_init() {

    bi_cmd_tx(CMD_DISK_INIT);
    return bi_check_status();
}

u8 bi_cmd_dir_load(u8 *path, u8 sorted) {

    bi_cmd_tx(CMD_F_DIR_LD);
    bi_fifo_wr(&sorted, 1);
    bi_tx_string(path);

    return bi_check_status();
}

void bi_cmd_dir_get_size(u16 *size) {

    bi_cmd_tx(CMD_F_DIR_SIZE);
    bi_fifo_rd(size, 2);
}

void bi_cmd_dir_get_recs(u16 start_idx, u16 amount, u16 max_name_len) {

    bi_cmd_tx(CMD_F_DIR_GET);
    bi_fifo_wr(&start_idx, 2);
    bi_fifo_wr(&amount, 2);
    bi_fifo_wr(&max_name_len, 2);
}

void bi_cmd_uart_wr(void *data, u16 len) {

    bi_cmd_tx(CMD_UART_WR);
    bi_fifo_wr(&len, 2);
    bi_fifo_wr(data, len);
}

void bi_cmd_usb_wr(void *data, u16 len) {

    bi_cmd_tx(CMD_USB_WR);
    bi_fifo_wr(&len, 2);
    bi_fifo_wr(data, len);
}

void bi_cmd_fifo_wr(void *data, u16 len) {//write to own fifo buffer

    bi_cmd_tx(CMD_FIFO_WR);
    bi_fifo_wr(&len, 2);
    bi_fifo_wr(data, len);
}

u8 bi_cmd_file_open(u8 *path, u8 mode) {

    if (*path == 0)return ERR_NULL_PATH;
    bi_cmd_tx(CMD_F_FOPN);
    bi_fifo_wr(&mode, 1);
    bi_tx_string(path);
    return bi_check_status();
}

u8 bi_cmd_file_close() {

    bi_cmd_tx(CMD_F_FCLOSE);
    return bi_check_status();
}

u8 bi_cmd_file_read_mem(u32 addr, u32 len) {

    if (len == 0)return 0;
    bi_cmd_tx(CMD_F_FRD_MEM);
    bi_fifo_wr(&addr, 4);
    bi_fifo_wr(&len, 4);

    //bi_dma_exec();
    bi_run_dma();

    return bi_check_status();
}

u8 bi_cmd_file_read(void *dst, u32 len) {

    u8 resp;
    u32 block;

    while (len) {

        block = min(512, len);

        bi_cmd_tx(CMD_F_FRD); //we can read up to 4096 in single block. but reccomended not more than 512 to avoid fifo overload
        bi_fifo_wr(&block, 4);

        bi_fifo_rd(&resp, 1);
        if (resp)return resp;

        bi_fifo_rd(dst, block);

        len -= block;
        (u8 *) dst += block;
    }

    return 0;
}

u8 bi_cmd_file_write(void *src, u32 len) {

    u8 resp;
    u32 block;

    bi_cmd_tx(CMD_F_FWR);
    bi_fifo_wr(&len, 4);

    while (len) {

        block = min(ACK_BLOCK_SIZE, len);

        bi_fifo_rd(&resp, 1);
        if (resp)return resp;

        bi_fifo_wr(src, block);

        len -= block;
        (u8*) src += block;
    }

    return bi_check_status();
}

u8 bi_cmd_file_write_mem(u32 addr, u32 len) {

    if (len == 0)return 0;
    bi_cmd_tx(CMD_F_FWR_MEM);
    bi_fifo_wr(&addr, 4);
    bi_fifo_wr(&len, 4);

    //bi_dma_exec();
    bi_run_dma();

    return bi_check_status();
}

u8 bi_cmd_file_set_ptr(u32 addr) {

    bi_cmd_tx(CMD_F_FPTR);
    bi_fifo_wr(&addr, 4);
    return bi_check_status();
}

u8 bi_cmd_file_info(u8 *path, FileInfo *inf) {

    u8 resp;

    bi_cmd_tx(CMD_F_FINFO);
    bi_tx_string(path);

    bi_fifo_rd(&resp, 1);
    if (resp)return resp;

    bi_rx_file_info(inf);

    return 0;
}

u8 bi_cmd_file_del(u8 *path) {

    bi_cmd_tx(CMD_F_DEL);
    bi_tx_string(path);
    return bi_check_status();
}

u8 bi_cmd_fpg_init(u8 map_pack) {

    u32 size;
    u8 resp;
    u8 path[32];


    path[0] = 0;
    str_append(path, PATH_MAP);
    str_append(path, "/");
    if (map_pack < 128)str_append(path, "0");
    if (map_pack < 10)str_append(path, "0");
    str_append_num(path, map_pack);
    str_append(path, ".RBF");

    resp = bi_file_get_size(path, &size);
    if (resp == FAT_NO_FILE)return ERR_MAP_NOT_FOUND;
    if (resp)return resp;

    resp = bi_cmd_file_open(path, FA_READ);
    if (resp)return resp;


    bi_cmd_tx(CMD_FPG_SDC);
    bi_fifo_wr(&size, 4);

    bi_reboot(STATUS_UNLOCK | STATUS_FPG_OK);

    return 0;
}

void bi_cmd_fpg_init_cfg(MapConfig *cfg) {

    //after fpga reboot this config will be applied
    bi_cmd_tx(CMD_FPG_CFG);
    bi_fifo_wr(cfg, sizeof (MapConfig));
}

u8 bi_cmd_file_crc(u32 len, u32 *crc_base) {

    u8 resp;
    bi_cmd_tx(CMD_F_FCRC);
    bi_fifo_wr(&len, 4);
    bi_fifo_wr(crc_base, 4);

    bi_fifo_rd(&resp, 1);
    if (resp)return resp;
    bi_fifo_rd(crc_base, 4);

    return 0;
}

void bi_cmd_mem_set(u8 val, u32 addr, u32 len) {

    bi_cmd_tx(CMD_MEM_SET);
    bi_fifo_wr(&addr, 4);
    bi_fifo_wr(&len, 4);
    bi_fifo_wr(&val, 1);
    bi_run_dma();
}

u8 bi_cmd_mem_test(u8 val, u32 addr, u32 len) {

    u8 resp;

    bi_cmd_tx(CMD_MEM_TST);
    bi_fifo_wr(&addr, 4);
    bi_fifo_wr(&len, 4);
    bi_fifo_wr(&val, 1);
    bi_run_dma();
    bi_fifo_rd(&resp, 1);

    return resp;
}

void bi_cmd_mem_rd(u32 addr, void *dst, u32 len) {

    u8 ack = 0;

    bi_cmd_tx(CMD_MEM_RD);

    bi_fifo_wr(&addr, 4);
    bi_fifo_wr(&len, 4);

    if (addr < ADDR_CFG) {
        bi_run_dma();
    } else {
        bi_fifo_wr(&ack, 1); //move to ram app for access to memoey
    }

    bi_fifo_rd(dst, len);
}

void bi_cmd_mem_wr(u32 addr, void *src, u32 len) {

    u8 ack = 0; //force to wait second ack byte befor dma
    if (addr < ADDR_CFG)ack = 0xaa;

    bi_cmd_tx(CMD_MEM_WR);
    bi_fifo_wr(&addr, 4);
    bi_fifo_wr(&len, 4);
    bi_fifo_wr(&ack, 1);
    bi_fifo_wr(src, len);

    if (ack == 0xaa) {
        bi_run_dma();
    }
}

void bi_cmd_mem_crc(u32 addr, u32 len, u32 *crc_base) {

    bi_cmd_tx(CMD_MEM_CRC);
    bi_fifo_wr(&addr, 4);
    bi_fifo_wr(&len, 4);
    bi_fifo_wr(crc_base, 4);
    bi_run_dma();

    bi_fifo_rd(crc_base, 4);

}

void bi_cmd_upd_exec(u32 addr, u32 crc) {

    bi_cmd_tx(CMD_UPD_EXEC);
    bi_fifo_wr(&addr, 4);
    bi_fifo_wr(&crc, 4);
    bi_reboot(STATUS_UNLOCK | STATUS_FPG_OK);
}

void bi_cmd_get_vdc(Vdc *vdc) {

    bi_cmd_tx(CMD_GET_VDC);
    bi_fifo_rd(vdc, sizeof (Vdc));

}

void bi_cmd_rtc_get(RtcTime *time) {

    bi_cmd_tx(CMD_RTC_GET);
    bi_fifo_rd(time, sizeof (RtcTime));
}

void bi_cmd_rtc_set(RtcTime *time) {

    bi_cmd_tx(CMD_RTC_SET);
    bi_fifo_wr(time, sizeof (RtcTime));
}

void bi_cmd_sys_inf(SysInfoIO *inf) {
    bi_cmd_tx(CMD_SYS_INF);
    bi_fifo_rd(inf, sizeof (SysInfoIO));
}

void bi_cmd_reboot() {

    bi_cmd_tx(CMD_REINIT);
    bi_reboot(STATUS_UNLOCK | STATUS_FPG_OK);
}

void bi_cmd_game_ctr() {
    bi_cmd_tx(CMD_GAME_CTR);
}

void bi_cmd_fla_rd(void *dst, u32 addr, u32 len) {

    bi_cmd_tx(CMD_FLA_RD);
    bi_fifo_wr(&addr, 4);
    bi_fifo_wr(&len, 4);
    bi_fifo_rd(dst, len);
}

u8 bi_cmd_fla_wr_sdc(u32 addr, u32 len) {

    bi_cmd_tx(CMD_FLA_WR_SDC);
    bi_fifo_wr(&addr, 4);
    bi_fifo_wr(&len, 4);
    return bi_check_status();
}
//****************************************************************************** 
//****************************************************************************** 
//****************************************************************************** 

void bi_fifo_wr(void *data, u16 len) {


    while (len) {
        zp_src = data;
        zp_len = len;
        if (zp_len > 256)zp_len = 256;
        bi_fifo_write(); //can transfer 256 bytes max
        if (len <= 256)return;
        len -= 256;
        (u8 *) data += 256;
    }

}

void bi_fifo_rd(void *data, u16 len) {


    while (len) {

        zp_dst = data;
        zp_len = len;
        if (zp_len > 256)zp_len = 256;
        bi_fifo_read(); //can transfer 256 bytes max
        if (len <= 256)return;
        len -= 256;
        (u8 *) data += 256;
    }

    /*
        while (len--) {

            while ((REG_FIFO_STAT & 0x80));
     *((u8 *) data)++ = REG_FIFO_DATA;
        }
     */


}

u8 bi_fifo_rd_skip(u16 len) {

    u8 tmp;

    while (len--) {

        while ((REG_FIFO_STAT & FIFO_MOS_RXF));
        tmp = REG_FIFO_DATA;
    }

    return 0;
}

u8 bi_fifo_busy() {

    return REG_FIFO_STAT & FIFO_MOS_RXF;
}

u8 bi_check_status() {

    u16 status;

    bi_cmd_status(&status);

    if ((status & 0xff00) != 0xA500) {

        return ERR_UNXP_STAT;
    }

    return status & 0xff;
}

void bi_tx_string(u8 *string) {

    u16 str_len = 0;
    u8 *ptr = string;

    while (*ptr++ != 0)str_len++;

    bi_fifo_wr(&str_len, 2);
    bi_fifo_wr(string, str_len);
}

void bi_rx_string(u8 *string) {

    u16 str_len;

    bi_fifo_rd(&str_len, 2);

    if (string == 0) {
        bi_fifo_rd_skip(str_len);
        return;
    }

    string[str_len] = 0;

    bi_fifo_rd(string, str_len);
}

void bi_rx_file_info(FileInfo *inf) {

    bi_fifo_rd(inf, 9);
    bi_rx_string(inf->file_name);
    inf->is_dir &= AT_DIR;
}

u8 bi_rx_next_rec(FileInfo *inf) {

    u8 resp;

    bi_fifo_rd(&resp, 1);
    if (resp)return resp;

    bi_rx_file_info(inf);

    return 0;
}

void bi_halt_usb() {//for external access to ram

    u16 len = 1;
    bi_cmd_tx(CMD_USB_WR);
    bi_fifo_wr(&len, 2);

    bi_halt(STATUS_UNLOCK);
}

void bi_run_dma() { //acknowledge mcu access to memory and wait until it ends in wram

    bi_halt(STATUS_CMD_OK);
}

u8 bi_get_rom_mask(u32 size) {

    u32 max = 8192;
    u8 msk = 0;

    while (max < size) {
        msk++;
        max *= 2;
    }

    return msk & 0x0F;
}

u8 bi_get_srm_mask(u32 size) {

    u32 max = 1024;
    u8 msk = 0;

    while (max < size) {
        msk++;
        max *= 2;
    }

    return msk & 0x0F;
}

void bi_exit_game() {


    MapConfig cfg;
    mem_set(&cfg, 0, sizeof (MapConfig));
    cfg.map_idx = 255;
    cfg.map_ctrl = MAP_CTRL_UNLOCK;

    bi_cfg_set(&cfg);
    asm("jmp ($FFFC)");

    //bi_cmd_fpg_init(&cfg, 255);
}

void bi_cfg_set(MapConfig *cfg) {

    bi_cmd_mem_wr(ADDR_CFG, cfg, sizeof (MapConfig));
}

void bi_cfg_get(MapConfig *cfg) {

    bi_cmd_mem_rd(ADDR_CFG, cfg, sizeof (MapConfig));
}

u8 bi_file_get_size(u8 *path, u32 *size) {

    u8 resp;
    FileInfo inf = {0};

    resp = bi_cmd_file_info(path, &inf);
    if (resp)return resp;

    *size = inf.size;
    return 0;
}

void bi_sleep(u16 ms) {

    u16 time = REG_TIMER;
    while ((u16) (REG_TIMER - time) < ms);
}

u16 bi_get_ticks() {

    return REG_TIMER;
}

void bi_reboot_usb() {//for extrnal fpga reboot

    u16 len = 1; //next 1 byte received via fifo will be sent to usb (ack byte)
    bi_cmd_tx(CMD_USB_WR);
    bi_fifo_wr(&len, 2);

    bi_reboot(STATUS_UNLOCK | STATUS_FPG_OK);
}

void bi_reboot(u8 status) {

    zp_arg = status;
    bi_reboot_exec();
}

void bi_halt(u8 status) {

    zp_arg = status;
    bi_halt_exec();
}
