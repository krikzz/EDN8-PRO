

`include "../base/defs.v"

module map_068 //Sunsoft-4
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
	ss_addr[7:0] == 4 ? nt[0] : 
	ss_addr[7:0] == 5 ? nt[1] : 
	ss_addr[7:0] == 6 ? prg : 
	ss_addr[7:0] == 7 ? mirror_mode : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = cpu_addr[14:13] == 2'b11 & cpu_ce & m2;
	assign ram_we = !cpu_rw & ram_ce;
	assign rom_ce = !cpu_ce;
	assign chr_ce = ciram_ce;
	assign chr_we = 0;//cfg_chr_ram ? !ppu_we & ciram_ce : 0;
	
	assign ciram_a10 = !mirror_mode[0] ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = nt_area ? 1 : !ppu_addr[13];
	
	assign prg_addr[13:0] = cpu_addr[13:0];
	assign prg_addr[17:14] =  !cpu_addr[14] ? prg[3:0] : 4'b1111;
	
	assign chr_addr[9:0] = ppu_addr[9:0];
	assign chr_addr[10] =  nt_area ? nt[ciram_a10][0] : ppu_addr[10];
	assign chr_addr[17:11] = nt_area ? {1'b1, nt[ciram_a10][6:1]} : chr[ppu_addr[12:11]];
	
	wire nt_area = ppu_addr[13] & !ppu_addr[12] & mirror_mode[1];
	
	
	reg [6:0]chr[4];
	reg [6:0]nt[2];
	reg [3:0]prg;
	reg [1:0]mirror_mode;
	
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:2] == 0)chr[ss_addr[1:0]] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 4)nt[0] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 5)nt[1] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 6)prg <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 7)mirror_mode <= cpu_dat;
	end
		else
	if(!cpu_ce & !cpu_rw)
	begin
		
		if(cpu_addr[14] == 0)chr[cpu_addr[13:12]] <= cpu_dat[6:0];
		if(cpu_addr[14:12] == 4)nt[0] <= cpu_dat[6:0];
		if(cpu_addr[14:12] == 5)nt[1] <= cpu_dat[6:0];
		if(cpu_addr[14:12] == 6)mirror_mode[1:0] <= {cpu_dat[4], cpu_dat[0]};
		if(cpu_addr[14:12] == 7)prg[3:0] <= cpu_dat[3:0];
	
	end
	
	
endmodule



