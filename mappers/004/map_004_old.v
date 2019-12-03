
`include "../base/defs.v"

module map_004 //MMC3
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
	wire cfg_mmc3a = map_opt[0];
	//*************************************************************  save state setup
	parameter MAP_NUM = 8'd4;
	assign ss_rdat[7:0] = 
	ss_addr[7:3] == 0 ? mmc_regs[ss_addr[2:0]][7:0] : 
	ss_addr[7:3] == 1 ? reg_8001[ss_addr[2:0]][7:0] : 
	ss_addr[7:0] == 16 ? irq_ctr[7:0] : 
	ss_addr[7:0] == 17 ? {3'b000, irq_on, irq_pend, 1'b0, irq_rld_req, 1'b0} : 
	ss_addr[7:0] == 127 ? MAP_NUM : 8'hff;
	//*************************************************************
	wire ram_area = {cpu_addr[15:13], 13'd0} == 16'h6000;
	assign map_cpu_oe = ram_area & !ram_on & cpu_rw;//open bus handling
	assign map_cpu_dout[7:0] = 8'hff;
	wire mmc3_ram_ce = ram_area & ram_on;
	
	assign ram_we = !cpu_rw & ram_ce & !ram_we_off;
	assign ram_ce = mmc3_ram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & chr_ce : 0;
	assign rom_ce = cpu_addr[15];
	assign chr_ce = !ppu_addr[13];
	
	
	
	assign ciram_a10 = !mirror_mode ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[12:0] = cpu_addr[12:0];
	assign chr_addr[9:0] = ppu_addr[9:0];
	
	assign chr_addr[17:10] = cfg_chr_ram ? {5'b00000, chr[2:0]} : chr[7:0];

	
	wire [7:0]chr = 
	ppu_addr[12:11] == {chr_invert, 1'b0} ? {reg_8001[0][7:1], ppu_addr[10]} :
	ppu_addr[12:11] == {chr_invert, 1'b1} ? {reg_8001[1][7:1], ppu_addr[10]} : 
	ppu_addr[11:10] == 0 ? reg_8001[2][7:0] : 
	ppu_addr[11:10] == 1 ? reg_8001[3][7:0] : 
	ppu_addr[11:10] == 2 ? reg_8001[4][7:0] : 
   reg_8001[5][7:0];
	
	
	
	assign prg_addr[18:13] = 
	cpu_addr[14:13] == 0 ? prg_0 :
	cpu_addr[14:13] == 1 ? prg_1 : 
	cpu_addr[14:13] == 2 ? prg_2 : prg_3;
	
	wire [5:0]prg_0 = !swap_control ? reg_8001[6][5:0] : 6'b111110;
	wire [5:0]prg_1 = reg_8001[7][5:0];
	wire [5:0]prg_2 = swap_control ? reg_8001[6][5:0] : 6'b111110;
	wire [5:0]prg_3 = 6'b111111;
	

	wire [2:0]reg_addr = {cpu_addr[14], cpu_addr[13], cpu_addr[0]};

	
	reg irq_on;
	reg [7:0]irq_ctr;
	reg [7:0]reg_8001[8];
	reg [7:0]mmc_regs[8];
	
	
	reg irq_pend;
	reg irq_rld_req;
	reg [7:0]a12_filter;
	
	
	assign irq = irq_pend | irq_act;	
	
	
	parameter REG_CFG = 0;
	parameter REG_MIRROR = 2;
	parameter REG_RAM_CFG = 3;
	parameter REG_RELOAD = 4;
	
	wire swap_control = mmc_regs[REG_CFG][6];
	wire chr_invert = mmc_regs[REG_CFG][7];
	wire [2:0]addr_8001 = mmc_regs[REG_CFG][2:0];
	
	wire mirror_mode = mmc_regs[REG_MIRROR][0];
	wire ram_on = mmc_regs[REG_RAM_CFG][7];
	wire ram_we_off = mmc_regs[REG_RAM_CFG][6];
	
	
	wire irq_reload = irq_rld_req | (!cfg_mmc3a & irq_ctr == 0);
	
	wire a12_tick = ppu_addr[12] == 1 & a12_filter[3:0] == 0;
	
	wire irq_act = irq_on & a12_tick & ((irq_ctr == 1 & !irq_reload) | (irq_reload &  mmc_regs[REG_RELOAD][7:0] == 0));
	
	
	
	always @(negedge m2)
	begin
		a12_filter[7:0] <= {a12_filter[6:0], ppu_addr[12]};
	end
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:3] == 0)mmc_regs[ss_addr[2:0]][7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:3] == 1)reg_8001[ss_addr[2:0]][7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 17)
		begin
			irq_rld_req <= cpu_dat[1];//cpu_dat[1] == cpu_dat[0] ? 0 : 1;
			irq_pend <= cpu_dat[3];//cpu_dat[3] == cpu_dat[2] ? 0 : 1;
			irq_on <= cpu_dat[4];
		end
	end
		else
	if(map_rst)
	begin
			irq_on <= 0;
			irq_pend <= 0;
			
			mmc_regs[REG_CFG][7:0] <= 0;
			mmc_regs[REG_RAM_CFG][7:0] <= 0;
			mmc_regs[REG_MIRROR][0] <=  cfg_mir_v;
			
			
			reg_8001[0][7:0] <= 0;
			reg_8001[1][7:0] <= 2;
			reg_8001[2][7:0] <= 4;
			reg_8001[3][7:0] <= 5;
			reg_8001[4][7:0] <= 6;
			reg_8001[5][7:0] <= 7;
			
			reg_8001[6][7:0] <= 0;
			reg_8001[7][7:0] <= 1;
	end
		else
	begin
		
		
		if(a12_tick)
		begin
		
			if(!irq_pend)irq_pend <= irq_act;
			
			if(irq_rld_req)irq_rld_req <= 0;
			
			irq_ctr <= irq_ctr == 0 | irq_reload ? mmc_regs[REG_RELOAD][7:0] : irq_ctr - 1;
			
		end
		
		
		if(cpu_addr[15] & !cpu_rw)
		begin
			
			mmc_regs[reg_addr][7:0] <= cpu_dat[7:0];
			
			if(reg_addr == 1)reg_8001[addr_8001[2:0]][7:0] <= cpu_dat[7:0];
			if(reg_addr == 5)irq_rld_req <= 1;
			if(reg_addr == 6)irq_on <= 0;
			if(reg_addr == 6)irq_pend <= 0;
			if(reg_addr == 7)irq_on <= 1;
			
		end	
		
		
	end
	
	
endmodule


