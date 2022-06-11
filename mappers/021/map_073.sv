
module map_073(//VRC3

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
	assign mao.sst_di[7:0] =
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
	assign prg.addr[13:0]	= cpu.addr[13:0];
	assign prg.addr[17:14] =  prg_addr[17:14];
	
	assign chr.ce 				= mao.ciram_ce;
	assign chr.oe 				= !ppu.oe;
	assign chr.we 				= cfg.chr_ram ? !ppu.we & mao.ciram_ce : 0;
	assign chr.addr[12:0]	= ppu.addr[12:0];

	
	//A10-Vmir, A11-Hmir
	assign mao.ciram_a10 	= cfg.mir_v ? ppu.addr[10] : ppu.addr[11];
	assign mao.ciram_ce 		= !ppu.addr[13];
	
	assign mao.irq				= !irq_n;
//************************************************************* mapper implementation
	
	wire irq_n;
	wire wram_ce_n;
	wire prg_ce_n;
	wire [17:14]prg_addr;
	
	wire [7:0]sst_di;
	
	chip_vrc3 vrc3_inst(

		.cpu_m2(cpu.m2),
		.cpu_rw(cpu.rw),
		.cpu_a12(cpu.addr[12]),
		.cpu_a13(cpu.addr[13]),
		.cpu_a14(cpu.addr[14]),
		.cpu_ce_n(!cpu.addr[15]),
		.cpu_data(cpu.data[3:0]),
		
		.irq_n(irq_n),
		.wram_ce_n(wram_ce_n),
		.prg_ce_n(prg_ce_n),
		.prg_addr(prg_addr),
		
		.rst(mai.map_rst),
		.sst(sst),
		.sst_di(sst_di)
	);
	
endmodule
