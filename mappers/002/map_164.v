
`include "../base/defs.v"

module map_164
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
	ss_addr[7:0] == 0 ? bank : 
	ss_addr[7:0] == 1 ? latch : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = {cpu_addr[15:13], 13'd0} == 16'h6000;
	assign ram_we = !cpu_rw & ram_ce;
	assign rom_ce = !cpu_ce;
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = cfg_mir_v ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[14:0] = cpu_addr[14:0];
	assign prg_addr[20:15] = bank[5:0];
	
	assign chr_addr[12:0] = ppu_addr[12:0];
	
	reg [7:0]bank;
	reg [7:0]latch;
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 0)bank[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 1)latch[7:0] <= cpu_dat[7:0];
	end
		else
	if(map_rst)bank <= 8'h0f;
		else
	if(!cpu_rw)
	begin
		

		if((cpu_addr[15:0] & 16'hF300) == 16'h5000)bank[3:0] <= cpu_dat[3:0];
		if((cpu_addr[15:0] & 16'hF300) == 16'h5100)bank[7:4] <= cpu_dat[3:0];
		if((cpu_addr[15:0] & 16'hF300) == 16'h5300)latch[7:0] <= cpu_dat[7:0];
		
	end
	
endmodule
