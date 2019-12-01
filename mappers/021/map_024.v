
`include "../base/defs.v"

module map_024 //VRC6
	(map_out, bus, sys_cfg, ss_ctrl);
	
	`include "../base/bus_in.v"
	`include "../base/map_out.v"
	`include "../base/sys_cfg_in.v"
	`include "../base/ss_ctrl_in.v"
	
	output [`BW_MAP_OUT-1:0]map_out;
	input [`BW_SYS_CFG-1:0]sys_cfg;
	
	
	
	assign sync_m2 = 1;
	assign mir_4sc = 0;//enable support for 4-screen mirroring. for activation should be ensabled in sys_cfg also
	assign srm_addr[12:0] = cpu_addr[12:0];
	assign prg_oe = cpu_rw;
	assign chr_oe = !ppu_oe;
	//*************************************************************  save state setup
	assign ss_rdat[7:0] = 
	{ss_addr[7:3], 3'd0} == 0 ? chr[ss_addr[2:0]][7:0] :
	//{ss_addr[7:3], 3'd0} == 8 ? chr[ss_addr[2:0]][8] :
	ss_addr[7:0] == 16 ? prg[0][7:0] :
	ss_addr[7:0] == 17 ? prg[1][7:0] :
	ss_addr[7:0] == 18 ? {mir_mode[1:0]} :
	ss_addr[7:0] == 32 ? irq_ss :
	ss_addr[7:0] == 33 ? irq_ss :
	ss_addr[7:0] == 34 ? irq_ss :
	ss_addr[7:0] == 35 ? irq_ss :
	ss_addr[7:0] == 36 ? irq_ss :
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = {cpu_addr[15:13], 13'd0} == 16'h6000;
	assign ram_we = !cpu_rw & ram_ce;
	assign rom_ce = cpu_addr[15];
	assign chr_ce = ciram_ce;
	assign chr_we = 0;
	
	assign ciram_a10 = mir_mode[1] ? mir_mode[0] : !mir_mode[0] ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[12:0] = cpu_addr[12:0];
	assign prg_addr[20:13] = 
	{cpu_addr[15:13],13'd0} == 16'hc000 ? prg[1][7:0] :
	{cpu_addr[15:13],13'd0} == 16'he000 ? 8'hff :
	{prg[0][6:0], cpu_addr[13]};
	
	
	//cpu_addr[14:13] == 2'b11 ? 5'h1f : cpu_addr[14:13] == 2'b10 ? prg[1][4:0] : {prg[0][3:0], cpu_addr[13]};
	
	
	assign chr_addr[9:0] = ppu_addr[9:0];
	assign chr_addr[17:10] = chr_map[7:0];
	
	
	wire map_24 = map_idx == 24;
	wire map_26 = map_idx == 26;
	wire [1:0]reg_map24 = cpu_addr[3:2] == 0 ?  cpu_addr[1:0] : cpu_addr[3:2];
	wire [1:0]reg_map26 = cpu_addr[3:2] == 0 ? {cpu_addr[0], cpu_addr[1]} : {cpu_addr[2], cpu_addr[3]};
	wire [15:0]reg_addr = {cpu_addr[15:12], 10'd0, (map_24 ? reg_map24[1:0] : reg_map26[1:0]) };


	wire [7:0]chr_map = chr[ppu_addr[12:10]];
	

	reg [7:0]prg[2];
	reg [7:0]chr[8];
	reg [1:0]mir_mode;

	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & {ss_addr[7:3], 3'd0} == 0)chr[ss_addr[2:0]][7:0] <= cpu_dat[7:0];
		//if(ss_we & {ss_addr[7:3], 3'd0} == 8)chr[ss_addr[2:0]][8] <= cpu_dat[0];
		if(ss_we & ss_addr[7:0] == 16)prg[0][7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 17)prg[1][7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 18){mir_mode[1:0]} <= cpu_dat[1:0];
	end
		else
	if(map_rst)
	begin
		prg[1] <= 1;
		prg[0] <= 0;
		mir_mode <= 0;
	end
		else
	if(!cpu_rw)
	begin

		if({cpu_addr[15:12], 12'd0} == 16'h8000)prg[0][7:0] <= cpu_dat[7:0];
		if({cpu_addr[15:12], 12'd0} == 16'hC000)prg[1][7:0] <= cpu_dat[7:0];
		
		if(reg_addr[15:0] == 16'hB003)mir_mode[1:0] <= cpu_dat[3:2];
		
		if({reg_addr[15:2], 2'd0} == 16'hD000)chr[{1'b0, reg_addr[1:0]}][7:0] <= cpu_dat[7:0];
		if({reg_addr[15:2], 2'd0} == 16'hE000)chr[{1'b1, reg_addr[1:0]}][7:0] <= cpu_dat[7:0];

	end

	
	wire [7:0]irq_ss;
	irq_vrc(
		.bus(bus),
		.ss_ctrl(ss_ctrl),
		.ss_dout(irq_ss),
		.reg_addr(reg_addr),
		.map_idx(map_idx),
		.irq(irq)
	);


	wire [6:0]snd_vol;
	snd_vrc6 snd_inst(
		.bus(bus), 
		.snd_vol(snd_vol),
		.chr_reg_addr(reg_addr[1:0])
	);


		
	dac_ds dac_inst(clk, m2, {snd_vol[6:0], 4'd0}, master_vol, pwm);

endmodule




module dac_ds
(clk, m2, vol, master_vol, snd);
	
	parameter DEPTH = 11;
	
	input clk, m2;
	input [DEPTH-1:0]	vol;
	input [7:0]master_vol;
	output reg snd;
	

	
	wire [DEPTH+1:0]delta;
	wire [DEPTH+1:0]sigma;
	

	reg [DEPTH+1:0] sigma_st;	
	reg [DEPTH-1:0] vol_st;

	assign	delta[DEPTH+1:0] = {2'b0, vol_st[DEPTH-1:0]} + {sigma_st[DEPTH+1], sigma_st[DEPTH+1], {(DEPTH){1'b0}}};
	assign	sigma[DEPTH+1:0] = delta[DEPTH+1:0] + sigma_st[DEPTH+1:0];

	

	always @(negedge m2)
	begin
		vol_st[DEPTH-1:0] <= (vol[DEPTH-1:0] * master_vol) / 128;
	end
	
	
	always @(negedge clk) 
	begin
		sigma_st[DEPTH+1:0] <= sigma[DEPTH+1:0];
		snd <= sigma_st[DEPTH+1];
	end
	
endmodule  



