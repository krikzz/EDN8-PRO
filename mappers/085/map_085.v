`include "../base/defs.v"

module map_085
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
	ss_addr[7:0] == 16 ? prg[0][7:0] :
	ss_addr[7:0] == 17 ? prg[1][7:0] :
	ss_addr[7:0] == 18 ? {audio_mute, mir_mode[1:0]} :
	ss_addr[7:0] == 19 ? prg[2][7:0] :
	ss_addr[7:0] == 32 ? {prescal[8], irq_pend, irq_cfg[2:0]} :
	ss_addr[7:0] == 33 ? irq_latch[7:0] :
	ss_addr[7:0] == 34 ? irq_ctr[7:0] :
	ss_addr[7:0] == 35 ? prescal[7:0] :
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = {cpu_addr[15:13], 13'd0} == 16'h6000;
	assign ram_we = !cpu_rw & ram_ce;	
	assign rom_ce = cpu_addr[15];
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = 
	mir_mode[1:0] == 0 ? ppu_addr[10] : 
	mir_mode[1:0] == 1 ? ppu_addr[11] : 
	mir_mode[1:0] == 2 ? 0 : 1;
	
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[12:0] = cpu_addr[12:0];
	assign prg_addr[20:13] =
	cpu_addr[14:13] == 0 ? prg[0] :
	cpu_addr[14:13] == 1 ? prg[1] :
	cpu_addr[14:13] == 2 ? prg[2] : 8'hFF;
	
	assign chr_addr[9:0] = ppu_addr[9:0];
	assign chr_addr[17:10] = chr[ppu_addr[12:10]][7:0];

	
	wire [15:0]reg_addr = {cpu_addr[15:5], cpu_addr[4] | cpu_addr[3], 1'b0, cpu_addr[2:0]};
	
	
	reg [7:0]prg[3];
	reg [7:0]chr[8];
	reg [1:0]mir_mode;
	reg audio_mute;
	

	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:3] == 0)chr[ss_addr[2:0]][7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr == 16)prg[0][7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr == 17)prg[1][7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr == 18){audio_mute, mir_mode[1:0]} <= cpu_dat[2:0];
		if(ss_we & ss_addr == 19)prg[2][7:0] <= cpu_dat[7:0];
	end
		else
	if(map_rst)
	begin
		chr[0] <= 0;
		chr[1] <= 1;
		chr[2] <= 2;
		chr[3] <= 3;
		chr[4] <= 4;
		chr[5] <= 5;
		chr[6] <= 6;
		chr[7] <= 7;
		mir_mode <= 0;
		audio_mute <= 1;
	end
		else
	if(!cpu_rw)
	case(reg_addr[15:0])
	
		16'h8000:prg[0] <= cpu_dat[5:0];
		16'h8010:prg[1] <= cpu_dat[5:0];
		16'h9000:prg[2] <= cpu_dat[5:0];
		
		16'hA000:chr[0] <= cpu_dat[7:0];
		16'hA010:chr[1] <= cpu_dat[7:0];
		16'hB000:chr[2] <= cpu_dat[7:0];
		16'hB010:chr[3] <= cpu_dat[7:0];
		
		16'hC000:chr[4] <= cpu_dat[7:0];
		16'hC010:chr[5] <= cpu_dat[7:0];
		16'hD000:chr[6] <= cpu_dat[7:0];
		16'hD010:chr[7] <= cpu_dat[7:0];
		
		16'hE000:{audio_mute, mir_mode[1:0]} <= {cpu_dat[6], cpu_dat[1:0]};
		
	endcase
	
	parameter IRQ_REG_LAT = 16'hE010;
	parameter IRQ_REG_CFG = 16'hF000;
	parameter IRQ_REG_ACK = 16'hF010;
	`include "vrc6-irq.v"
	
	
	wire [10:0]vol;	
	ym2413_audio ym2413_inst(m2, !map_rst, cpu_dat, cpu_addr, cpu_ce, cpu_rw, clk, vol, audio_mute);
	
	dac_ds dac(clk, m2, vol, master_vol, pwm);
	
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


