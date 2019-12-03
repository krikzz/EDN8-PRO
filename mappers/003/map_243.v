
`include "../base/defs.v"

module map_243
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
	ss_addr[7:0] == 0 ? reg_addr : 
	ss_addr[7:0] == 1 ? chr : 
	ss_addr[7:0] == 2 ? prg : 
	ss_addr[7:0] == 3 ? mirror_mode : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************

	assign ram_we = !cpu_rw & ram_ce;
	assign ram_ce = cpu_addr[14:13] == 2'b11 & cpu_ce & m2;
	assign rom_ce = !cpu_ce;
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = 
	mirror_mode[1:0] == 2'b00 ? ppu_addr[11] :
	mirror_mode[1:0] == 2'b01 ? ppu_addr[10] :
	mirror_mode[1:0] == 2'b11 ? 1 :
	ppu_addr[11:10] == 0 ? 0 : 1;
	
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[12:0] = cpu_addr[12:0];
	assign prg_addr[14:13] = cpu_ce ? 0 : cpu_addr[14:13];
	assign prg_addr[17:15] = cpu_ce ? 0 : prg[2:0];
	
	assign chr_addr[12:0] = ppu_addr[12:0];
	assign chr_addr[16:13] = chr[3:0];
	
	reg [2:0]reg_addr;
	reg [3:0]chr;
	reg [2:0]prg;
	reg [1:0]mirror_mode;
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 0)reg_addr <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 1)chr <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 2)prg <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 3)mirror_mode <= cpu_dat;
	end
		else
	begin
	
		if(map_rst)
		begin
			reg_addr <= 0;
			chr <= 0;
			prg <= 0;
			mirror_mode <= 0;
		end
			else
		if(cpu_ce & !cpu_rw & cpu_addr[14:12] == 3'b100 & cpu_addr[8])
		begin
			
			if(!cpu_addr[0])reg_addr[2:0] <= cpu_dat[2:0];
				else
			case(reg_addr[2:0])
				/*
				0:begin
					chr <= 0;
					prg <= 0;
				end*/
				2:begin
					chr[3] <= cpu_dat[0];//2
				end
				4:begin
					chr[2] <= cpu_dat[0];//1
				end
				5:begin
					prg[2:0] <= cpu_dat[2:0];
				end
				6:begin
					chr[1:0] <= cpu_dat[1:0];//0
				end
				7:begin
					mirror_mode[1:0] <= cpu_dat[2:1];
				end
			
			endcase
		
		end
	
	end
	
	
endmodule
