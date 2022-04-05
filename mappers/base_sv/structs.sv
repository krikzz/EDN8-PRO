

typedef struct{
	
	bit [7:0]dati;
	bit [22:0]addr;
	bit ce, oe, we;
	
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
