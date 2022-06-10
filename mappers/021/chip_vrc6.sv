
module chip_vrc6(
	
	input  cpu_m2,
	input  cpu_rw,
	input  cpu_a0,
	input  cpu_a1,
	input  cpu_a12,
	input  cpu_a13,
	input  cpu_a14,
	input  cpu_ce_n,
	input  [7:0]cpu_data,
	input  [13:10]ppu_addr,
	input  ppu_oe_n,//what is this for?
	
	output irq_n, 
	output ciram_ce_n,
	output chr_ce_n,
	output prg_ce_n, 
	output wram_ce_n,
	output [17:10]chr_addr,
	output [20:13]prg_addr,
	output [6:0]snd_vol,
	
	input  rst,
	input  SSTBus sst,
	output [7:0]sst_di
);
//************************************************************* sst
	assign sst_di[7:0]	=
	sst.addr[7:0]  <  8 ? chr_reg[sst.addr[2:0]] :
	sst.addr[7:0] == 16 ? prg_reg[0] :
	sst.addr[7:0] == 17 ? prg_reg[1] :
	sst.addr[7:0] == 18 ? bnk_cfg :
	sst.addr[7:0]  < 48 ? irq_ss :
	snd_ss;
//*************************************************************
	assign wram_ce_n			= !({cpu_addr[15:13], 13'd0} == 16'h6000 & bnk_cfg[7]);
	assign ciram_ce_n			= bnk_cfg[4] ? 1 : !ppu_addr[13];
	assign chr_ce_n			= !ciram_ce_n;
	assign prg_ce_n			= !cpu_addr[15];
	assign irq_n				= !irq_pend;
	
	
	assign prg_addr[20:13]	= 
	{cpu_addr[15:13],13'd0} == 16'hc000 ? prg_reg[1][7:0] :
	{cpu_addr[15:13],13'd0} == 16'he000 ? 8'hff :
	{prg_reg[0][6:0], cpu_addr[13]};
	

	assign chr_addr[17:10] 	= ppu_addr[13] ? ntb_xx: chr_xx;

//************************************************************* chr mapping	
	wire [17:10]chr_xx		= {chr_map[17:11], chr_xx_a10};
	
	wire chr_xx_a10			=
	bnk_cfg[1:0] == 0	? chr_map[10] : 
	bnk_cfg[1:0] == 1	? chr_m1_a10 : 
	ppu_addr[12] == 1 ? chr_m2_a10 : chr_map[10];
	
	wire chr_m1_a10			= bnk_cfg[5] ? ppu_addr[10] : chr_m1[10];
	wire chr_m2_a10			= bnk_cfg[5] ? ppu_addr[10] : chr_m2_1[10];
	
	wire [17:10]chr_map		= 
	bnk_cfg[1:0] == 0 ? chr_m0[17:10] : 
	bnk_cfg[1:0] == 1 ? chr_m1[17:10]  : 
	ppu_addr[12] == 0 ? chr_m2_0[17:10] : chr_m2_1[17:10];
	
	wire [17:10]chr_m0		= chr_reg[ppu_addr[12:10]];
	wire [17:10]chr_m1		= chr_reg[ppu_addr[12:11]][7:0];
	wire [17:10]chr_m2_0		= chr_reg[ppu_addr[11:10]];
	wire [17:10]chr_m2_1		= chr_reg[4 + ppu_addr[11]][7:0];
	
//************************************************************* ntb mapping
	wire [17:10]ntb_xx 		= {ntb_map[17:11], ntb_xx_a10};

	wire ntb_xx_a10 			= 
	bnk_cfg[1:0] == 0 ? ntb_m0_a10 : 
	bnk_cfg[1:0] == 3 ? ntb_m3_a10 : ntb_map[10];
	
	wire ntb_m0_a10	= 
	bnk_cfg[5] == 0 ? ntb_map[10] : 
	bnk_cfg[3] == 1 ? bnk_cfg[2] : 
	bnk_cfg[2] == 0 ? ppu_addr[10] : ppu_addr[11];
	
	wire ntb_m3_a10	= 
	bnk_cfg[5]   == 0 ? ntb_map[10] : 
	bnk_cfg[3:2] == 0 ? ppu_addr[11] :
	bnk_cfg[3:2] == 1 ? ppu_addr[10] :
	bnk_cfg[3:2] == 2 ? 1 : 0;
	
	wire [17:10]ntb_map		= 
	bnk_cfg[2:0] == 1 ? ntb_m0 : 
	bnk_cfg[2:0] == 5 ? ntb_m0 : 
	bnk_cfg[2:0] == 2 ? ntb_m1 : 
	bnk_cfg[2:0] == 3 ? ntb_m1 : 
	bnk_cfg[2:0] == 4 ? ntb_m1 : ntb_m2;
	
	wire [17:10]ntb_m0		= chr_reg[4 + ppu_addr[11:10]];//1,5
	wire [17:10]ntb_m1		= chr_reg[6 + ppu_addr[10]];//2,3,4
	wire [17:10]ntb_m2		= chr_reg[6 + ppu_addr[11]];//0,6,7
	
//*************************************************************	
	
	wire [15:0]cpu_addr		= {!cpu_ce_n, cpu_a14, cpu_a13, cpu_a12, 10'd0, cpu_a1, cpu_a0};
	
	reg [7:0]prg_reg[2];
	reg [7:0]chr_reg[8];
	reg [7:0]bnk_cfg;

	
	always @(negedge cpu_m2)
	if(sst.act)
	begin
		if(sst.we_reg & sst.addr[7:0]  <  8)chr_reg[sst.addr[2:0]] <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 16)prg_reg[0]							<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 17)prg_reg[1]							<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 18)bnk_cfg								<= sst.dato;
	end
		else
	if(rst)
	begin
		prg_reg[1] 	<= 1;
		prg_reg[0] 	<= 0;
		bnk_cfg 		<= 0;
	end
		else
	if(!cpu_rw)
	begin
		
		case({cpu_addr[15:12], 12'd0})
		
			16'h8000:prg_reg[0]								<= cpu_data;
			16'hC000:prg_reg[1]								<= cpu_data;
			16'hD000:chr_reg[{1'b0, cpu_addr[1:0]}] 	<= cpu_data;
			16'hE000:chr_reg[{1'b1, cpu_addr[1:0]}]	<= cpu_data;
			
		endcase
		
		if(cpu_addr[15:0] == 16'hB003)
		begin
			bnk_cfg	<= cpu_data;
		end

	end
	
//************************************************************* irq
	wire [7:0]irq_ss;
	wire irq_pend;
	
	irq_vrc irq_vrc_inst(
		
		.cpu_data(cpu_data[7:0]),
		.cpu_m2(cpu_m2),
		.cpu_rw(cpu_rw),
		.map_rst(rst),
		.ce_latx(cpu_addr == 16'hF000),
		.ce_ctrl(cpu_addr == 16'hF001),
		.ce_ackn(cpu_addr == 16'hF002),
		
		.irq(irq_pend),
		
		.sst(sst),
		.sst_di(irq_ss)
	);

//************************************************************* audio
	wire [7:0]snd_ss;
	
	snd_vrc6 snd_inst(
	
		.cpu_m2(cpu_m2),
		.cpu_rw(cpu_rw),	
		.cpu_data(cpu_data),
		.cpu_addr(cpu_addr),	
		.rst(rst),
		.snd_vol(snd_vol),
		
		.sst(sst),
		.sst_di(snd_ss)
	);

endmodule
