
`include "../base/defs.v"

module map_079 // NINA-03/6
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
	ss_addr[7:0] == 0 ? prg_reg : 
	ss_addr[7:0] == 1 ? chr_reg : 
	ss_addr[7:0] == 2 ? mirror_mode : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	
	assign ram_we = 0;
	assign chr_we = 0;
	assign ram_ce = 0;
	assign rom_ce = !cpu_ce;
	assign chr_ce = ciram_ce;
	
	wire mirror_113 = mirror_mode ? ppu_addr[10] : ppu_addr[11];
	assign ciram_a10 = map_idx == 113 ? mirror_113 : cfg_mir_v ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	
	assign prg_addr[14:0] = cpu_addr[14:0];
	assign prg_addr[17:15] = prg_reg[2:0];
	
	assign chr_addr[12:0] = ppu_addr[12:0];
	assign chr_addr[16:13] = chr_reg[3:0];
	
	reg [2:0]prg_reg;
	reg [3:0]chr_reg;
	reg mirror_mode;
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 0)prg_reg <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 1)chr_reg <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 2)mirror_mode <= cpu_dat;
	end
		else
	begin
	
		if(map_rst)
		begin
			chr_reg <= 0;
			prg_reg <= 0;
		end
			else
		if(cpu_ce & !cpu_rw & cpu_addr[14:13] == 2'b10 & cpu_addr[8] == 1)
		begin
			prg_reg[2:0] <= cpu_dat[5:3];
			chr_reg[2:0] <= cpu_dat[2:0];
			chr_reg[3] <= cpu_dat[6];
			mirror_mode <= cpu_dat[7];
		end
	
	end
	
endmodule
