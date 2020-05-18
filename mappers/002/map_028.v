
`include "../base/defs.v"

module map_028
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
	ss_addr[7:0] == 0 ? ine_prg : 
	ss_addr[7:0] == 1 ? out_prg : 
	ss_addr[7:0] == 2 ? {prg_mode[1:0], mirror_mode[1:0], prg_size[1:0], reg_addr[1:0]} : 
	ss_addr[7:0] == 3 ? chr_ram_bank : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************

	assign ram_we = !cpu_rw & ram_ce;
	assign ram_ce = cpu_addr[14:13] == 2'b11 & !cpu_addr[15];
	assign rom_ce = cpu_addr[15];
	assign chr_ce = ciram_ce;
	assign chr_we = !ppu_we & ciram_ce;
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = !mirror_mode[1] ? mirror_mode[0] : !mirror_mode[0] ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
		
	assign chr_addr[12:0] = ppu_addr[12:0];
	assign chr_addr[14:13] = chr_ram_bank[1:0];
	
	assign prg_addr[13:0] = cpu_addr[13:0];
	assign prg_addr[22:14] = 
	prg_mode[1] == 0 & prg_size == 0 ? {out_prg[7:0], cpu_addr[14]} : 
	prg_mode[1] == 0 & prg_size == 1 ? {out_prg[7:1], ine_prg[0], cpu_addr[14]} : 
	prg_mode[1] == 0 & prg_size == 2 ? {out_prg[7:2], ine_prg[1:0], cpu_addr[14]} : 
	prg_mode[1] == 0 & prg_size == 3 ? {out_prg[7:3], ine_prg[2:0], cpu_addr[14]} : 
	prg_mode[0] == cpu_addr[14] ? {out_prg[7:0], cpu_addr[14]} : 
	prg_size == 0 ? {out_prg[7:0], ine_prg[0]} : 
	prg_size == 1 ? {out_prg[7:1], ine_prg[1:0]} : 
	prg_size == 2 ? {out_prg[7:2], ine_prg[2:0]} : 
	prg_size == 3 ? {out_prg[7:3], ine_prg[3:0]} : 0;
	

	reg [3:0]ine_prg;
	reg [7:0]out_prg;
	
	reg [1:0]reg_addr;
	reg [1:0]prg_size;
	reg [1:0]mirror_mode;
	reg [1:0]prg_mode;
	
	reg [1:0]chr_ram_bank;
	 
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 0)ine_prg <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 1)out_prg <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 2){prg_mode[1:0], mirror_mode[1:0], prg_size[1:0], reg_addr[1:0]} <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 3)chr_ram_bank <= cpu_dat;
	end
		else
	if(map_rst)
	begin
		ine_prg[3:0] <= 0;
		out_prg[7:0] <= 8'hff;
		mirror_mode[1:0] <= 2'b01;
	end
		else
	begin
	
		if(!cpu_rw & !cpu_addr[15] & cpu_addr[14:12] == 3'b101)reg_addr[1:0] <= {cpu_dat[7], cpu_dat[0]};
			else
		if(!cpu_rw & !cpu_ce)
		case(reg_addr)
			0:begin
				chr_ram_bank[1:0] <= cpu_dat[1:0];
				if(!mirror_mode[1])mirror_mode[0] <= cpu_dat[4];
			end
			1:begin
				ine_prg[3:0] <= cpu_dat[3:0];
				if(!mirror_mode[1])mirror_mode[0] <= cpu_dat[4];
			end
			2:begin
				mirror_mode[1:0] <= cpu_dat[1:0];
				prg_mode[1:0] <= cpu_dat[3:2];
				prg_size[1:0] <= cpu_dat[5:4];
			end
			3:begin
				out_prg[7:0] <= cpu_dat[7:0];
			end
		endcase
		
	end
	
	
endmodule
