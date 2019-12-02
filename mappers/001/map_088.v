

`include "../base/defs.v"

module map_088 
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
	ss_addr[7:3] == 0 ? chr_prg[ss_addr[2:0]] : 
	ss_addr[7:0] == 8 ? {mirror_mode, reg_addr[2:0]} :
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = 0;
	assign ram_we = 0;
	assign rom_ce = !cpu_ce;
	assign chr_ce = ciram_ce;
	assign chr_we = 0;//cfg_chr_ram ? !ppu_we & ciram_ce : 0;
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = 
	map_idx == 95  ? chr_addr[15] : 
	map_idx == 154 ? mirror_mode : 
	cfg_mir_v ? ppu_addr[10] : 
	ppu_addr[11];
	
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[12:0] = cpu_addr[12:0];
	assign prg_addr[18:13] = 
	cpu_addr[14:13] == 0 ? chr_prg[6][5:0] : 
	cpu_addr[14:13] == 1 ? chr_prg[7][5:0] : {5'b11111, cpu_addr[13]};

	
	assign chr_addr[9:0] = ppu_addr[9:0];
	assign chr_addr[15:10] = 
	ppu_addr[12:11] == 0 ? {chr_prg[0][5:1], ppu_addr[10]} :
	ppu_addr[12:11] == 1 ? {chr_prg[1][5:1], ppu_addr[10]} : chr_prg[2 + ppu_addr[11:10]][5:0];
	
	assign chr_addr[16] = ppu_addr[12];
	
	
	reg [5:0]chr_prg[8];	
	reg [2:0]reg_addr;
	reg mirror_mode;
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:3] == 0)chr_prg[ss_addr[2:0]] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 8){mirror_mode, reg_addr[2:0]} <= cpu_dat;
	end
		else
	if(!cpu_rw & !cpu_ce)
	begin
		
		mirror_mode <= cpu_dat[6];
		if(cpu_addr[0] == 0)reg_addr <= cpu_dat[2:0];
		if(cpu_addr[0] == 1)chr_prg[reg_addr[2:0]][5:0] <= cpu_dat[5:0];
		
	end
	
	
endmodule
