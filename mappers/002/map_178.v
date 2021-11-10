
`include "../base/defs.v"

module map_178
(map_out, bus, sys_cfg, ss_ctrl);

	`include "../base/bus_in.v"
	`include "../base/map_out.v"
	`include "../base/sys_cfg_in.v"
	`include "../base/ss_ctrl_in.v"
	
	output [`BW_MAP_OUT-1:0]map_out;
	input [`BW_SYS_CFG-1:0]sys_cfg;
	
	
	assign sync_m2 = 1;
	assign mir_4sc = 0;//enable support for 4-screen mirroring. for activation should be ensabled in sys_cfg also
	assign srm_addr[14:0] = {wrm[1:0], cpu_addr[12:0]};
	assign prg_oe = cpu_rw;
	assign chr_oe = !ppu_oe;
	//*************************************************************  save state setup
	assign ss_rdat[7:0] = 
	ss_addr[7:0] == 0 ? wrm : 
	ss_addr[7:0] == 1 ? prg : 
	ss_addr[7:0] == 2 ? {prg_mode[1:0], mirror_mode}  : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = {cpu_addr[15:13], 13'd0} == 16'h6000;
	assign ram_we = !cpu_rw & ram_ce;
	assign rom_ce = !cpu_ce;
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = !mirror_mode ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[13:0] = cpu_addr[13:0];
	assign prg_addr[20:14] =
	prg_mode == 0 ? {prg[6:1], cpu_addr[14]} : 
	prg_mode == 1 & cpu_addr[15] == 0 ? prg[6:0] : 
	prg_mode == 1 & cpu_addr[15] == 1 ? {prg[6:3], 3'd7} : 
	prg_mode == 3 & cpu_addr[15] == 0 ? prg[6:0] : (prg[6:0] | 6);
	
	
	assign chr_addr[12:0] = ppu_addr[12:0];
	
	reg [7:0]prg;
	reg [1:0]prg_mode;
	reg [1:0]wrm;
	reg mirror_mode;
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 0)wrm <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 1)prg <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 2){prg_mode[1:0], mirror_mode} <= cpu_dat;
	end
		else
	if(!cpu_rw)
	begin
		
		if(cpu_addr[15:0] == 16'h4800){prg_mode[1:0], mirror_mode} <= cpu_dat[2:0];
		if(cpu_addr[15:0] == 16'h4801)prg[2:0] <= cpu_dat[2:0];
		if(cpu_addr[15:0] == 16'h4802)prg[7:3] <= cpu_dat[4:0];
		if(cpu_addr[15:0] == 16'h4803)wrm[1:0] <= cpu_dat[1:0];
		
		/*
		if(cpu_ce & !cpu_rw & cpu_addr[14:8] == 7'h48)
		begin
			if(cpu_addr[1:0] == 0)mirror_mode <= cpu_dat[0];
				else
			if(cpu_addr[1:0] == 1)prg[5:0] <= cpu_dat[4:1] + ppp;
				else
			if(cpu_addr[1:0] == 2)ppp[7:2] <= cpu_dat[5:0];
		end*/
		
	end
	
endmodule
