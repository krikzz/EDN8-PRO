 
module map_021(

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
	{sst.addr[7:3], 3'd0} == 0 ? chr_reg[sst.addr[2:0]][7:0] :
	{sst.addr[7:3], 3'd0} == 8 ? chr_reg[sst.addr[2:0]][8] :
	sst.addr[7:0] == 16 ? prg_reg[0][7:0] :
	sst.addr[7:0] == 17 ? prg_reg[1][7:0] :
	sst.addr[7:0] == 18 ? {swp_mode, mir_mode[1:0]} :
	sst.addr[7:0] == 32 ? irq_ss :
	sst.addr[7:0] == 33 ? irq_ss :
	sst.addr[7:0] == 34 ? irq_ss :
	sst.addr[7:0] == 35 ? irq_ss :
	sst.addr[7:0] == 36 ? irq_ss :
	sst.addr[7:0] == 127 ? cfg.map_idx : 8'hff;
//************************************************************* mapper-controlled pins
	assign srm.ce				= {cpu.addr[15:13], 13'd0} == 16'h6000;
	assign srm.oe				= cpu.rw;
	assign srm.we				= !cpu.rw;
	assign srm.addr[12:0]	= cpu.addr[12:0];
	
	assign prg.ce				= cpu.addr[15];
	assign prg.oe 				= cpu.rw;
	assign prg.we				= 0;
	assign prg.addr[12:0]	= cpu.addr[12:0];
	assign prg.addr[20:13]	= 
	{cpu.addr[15:13], 13'd0} == 16'h8000 & swp_mode == 0 ? prg_reg[0][7:0] : 
	{cpu.addr[15:13], 13'd0} == 16'h8000 & swp_mode == 1 ? 8'hFE : 
	{cpu.addr[15:13], 13'd0} == 16'hA000 ? prg_reg[1][7:0] : 
	{cpu.addr[15:13], 13'd0} == 16'hC000 & swp_mode == 0 ? 8'hFE : 
	{cpu.addr[15:13], 13'd0} == 16'hC000 & swp_mode == 1 ? prg_reg[0][7:0] : 
	8'hFF; 
	
	assign chr.ce 				= mao.ciram_ce;
	assign chr.oe 				= !ppu.oe;
	assign chr.we 				= cfg.chr_ram ? !ppu.we & mao.ciram_ce : 0;
	assign chr.addr[9:0]		= ppu.addr[9:0];
	assign chr.addr[17:10]	= cfg.map_idx == 22 ? chr_reg[ppu.addr[12:10]][7:1] : chr_reg[ppu.addr[12:10]][7:0];

	
	//A10-Vmir, A11-Hmir
	assign mao.ciram_a10 	= mir_mode[1] & vrc4 ? mir_mode[0] : !mir_mode[0] ? ppu.addr[10] : ppu.addr[11];
	assign mao.ciram_ce 		= !ppu.addr[13];
	
	assign mao.irq				= irq_out & vrc4;
//************************************************************* mapper implementation
	assign int_cpu_oe 		= cpu.rw & vrc2_latch_ce;
	assign int_cpu_data 		= {cpu.addr[15:9], vrc2_latch};
	

	wire vrc2 					= cfg.map_idx == 22 | (cfg.map_sub == 3 & (cfg.map_idx == 23 | cfg.map_idx == 25));
	wire vrc4					= !vrc2;
	
	
	wire [1:0]reg_map21_s0 	= cpu.addr[7:6] == 0 ? {cpu.addr[2], cpu.addr[1]} : {cpu.addr[7], cpu.addr[6]};
	wire [1:0]reg_map21_s1 	= cpu.addr[2:1];
	wire [1:0]reg_map21_s2 	= cpu.addr[7:6];
	
	wire [1:0]reg_map23_s0 	= cpu.addr[3:2] == 0 ?  cpu.addr[1:0] : cpu.addr[3:2];
	wire [1:0]reg_map23_s1 	= cpu.addr[1:0];
	wire [1:0]reg_map23_s2 	= cpu.addr[3:2];
	
	wire [1:0]reg_map25_s0 	= cpu.addr[3:2] == 0 ? {cpu.addr[0], cpu.addr[1]} : {cpu.addr[2], cpu.addr[3]};
	wire [1:0]reg_map25_s1 	= {cpu.addr[0], cpu.addr[1]};
	wire [1:0]reg_map25_s2 	= {cpu.addr[2], cpu.addr[3]};
	
	wire [1:0]reg_map21 		= cfg.map_sub == 1 ? reg_map21_s1 : cfg.map_sub == 2 ? reg_map21_s2 : reg_map21_s0;
	wire [1:0]reg_map22 		= {cpu.addr[0], cpu.addr[1]};
	wire [1:0]reg_map23 		= (cfg.map_sub == 1 | cfg.map_sub == 3) ? reg_map23_s1 : cfg.map_sub == 2 ? reg_map23_s2 : reg_map23_s0;
	wire [1:0]reg_map25 		= (cfg.map_sub == 1 | cfg.map_sub == 3) ? reg_map25_s1 : cfg.map_sub == 2 ? reg_map25_s2 : reg_map25_s0;
	
	wire [1:0]reg_map = 
	cfg.map_idx == 21 ? reg_map21[1:0] : 
	cfg.map_idx == 22 ? reg_map22[1:0] : 
	cfg.map_idx == 25 ? reg_map25[1:0] : reg_map23[1:0];
	
	wire [15:0]reg_addr = {cpu.addr[15:12], 8'd0, 2'd0, reg_map[1:0]};
	
	
	wire vrc2_latch_ce = {cpu.addr[15:12], 12'd0} == 16'h6000 & cfg.prg_ram_off & vrc2;
	
	reg [8:0]chr_reg[8];
	reg [7:0]prg_reg[2];
	reg swp_mode;
	reg [1:0]mir_mode;
	reg vrc2_latch;
	
	
	always @(negedge cpu.m2)
	if(sst.act)
	begin
		if(sst.we_reg & {sst.addr[7:3], 3'd0} == 0)chr_reg[sst.addr[2:0]][7:0] <= sst.dato[7:0];
		if(sst.we_reg & {sst.addr[7:3], 3'd0} == 8)chr_reg[sst.addr[2:0]][8] <= sst.dato[0];
		if(sst.we_reg & sst.addr[7:0] == 16)prg_reg[0][7:0] <= sst.dato[7:0];
		if(sst.we_reg & sst.addr[7:0] == 17)prg_reg[1][7:0] <= sst.dato[7:0];
		if(sst.we_reg & sst.addr[7:0] == 18){swp_mode, mir_mode[1:0]} <= sst.dato[2:0];
	end
		else
	if(mai.map_rst)
	begin
		prg_reg[1] <= 1;
		prg_reg[0] <= 0;
		swp_mode <= 0;
		mir_mode <= 3;
	end
		else
	if(!cpu.rw)
	begin
	
		if(cpu.addr[15:0] == 16'h9fff)mir_mode <= cpu.data[1:0];//Kaiketsu Yanchamaru fix
		
		if(reg_addr[15:0] == 16'h9000)mir_mode <= cpu.data[1:0];
		if(reg_addr[15:0] == 16'h9002)swp_mode <= cpu.data[1] & vrc4;
		
		
		if({reg_addr[15:2],2'b0} == 16'h8000)prg_reg[0][7:0] <= cpu.data[7:0];
		if({reg_addr[15:2],2'b0} == 16'hA000)prg_reg[1][7:0] <= cpu.data[7:0];
		
		
		if(reg_addr[15:0] == 16'hB000)chr_reg[0][3:0] <= cpu.data[3:0];
		if(reg_addr[15:0] == 16'hB001)chr_reg[0][8:4] <= cpu.data[4:0];
		if(reg_addr[15:0] == 16'hB002)chr_reg[1][3:0] <= cpu.data[3:0];
		if(reg_addr[15:0] == 16'hB003)chr_reg[1][8:4] <= cpu.data[4:0];
		
		if(reg_addr[15:0] == 16'hC000)chr_reg[2][3:0] <= cpu.data[3:0];
		if(reg_addr[15:0] == 16'hC001)chr_reg[2][8:4] <= cpu.data[4:0];
		if(reg_addr[15:0] == 16'hC002)chr_reg[3][3:0] <= cpu.data[3:0];
		if(reg_addr[15:0] == 16'hC003)chr_reg[3][8:4] <= cpu.data[4:0];
		
		if(reg_addr[15:0] == 16'hD000)chr_reg[4][3:0] <= cpu.data[3:0];
		if(reg_addr[15:0] == 16'hD001)chr_reg[4][8:4] <= cpu.data[4:0];
		if(reg_addr[15:0] == 16'hD002)chr_reg[5][3:0] <= cpu.data[3:0];
		if(reg_addr[15:0] == 16'hD003)chr_reg[5][8:4] <= cpu.data[4:0];
		
		if(reg_addr[15:0] == 16'hE000)chr_reg[6][3:0] <= cpu.data[3:0];
		if(reg_addr[15:0] == 16'hE001)chr_reg[6][8:4] <= cpu.data[4:0];
		if(reg_addr[15:0] == 16'hE002)chr_reg[7][3:0] <= cpu.data[3:0];
		if(reg_addr[15:0] == 16'hE003)chr_reg[7][8:4] <= cpu.data[4:0];
		
		if(vrc2_latch_ce)vrc2_latch <= cpu.data[0];
		
	end
	
	
	wire irq_out;
	wire [7:0]irq_ss;
	
	irq_vrc irq_vrc_inst(
		
		.cpu(cpu),
		.sst(sst),
		.reg_addr(reg_addr),
		.map_idx(cfg.map_idx),
		.map_rst(mai.map_rst),
		
		.irq(irq_out),
		.ss_dout(irq_ss),
	);
	
	/*
	irq_vrc(
		.bus(bus),
		.ss_ctrl(ss_ctrl),
		.ss_dout(irq_ss),
		.reg_addr(reg_addr),
		.map_idx(map_idx),
		.irq(irq_out)
	);*/
	
endmodule
