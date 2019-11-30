
`include "../base/defs.v"

module map_032 //Irem-G101
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
	ss_addr[7:2] == 0 ? chr[ss_addr[2:0]] : 
	ss_addr[7:0] == 8 ? prg[0] : 
	ss_addr[7:0] == 9 ? prg[1] : 
	ss_addr[7:0] == 10 ? prg[2] : 
	ss_addr[7:0] == 11 ? mode : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = {cpu_addr[15:13], 13'd0} == 16'h6000;
	assign ram_we = !cpu_rw & ram_ce;
	assign rom_ce = cpu_addr[15];
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;
	
	assign ciram_a10 = cfg_mir_v ? 0 : !mode[0] ? ppu_addr[10] : ppu_addr[11];//0=hm, 1vm
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[12:0] = cpu_addr[12:0];

	assign prg_addr[17:13] = 
	cpu_addr[14:13] == 0 ? prg[0]: 
	cpu_addr[14:13] == 1 ? prg[1] : 
	cpu_addr[14:13] == 2 ? prg[2] : 5'b11111;
	
	
	assign chr_addr[9:0] = ppu_addr[9:0];
	assign chr_addr[16:10] = chr_reg[6:0];

	wire [6:0]chr_reg = chr[ppu_addr[12:10]];
	reg [6:0]chr[8];
	reg [4:0]prg[3];	
	reg [1:0]mode;
	
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:3] == 0)chr[ss_addr[2:0]] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 8)prg[0] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 9)prg[1] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 10)prg[2] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 11)mode <= cpu_dat;
	end
		else
	if(map_rst)
	begin
		mode <= 0;
		prg[0] <= 30;
		prg[1] <= 31;
		prg[2] <= 30;
	end
		else
	if(!cpu_ce & !cpu_rw)
	begin
		
		if(cpu_addr[13:12] == 0 & mode[1] == 0)prg[0][4:0] <= cpu_dat[4:0];
		if(cpu_addr[13:12] == 0 & mode[1] == 1)prg[2][4:0] <= cpu_dat[4:0];
		if(cpu_addr[13:12] == 1)mode[1:0] <= cpu_dat[1:0];
		if(cpu_addr[13:12] == 2)prg[1][4:0] <= cpu_dat[4:0];
		if(cpu_addr[13:12] == 3)chr[cpu_addr[2:0]][6:0] <= cpu_dat[6:0];
		
	end
	



	
endmodule

