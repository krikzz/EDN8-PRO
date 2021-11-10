
`include "../base/defs.v"

module map_210
(map_out, bus, sys_cfg, ss_ctrl);

	`include "../base/bus_in.v"
	`include "../base/map_out.v"
	`include "../base/sys_cfg_in.v"
	`include "../base/ss_ctrl_in.v"
	
	output [`BW_MAP_OUT-1:0]map_out;
	input [`BW_SYS_CFG-1:0]sys_cfg;
	
	
	assign sync_m2 = 1;
	assign mir_4sc = 0;//enable support for 4-screen mirroring. for activation should be ensabled in sys_cfg also
	assign srm_addr[10:0] = cpu_addr[10:0];
	assign prg_oe = cpu_rw;
	assign chr_oe = !ppu_oe;
	//*************************************************************  save state setup
	assign ss_rdat[7:0] = 
	ss_addr[7:3] == 0	  ? chr_bank[ss_addr[2:0]] :
	ss_addr[7:0] == 8	  ? prg_bank[0] :
	ss_addr[7:0] == 9   ? prg_bank[1] :
	ss_addr[7:0] == 10  ? prg_bank[2] :
	ss_addr[7:0] == 11  ? prg_ram_on :
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = {cpu_addr[15:13], 13'd0} == 16'h6000 & map_sub == 1;
	assign ram_we = !cpu_rw & ram_ce & prg_ram_on;
	assign rom_ce = cpu_addr[15];
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;
	
	
	assign ciram_ce = !ppu_addr[13];
	assign ciram_a10 =
	map_sub == 1 ? (cfg_mir_v ? ppu_addr[10] : ppu_addr[11]) : 
	prg_bank[0][7:6] == 0 ? 0 : 
	prg_bank[0][7:6] == 1 ? ppu_addr[10] : 
	prg_bank[0][7:6] == 2 ? ppu_addr[11] : 1;
	
	
		
	assign chr_addr[9:0] = ppu_addr[9:0];
	assign chr_addr[17:10] = chr_bank[ppu_addr[12:10]][7:0];
	
	assign prg_addr[12:0] = cpu_addr[12:0];
	assign prg_addr[18:13] = 
	cpu_addr[14:13] == 0 ? prg_bank[0][5:0] : 
	cpu_addr[14:13] == 1 ? prg_bank[1][5:0] : 
	cpu_addr[14:13] == 2 ? prg_bank[2][5:0] : 6'h3f;
	
	reg [7:0]prg_bank[3];
	reg [7:0]chr_bank[8];
	reg prg_ram_on;
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:3] == 0)chr_bank[ss_addr[2:0]] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 8)prg_bank[0] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 9)prg_bank[1] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 10)prg_bank[2] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 11)prg_ram_on <= cpu_dat;
	end
		else
	if(map_rst)
	begin
		prg_ram_on <= 0;
	end
		else
	if(!cpu_rw)
	begin
		
		if((cpu_addr[15:0] & 16'hC000) == 16'h8000)
		begin
			chr_bank[cpu_addr[13:11]][7:0] <= cpu_dat[7:0];
		end
		
		case(cpu_addr[15:0] & 16'hF800)
			16'hC000:prg_ram_on <= cpu_dat[0];
			16'hE000:prg_bank[0][7:0] <= cpu_dat[7:0];
			16'hE800:prg_bank[1][7:0] <= cpu_dat[7:0];
			16'hF000:prg_bank[2][7:0] <= cpu_dat[7:0];
		endcase
		
	
	end
	
endmodule
