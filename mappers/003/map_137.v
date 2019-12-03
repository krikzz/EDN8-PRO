
`include "../base/defs.v"

module map_137
(map_out, bus, sys_cfg, ss_ctrl);

	`include "../base/bus_in.v"
	`include "../base/map_out.v"
	`include "../base/sys_cfg_in.v"
	`include "../base/ss_ctrl_in.v"
	
	output [`BW_MAP_OUT-1:0]map_out;
	input [`BW_SYS_CFG-1:0]sys_cfg;
	
	
	assign sync_m2 = 1;
	assign mir_4sc = 1;//enable support for 4-screen mirroring. for activation should be ensabled in sys_cfg also
	assign srm_addr[12:0] = cpu_addr[12:0];
	assign prg_oe = cpu_rw;
	assign chr_oe = !ppu_oe;
	//*************************************************************  save state setup
	assign ss_rdat[7:0] = 
	ss_addr[7:3] == 0 ? regs[ss_addr[2:0]] : 
	ss_addr[7:0] == 8 ? reg_addr : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************

	assign ram_we = !cpu_rw & ram_ce;
	assign ram_ce = 0;//cpu_addr[14:13] == 2'b11 & cpu_ce & m2;
	assign rom_ce = !cpu_ce;
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = 
	regs[7][0] ? 	ppu_addr[10] : 
	regs[7][2:1] == 0 ? ppu_addr[10] : 
	regs[7][2:1] == 1 ? ppu_addr[11] : 
	regs[7][2:1] == 2 ? (ppu_addr[11:10] == 0 ? 0 : 1) : 0;
	//cfg_mir_v ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[14:0] = cpu_addr[14:0];
	assign prg_addr[17:15] = regs[5];
	
	assign chr_addr[9:0] = ppu_addr[9:0];
	assign chr_addr[18:10] = 
	cfg_chr_ram ? ppu_addr[12:10] :
	map_idx == 137 ? ppu_137 : 
	map_idx == 138 ? ppu_138 :
	map_idx == 139 ? ppu_139 :
	ppu_141;
	
	
	
	wire [8:0]ppu_137 = 
	ppu_addr[12] ? {3'b111, ppu_addr[11:10]} : 
	ppu_addr[12:10] == 0 ? {2'b00, regs[ppu_addr[11:10]][2:0]} : 
	ppu_addr[12:10] == 1 ? {regs[4][0], 1'b0, regs[ppu_addr[11:10]][2:0]}  : 
	ppu_addr[12:10] == 2 ? {regs[4][1], 1'b0, regs[ppu_addr[11:10]][2:0]}  : {regs[4][2], regs[6][0], regs[ppu_addr[11:10]][2:0]};
	
	
	wire [8:0]ppu_138;
	assign ppu_138[0] = ppu_addr[10];
	assign ppu_138[3:1] = regs[7][0] ? regs[0][2:0] : regs[ppu_addr[12:11]][2:0];
	assign ppu_138[6:4] = regs[4][2:0];
	
	wire [8:0]ppu_139;
	assign ppu_139[2:0] = ppu_addr[12:10];
	assign ppu_139[5:3] = regs[7][0] ? regs[0][2:0] : regs[ppu_addr[12:11]][2:0];
	assign ppu_139[8:6] = regs[4][2:0];
	
	wire [8:0]ppu_141;
	assign ppu_141[1:0] = ppu_addr[11:10];
	assign ppu_141[4:2] = regs[7][0] ? regs[0][2:0] : regs[ppu_addr[12:11]][2:0];
	assign ppu_141[7:5] = regs[4][2:0];
	
	//regs[7][0] ? {regs[4][2:0], regs[0][2:0], ppu_addr[10]} : 
	//{regs[4][2:0], regs[ppu_addr[12:11]][2:0], ppu_addr[10]};
	

	
	reg [2:0]reg_addr;
	reg [2:0]regs[8];
	wire reg_ce = cpu_ce & cpu_addr[14:8] == 7'h41;
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:3] == 0)regs[ss_addr[2:0]] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 8)reg_addr <= cpu_dat;
	end
		else
	begin
		
		if(map_rst)regs[5] <= 0;
		if(!cpu_rw & reg_ce & cpu_addr[0] == 0)reg_addr[2:0] <= cpu_dat[2:0];
		if(!cpu_rw & reg_ce & cpu_addr[0] == 1)regs[reg_addr][2:0] <= cpu_dat[2:0];
		
	end
	
endmodule
