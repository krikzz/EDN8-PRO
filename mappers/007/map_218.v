
`include "../base/defs.v"

module map_218
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
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = 0;
	assign ram_we = 0;
	assign rom_ce = cpu_addr[15];
	assign chr_ce = 0;
	assign chr_we = 0;//
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = 
	cfg_mir_v ? ppu_addr[10] : 
	cfg_mir_h ? ppu_addr[11] : 
	cfg_mir_1 ? ppu_addr[12] : 
	ppu_addr[13];
	
	assign ciram_ce = 0;
	
	assign prg_addr[14:0] = cpu_addr[14:0];
	

endmodule
