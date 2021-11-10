
`include "../base/defs.v"

module map_072
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
	ss_addr[7:0] == 0 ? {chr[3:0], prg[3:0]} :
	ss_addr[7:0] == 1 ? {p_latch, c_latch} :
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = 0;
	assign ram_we = 0;
	assign rom_ce = cpu_addr[15];
	assign chr_ce = ciram_ce;
	assign chr_we = 0;
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = cfg_mir_v ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[13:0] = cpu_addr[13:0];
	assign prg_addr[17:14] = map_idx == 8'd92 ? prg_92 : prg_72;
	
	wire [3:0]prg_92 = cpu_addr[14] == 1 ? prg[3:0] : 4'b0000;
	wire [3:0]prg_72 = cpu_addr[14] == 0 ? prg[3:0] : 4'b1111;

	
	assign chr_addr[12:0] = ppu_addr[12:0];
	assign chr_addr[16:13] = chr[3:0];
	
	reg [3:0]prg;
	reg [3:0]chr;
	
	reg p_latch;
	reg c_latch;
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 0){chr[3:0], prg[3:0]} <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 1){p_latch, c_latch} <= cpu_dat[1:0];
	end
		else
	if(!cpu_ce & !cpu_rw)
	begin
		p_latch <= cpu_dat[7];
		c_latch <= cpu_dat[6];
		if(p_latch == 0 & cpu_dat[7] == 1)prg[3:0] <= cpu_dat[3:0];
		if(c_latch == 0 & cpu_dat[6] == 1)chr[3:0] <= cpu_dat[3:0];
	end
	
endmodule
