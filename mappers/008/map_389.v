
`include "../base/defs.v"

module map_389
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
	ss_addr[7:0] == 0 ? chr : 
	ss_addr[7:0] == 1 ? prg : 
	ss_addr[7:0] == 2 ? prg_u064 : 
	ss_addr[7:0] == 3 ? {mir_mode, mode_unrom064} : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = {cpu_addr[15:13], 13'd0} == 16'h6000;
	assign ram_we = !cpu_rw & ram_ce;
	assign rom_ce = cpu_addr[15];
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = mir_mode ? ppu_addr[11] : ppu_addr[10];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[13:0] = cpu_addr[13:0];
	
	assign prg_addr[18:14] = 
	!mode_unrom064 ? {prg[3:0], cpu_addr[14]} : 
	!cpu_addr[14] ? {prg[3:1], prg_u064[1:0]} : {prg[3:1], 2'b11};
	
	assign chr_addr[12:0] = ppu_addr[12:0];
	assign chr_addr[17:13] = chr[4:0];
	
	reg [4:0]chr;
	reg [3:0]prg;
	reg [1:0]prg_u064;
	reg mode_unrom064;
	reg mir_mode;
	
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 0)chr <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 1)prg <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 2)prg_u064 <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 3){mir_mode, mode_unrom064} <= cpu_dat;
	end
		else
	if(map_rst)
	begin
		chr <= 0;
		prg <= 0;
		prg_u064 <= 0;
		mode_unrom064 <= 0;
		mir_mode <= 0;
	end
		else
	if(!cpu_rw)
	begin
		
		if({cpu_addr[15:12],12'd0} == 16'h8000){prg[3:0], mir_mode} <= {cpu_addr[6:3], cpu_addr[0]};
		if({cpu_addr[15:12],12'd0} == 16'h9000){chr[4:2], mode_unrom064} <= {cpu_addr[5:3], cpu_addr[1]};
		if({cpu_addr[15:13],13'd0} >= 16'hA000){prg_u064[1:0], chr[1:0]} <= cpu_addr[3:0];
		
	end
	
endmodule
