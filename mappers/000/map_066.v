
module map_066 //GxROM
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
	ss_addr[7:0] == 0 ? {2'd0, prg[1:0], chr[3:0]} : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = 0;
	assign ram_we = 0;
	assign chr_we = 0;
	assign rom_ce = cpu_addr[15];
	assign chr_ce = ciram_ce;
	
	assign ciram_a10 = cfg_mir_v ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[14:0] = cpu_addr[14:0];
	assign prg_addr[16:15] = prg[1:0];
	
	assign chr_addr[12:0] = ppu_addr[12:0];
	assign chr_addr[16:13] = chr[3:0];
	
	reg [1:0]prg;
	reg [3:0]chr;
	
	wire reg_ce = 
	map_idx == 36 ? cpu_addr[15:14] == 2'b10 : 
	map_idx == 38 ? cpu_addr[15:12] == 4'b0111 : 
	cpu_addr[15] | cpu_addr[14:12] == 3'b110;
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 0){prg[1:0], chr[3:0]} <= cpu_dat[5:0];
	end
		else
	if(reg_ce & !cpu_rw){prg[1:0], chr[3:0]} <= cpu_dat[5:0];

	
endmodule
