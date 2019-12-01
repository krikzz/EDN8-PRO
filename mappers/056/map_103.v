
`include "../base/defs.v"

module map_103
(map_out, bus, sys_cfg, ss_ctrl); //no mapper

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
	parameter MAP_NUM = 8'd27;
	assign ss_rdat[7:0] = 
	ss_addr[7:0] == 0 ? {2'b00, mirror, ram_dis, prg_bank[3:0]} : 
	ss_addr[7:0] == 127 ? MAP_NUM : 8'hff;
	//*************************************************************

	wire ram_on = !cpu_rw | (ram_area & !ram_dis);
	
	assign ram_we = !cpu_rw & ram_area & m2;
	assign ram_ce = ram_on & m2;
	assign rom_ce = (lo_ram_area | !cpu_ce) & !ram_on;
	assign chr_ce = ciram_ce;
	assign chr_we = !ppu_we & ciram_ce;//if cfg_chr_ram == 1 means that we don't have CHR rom, only CHR ram
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = !mirror ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[12:0] = ram_on ? (cpu_ce ? cpu_addr[12:0] : cpu_addr[12:0] - 13'h1800) : cpu_addr[12:0];
	assign prg_addr[16:13] = ram_on ? (cpu_ce ? 4'h0 : 4'h1) : 
	lo_ram_area ? (ram_dis ? prg_bank[3:0] : 0) : {2'b11, cpu_addr[14:13]};
	
	assign chr_addr[12:0] = ppu_addr[12:0];
	
	reg mirror;
	reg ram_dis;
	reg [3:0]prg_bank;
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 0) {mirror, ram_dis, prg_bank[3:0]} <= cpu_dat[5:0];
	end
	else
	begin			
		if(!cpu_rw & cpu_addr[15:12] == 4'h8) prg_bank[3:0] <= cpu_dat[3:0];
		if(!cpu_rw & cpu_addr[15:12] == 4'hE) mirror <= cpu_dat[3];
		if(!cpu_rw & cpu_addr[15:12] == 4'hF) ram_dis <= cpu_dat[4];
	end
	
	wire ram_area = lo_ram_area | hi_ram_area;
	wire lo_ram_area = {cpu_addr[15:13], 13'd0} == 16'h6000;
	wire hi_ram_area = cpu_addr[15:0] >= 16'hB800 & cpu_addr[15:0] < 16'hD800;

endmodule

