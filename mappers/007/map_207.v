
`include "../base/defs.v"

module map_207
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
	ss_addr[7:0]  < 10  ? regs[ss_addr] : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = (cpu_addr[15:0] & 16'hFF00) == 16'h7F00 & ram_on;
	assign ram_we = !cpu_rw & ram_ce;
	assign rom_ce = cpu_addr[15];
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = regs[ppu_addr[11]][7];
	
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[12:0] = cpu_addr[12:0];
	assign prg_addr[20:13] = 
	cpu_addr[14:13] == 0 ? regs[7] : 
	cpu_addr[14:13] == 1 ? regs[8] :
	cpu_addr[14:13] == 2 ? regs[9] : 8'hff;

	
	assign chr_addr[9:0] = ppu_addr[9:0];
	assign chr_addr[17:10] = 
	ppu_addr[12:11] == 0 ? {regs[0][6:1], ppu_addr[10]} : 
	ppu_addr[12:11] == 1 ? {regs[1][6:1], ppu_addr[10]} : 
	ppu_addr[12:10] == 4 ?  regs[2][7:0] : 
	ppu_addr[12:10] == 5 ?  regs[3][7:0] : 
	ppu_addr[12:10] == 6 ?  regs[4][7:0] : regs[5][7:0];
	
	wire ram_on = regs[6] == 8'hA3;
	
	reg [7:0]regs[10];
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] < 10)regs[ss_addr] <= cpu_dat;
	end
		else
	if(map_rst)
	begin
		regs[0] <= 0;
		regs[1] <= 0;
	end
		else
	if(!cpu_rw)
	begin
		
		if(cpu_addr == 16'h7EF0)regs[0] <= cpu_dat;
		if(cpu_addr == 16'h7EF1)regs[1] <= cpu_dat;
		if(cpu_addr == 16'h7EF2)regs[2] <= cpu_dat;
		if(cpu_addr == 16'h7EF3)regs[3] <= cpu_dat;
		if(cpu_addr == 16'h7EF4)regs[4] <= cpu_dat;
		if(cpu_addr == 16'h7EF5)regs[5] <= cpu_dat;
		if((cpu_addr & 16'hfffe) == 16'h7EF8)regs[6] <= cpu_dat;
		if((cpu_addr & 16'hfffe) == 16'h7EFA)regs[7] <= cpu_dat;
		if((cpu_addr & 16'hfffe) == 16'h7EFC)regs[8] <= cpu_dat;
		if((cpu_addr & 16'hfffe) == 16'h7EFE)regs[9] <= cpu_dat;
		
	end

	
endmodule
