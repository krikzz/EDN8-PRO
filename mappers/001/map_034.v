
`include "../base/defs.v"

module map_034 //BxROM/NINA-001
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
	ss_addr[7:0] == 1 ? chr0 : 
	ss_addr[7:0] == 2 ? chr1 : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = {cpu_addr[15:13], 13'd0} == 16'h6000;
	assign ram_we = !cpu_rw & ram_ce;	
	assign rom_ce = !cpu_ce;
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;
	
	assign ciram_a10 = cfg_mir_v ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[14:0] = cpu_addr[14:0];
	assign prg_addr[18:15] = cpu_ce ? 0 : prg[3:0];
	
	assign chr_addr[11:0] = ppu_addr[11:0];
	assign chr_addr[12] = cfg_chr_ram ? ppu_addr[12] : chr_reg[0];
	assign chr_addr[16:13] = chr_reg[4:1];
	
	reg [3:0]prg;
	reg [4:0]chr0;
	reg [4:0]chr1;
	
	wire [4:0]chr_reg = !ppu_addr[12] ? chr0[4:0] : chr1[4:0];
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 0)prg <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 1)chr0 <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 2)chr1 <= cpu_dat;
	end
		else
	if(map_rst)
	begin
		prg <= 0;
	end
		else
	if(cfg_chr_ram == 1 & cpu_addr[15] == 1 & !cpu_rw)prg[3:0] <= cpu_dat[3:0];
		else
	if(cfg_chr_ram == 0 & cpu_addr[15] == 0 & !cpu_rw)
	begin
		if(cpu_addr[14:0] == 15'h7FFD)prg[3:0] <= cpu_dat[3:0];
			else
		if(cpu_addr[14:0] == 15'h7FFE)chr0[4:0] <= cpu_dat[4:0];
			else
		if(cpu_addr[14:0] == 15'h7FFF)chr1[4:0] <= cpu_dat[4:0];
	end
		
		
endmodule
