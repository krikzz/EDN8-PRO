
`include "../base/defs.v"

module map_076 
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
	ss_addr[7:2] == 0 ? chr[ss_addr[1:0]] : 
	ss_addr[7:0] == 4 ? prg[0] : 
	ss_addr[7:0] == 5 ? prg[1] : 
	ss_addr[7:0] == 6 ? reg_addr : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = 0;
	assign ram_we = 0;
	assign rom_ce = !cpu_ce;
	assign chr_ce = ciram_ce;
	assign chr_we = 0;
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = cfg_mir_v ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[12:0] = cpu_addr[12:0];
	assign prg_addr[18:13] = 
	cpu_addr[14:13] == 0 ? prg[0][5:0] : 
	cpu_addr[14:13] == 1 ? prg[1][5:0] : {5'b11111, cpu_addr[13]};

	
	assign chr_addr[10:0] = ppu_addr[10:0];
	assign chr_addr[16:11] = chr[ppu_addr[12:11]];
	
	
	reg [5:0]chr[4];
	reg [5:0]prg[4];	
	reg [2:0]reg_addr;
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:2] == 0)chr[ss_addr[1:0]] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 4)prg[0] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 5)prg[1] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 6)reg_addr <= cpu_dat;
	end
		else
	if(!cpu_rw & !cpu_ce)
	begin
	
		if(cpu_addr[0] == 0)reg_addr <= cpu_dat[2:0];
		
		if(cpu_addr[0] == 1 & reg_addr[2:0] == 2)chr[0] <= cpu_dat;
		if(cpu_addr[0] == 1 & reg_addr[2:0] == 3)chr[1] <= cpu_dat;
		if(cpu_addr[0] == 1 & reg_addr[2:0] == 4)chr[2] <= cpu_dat;
		if(cpu_addr[0] == 1 & reg_addr[2:0] == 5)chr[3] <= cpu_dat;
		if(cpu_addr[0] == 1 & reg_addr[2:0] == 6)prg[0] <= cpu_dat;
		if(cpu_addr[0] == 1 & reg_addr[2:0] == 7)prg[1] <= cpu_dat;
		
	end
	

	
endmodule
