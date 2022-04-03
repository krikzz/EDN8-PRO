

typedef struct{
	
	bit [7:0]dati;
	bit [22:0]addr;
	bit ce, oe, we;
	
}MemCtrl;

typedef struct{

	bit [10:0]addr;
	bit act;
	bit we;
	bit ce_reg;
	bit ce_snif_ppu;
	bit ce_snif_oam;
	bit ce_mem;
	
	bit ce_map;
	bit we_map;
	
	bit [7:0]dato;
	
}SSTBus;


//mem_dma  removed.
//chr_xram removed. need better implementation
//map_led=led

typedef struct {

	bit async_wr;//(!sync_m2) for dma
	bit prg_mask_off; 
	bit chr_mask_off;
	bit srm_mask_off;
	
	bit ciram_a10;
	bit ciram_ce;
	bit irq;
	bit pwm;
	
	bit mir_4sc;
	bit led;
	bit bus_conflicts;
	bit eep_on;
	
	
	bit map_cpu_oe;
	bit map_ppu_oe;
	bit [7:0]map_cpu_do;
	bit [7:0]map_ppu_do;
	
	bit [7:0]sst_di;
	
	MemCtrl prg;
	MemCtrl chr;
	MemCtrl srm;
	MemCtrl eep;
	
}MapOut;

typedef struct {
	
	bit [7:0]sst_do;
	
	SSTBus sst;
	
}MapIn;





module map_04_sv(
);
endmodule

