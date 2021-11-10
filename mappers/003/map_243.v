
`include "../base/defs.v"

module map_243
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
	ss_addr[7:0]  < 8 ? regs[ss_addr[2:0]] : 
	ss_addr[7:0] == 8 ? reg_addr : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = {cpu_addr[15:13], 13'd0} == 16'h6000;
	assign ram_we = !cpu_rw & ram_ce;
	assign rom_ce = cpu_addr[15];
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = 
	mirror_mode[1:0] == 2'b00 ? ppu_addr[11] :
	mirror_mode[1:0] == 2'b01 ? ppu_addr[10] :
	mirror_mode[1:0] == 2'b11 ? 1 :
	ppu_addr[11:10] == 0 ? 0 : 1;
	
	assign ciram_ce = !ppu_addr[13];
	
	assign chr_addr[12:0] = ppu_addr[12:0];
	assign chr_addr[16:13] = chr[3:0];
	
	assign prg_addr[14:0] = cpu_addr[14:0];
	assign prg_addr[16:15] = prg[1:0];
	
	assign map_cpu_oe = regs_ce & cpu_rw & cpu_addr[0];
	assign map_cpu_dout[7:0] = regs[reg_addr[2:0]];

	
	wire regs_ce = (cpu_addr[15:0] & 16'hC100) == 16'h4100;
		
	wire [3:0]chr = {regs[2][0], regs[4][0], regs[6][1:0]};
	wire [2:0]prg = map_idx == 150 ? (regs[2][0] | regs[5][1:0]) : regs[5][1:0];//sub mapper required?
	wire [1:0]mirror_mode = regs[7][2:1];
	
	reg [2:0]reg_addr;
	reg [2:0]regs[8];
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0]  < 8)regs[ss_addr[2:0]] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 8)reg_addr <= cpu_dat;
	end
		else
	if(map_rst)
	begin
		regs[4] <= 0;
		regs[5] <= 0;
		regs[6] <= 0;
		regs[7] <= 0;
	end
		else
	if(regs_ce & !cpu_rw)
	begin
		
		if(cpu_addr[0] == 0)reg_addr[2:0] <= cpu_dat[2:0];
		if(cpu_addr[0] == 1)regs[reg_addr[2:0]][2:0] <= cpu_dat[2:0];
	
	end
	
	
endmodule
