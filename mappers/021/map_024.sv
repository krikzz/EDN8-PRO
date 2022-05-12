
module map_024(

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
	sst.addr[7:0] == 16 ? prg_reg[0][7:0] :
	sst.addr[7:0] == 17 ? prg_reg[1][7:0] :
	sst.addr[7:0] == 18 ? {mir_mode[1:0]} :
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
	{cpu.addr[15:13],13'd0} == 16'hc000 ? prg_reg[1][7:0] :
	{cpu.addr[15:13],13'd0} == 16'he000 ? 8'hff :
	{prg_reg[0][6:0], cpu.addr[13]};
	
	assign chr.ce 				= mao.ciram_ce;
	assign chr.oe 				= !ppu.oe;
	assign chr.we 				= cfg.chr_ram ? !ppu.we & mao.ciram_ce : 0;
	assign chr.addr[9:0]		= ppu.addr[9:0];
	assign chr.addr[17:10] 	= chr_map[7:0];

	
	//A10-Vmir, A11-Hmir
	assign mao.ciram_a10 	= mir_mode[1] ? mir_mode[0] : !mir_mode[0] ? ppu.addr[10] : ppu.addr[11];
	assign mao.ciram_ce 		= !ppu.addr[13];
	
	assign mao.irq				= irq_pend;
	assign mao.snd[15:0]		= {snd_vol[6:0], 9'd0};
//************************************************************* mapper implementation
	wire [1:0]reg_map24 	= cpu.addr[3:2] == 0 ?  cpu.addr[1:0] : cpu.addr[3:2];
	wire [1:0]reg_map26 	= cpu.addr[3:2] == 0 ? {cpu.addr[0], cpu.addr[1]} : {cpu.addr[2], cpu.addr[3]};
	wire [1:0]reg_mapxx	= cfg.map_idx == 24 ? reg_map24[1:0] : reg_map26[1:0];
	wire [15:0]reg_addr 	= {cpu.addr[15:12], 10'd0, reg_mapxx[1:0]};


	wire [7:0]chr_map = chr_reg[ppu.addr[12:10]];
	

	reg [7:0]prg_reg[2];
	reg [7:0]chr_reg[8];
	reg [1:0]mir_mode;

	
	always @(negedge cpu.m2)
	if(sst.act)
	begin
		if(sst.we_reg & {sst.addr[7:3], 3'd0} == 0)chr_reg[sst.addr[2:0]][7:0] <= sst.dato[7:0];
		if(sst.we_reg & sst.addr[7:0] == 16)prg_reg[0][7:0] <= sst.dato[7:0];
		if(sst.we_reg & sst.addr[7:0] == 17)prg_reg[1][7:0] <= sst.dato[7:0];
		if(sst.we_reg & sst.addr[7:0] == 18){mir_mode[1:0]} <= sst.dato[1:0];
	end
		else
	if(mai.map_rst)
	begin
		prg_reg[1] 	<= 1;
		prg_reg[0] 	<= 0;
		mir_mode 	<= 0;
	end
		else
	if(!cpu.rw)
	begin

		if({cpu.addr[15:12], 12'd0} == 16'h8000)prg_reg[0][7:0] 	<= cpu.data[7:0];
		if({cpu.addr[15:12], 12'd0} == 16'hC000)prg_reg[1][7:0] 	<= cpu.data[7:0];
		
		if(reg_addr[15:0] == 16'hB003)mir_mode[1:0] <= cpu.data[3:2];
		
		if({reg_addr[15:2], 2'd0} == 16'hD000)chr_reg[{1'b0, reg_addr[1:0]}][7:0] <= cpu.data[7:0];
		if({reg_addr[15:2], 2'd0} == 16'hE000)chr_reg[{1'b1, reg_addr[1:0]}][7:0] <= cpu.data[7:0];

	end

	
	
	wire irq_pend;
	wire [7:0]irq_ss;
	
	irq_vrc irq_vrc_inst(
		
		.cpu(cpu),
		.sst(sst),
		.reg_addr(reg_addr),
		.map_idx(cfg.map_idx),
		.map_rst(mai.map_rst),
		
		.irq(irq_pend),
		.ss_dout(irq_ss)
	);
	


	wire [6:0]snd_vol;
	
	snd_vrc6 snd_inst(
	
		.cpu(cpu),
		.chr_reg_addr(reg_addr[1:0]),
		.map_rst(mai.map_rst),

		.snd_vol(snd_vol)
	);

	
endmodule
