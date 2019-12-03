
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
	assign ram_ce = cpu_addr[14:13] == 2'b11 & cpu_ce & m2;
	assign rom_ce = !cpu_ce;
	assign chr_ce = ciram_ce;
	assign chr_we = !ppu_we & ciram_ce;
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = !mirror_mode[1] ? mirror_mode[0] : !mirror_mode[0] ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[12:0] = cpu_addr[12:0];
	assign prg_addr[13] = cpu_ce ? 0 : cpu_addr[13];
	assign prg_addr[18:14] = cpu_ce ? 0 : prg[4:0];
	
	assign chr_addr[12:0] = ppu_addr[12:0];
	assign chr_addr[14:13] = chr_ram_bank[1:0];
	

	reg [3:0]ine_prg;
	reg [5:0]out_prg;
	
	reg [1:0]reg_addr;
	reg [1:0]prg_size;
	reg [1:0]mirror_mode;
	reg [1:0]prg_mode;
	
	reg [1:0]chr_ram_bank;
	

	wire [2:0]size_mask = 
	prg_size[1:0] == 0 ? 3'b000 : 
	prg_size[1:0] == 1 ? 3'b001 : 
	prg_size[1:0] == 2 ? 3'b011 : 3'b111;
	
	wire fixed_bank = !prg_mode[1] ? 0 : !prg_mode[0] ? !cpu_addr[14] : cpu_addr[14];
	wire [4:0]prg;
	assign prg[0] = !prg_mode[1] ? cpu_addr[14] : fixed_bank ? cpu_addr[14] : ine_prg[0];
	assign prg[1] = size_mask[0] & !fixed_bank  ? ine_prg[1] : out_prg[0];
	assign prg[2] = size_mask[1] & !fixed_bank  ? ine_prg[2] : out_prg[1];
	assign prg[3] = size_mask[2] & !fixed_bank  ? ine_prg[3] : out_prg[2];
	assign prg[4] = out_prg[3];
	
	 
	
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
		out_prg[5:0] <= 5'b11111;
		mirror_mode[1:0] <= 2'b01;
	end
		else
	begin
	
		if(!cpu_rw & cpu_ce & cpu_addr[14:12] == 3'b101)reg_addr[1:0] <= {cpu_dat[7], cpu_dat[0]};
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
				out_prg[5:0] <= cpu_dat[5:0];
			end
		endcase
		
	end
	
	
endmodule
