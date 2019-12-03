
`include "../base/defs.v"

module map_227
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
	ss_addr[7:0] == 0 ? reg_data[7:0] : 
	ss_addr[7:0] == 0 ? reg_data[9:8] : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************

	assign ram_we = !cpu_rw & ram_ce;
	assign ram_ce = 0;//cpu_addr[14:13] == 2'b11 & cpu_ce & m2;
	assign rom_ce = !cpu_ce;
	assign chr_ce = ciram_ce;
	assign chr_we = !mode ? !ppu_we & ciram_ce : 0;
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = !mirror ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[13:0] = cpu_addr[13:0];
	//assign prg_addr[13] = cpu_ce ? 0 : cpu_addr[13];
	
	assign prg_addr[18:14] =  
	prg_config[2:1] == 2'b10 ? prg_mode[0] : 
	prg_config[2:1] == 2'b11 ? prg_mode[1] : 
	prg_config[2:0] == 3'b000 ? prg_mode[2] : 
	prg_config[2:0] == 3'b010 ? prg_mode[3] : 
	prg_config[2:0] == 3'b001 ? prg_mode[4] : prg_mode[5];
	//prg_config[2:0] == 3'b011 ?  : 

	wire [4:0]prg_mode[6];
	assign prg_mode[0] = prg[4:0];
	assign prg_mode[1] = {prg[4:1], cpu_addr[14]};//???
	assign prg_mode[2] = !cpu_addr[14] ? prg[4:0] : prg[4:0] & 8'h38;
	assign prg_mode[3] = !cpu_addr[14] ? prg[4:0] & 8'h3e : prg[4:0] & 8'h38;
	assign prg_mode[4] = !cpu_addr[14] ? prg[4:0] : prg[4:0] | 8'h07;
	assign prg_mode[5] = !cpu_addr[14] ? prg[4:0] & 8'h3e : prg[4:0] | 8'h07;
	
	assign chr_addr[12:0] = ppu_addr[12:0];
	
	reg [9:0]reg_data;
	
	wire prg_size = reg_data[0];
	wire mirror = reg_data[1];
	wire [5:0]prg = {reg_data[8], reg_data[6:2]};
	wire mode = reg_data[7];
	wire last_prg = reg_data[9];
	
	wire [2:0]prg_config = {mode, prg_size, last_prg};
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 0)reg_data[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 1)reg_data[9:8] <= cpu_dat[1:0];
	end
		else
	begin
		if(map_rst)reg_data = 0;//9'b111111110;
			else
		if(!cpu_ce & !cpu_rw)reg_data[9:0] <= cpu_addr[9:0];
	end
	
endmodule
