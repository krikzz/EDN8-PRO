
module map_137(

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
	sst.addr[7:3] == 0 ? regs[sst.addr[2:0]] :
	sst.addr[7:0] == 8 ? reg_addr :
	sst.addr[7:0] == 127 ? cfg.map_idx : 8'hff;
//************************************************************* mapper-controlled pins
	assign srm.ce				= 0;
	assign srm.oe				= 0;
	assign srm.we				= 0;
	assign srm.addr[12:0]	= cpu.addr[12:0];
	
	assign prg.ce				= cpu.addr[15];
	assign prg.oe 				= cpu.rw;
	assign prg.we				= 0;
	assign prg.addr[14:0]	= cpu.addr[14:0];
	assign prg.addr[17:15] 	= regs[5];
	
	assign chr.ce 				= mao.ciram_ce;
	assign chr.oe 				= !ppu.oe;
	assign chr.we 				= cfg.chr_ram ? !ppu.we & mao.ciram_ce : 0;
	assign chr.addr[9:0]		= ppu.addr[9:0];
	assign chr.addr[18:10] 	= 
	cfg.chr_ram 				? ppu.addr[12:10] :
	cfg.map_idx == 137		? ppu_137 : 
	cfg.map_idx == 138 		? ppu_138 :
	cfg.map_idx == 139 		? ppu_139 :
	ppu_141;

	
	//A10-Vmir, A11-Hmir
	assign mao.ciram_a10 	= 
	regs[7][0] 					? ppu.addr[10] : 
	regs[7][2:1] == 0 		? ppu.addr[10] : 
	regs[7][2:1] == 1 		? ppu.addr[11] : 
	regs[7][2:1] == 2 		? (ppu.addr[11:10] == 0 ? 0 : 1) : 0;
	assign mao.ciram_ce 		= !ppu.addr[13];
	
	assign mao.irq				= 0;
//************************************************************* mapper implementation	
	wire [8:0]ppu_137 = 
	ppu.addr[12] ? {3'b111, ppu.addr[11:10]} : 
	ppu.addr[12:10] == 0 ? {2'b00, regs[ppu.addr[11:10]][2:0]} : 
	ppu.addr[12:10] == 1 ? {regs[4][0], 1'b0, regs[ppu.addr[11:10]][2:0]}  : 
	ppu.addr[12:10] == 2 ? {regs[4][1], 1'b0, regs[ppu.addr[11:10]][2:0]}  : {regs[4][2], regs[6][0], regs[ppu.addr[11:10]][2:0]};
	
	
	wire [8:0]ppu_138;
	assign ppu_138[0] = ppu.addr[10];
	assign ppu_138[3:1] = regs[7][0] ? regs[0][2:0] : regs[ppu.addr[12:11]][2:0];
	assign ppu_138[6:4] = regs[4][2:0];
	
	wire [8:0]ppu_139;
	assign ppu_139[2:0] = ppu.addr[12:10];
	assign ppu_139[5:3] = regs[7][0] ? regs[0][2:0] : regs[ppu.addr[12:11]][2:0];
	assign ppu_139[8:6] = regs[4][2:0];
	
	wire [8:0]ppu_141;
	assign ppu_141[1:0] = ppu.addr[11:10];
	assign ppu_141[4:2] = regs[7][0] ? regs[0][2:0] : regs[ppu.addr[12:11]][2:0];
	assign ppu_141[7:5] = regs[4][2:0];
	
	wire reg_ce = cpu.addr[15:8] == 8'h41;
	
	reg [2:0]reg_addr;
	reg [2:0]regs[8];
	
	always @(negedge cpu.m2)
	if(sst.act)
	begin
		if(sst.we_reg & sst.addr[7:3] == 0)regs[sst.addr[2:0]]	<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 8)reg_addr 					<= sst.dato;
	end
		else
	if(mai.map_rst)
	begin
		regs[5] <= 0;
	end
		else
	if(!cpu.rw & reg_ce)
	begin
		
		if(cpu.addr[0] == 0)reg_addr[2:0] 			<= cpu.data[2:0];
		if(cpu.addr[0] == 1)regs[reg_addr][2:0] 	<= cpu.data[2:0];
		
	end
	
endmodule
