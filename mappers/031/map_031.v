
`include "../base/defs.v"

module map_031
	(map_out, bus, sys_cfg, ss_ctrl);
	
	`include "../base/bus_in.v"
	`include "../base/map_out.v"
	`include "../base/sys_cfg_in.v"
	`include "../base/ss_ctrl_in.v"
	
	output [`BW_MAP_OUT-1:0]map_out;
	input [`BW_SYS_CFG-1:0]sys_cfg;
	
	
	
	assign sync_m2 = 1;
	assign mir_4sc = 0;//enable support for 4-screen mirroring. for activation should be ensabled in sys_cfg also
	assign srm_addr[12:0] = prg_addr[12:0];
	assign prg_oe = cpu_rw;
	assign chr_oe = !ppu_oe;
	//*************************************************************  save state setup
	assign ss_rdat[7:0] = 
	ss_addr[7:3] == 0 ? bank[ss_addr[2:0]] : 
	ss_addr[7:0] == 8 ? bank_fds[0] :
	ss_addr[7:0] == 9 ? bank_fds[1] :
	ss_addr[7:0] == 10 ? mode : 
	ss_addr[7:0] == 11 ? exp_setup[7:0] :
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = 0;
	assign ram_we = 0;
	assign rom_ce = cpu_addr[15] | ram_ce_x;
	assign rom_we = !cpu_rw & (ram_ce_x | ram_ce_fds);
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0; // allows 8k CHR ROM or RAM
	
	assign ciram_a10 = cfg_mir_v ? ppu_addr[10] : ppu_addr[11]; // mirroring
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[11:0] = cpu_addr[11:0];
	assign prg_addr[19:12] = 
	player_bank ? 8'hff : 
	ram_ce_std & act_fds ? bank_fds[cpu_addr[12]][7:0] :
	ram_ce_std  ? {5'd0, 2'd0, cpu_addr[12]}: 
	ram_ce_pla  ? {5'd1, 3'd0} :
	ram_ce_mmc5 ? {5'd2, 3'd0} :
	bank[cpu_addr[14:12]][7:0];
	
	assign prg_addr[20] = ram_ce_std & act_fds ? 0 : ram_ce_x;
	
	assign chr_addr[12:0] = ppu_addr[12:0];
	
	assign map_cpu_oe = map_oe_n163 | map_oe_fds;
	assign map_cpu_dout[7:0] = 
	map_oe_fds ? dout_fds[7:0] : 
	map_oe_n163 ? dout_n163[7:0] : 
	8'hff;
	
	wire ram_ce_x = ram_ce_mmc5 | ram_ce_std | ram_ce_pla;
	wire ram_ce_std = {cpu_addr[15:13], 13'd0} == 16'h6000;
	wire ram_ce_pla = {cpu_addr[15:8], 8'd0} == 16'h4200;
	wire player_bank = {cpu_addr[15:12], 12'd0} == 16'hF000 & mode == 0;

	reg [7:0]bank[8];
	reg [7:0]bank_fds[2];
	reg mode;

	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:3] == 0)bank[ss_addr[2:0]] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 8)bank_fds[0] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 9)bank_fds[1] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 10)mode <= cpu_dat[0];
	end
		else
	if(map_rst)
	begin
		bank[7][7:0] <= 8'hff;
		mode <= 1;
		bank_fds[0] <= 6;
		bank_fds[1] <= 7;
	end
		else
	if(!cpu_rw)
	begin
		
		if(cpu_addr[15:0] == 16'h42FE)mode <= 0;
		if(cpu_addr[15:0] == 16'h42FF)mode <= 1;
		
		if(cpu_addr[15:0] == 16'h5FF6)bank_fds[0] <= cpu_dat;
		if(cpu_addr[15:0] == 16'h5FF7)bank_fds[1] <= cpu_dat;
		
		if ({cpu_addr[15:12], 12'd0} === 16'h5000)
		begin
			bank[cpu_addr[2:0]][7:0] <= cpu_dat[7:0];
		end
		
	end
	
	//************************************************************* expansion sound
	reg [7:0]exp_setup;
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 11)exp_setup[7:0] <= cpu_dat[7:0];
	end
		else
	begin
		if(cpu_addr[15:0] == 16'h42FC & !cpu_rw)exp_setup[7:0] <= cpu_dat[7:0];
	end
	


	wire act_vrc6 = exp_setup[0];
	wire act_vrc7 = exp_setup[1];
	wire act_fds  = exp_setup[2];
	wire act_mmc5 = exp_setup[3];
	wire act_n163 = exp_setup[4];
	wire act_su5b = exp_setup[5];
	
	wire pwm_vrc6, pwm_vrc7, pwm_fds, pwm_mmc5, pwm_n163, pwm_su5b;
	
	assign pwm = 
	act_vrc6 ? pwm_vrc6 : 
	act_vrc7 ? pwm_vrc7 : 
	act_fds  ? pwm_fds : 
	act_mmc5 ? pwm_mmc5 : 
	act_n163 ? pwm_n163 : 
	act_su5b ? pwm_su5b : 0;
	
	//************************************************************* vrc6
	wire map_24 = 1;
	wire [1:0]reg_map24 = cpu_addr[3:2] == 0 ?  cpu_addr[1:0] : cpu_addr[3:2];
	wire [1:0]reg_map26 = cpu_addr[3:2] == 0 ? {cpu_addr[0], cpu_addr[1]} : {cpu_addr[2], cpu_addr[3]};
	wire [15:0]reg_addr = {cpu_addr[15:12], 10'd0, (map_24 ? reg_map24[1:0] : reg_map26[1:0])};
	wire [6:0]snd_vol_vrc6;
	
	snd_vrc6 snd_vrc6_inst(
		.bus(bus), 
		.snd_vol(snd_vol_vrc6),
		.chr_reg_addr(reg_addr[1:0])
	);

	dac_ds7 dac_vrc6(clk, m2, snd_vol_vrc6, master_vol, pwm_vrc6);
	
	//************************************************************* n163
	wire map_oe_n163 = {cpu_addr[15:11], 11'd0} == 16'h4800 & cpu_rw & act_n163;
	wire [7:0]dout_n163;
	wire [7:0]snd_vol_n163;
	snd_n163 snd_n163_inst(
		.bus(bus), 
		.vol(snd_vol_n163), 
		.dout(dout_n163)
	);
	
	dac_ds8 dac_n163(clk, m2, snd_vol_n163, master_vol, pwm_n163);
	
	//************************************************************* sunsoft5b
	wire [11:0]snd_vol_su5b;
	ym2149 ym2149_inst(
		.cpu_d(cpu_dat),
		.cpu_a(cpu_addr[14:10]), 
		.cpu_ce_n(cpu_ce), 
		.cpu_rw(cpu_rw), 
		.phi_2(m2),
		.audio_clk(clk), 
		.audio_out(snd_vol_su5b), 
		.map_enable(!map_rst)
	);
	
	dac_ds12 dac_su5b(clk, m2, snd_vol_su5b, master_vol, pwm_su5b);
	
	//************************************************************* fds
	wire ram_ce_fds = {cpu_addr[15:13], 13'd0} != 16'hE000 & cpu_addr[15] & act_fds;
	wire map_oe_fds = map_oe_fds_int & act_fds;
	wire map_oe_fds_int;
	wire [11:0]snd_vol_fds;
	wire [7:0]dout_fds;
/*
	snd_fds snd_fds_inst(
		.bus(bus), 
		.vol(snd_vol_fds), 
		.bus_oe(map_oe_fds_int), 
		.dout(dout_fds),
	);

	dac_ds12 dac_fds(clk, m2, snd_vol_fds, master_vol, pwm_fds);*/
	//************************************************************* vrc7
	wire [10:0]snd_vol_vrc7;	
	ym2413_audio ym2413_inst(m2, !map_rst, cpu_dat, cpu_addr, cpu_ce, cpu_rw, clk, snd_vol_vrc7, 0);
	
	dac_ds11 dac_vrc7(clk, m2, snd_vol_vrc7, master_vol, pwm_vrc7);
	
	//************************************************************* mmc5
	wire ram_ce_mmc5 = {cpu_addr[15:10], 10'd0} == 16'h5C00 & act_mmc5;
	//wire raddr_mmc5[]
	
endmodule


module dac_ds11
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

	
	reg clk_div;
	always @(negedge m2)clk_div <= !clk_div;
	
	always @(negedge clk_div)
	begin
		vol_st[DEPTH-1:0] <= (vol[DEPTH-1:0] * master_vol) / 128;
	end
	
	
	always @(negedge clk) 
	begin
		sigma_st[DEPTH+1:0] <= sigma[DEPTH+1:0];
		snd <= sigma_st[DEPTH+1];
	end
	
endmodule  

module dac_ds12
(clk, m2, vol, master_vol, snd);
	
	parameter DEPTH = 12;
	
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

	
	reg clk_div;
	always @(negedge m2)clk_div <= !clk_div;
	
	always @(negedge clk_div)
	begin
		vol_st[DEPTH-1:0] <= (vol[DEPTH-1:0] * master_vol) / 128;
	end
	
	
	always @(negedge clk) 
	begin
		sigma_st[DEPTH+1:0] <= sigma[DEPTH+1:0];
		snd <= sigma_st[DEPTH+1];
	end
	
endmodule  

module dac_ds8
(clk, m2, vol, master_vol, snd);
	
	parameter DEPTH = 8;
	
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

	
	reg clk_div;
	always @(negedge m2)clk_div <= !clk_div;
	
	always @(negedge clk_div)
	begin
		vol_st[DEPTH-1:0] <= (vol[DEPTH-1:0] * master_vol) / 128;
	end
	
	
	always @(negedge clk) 
	begin
		sigma_st[DEPTH+1:0] <= sigma[DEPTH+1:0];
		snd <= sigma_st[DEPTH+1];
	end
	
endmodule  



module dac_ds7
(clk, m2, vol, master_vol, snd);
	
	parameter DEPTH = 7;
	
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

	
	reg clk_div;
	always @(negedge m2)clk_div <= !clk_div;
	
	always @(negedge clk_div)
	begin
		vol_st[DEPTH-1:0] <= (vol[DEPTH-1:0] * master_vol) / 128;
	end
	
	
	always @(negedge clk) 
	begin
		sigma_st[DEPTH+1:0] <= sigma[DEPTH+1:0];
		snd <= sigma_st[DEPTH+1];
	end
	
endmodule  
