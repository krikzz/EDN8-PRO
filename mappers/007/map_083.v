
`include "../base/defs.v"

module map_083
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
	{ss_addr[7:3], 3'd0} == 0  ? chr[ss_addr[2:0]] : 
	{ss_addr[7:2], 2'd0} == 8  ? prg[ss_addr[1:0]] : 
	{ss_addr[7:2], 2'd0} == 12 ? skram[ss_addr[1:0]] :
	ss_addr[7:0] == 16  ? mode :
	ss_addr[7:0] == 17  ? outer :
	ss_addr[7:0] == 18  ? irq_ctr[15:8] :
	ss_addr[7:0] == 19  ? irq_ctr[7:0] :
	ss_addr[7:0] == 20  ? {irq_pend, irq_on} :
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = ram_area & map_sub == 2;
	assign ram_we = !cpu_rw & ram_ce;
	assign rom_ce = cpu_addr[15] | (prg_ext & ram_area);
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;
	
	assign map_cpu_oe = cpu_rw & (dsw_ce | skram_ce);
	assign map_cpu_dout[7:0] = 
	dsw_ce ? {cpu_addr[15:10], dip_switch[1:0]} : 
	skram[cpu_addr[1:0]][7:0];
	
	//A10-Vmir, A11-Hmir
	assign ciram_ce = !ppu_addr[13];
	assign ciram_a10 = 
	mir_mode == 0 ? ppu_addr[10] : 
	mir_mode == 1 ? ppu_addr[11] : 
	mir_mode[0];
	
		
	assign chr_addr[9:0]   = ppu_addr[9:0];
	assign chr_addr[19:10] = 
	map_sub == 1 & ppu_addr[12:11] == 0 ? {chr[0][7:0], ppu_addr[10]} :
	map_sub == 1 & ppu_addr[12:11] == 1 ? {chr[1][7:0], ppu_addr[10]} :
	map_sub == 1 & ppu_addr[12:11] == 2 ? {chr[6][7:0], ppu_addr[10]} :
	map_sub == 1 & ppu_addr[12:11] == 3 ? {chr[7][7:0], ppu_addr[10]} :
	{outer[5:4], chr[ppu_addr[12:10]][7:0]};
	
	//assign chr_addr[19:18] = outer[5:4];
	
	assign prg_addr[12:0]  = cpu_addr[12:0];
	assign prg_addr[17:13] =
	ram_area ? prg[3] :
	prg_mode == 0 & cpu_addr[14] == 0 ? {outer[3:0], cpu_addr[13]} :
	prg_mode == 0 & cpu_addr[14] == 1 ? {4'b1111, cpu_addr[13]} :
	prg_mode == 1 ? {outer[3:1], cpu_addr[14:13]} : 
	cpu_addr[14:13] == 0 ? prg[0] :
	cpu_addr[14:13] == 1 ? prg[1] :
	cpu_addr[14:13] == 2 ? prg[2] : 5'b11111;
	
	assign prg_addr[19:18] = outer[5:4];
	
	assign srm_addr[14:13] = outer[7:6];
	
	assign irq = irq_pend;

	
	wire [1:0]dip_switch = 0;
	
	wire ram_area = {cpu_addr[15:13], 13'd0} == 16'h6000;
	wire dsw_ce   = (cpu_addr[15:0] & 16'hDF00) == 16'h5000;
	wire skram_ce = (cpu_addr[15:0] & 16'hDF00) == 16'h5100;
	wire irq_we   = (cpu_addr[15:0] & 16'h8301) == 16'h8200 & !cpu_rw;
	
	
	wire [1:0]mir_mode = mode[1:0];
	wire [1:0]prg_mode = mode[4:3];
	wire prg_ext = mode[5] & map_sub != 2;
	wire irq_mode = mode[6];
	
	reg [7:0]mode;
	reg [7:0]chr[8];
	reg [7:0]prg[4];
	reg [7:0]outer;
	reg [7:0]skram[4];
	reg [15:0]irq_ctr;
	reg irq_pend, irq_on;
	
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & {ss_addr[7:3], 3'd0} == 0)chr[ss_addr[2:0]] <= cpu_dat;
		if(ss_we & {ss_addr[7:2], 2'd0} == 8)prg[ss_addr[1:0]] <= cpu_dat;
		if(ss_we & {ss_addr[7:2], 2'd0} == 12)skram[ss_addr[1:0]] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 16)mode <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 17)outer <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 18)irq_ctr[15:8] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 19)irq_ctr[7:0] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 20){irq_pend, irq_on} <= cpu_dat;
	end
		else
	if(map_rst)
	begin
		mode <= 0;
		irq_pend <= 0;
		irq_on <= 0;
	end
		else
	begin
	
		if(irq_we)
		begin
			if(cpu_addr[0] == 0)irq_ctr[7:0] <= cpu_dat[7:0];
			if(cpu_addr[0] == 0)irq_pend <= 0;
			if(cpu_addr[0] == 1)irq_ctr[15:8] <= cpu_dat[7:0];
			if(cpu_addr[0] == 1)irq_on <= mode[7];
		end
			else
		if(irq_on)
		begin
			
			irq_ctr <= irq_mode ? irq_ctr - 1 : irq_ctr + 1;
			if(irq_ctr == 16'h0000){irq_on, irq_pend} <= 2'b01;
			
		end
	
		if(!cpu_rw & (cpu_addr[15:0] & 16'h8300) == 16'h8000)outer[7:0] <= cpu_dat[7:0];
		
		if(!cpu_rw & (cpu_addr[15:0] & 16'h8300) == 16'h8100)mode[7:0] <= cpu_dat[7:0];
		
		if(!cpu_rw & (cpu_addr[15:0] & 16'h8318) == 16'h8300)prg[cpu_addr[1:0]][7:0] <= cpu_dat[7:0];
		
		if(!cpu_rw & (cpu_addr[15:0] & 16'h8318) == 16'h8310)chr[cpu_addr[2:0]][7:0] <= cpu_dat[7:0];
		
		if(!cpu_rw & skram_ce)skram[cpu_addr[1:0]][7:0] <= cpu_dat[7:0];
		
	
	end
	
endmodule
