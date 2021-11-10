

module map_069 //Sunsoft 5 / FME-7
	(map_out, bus, sys_cfg, ss_ctrl);
	
	`include "../base/bus_in.v"
	`include "../base/map_out.v"
	`include "../base/sys_cfg_in.v"
	`include "../base/ss_ctrl_in.v"
	
	output [`BW_MAP_OUT-1:0]map_out;
	input [`BW_SYS_CFG-1:0]sys_cfg;
	
	
	
	assign sync_m2 = 1;
	assign mir_4sc = 0;//enable support for 4-screen mirroring. for activation should be ensabled in sys_cfg also
	assign srm_addr[14:0] = prg_addr[14:0];
	assign prg_oe = cpu_rw;
	assign chr_oe = !ppu_oe;
	//*************************************************************  save state setup
	assign ss_rdat[7:0] = 
	ss_addr[7:3] == 0 ? chr[ss_addr[2:0]] :
	ss_addr[7:2] == 2 ? prg[ss_addr[1:0]] :
	ss_addr[7:0] == 12 ? irq_ctr[15:8] :
	ss_addr[7:0] == 13 ? irq_ctr[7:0] :
	ss_addr[7:0] == 14 ? {r_c[1:0], r_d[1:0], raddr[3:0]} : 
	ss_addr[7:0] == 15 ? irq_st : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	wire ram_area = {cpu_addr[15:13], 13'd0} == 16'h6000;
	assign ram_ce = ram_area & ram_on;
	assign ram_we = !cpu_rw & ram_ce;
	assign rom_ce = cpu_addr[15] | (ram_area & ext_rom_on);
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;

	
	assign ciram_a10 = !r_c[1] ? (!r_c[0] ? ppu_addr[10] : ppu_addr[11]) : r_c[0];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[12:0] = cpu_addr[12:0];
	
	assign prg_addr[20:13] =
	cpu_ce ? prg[0][7:0] : 
	cpu_addr[14:13] == 3 ?  8'hff : prg[1 + cpu_addr[14:13]][7:0];

	
	assign chr_addr[9:0] = ppu_addr[9:0];
	assign chr_addr[17:10] = chr[ppu_addr[12:10]];	
	assign irq = irq_st;
	
	wire ram_on = prg[0][7:6] == 2'b11;
	wire ext_rom_on = prg[0][6] == 0;
	wire reg_addr_we = cpu_addr[14:13] == 0 & !cpu_ce & !cpu_rw;
	wire reg_data_we = cpu_addr[14:13] == 1 & !cpu_ce & !cpu_rw;
	
	
	reg [7:0]chr[8];
	reg [7:0]prg[4];
	reg [15:0]irq_ctr;
	reg [3:0]raddr;
	reg [1:0]r_c;
	reg [1:0]r_d;
	reg irq_st;
	
	

	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:3] == 0)chr[ss_addr[2:0]] <= cpu_dat;
		if(ss_we & ss_addr[7:2] == 2)prg[ss_addr[1:0]] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 12)irq_ctr[15:8] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 13)irq_ctr[7:0] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 14){r_c[1:0], r_d[1:0], raddr[3:0]} <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 15)irq_st <= cpu_dat;
	end
		else
	begin
		
		
		if(r_d[1])
		begin
			irq_ctr <= irq_ctr - 1;
			if(irq_ctr == 0 & r_d[0])irq_st <= 1;
		end
		
		
		if(reg_addr_we)raddr[3:0] <= cpu_dat[3:0];
		if(reg_data_we & raddr[3] == 0)chr[raddr[2:0]] <= cpu_dat[7:0];
		if(reg_data_we & raddr[3:2] == 2)prg[raddr[1:0]] <= cpu_dat[7:0];
		if(reg_data_we & raddr[3:0] == 12)r_c[1:0] <= cpu_dat[1:0];
		if(reg_data_we & raddr[3:0] == 13){irq_st, r_d[1:0]} <= {1'b0, cpu_dat[7],cpu_dat[0]};
		if(reg_data_we & raddr[3:0] == 14)irq_ctr[7:0] <= cpu_dat;
		if(reg_data_we & raddr[3:0] == 15)irq_ctr[15:8] <= cpu_dat;
		
		
	end
	

	wire [11:0]snd_vol;
	ym2149 ym2149_inst(cpu_dat, cpu_addr[14:10], cpu_ce, cpu_rw, m2, clk, snd_vol, !map_rst);
	
	dac_ds dac_inst(clk, m2, snd_vol, master_vol, pwm);
	
endmodule




module dac_ds
(clk, m2, vol, master_vol, snd);
	
	parameter DEPTH = 12;
	
	input clk, m2;
	input [DEPTH-1:0]	vol;
	input [7:0]master_vol;
	output reg snd;
	

	
	wire [DEPTH+1:0]delta;
	wire [DEPTH+1:0]sigma;
	

	reg [DEPTH+1:0] sigma_st;	
	reg [DEPTH-1:0] vol_st;

	assign	delta[DEPTH+1:0] = {2'b0, vol_st[DEPTH-1:0]} + {sigma_st[DEPTH+1], sigma_st[DEPTH+1], {(DEPTH){1'b0}}};
	assign	sigma[DEPTH+1:0] = delta[DEPTH+1:0] + sigma_st[DEPTH+1:0];

	
	reg clk_div;
	always @(negedge m2)clk_div <= !clk_div;
	
	always @(negedge clk_div)
	begin
		vol_st[DEPTH-1:0] <= (vol[DEPTH-1:0] * master_vol) / 128;
	end
	
	
	always @(negedge clk) 
	begin
		sigma_st[DEPTH+1:0] <= sigma[DEPTH+1:0];
		snd <= sigma_st[DEPTH+1];
	end
	
endmodule  
