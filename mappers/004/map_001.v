
`include "../base/defs.v"

module map_001 //MMC1
(map_out, bus, sys_cfg, ss_ctrl);
	
	`include "../base/bus_in.v"
	`include "../base/map_out.v"
	`include "../base/sys_cfg_in.v"
	`include "../base/ss_ctrl_in.v"
	
	output [`BW_MAP_OUT-1:0]map_out;
	input [`BW_SYS_CFG-1:0]sys_cfg;
	
	
	assign sync_m2 = 1;
	assign mir_4sc = 0;//enable support for 4-screen mirroring. for activation should be ensabled in sys_cfg also
	assign srm_addr[14:0] = {srm_bank[1:0], cpu_addr[12:0]};
	assign prg_oe = cpu_rw;
	assign chr_oe = !ppu_oe;
	//*************************************************************  save state setup
	parameter MAP_NUM = 8'd1;
	assign ss_rdat[7:0] = 
	ss_addr[7:2] == 0 ? map_regs[ss_addr[1:0]][4:0] : 
	ss_addr[7:0] == 4 ? {4'b0000,  buff[4:0]} :
	ss_addr[7:0] == 127 ? MAP_NUM : 8'hff;
	//*************************************************************
	assign ram_ce = {cpu_addr[15:13], 13'd0} == 16'h6000 & ram_on;
	assign ram_we = !cpu_rw & ram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;
	assign rom_ce = cpu_addr[15];
	assign chr_ce = ciram_ce;
	
	assign ciram_a10 = !r0[1] ? r0[0] : !r0[0] ? ppu_addr[10] : ppu_addr[11];//may be should be fixed
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[13:0] = cpu_addr[13:0];
	assign prg_addr[14] = map_sub == 5 ? cpu_addr[14]  :  prg_bank[0];
	assign prg_addr[18:15] = {chr_bank[4], prg_bank[3:1]};
	
	
	assign chr_addr[11:0] = ppu_addr[11:0];
	assign chr_addr[16:12] = 
	cfg_chr_ram  ? {4'b0000, chr_bank[0]}   : 
	chr_bank[4:0];

	wire [1:0]srm_bank = cfg_chr_ram ? chr_bank[3:2] : 2'b00;
	
	wire [3:0]prg_bank = prg_mode == 0 ? {r3[3:1], cpu_addr[14]} : r0[2] != cpu_addr[14] ? r3[3:0] : (!cpu_addr[14] ? 0 : 4'hf);

	wire [4:0]chr_bank = chr_mode == 0 ? {r1[4:1], ppu_addr[12]} : !ppu_addr[12] ? r1[4:0] : r2[4:0];
	
	
	wire chr_mode = r0[4];
	wire prg_mode = r0[3];
	wire ram_on   = r3[4] == 0 | map_idx == 155;
	
	wire [4:0]r0 = map_regs[0][4:0];
	wire [4:0]r1 = map_regs[1][4:0];
	wire [4:0]r2 = map_regs[2][4:0];
	wire [4:0]r3 = map_regs[3][4:0];
		
	wire reg_we = cpu_addr[15] & !cpu_rw & !reg_we_st;
	wire reg_rst = reg_we & cpu_dat[7];
	
	reg reg_we_st;
	reg [4:0]map_regs[4];
	reg [4:0]buff;
	
	always @(negedge m2)reg_we_st <= reg_we;

	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:2] == 0)map_regs[ss_addr[1:0]][4:0] <= cpu_dat[4:0];
		if(ss_we & ss_addr == 4)buff[4:0] <= cpu_dat[4:0];
	end
		else
	if(map_rst)
	begin
		map_regs[0][4:0] <= 5'b11111;
		map_regs[3][4] <= 0;
	end
		else
	if(reg_rst)
	begin
		buff[4:0] <= 5'b10000;
		map_regs[0][3:2] <= 2'b11;
	end
		else
	if(reg_we)
	begin
		if(buff[0] == 0)buff[4:0] <= {cpu_dat[0], buff[4:1]};
		if(buff[0] == 1)buff[4:0] <= 5'b10000;
		if(buff[0] == 1)map_regs[cpu_addr[14:13]][4:0] <= {cpu_dat[0], buff[4:1]};
	end
	
	
endmodule
