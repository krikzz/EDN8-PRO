 

module map_004(

	input  MapIn  mai,
	output MapOut mao
);
//************************************************************* standard mapper header
	CpuBus cpu;
	PpuBus ppu;
	SysCfg cfg;
	assign cpu = mai.cpu;
	assign ppu = mai.ppu;
	assign cfg = mai.cfg;
	
	MemCtrl prg;
	MemCtrl chr;
	MemCtrl srm;
	assign mao.prg = prg;
	assign mao.chr = chr;
	assign mao.srm = srm;
	
	
	assign mao.srm_mask_off = 0;
	assign mao.chr_mask_off = 0;
	assign mao.prg_mask_off = 0;
	assign mao.mir_4sc		= 1;//enable support for 4-screen mirroring. for activation should be ensabled in cfg also

	
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
//************************************************************* mapper implementation below

	assign srm.oe				= cpu.rw;
	assign srm.addr[12:0]	= cpu.addr[12:0];
	
	assign prg.oe 				= cpu.rw;
	assign prg.we				= 0;
	assign prg.addr[12:0]	= cpu.addr[12:0];
	
	assign chr.ce 				= mao.ciram_ce;
	assign chr.oe 				= !ppu.oe;
	assign chr.we 				= cfg.chr_ram ? !ppu.we & mao.ciram_ce : 0;
	assign chr.addr[9:0]		= ppu.addr[9:0];
	
	
	assign mao.ciram_ce 		= !ppu.addr[13];

	
	
	chip_mmc3 mmc3_inst(
		
		.clk(mai.clk),
		
		.cpu_data(cpu.data[7:0]),
		.cpu_a0(cpu.addr[0]),
		.cpu_a13(cpu.addr[13]),
		.cpu_a14(cpu.addr[14]),
		.romsel(!cpu.addr[15]),
		.cpu_rw(cpu.rw),
		.cpu_m2(cpu.m2),
		
		.ppu_a10(ppu.addr[10]),
		.ppu_a11(ppu.addr[11]),
		.ppu_a12(ppu.addr[12]),

		
		.pin_prg_addr(prg.addr[18:13]),
		.pin_chr_addr(chr.addr[17:10]),
		.pin_ram_ce(srm.ce),
		.pin_ram_we(srm.we),
		.pin_rom_ce(prg.ce),
		.pin_cir_a10(mao.ciram_a10),
		.pin_irq(mao.irq)
	);
	
	/*
	wire [18:13]pin_prg_addr;
	wire [18:13]pin_chr_addr;
	wire pin_ram_we;
	wire pin_ram_ce;
	wire pin_ram_on;
	wire pin_rom_ce;
	wire pin_cir_a10;
	wire pin_irq;
	
	
	assign pin_ram_on = (cpu.addr[13] & cpu.addr[14] & !cpu.addr[15]);
	
	
	wire decode_en;
	
	wire m2_lag0	=	m2_st[0];
	wire m2_lag1	=	m2_st[2];
	wire m2_lag2	=	m2_st[4];
	
	reg [7:0]m2_st;
	
	always @(posedge mai.clk)
	begin
		
		m2_st[7:0]	<= {m2_st[6:0], cpu.m2};
	
	end*/
	
endmodule

module chip_mmc3(
	
	input  clk,
	
	input  [7:0]cpu_data,
	input  cpu_a0,
	input  cpu_a13,
	input  cpu_a14,
	input  romsel,
	input  cpu_rw,
	input  cpu_m2,
	
	input  ppu_a10,
	input  ppu_a11,
	input  ppu_a12,

	output [18:13]pin_prg_addr,
	output [18:13]pin_chr_addr,
	output pin_ram_ce,
	output pin_ram_we,
	output pin_rom_ce,
	output pin_cir_a10,
	output pin_irq
);
	

	
	assign pin_ram_ce = 
	(reg_A001[7] & cpu_a13 & cpu_a14 & romsel) &
	!(!cpu_m2 | m2_lag0 | m2_lag1) &
	!(reg_A001[6] & !cpu_rw);
	
	
	wire decode_en;
	
	wire m2_lag0	=	m2_st[0];
	wire m2_lag1	=	m2_st[2];
	wire m2_lag2	=	m2_st[4];
	
	reg [7:0]m2_st;
	
	always @(posedge clk)
	begin
		m2_st[7:0]	<= {m2_st[6:0], cpu_m2};
	end
	
	
	reg [7:0]r8000;
	reg [7:0]r8001[8];
	reg [7:0]rA000;
	reg [7:0]rA001;
	
	always @(posedge clk)
	begin
	end
	
endmodule
