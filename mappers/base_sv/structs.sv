

typedef struct{
	
	bit [7:0]dati;
	bit [22:0]addr;
	bit ce, oe, we;
	bit async_io;
	
}MemCtrl;

//********

typedef struct{

	bit [7:0]data;
	bit [15:0]addr;
	bit rw;
	bit m2;
	
}CpuBus;

//********

typedef struct{

	bit [7:0]data;
	bit [13:0]addr;
	bit oe;
	bit we;

}PpuBus;

//********

typedef struct {
	
	bit clk;
	bit fds_sw;
	bit sys_rst;
	bit map_rst;
	bit os_act;
	
	bit [7:0]prg_do;//prg rom data out
	bit [7:0]chr_do;//chr rom data out
	bit [7:0]srm_do;//bram data out
	
	//bit [7:0]sst_do;
	//SSTBus sst;
	
	CpuBus cpu;
	PpuBus ppu;
	
}MapIn;

//********

typedef struct {

	bit sync_m2;
	bit prg_mask_off; 
	bit chr_mask_off;
	bit srm_mask_off;
	
	bit ciram_a10;
	bit ciram_ce;
	bit irq;
	bit pwm;
	bit led;
	
	bit mir_4sc;
	bit bus_conflicts;
	
	bit map_cpu_oe;
	bit map_ppu_oe;
	bit [7:0]map_cpu_do;
	bit [7:0]map_ppu_do;
	
	bit [7:0]sst_di;
	
	MemCtrl prg;//prg rom
	MemCtrl chr;//chr rom
	MemCtrl srm;//bram
	
}MapOut;

//********

typedef struct{
	
	//bit dst_prg;
	//bit dst_chr;
	//bit dst_srm;
	//bit dst_sys;
	
	bit ce_prg;
	bit ce_chr;
	bit ce_srm;
	bit ce_sys;
	
	bit ce_cfg;
	bit ce_cfg_ggc;
	bit ce_cfg_reg;
	
	bit ce_ss;
	
	bit ce_fifo;
		
}PiMap;

//********

typedef struct{

	bit [7:0]dato;
	bit [31:0]addr;
	bit we;
	bit oe;
	bit act;		//async rw
	PiMap map;
	
	bit clk;//remove me
}PiBus;

//********

typedef struct{
	
	MemCtrl mem;
	
	bit [7:0]pi_di;
	bit req_prg, req_chr, req_srm;
	bit mem_req;
	
}DmaBus;

//********

typedef struct{
	

	bit [11:0]map_idx;
	bit [9:0]prg_msk;
	bit [9:0]chr_msk;
	bit [10:0]srm_msk;
	bit [7:0]master_vol;
	bit [7:0]ss_key_save;
	bit [7:0]ss_key_load;
	bit [7:0]ss_key_menu;

	bit mc_mir_h;
	bit mc_mir_v;
	bit mc_mir_4;
	bit mc_mir_1;
	bit mc_chr_ram;
	bit mc_prg_ram_off;
	bit [3:0]map_sub;

	bit ct_rst_delay;
	bit ct_ss_on;
	bit ct_gg_on;
	bit ct_ss_btn;
	bit ct_fami;
	bit ct_unlock;
	
	bit [18:0]srm_size;
	
}SysCfg;
