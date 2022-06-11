
module map_024(//VRC6

	input  MapIn  mai,
	output MapOut mao
);
//************************************************************* base header
	CpuBus cpu;
	PpuBus ppu;
	SysCfg cfg;
	SSTBus sst;
	assign cpu = mai.cpu;
	assign ppu = mai.ppu;
	assign cfg = mai.cfg;
	assign sst = mai.sst;
	
	MemCtrl prg;
	MemCtrl chr;
	MemCtrl srm;
	assign mao.prg = prg;
	assign mao.chr = chr;
	assign mao.srm = srm;

	assign prg.dati			= cpu.data;
	assign chr.dati			= ppu.data;
	assign srm.dati			= cpu.data;
	
	wire int_cpu_oe;
	wire int_ppu_oe;
	wire [7:0]int_cpu_data;
	wire [7:0]int_ppu_data;
	
	assign mao.map_cpu_oe	= int_cpu_oe | (srm.ce & srm.oe) | (prg.ce & prg.oe);
	assign mao.map_cpu_do	= int_cpu_oe ? int_cpu_data : srm.ce ? mai.srm_do : mai.prg_do;
	
	assign mao.map_ppu_oe	= int_ppu_oe | (chr.ce & chr.oe);
	assign mao.map_ppu_do	= int_ppu_oe ? int_ppu_data : mai.chr_do;
//************************************************************* configuration
	assign mao.prg_mask_off = 0;
	assign mao.chr_mask_off = 0;
	assign mao.srm_mask_off = 0;
	assign mao.mir_4sc		= 0;//enable support for 4-screen mirroring. for activation should be enabled in cfg.mir_4 also
	assign mao.bus_cf 		= 0;//bus conflicts
//************************************************************* save state regs read
	assign mao.sst_di[7:0] 	=
	sst.addr[7:0]  < 127 ? sst_di :
	sst.addr[7:0] == 127 ? cfg.map_idx : 8'hff;
//************************************************************* mapper-controlled pins
	assign srm.ce				= !wram_ce_n;
	assign srm.oe				= cpu.rw;
	assign srm.we				= !cpu.rw;
	assign srm.addr[12:0]	= cpu.addr[12:0];
	
	assign prg.ce				= !prg_ce_n;
	assign prg.oe 				= cpu.rw;
	assign prg.we				= 0;
	assign prg.addr[12:0]	= cpu.addr[12:0];
	assign prg.addr[20:13]	= prg_addr[20:13];
	
	assign chr.ce 				= !chr_ce_n;
	assign chr.oe 				= !ppu.oe;
	assign chr.we 				= cfg.chr_ram ? !ppu.we & mao.ciram_ce : 0;
	assign chr.addr[9:0]		= ppu.addr[9:0];
	assign chr.addr[17:10] 	= chr_addr[17:10];

	
	//A10-Vmir, A11-Hmir
	assign mao.ciram_a10 	= chr_addr[10];
	assign mao.ciram_ce 		= ciram_ce_n;
	
	assign mao.irq				= !irq_n;
	assign mao.snd[15:0]		= {snd_vol[6:0], 9'd0};
//************************************************************* mapper implementation
	
	wire [1:0]map_ax		= cfg.map_idx == 24 ? cpu.addr[1:0] : {cpu.addr[0], cpu.addr[1]};
	
	wire irq_n;
	wire ciram_ce_n;
	wire chr_ce_n;
	wire prg_ce_n;
	wire wram_ce_n;
	wire [17:10]chr_addr;
	wire [20:13]prg_addr;	
	wire [6:0]snd_vol;
	
	wire [7:0]sst_di;

	chip_vrc6 vrc6_inst(

		.cpu_m2(cpu.m2),
		.cpu_rw(cpu.rw),
		.cpu_a0(map_ax[0]),
		.cpu_a1(map_ax[1]),
		.cpu_a12(cpu.addr[12]),
		.cpu_a13(cpu.addr[13]),
		.cpu_a14(cpu.addr[14]),
		.cpu_ce_n(!cpu.addr[15]),
		.cpu_data(cpu.data),
		.ppu_addr(ppu.addr[13:10]),
		.ppu_oe_n(ppu.oe),//what is this for?
		
		.irq_n(irq_n),
		.ciram_ce_n(ciram_ce_n),
		.chr_ce_n(chr_ce_n),
		.prg_ce_n(prg_ce_n), 
		.wram_ce_n(wram_ce_n),
		.chr_addr(chr_addr),
		.prg_addr(prg_addr),
		.snd_vol(snd_vol),
		
		.rst(mai.map_rst),
		.sst(sst),
		.sst_di(sst_di)
	);
	
endmodule
