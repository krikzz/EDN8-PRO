
`include "../base/defs.v"

module map_015
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
	ss_addr[7:0] == 0 ? {prg_sub, mirro_mode, prg[5:0]} : 
	ss_addr[7:0] == 1 ? bank_mode[1:0] : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = {cpu_addr[15:13], 13'd0} == 16'h6000;
	assign ram_we = !cpu_rw & ram_ce;
	assign rom_ce = cpu_addr[15];
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = mirro_mode ? ppu_addr[11] : ppu_addr[10];
	assign ciram_ce = !ppu_addr[13];
	
	assign chr_addr[12:0] = ppu_addr[12:0];
	
	assign prg_addr[12:0] = cpu_addr[12:0];

	assign prg_addr[19:13] = 
	bank_mode == 0 ? ({prg[5:0], 1'b0} + cpu_addr[14:13])  ^ prg_sub :
	bank_mode == 2 ? {prg[5:0], prg_sub} : 
	bank_mode == 3 ? {prg[5:0], prg_sub} + cpu_addr[13] : 
	cpu_addr[14] == 0 ? {prg[5:0], prg_sub} + cpu_addr[13] : {6'b111111, prg_sub} + cpu_addr[13];
	
	
	reg [1:0]bank_mode;
	reg [5:0]prg;
	reg mirro_mode;
	reg prg_sub;
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 0){prg_sub, mirro_mode, prg[5:0]} <= cpu_dat[6:0];
		if(ss_we & ss_addr[7:0] == 1)bank_mode[1:0] <= cpu_dat[1:0];
	end
		else
	if(map_rst)
	begin
		prg <= 0;
		bank_mode <= 0;
		prg_sub <= 0;
		mirro_mode <= 0;
	end
		else
	if(!cpu_rw & cpu_addr[15])
	begin
		
		{prg_sub, mirro_mode, prg[5:0]} <= cpu_dat[7:0];
		bank_mode[1:0] <= cpu_addr[1:0];
		
	end
	
	
endmodule
