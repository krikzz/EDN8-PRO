
`include "../base/defs.v"

module map_075 //VRC1
	(map_out, bus, sys_cfg, ss_ctrl);
	
	`include "../base/bus_in.v"
	`include "../base/map_out.v"
	`include "../base/sys_cfg_in.v"
	`include "../base/ss_ctrl_in.v"
	
	output [`BW_MAP_OUT-1:0]map_out;
	input [`BW_SYS_CFG-1:0]sys_cfg;
	
	
	
	assign sync_m2 = 1;
	assign mir_4sc = 1;//enable support for 4-screen mirroring. for activation should be ensabled in sys_cfg also
	assign srm_addr[12:0] = cpu_addr[12:0];
	assign prg_oe = cpu_rw;
	assign chr_oe = !ppu_oe;
	//*************************************************************  save state setup
	assign ss_rdat[7:0] = 
	ss_addr[7:0] == 0 ? prg0 : 
	ss_addr[7:0] == 1 ? prg1 : 
	ss_addr[7:0] == 2 ? prg2 : 
	ss_addr[7:0] == 3 ? chr0 : 
	ss_addr[7:0] == 4 ? chr1 : 
	ss_addr[7:0] == 5 ? mir_mode : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = 0;
	assign ram_we = 0;
	assign rom_ce = cpu_addr[15];
	assign chr_ce = ciram_ce;
	assign chr_we = 0;
	
	//A10-Vmir, A11-Hmir
	wire hmirror =  cfg_mir_v ? ppu_addr[10] : ppu_addr[11];
	assign ciram_a10 = map_idx == 151 ? hmirror : !mir_mode ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[12:0] = cpu_addr[12:0];
	assign prg_addr[16:13] = 
	cpu_addr[14:13] == 0 ? prg0[3:0] : 
	cpu_addr[14:13] == 1 ? prg1[3:0] : 
	cpu_addr[14:13] == 2 ? prg2[3:0] : 
	4'b1111; 
	
	assign chr_addr[11:0] = ppu_addr[11:0];
	assign chr_addr[16:12] = !ppu_addr[12] ? chr0[4:0] : chr1[4:0];
	
	wire [15:0]reg_addr = {cpu_addr[15:12], 12'd0};
	
	reg [3:0]prg0, prg1, prg2;
	reg [4:0]chr0, chr1;
	reg mir_mode;
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 0)prg0 <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 1)prg1 <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 2)prg2 <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 3)chr0 <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 4)chr1 <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 5)mir_mode <= cpu_dat[0];
	end
		else
	begin
	
		if(reg_addr[15:0] == 16'h8000 & !cpu_rw)prg0[3:0] <= cpu_dat[3:0];
		if(reg_addr[15:0] == 16'h9000 & !cpu_rw){chr1[4], chr0[4], mir_mode} <= cpu_dat[2:0];
		if(reg_addr[15:0] == 16'hA000 & !cpu_rw)prg1[3:0] <= cpu_dat[3:0];
		if(reg_addr[15:0] == 16'hC000 & !cpu_rw)prg2[3:0] <= cpu_dat[3:0];
		if(reg_addr[15:0] == 16'hE000 & !cpu_rw)chr0[3:0] <= cpu_dat[3:0];
		if(reg_addr[15:0] == 16'hF000 & !cpu_rw)chr1[3:0] <= cpu_dat[3:0];
	
	end
	
	
	
endmodule
