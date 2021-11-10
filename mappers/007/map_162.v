
`include "../base/defs.v"

module map_162
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
	ss_addr[7:0] == 0 ? prg_regs[0] :
	ss_addr[7:0] == 1 ? prg_regs[1] :
	ss_addr[7:0] == 2 ? prg_regs[2] :
	ss_addr[7:0] == 3 ? prg_regs[3] :
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = {cpu_addr[15:13], 13'd0} == 16'h6000;
	assign ram_we = !cpu_rw & ram_ce;
	assign rom_ce = cpu_addr[15];
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = cfg_mir_v ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[14:0] = cpu_addr[14:0];
	
	assign prg_addr[18:15] = 
	(prg_regs[3] & 5) == 0 ? {prg_regs[0][3:2], prg_regs[1][1], 1'b0} : 
	(prg_regs[3] & 5) == 1 ? {prg_regs[0][3:2], 2'b00} : 
	(prg_regs[3] & 5) == 4 ? {prg_regs[0][3:1], prg_regs[1][1]} : 
	prg_regs[0][3:0];
	
	assign prg_addr[20:19] = prg_regs[2][3:0];
	
	assign chr_addr[12:0] = ppu_addr[12:0];

	
	reg [7:0]prg_regs[4];
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 0)prg_regs[0] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 1)prg_regs[1] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 2)prg_regs[2] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 3)prg_regs[3] <= cpu_dat;
	end
		else
	if(map_rst)
	begin
		prg_regs[0] <= 3;
		prg_regs[1] <= 0;
		prg_regs[2] <= 0;
		prg_regs[3] <= 7;
	end
		else
	if(!cpu_rw & {cpu_addr[15:12],12'd0} == 16'h5000)
	begin
		
		prg_regs[cpu_addr[9:8]] <= cpu_dat[7:0];
		
	end
	
endmodule
