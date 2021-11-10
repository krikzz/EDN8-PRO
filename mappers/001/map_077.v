
`include "../base/defs.v"

module map_077
(map_out, bus, sys_cfg, ss_ctrl);

	`include "../base/bus_in.v"
	`include "../base/map_out.v"
	`include "../base/sys_cfg_in.v"
	`include "../base/ss_ctrl_in.v"
	
	output [`BW_MAP_OUT-1:0]map_out;
	input [`BW_SYS_CFG-1:0]sys_cfg;
	
	
	assign chr_mask_off = chr_ram_ce;
	
	assign sync_m2 = 1;
	assign mir_4sc = 0;//enable support for 4-screen mirroring. for activation should be ensabled in sys_cfg also
	assign srm_addr[12:0] = cpu_addr[12:0];
	assign prg_oe = cpu_rw;
	assign chr_oe = !ppu_oe;
	//*************************************************************  save state setup
	assign ss_rdat[7:0] = 
	ss_addr[7:0] == 0 ? {chr[3:0], prg[3:0]} : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = 0;
	assign ram_we = 0;
	assign rom_ce = !cpu_ce;
	assign chr_ce = ciram_ce;
	assign chr_we = !ppu_we & chr_ram_ce;
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = ppu_addr[10];
	assign ciram_ce = ppu_addr[13] == 1 & ppu_addr[11] == 1 ? 0 : 1;
	
	wire nt_ram = ppu_addr[13] == 1 & ppu_addr[11] == 0; 
	wire ch_ram = ppu_addr[13] == 0 & ppu_addr[12:11] != 0;
	wire chr_ram_ce = nt_ram | ch_ram;
	
	
	assign prg_addr[14:0] = cpu_addr[14:0];
	assign prg_addr[18:15] = prg[3:0];
	
	assign chr_addr[10:0] = ppu_addr[10:0];
	assign chr_addr[14:11] = !chr_ram_ce ? chr[3:0] : {2'b00, ppu_addr[12:11]};
	assign chr_addr[15] = chr_ram_ce;//dedicated memory for rom and sram
	
	
	
	reg [3:0]prg;
	reg [3:0]chr;
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 0){chr[3:0], prg[3:0]} <= cpu_dat[7:0];
	end
		else
	if(!cpu_ce & !cpu_rw)
	begin
		
		prg[3:0] <= cpu_dat[3:0];
		chr[3:0] <= cpu_dat[7:4];
	
	end
	
endmodule
