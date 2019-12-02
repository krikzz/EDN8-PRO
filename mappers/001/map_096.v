
`include "../base/defs.v"

module map_096
(map_out, bus, sys_cfg, ss_ctrl);

	`include "../base/bus_in.v"
	`include "../base/map_out.v"
	`include "../base/sys_cfg_in.v"
	`include "../base/ss_ctrl_in.v"
	
	output [`BW_MAP_OUT-1:0]map_out;
	input [`BW_SYS_CFG-1:0]sys_cfg;
	
	
	assign chr_mask_off = 1;
	assign sync_m2 = 1;
	assign mir_4sc = 0;//enable support for 4-screen mirroring. for activation should be ensabled in sys_cfg also
	assign srm_addr[12:0] = cpu_addr[12:0];
	assign prg_oe = cpu_rw;
	assign chr_oe = !ppu_oe;
	//*************************************************************  save state setup
	assign ss_rdat[7:0] = 
	ss_addr[7:0] == 0 ? {chr_page, prg[1:0]} : 
	ss_addr[7:0] == 1 ? chr_bank : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = 0;
	assign ram_we = 0;
	assign rom_ce = cpu_addr[15];
	assign chr_ce = ciram_ce;
	assign chr_we = !ppu_we & ciram_ce;
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = cfg_mir_v ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[12:0] = cpu_addr[12:0];
	assign prg_addr[14:13] = cpu_ce ? 0 : cpu_addr[14:13];
	assign prg_addr[16:15] = cpu_ce ? 0 : prg[1:0];
	
	assign chr_addr[11:0] = ppu_addr[11:0];
	assign chr_addr[13:12] = ppu_addr[12] ? 2'b11 : chr_bank[1:0];//ppu_addr[9:8];
	assign chr_addr[14] = chr_page;
	

	//wire ppu_clk = ppu_oe & ppu_we;
	reg [4:0]pa13_st;
	
	always @(negedge clk)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 1 & m2)chr_bank <= cpu_dat;
	end
		else
	begin
		pa13_st[4:0] <= {pa13_st[3:0], ppu_addr[13]};
		if(pa13_st[4:3] == 2'b01 & ppu_addr[12] == 0 & ppu_we & ppu_oe)chr_bank[1:0] <= ppu_addr[9:8];
	end
	
	
	
	reg [1:0]prg;
	reg [1:0]chr_bank;
	reg chr_page;
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 0){chr_page, prg[1:0]} <= cpu_dat;
	end
		else
	if(!cpu_ce & !cpu_rw)
	begin
		prg[1:0] <= cpu_dat[1:0];
		chr_page <= cpu_dat[2];
	end
	
endmodule
