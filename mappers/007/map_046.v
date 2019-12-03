
`include "../base/defs.v"

module map_046
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
	ss_addr[7:0] == 0 ? prg : 
	ss_addr[7:0] == 1 ? chr : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = 0;//{cpu_addr[15:13], 13'd0} == 16'h6000;
	assign ram_we = 0;//!cpu_rw & ram_ce;
	assign rom_ce = cpu_addr[15];
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = cfg_mir_v ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[14:0] = cpu_addr[14:0];
	assign prg_addr[19:15] = prg[4:0];
	
	assign chr_addr[12:0] = ppu_addr[12:0];
	assign chr_addr[19:13] = chr[6:0];
	
	reg [4:0]prg;
	reg [6:0]chr;
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 0)prg <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 1)chr <= cpu_dat;
	end
		else
	if(!cpu_rw)
	begin
		
		if({cpu_addr[15:13], 13'd0} == 16'h6000){chr[6:3], prg[4:1]} <= cpu_dat[7:0];
		if(cpu_addr[15]){chr[2:0], prg[0]} <= {cpu_dat[6:4], cpu_dat[0]};
		
	end
	
endmodule
