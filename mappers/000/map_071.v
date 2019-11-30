

`include "../base/defs.v"

module map_071 //NOMAP
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
	ss_addr[7:0] == 0 ? {mirror_mode, mir_control_on, prg_bank[3:0]} : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = 0;
	assign ram_we = 0;
	assign rom_ce = cpu_addr[15];
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;
	
	assign ciram_a10 = mir_control_on ? mirror_mode  : cfg_mir_v ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[13:0] = cpu_addr[13:0];
	assign prg_addr[17:14] = !cpu_addr[14] ? prg_bank[3:0] : 4'b1111;
	//assign prg_addr[19:18] = prg_bank[5:4];
	
	
	assign chr_addr[12:0] = ppu_addr[12:0];
	
	
	reg [3:0]prg_bank;
	reg mir_control_on;
	reg mirror_mode;

	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 0){mirror_mode, mir_control_on, prg_bank[3:0]} <= cpu_dat;
	end
		else
	if(map_rst)
	begin
		mir_control_on <= 0;
	end
		else
	begin
	
		if(!cpu_rw & cpu_addr[15:14] == 2'b11)prg_bank[3:0] <= cpu_dat[3:0];
		
		if(!cpu_rw & cpu_addr[15:12] == 4'b1001)
		begin
			mir_control_on <= 1;
			mirror_mode <= cpu_dat[4];
		end
	
	end
	
	
endmodule
