
module map_022(//VRC2

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
	sst.addr[7:0] <  127 ? sst_di :
	sst.addr[7:0] == 127 ? cfg.map_idx : 8'hff;
//************************************************************* mapper-controlled pins
	assign srm.ce				= ram_area & !cfg.prg_ram_off;
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
	assign chr.addr[18:10]	= cfg.map_idx == 22 ? chr_addr[18:11] : chr_addr[18:10];

	
	//A10-Vmir, A11-Hmir
	assign mao.ciram_a10 	= ciram_a10;
	assign mao.ciram_ce 		= !ppu.addr[13];
	assign int_cpu_oe			= ram_area & cfg.prg_ram_off & cpu.rw;
	assign int_cpu_data		= {cpu.addr[15:9], eep_do};
//************************************************************* mapper implementation
	wire ram_area				= {cpu.addr[15:13], 13'd0} == 16'h6000;
	
	wire [1:0]reg_map22 		= {cpu.addr[0], cpu.addr[1]};
	wire [1:0]reg_map23 		= {cpu.addr[1], cpu.addr[0]};
	wire [1:0]reg_map25 		= {cpu.addr[0], cpu.addr[1]};
	
	wire [1:0]map_ax 			= 
	cfg.map_idx == 22 ? reg_map22 :
	cfg.map_idx == 23 ? reg_map23 : reg_map25;
	
//************************************************************* VRC chip
	wire [7:0]sst_di;
	
	wire ciram_a10;
	wire chr_ce_n;
	wire [18:10]chr_addr;
	wire prg_ce_n;
	wire [20:13]prg_addr;
	wire eep_do;
	
	chip_vrc2 vrc2_inst(

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
		
		.eep_do(eep_do),
		.ciram_a10(ciram_a10),
		.chr_ce_n(chr_ce_n),
		.prg_ce_n(prg_ce_n),
		.chr_addr(chr_addr),
		.prg_addr(prg_addr),
		
		.rst(mai.map_rst),
		.sst(sst),
		.sst_di(sst_di)
	);
	
endmodule

