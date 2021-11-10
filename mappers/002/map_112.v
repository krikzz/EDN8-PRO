
`include "../base/defs.v"

module map_112
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
	ss_addr[7:0] == 0 ? prg0 : 
	ss_addr[7:0] == 1 ? prg1 : 
	ss_addr[7:0] == 2 ? chr0 : 
	ss_addr[7:0] == 3 ? chr1 : 
	ss_addr[7:0] == 4 ? chr2 : 
	ss_addr[7:0] == 5 ? chr3 : 
	ss_addr[7:0] == 6 ? chr4 : 
	ss_addr[7:0] == 7 ? chr5 : 
	ss_addr[7:0] == 8 ? {mirror_mode, reg_addr[2:0]} : 
	ss_addr[7:0] == 9 ? chr_hi : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = {cpu_addr[15:13], 13'd0} == 16'h6000;
	assign ram_we = !cpu_rw & ram_ce;
	assign rom_ce = !cpu_ce;
	assign chr_ce = ciram_ce;
	assign chr_we = 0;
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = !mirror_mode ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[12:0] = cpu_addr[12:0];
	assign prg_addr[18:13] = 
	cpu_addr[14:13] == 0 ? prg0[5:0] : 
	cpu_addr[14:13] == 1 ? prg1[5:0] : 
	{5'b11111, cpu_addr[13]};
	
	assign chr_addr[9:0] = ppu_addr[9:0];
	assign chr_addr[18:10] = 
	ppu_addr[12:11] == 0 ? {chr0[7:1], ppu_addr[10]} :
	ppu_addr[12:11] == 1 ? {chr1[7:1], ppu_addr[10]} :
	ppu_addr[11:10] == 0 ? {chr_hi[0], chr2[7:0]} :
	ppu_addr[11:10] == 1 ? {chr_hi[1], chr3[7:0]} :
	ppu_addr[11:10] == 2 ? {chr_hi[2], chr4[7:0]} :
	{chr_hi[3], chr5[7:0]};
	
	//assign chr_addr[18] = chr_hi;
	
	reg [3:0]chr_hi;
	reg [7:0]chr0;
	reg [7:0]chr1;
	reg [7:0]chr2;
	reg [7:0]chr3;
	reg [7:0]chr4;
	reg [7:0]chr5;
	
	reg [5:0]prg0;
	reg [5:0]prg1;
	
	reg [2:0]reg_addr;
	reg mirror_mode;
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 0)prg0 <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 1)prg1 <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 2)chr0 <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 3)chr1 <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 4)chr2 <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 5)chr3 <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 6)chr4 <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 7)chr5 <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 8){mirror_mode, reg_addr[2:0]} <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 9)chr_hi <= cpu_dat;
	end
		else
	if(!cpu_rw)
	begin
	
		if({cpu_addr[15:13], 12'd0, cpu_addr[0]} == 16'hE000)mirror_mode <= cpu_dat[0];
			
		if({cpu_addr[15:13], 12'd0, cpu_addr[0]} == 16'h8000)reg_addr <= cpu_dat[2:0];
		
		if({cpu_addr[15:13], 12'd0, cpu_addr[0]} == 16'hC000)chr_hi[3:0] <= cpu_dat[7:4];
	
		if({cpu_addr[15:13], 12'd0, cpu_addr[0]} == 16'hA000)
		case(reg_addr[2:0])
			0:begin
				prg0[5:0] <= cpu_dat[5:0];
			end
			1:begin
				prg1[5:0] <= cpu_dat[5:0];
			end
			2:begin
				chr0[7:0] <= cpu_dat[7:0];
			end
			3:begin
				chr1[7:0] <= cpu_dat[7:0];
			end
			4:begin
				chr2[7:0] <= cpu_dat[7:0];
			end
			5:begin
				chr3[7:0] <= cpu_dat[7:0];
			end
			6:begin
				chr4[7:0] <= cpu_dat[7:0];
			end
			7:begin
				chr5[7:0] <= cpu_dat[7:0];
			end
		endcase
		
	end
	
	
endmodule
