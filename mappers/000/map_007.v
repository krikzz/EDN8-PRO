
`include "../base/defs.v"

module map_007 //AxROM
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
	assign bus_conflicts = map_sub == 2;
	//*************************************************************  save state setup
	assign ss_rdat[7:0] = 
	ss_addr[7:0] == 0 ? {3'd0, vram_bit, 1'd0, prg_bank[2:0]} : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_we = !cpu_rw & ram_ce;
	assign ram_ce = {cpu_addr[15:13], 13'd0} == 16'h6000;
	assign rom_ce = cpu_addr[15];
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;
	
	assign ciram_a10 = vram_bit;
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[17:0] = {prg_bank[2:0], cpu_addr[14:0]};

	assign chr_addr[12:0] = ppu_addr[12:0];

	
	reg [2:0]prg_bank;
	reg vram_bit;

	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 0)prg_bank[2:0] <= cpu_dat[2:0];
		if(ss_we & ss_addr[7:0] == 0)vram_bit <= cpu_dat[4];
	end
		else
	begin
		
		if(cpu_addr[15] & !cpu_rw)
		begin
			prg_bank[2:0] <= cpu_dat[2:0];
			vram_bit <= cpu_dat[4];
		end
	end

	
endmodule
