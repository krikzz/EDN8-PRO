
module map_198(

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
	assign mao.srm_mask_off = 1;
	assign mao.mir_4sc		= 1;//enable support for 4-screen mirroring. for activation should be enabled in cfg.mir_4 also
	assign mao.bus_cf 		= 0;//bus conflicts
//************************************************************* save state regs read
	assign mao.sst_di[7:0] = 
	sst.addr[7:0] <  127	? sst_di :
	sst.addr[7:0] == 127 ? cfg.map_idx : 8'hff;	
//************************************************************* mapper-controlled pins
	assign srm.ce				= ram_ce1 | ram_ce2;
	assign srm.oe				= cpu.rw;
	assign srm.we				= ram_we;
	assign srm.addr[11:0]	= cpu.addr[11:0];
	assign srm.addr[13:12]	= ram_addr[13:12];
	
	assign prg.ce				= !prg_ce_n;
	assign prg.oe 				= cpu.rw;
	assign prg.we				= 0;
	assign prg.addr[12:0]	= cpu.addr[12:0];
	assign prg.addr[19:13]	= prg_addr_x[19:13];
	
	assign chr.ce 				= mao.ciram_ce;
	assign chr.oe 				= !ppu.oe;
	assign chr.we 				= cfg.chr_ram ? !ppu.we & mao.ciram_ce : 0;
	assign chr.addr[9:0]		= ppu.addr[9:0];
	assign chr.addr[17:10]	= cfg.chr_ram ? ppu.addr[12:10] : chr_addr[17:10];
	
	//A10-Vmir, A11-Hmir
	assign mao.ciram_a10 	= ciram_a10;
	assign mao.ciram_ce 		= !ppu.addr[13];
	
	assign mao.irq				= !irq_n;
//************************************************************* mapper implementation below
	
	wire irq_n;
	wire ciram_a10;
	wire ram_ce;
	wire ram_ce_n;
	wire ram_we_n;
	wire prg_ce_n;
	wire [19:13]prg_addr;
	wire [17:10]chr_addr;
	
	wire [7:0]sst_di;
	
	chip_mmc3_198 mmc3_inst(
	
		.cpu_data(cpu.data[7:0]),
		.cpu_a14(cpu.addr[14]),
		.cpu_a13(cpu.addr[13]),
		.cpu_a0(cpu.addr[0]),
		.cpu_ce_n(!cpu.addr[15]),
		.cpu_rw(cpu.rw),
		.cpu_m2(cpu.m2),
		.ppu_addr(ppu.addr[12:10]),
		
		.irq_n(irq_n),
		.ciram_a10(ciram_a10),
		.ram_ce(ram_ce),
		.ram_ce_n(ram_ce_n),
		.ram_we_n(ram_we_n),	
		.prg_ce_n(prg_ce_n),
		.prg_addr(prg_addr),
		.chr_addr(chr_addr),
		
		.clk(mai.clk),
		.rst(mai.map_rst),
		.map_sub(mai.cfg.map_sub),
		.mir_h(cfg.mir_h),
		.cpu_m3(cpu.m3),
		
		.sst(sst),
		.sst_di(sst_di)
	);
//************************************************************* map 198 specific stuff
	wire ram_ce1 				= {cpu.addr[15:13], 13'd0} == 16'h6000;
	wire ram_ce2 				= {cpu.addr[15:12], 12'd0} == 16'h5000;
	wire ram_we					= !cpu.rw;//not sure if this mapper uses mmc3 ram lock bits
	wire [13:12]ram_addr		= ram_ce2 ? 2'b10 : {1'b0, cpu.addr[12]};
	
	
	//i use sub 0 if PRG scheme is not 512+128
	wire [19:13]prg_addr_x	= cfg.map_sub == 1 | prg_addr[19] == 0 ? prg_addr[19:13] :  {3'b100, prg_addr[16:13]};
	
	
	
endmodule


//this one has extra prg addr bit
module chip_mmc3_198(
	
	//regular mapper io
	input  [7:0]cpu_data,
	input	 cpu_a14,
	input	 cpu_a13,
	input	 cpu_a0,
	input  cpu_ce_n,
	input  cpu_rw,
	input  cpu_m2,
	input  [12:10]ppu_addr,
	
	output irq_n,
	output ciram_a10,
	output ram_ce,
	output ram_ce_n,
	output ram_we_n,	
	output prg_ce_n,
	output [19:13]prg_addr,
	output [17:10]chr_addr,
	
	//extra stuff
	input  clk,
	input  rst,
	input  [3:0]map_sub,
	input  mir_h,//default mirroring mode in case if not controlled by mapper
	input  cpu_m3,
	
	input  SSTBus sst,
	output [7:0]sst_di
);
	
	assign sst_di[7:0] 	=
	sst.addr[7:3] == 0   ? r8001[sst.addr[2:0]]:
	sst.addr[7:0] == 8   ? r8000 : 
	sst.addr[7:0] == 9   ? rA000 : 
	sst.addr[7:0] == 10  ? rA001 : 
	sst.addr[7:0] >= 16  ? sst_di_irq :
	8'hff;
	
	
	assign irq_n			= !irq_pend;
	
	assign ciram_a10 		= !mir_mod ? ppu_addr[10] : ppu_addr[11];
	
	assign ram_ce			= {cpu_ce_n, cpu_a14, cpu_a13} == 3'b111 & ram_ce_on;
	assign ram_ce_n		= !ram_ce;
	assign ram_we_n		= !(!cpu_rw & !ram_we_off);
	
	assign prg_ce_n		= !(!cpu_ce_n & cpu_rw);
	
	assign prg_addr[19:13]	= 
	{cpu_a14, cpu_a13} == 0 ? (prg_mod == 0 ? r8001[6][6:0] : 7'b1111110) :
	{cpu_a14, cpu_a13} == 1 ? r8001[7][6:0] :
	{cpu_a14, cpu_a13} == 2 ? (prg_mod == 1 ? r8001[6][6:0] : 7'b1111110) :
	7'b1111111;
	
	assign chr_addr[17:10] 	= 
	ppu_addr[12:11] == {chr_mod, 1'b0} ? {r8001[0][7:1], ppu_addr[10]} :
	ppu_addr[12:11] == {chr_mod, 1'b1} ? {r8001[1][7:1], ppu_addr[10]} :
	ppu_addr[11:10] == 0 ? r8001[2][7:0] :
	ppu_addr[11:10] == 1 ? r8001[3][7:0] :
	ppu_addr[11:10] == 2 ? r8001[4][7:0] :
   r8001[5][7:0];
	
	wire decode_en 		= cpu_m3 & !cpu_rw;
	wire [3:0]reg_addr	= {!cpu_ce_n, cpu_a14, cpu_a13, cpu_a0};
	
	wire prg_mod 			= r8000[6];
	wire chr_mod 			= r8000[7];
	wire mir_mod 			= rA000[0];
	wire ram_we_off 		= rA001[6];
	wire ram_ce_on 		= rA001[7];
	
	reg [7:0]r8000;
	reg [7:0]r8001[8];
	reg [7:0]rA000;
	reg [7:0]rA001;
	
	
	always @(posedge clk)
	if(sst.act)
	begin
		if(cpu_m3)
		begin
			if(sst.we_reg & sst.addr[7:3] == 0)r8001[sst.addr[2:0]] 	<= sst.dato;
			if(sst.we_reg & sst.addr[7:0] == 8)r8000 						<= sst.dato;
			if(sst.we_reg & sst.addr[7:0] == 9)rA000 						<= sst.dato;
			if(sst.we_reg & sst.addr[7:0] == 10)rA001						<= sst.dato;
		end
	end
		else
	if(rst)
	begin
		r8000[7:0] 		<= 0;
	
		rA000[0] 		<= mir_h;
		rA001[7:0] 		<= 0;
	
		r8001[0][7:0]	<= 0;
		r8001[1][7:0] 	<= 2;
		r8001[2][7:0] 	<= 4;
		r8001[3][7:0] 	<= 5;
		r8001[4][7:0] 	<= 6;
		r8001[5][7:0] 	<= 7;
		r8001[6][7:0] 	<= 0;
		r8001[7][7:0] 	<= 1;
	end
		else
	if(decode_en)
	case(reg_addr[3:0])
		4'h8:r8000[7:0] 					<= cpu_data[7:0];
		4'h9:r8001[r8000[2:0]][7:0]	<= cpu_data[7:0];
		4'hA:rA000[7:0] 					<= cpu_data[7:0];
		4'hB:rA001[7:0] 					<= cpu_data[7:0];
	endcase
	
	
//************************************************************* irq
	wire irq_pend;
	wire [7:0]sst_di_irq;
	
	irq_mmc3 irq_mmc_inst(
		
		.clk(clk),
		.decode_en(decode_en),
		.cpu_m2(cpu_m2),
		.cpu_data(cpu_data),
		.reg_addr(reg_addr),
		.ppu_a12(ppu_addr[12]),
		.map_rst(rst),
		.mmc3a(map_sub == 4),
		.irq(irq_pend),
		
		.sst(sst),
		.sst_di(sst_di_irq)
	);

endmodule
