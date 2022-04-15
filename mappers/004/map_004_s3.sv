
module map_004_s3(//Acclaim mmc3 modification. Everything the same except irq

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
	assign mao.mir_4sc		= 1;//enable support for 4-screen mirroring. for activation should be enabled in cfg.mir_4 also
	assign mao.bus_cf 		= 0;//bus conflicts
//************************************************************* save state regs read
	assign mao.sst_di[7:0] = 
	sst_ce_irq 				? sst_do_irq : //addr 16-23 for irq
	sst.addr[7:3] == 0   ? r8001[sst.addr[2:0]]:
	sst.addr[7:0] == 8   ? r8000 : 
	sst.addr[7:0] == 9   ? rA000 : 
	sst.addr[7:0] == 10  ? rA001 : 
	sst.addr[7:0] == 127 ? cfg.map_idx : 8'hff;
//************************************************************* mapper-controlled pins
	assign srm.ce				= {cpu.addr[15:13], 13'd0} == 16'h6000 & ram_ce_on;// & (!ram_we_off | cpu.rw);
	assign srm.oe				= cpu.rw;
	assign srm.we				= !cpu.rw & !ram_we_off;
	assign srm.addr[12:0]	= cpu.addr[12:0];
	
	assign prg.ce				= cpu.addr[15];
	assign prg.oe 				= cpu.rw;
	assign prg.we				= 0;
	assign prg.addr[12:0]	= cpu.addr[12:0];
	assign prg.addr[18:13]	= 
	cpu.addr[14:13] == 0 ? (prg_mod == 0 ? r8001[6][5:0] : 6'b111110) :
	cpu.addr[14:13] == 1 ? r8001[7][5:0] : 
	cpu.addr[14:13] == 2 ? (prg_mod == 1 ? r8001[6][5:0] : 6'b111110) : 
	6'b111111;
	
	assign chr.ce 				= mao.ciram_ce;
	assign chr.oe 				= !ppu.oe;
	assign chr.we 				= cfg.chr_ram ? !ppu.we & mao.ciram_ce : 0;
	assign chr.addr[9:0]		= ppu.addr[9:0];
	assign chr.addr[17:10]	= cfg.chr_ram ? chr_addr_int[14:10] : chr_addr_int[17:10];//ines 2.0 requires 32k ram support
	
	//A10-Vmir, A11-Hmir
	assign mao.ciram_a10 	= !mir_mod ? ppu.addr[10] : ppu.addr[11];
	assign mao.ciram_ce 		= !ppu.addr[13];
	
	assign mao.irq				= irq_pend;
//************************************************************* mapper implementation below
	
	wire [17:10]chr_addr_int = 
	ppu.addr[12:11] == {chr_mod, 1'b0} ? {r8001[0][7:1], ppu.addr[10]} :
	ppu.addr[12:11] == {chr_mod, 1'b1} ? {r8001[1][7:1], ppu.addr[10]} :
	ppu.addr[11:10] == 0 ? r8001[2][7:0] : 
	ppu.addr[11:10] == 1 ? r8001[3][7:0] : 
	ppu.addr[11:10] == 2 ? r8001[4][7:0] : 
   r8001[5][7:0];
	
	wire decode_en 		= cpu.m3 & !cpu.rw;
	wire [3:0]reg_addr	= {cpu.addr[15:13], cpu.addr[0]};
	
	wire prg_mod 			= r8000[6];
	wire chr_mod 			= r8000[7];
	wire mir_mod 			= rA000[0];
	wire ram_we_off 		= rA001[6];
	wire ram_ce_on 		= rA001[7];
	
	reg [7:0]r8000;
	reg [7:0]r8001[8];
	reg [7:0]rA000;
	reg [7:0]rA001;
	
	
	always @(posedge mai.clk)
	if(sst.act)
	begin
		if(cpu.m3)
		begin
			if(sst.we_reg & sst.addr[7:3] == 0)r8001[sst.addr[2:0]] <= sst.dato;
			if(sst.we_reg & sst.addr[7:0] == 8)r8000 	<= sst.dato;
			if(sst.we_reg & sst.addr[7:0] == 9)rA000 	<= sst.dato;
			if(sst.we_reg & sst.addr[7:0] == 10)rA001	<= sst.dato;
		end
	end
		else
	if(mai.map_rst)
	begin
		r8000[7:0] 		<= 0;
	
		rA000[0] 		<= !cfg.mir_v;
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
		4'h8:r8000[7:0] 					<= cpu.data[7:0];
		4'h9:r8001[r8000[2:0]][7:0]	<= cpu.data[7:0];
		4'hA:rA000[7:0] 					<= cpu.data[7:0];
		4'hB:rA001[7:0] 					<= cpu.data[7:0];
	endcase
	
//************************************************************* irq
	wire irq_pend;
	wire sst_ce_irq;
	wire [7:0]sst_do_irq;
	
	irq_acc irq_acc_inst(
		
		.clk(mai.clk),
		.decode_en(decode_en),
		.cpu_m2(cpu.m2),
		.cpu_data(cpu.data),
		.reg_addr(reg_addr),
		.ppu_a12(ppu.addr[12]),
		.map_rst(mai.map_rst),
		.irq(irq_pend),
		
		.sst(sst),
		.sst_ce(sst_ce_irq),
		.sst_do(sst_do_irq)
	);
	
endmodule
