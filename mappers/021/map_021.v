
`include "../base/defs.v"

module map_021 //VRC4+VRC2
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
	{ss_addr[7:3], 3'd0} == 0 ? chr[ss_addr[2:0]][7:0] :
	{ss_addr[7:3], 3'd0} == 8 ? chr[ss_addr[2:0]][8] :
	ss_addr[7:0] == 16 ? prg[0][7:0] :
	ss_addr[7:0] == 17 ? prg[1][7:0] :
	ss_addr[7:0] == 18 ? {swp_mode, mir_mode[1:0]} :
	ss_addr[7:0] == 32 ? irq_ss :
	ss_addr[7:0] == 33 ? irq_ss :
	ss_addr[7:0] == 34 ? irq_ss :
	ss_addr[7:0] == 35 ? irq_ss :
	ss_addr[7:0] == 36 ? irq_ss :
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = {cpu_addr[15:13], 13'd0} == 16'h6000;
	assign ram_we = !cpu_rw;
	assign rom_ce = cpu_addr[15];
	assign chr_ce = ciram_ce;
	assign chr_we = 0;
	
	
	assign ciram_a10 = mir_mode[1] & vrc4 ? mir_mode[0] : !mir_mode[0] ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[12:0] = cpu_addr[12:0];
	assign prg_addr[20:13] = 
	{cpu_addr[15:13], 13'd0} == 16'h8000 & swp_mode == 0 ? prg[0][7:0] : 
	{cpu_addr[15:13], 13'd0} == 16'h8000 & swp_mode == 1 ? 8'hFE : 
	{cpu_addr[15:13], 13'd0} == 16'hA000 ? prg[1][7:0] : 
	{cpu_addr[15:13], 13'd0} == 16'hC000 & swp_mode == 0 ? 8'hFE : 
	{cpu_addr[15:13], 13'd0} == 16'hC000 & swp_mode == 1 ? prg[0][7:0] : 
	8'hFF; 

	assign chr_addr[9:0] = ppu_addr[9:0];
	assign chr_addr[17:10] = map_idx == 22 ? chr[ppu_addr[12:10]][7:1] : chr[ppu_addr[12:10]][7:0];
	
	assign map_cpu_oe = cpu_rw & vrc2_latch_ce;
	assign map_cpu_dout[7:0] = {cpu_addr[15:9], vrc2_latch};
	

	wire vrc2 = map_idx == 22 | (map_sub == 3 & (map_idx == 23 | map_idx == 25));
	wire vrc4 = !vrc2;
	
	
	wire [1:0]reg_map21_s0 = cpu_addr[7:6] == 0 ? {cpu_addr[2], cpu_addr[1]} : {cpu_addr[7], cpu_addr[6]};
	wire [1:0]reg_map21_s1 = cpu_addr[2:1];
	wire [1:0]reg_map21_s2 = cpu_addr[7:6];
	
	wire [1:0]reg_map23_s0 = cpu_addr[3:2] == 0 ?  cpu_addr[1:0] : cpu_addr[3:2];
	wire [1:0]reg_map23_s1 = cpu_addr[1:0];
	wire [1:0]reg_map23_s2 = cpu_addr[3:2];
	
	wire [1:0]reg_map25_s0 = cpu_addr[3:2] == 0 ? {cpu_addr[0], cpu_addr[1]} : {cpu_addr[2], cpu_addr[3]};
	wire [1:0]reg_map25_s1 = {cpu_addr[0], cpu_addr[1]};
	wire [1:0]reg_map25_s2 = {cpu_addr[2], cpu_addr[3]};
	
	wire [1:0]reg_map21 = map_sub == 1 ? reg_map21_s1 : map_sub == 2 ? reg_map21_s2 : reg_map21_s0;
	wire [1:0]reg_map22 = {cpu_addr[0], cpu_addr[1]};
	wire [1:0]reg_map23 = (map_sub == 1 | map_sub == 3) ? reg_map23_s1 : map_sub == 2 ? reg_map23_s2 : reg_map23_s0;
	wire [1:0]reg_map25 = (map_sub == 1 | map_sub == 3) ? reg_map25_s1 : map_sub == 2 ? reg_map25_s2 : reg_map25_s0;
	
	wire [1:0]reg_map = 
	map_idx == 21 ? reg_map21[1:0] : 
	map_idx == 22 ? reg_map22[1:0] : 
	map_idx == 25 ? reg_map25[1:0] : reg_map23[1:0];
	
	wire [15:0]reg_addr = {cpu_addr[15:12], 8'd0, 2'd0, reg_map[1:0]};
	
	
	wire vrc2_latch_ce = {cpu_addr[15:12], 12'd0} == 16'h6000 & cfg_prg_ram_off & vrc2;
	
	reg [8:0]chr[8];
	reg [7:0]prg[2];
	reg swp_mode;
	reg [1:0]mir_mode;
	reg vrc2_latch;
	
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & {ss_addr[7:3], 3'd0} == 0)chr[ss_addr[2:0]][7:0] <= cpu_dat[7:0];
		if(ss_we & {ss_addr[7:3], 3'd0} == 8)chr[ss_addr[2:0]][8] <= cpu_dat[0];
		if(ss_we & ss_addr[7:0] == 16)prg[0][7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 17)prg[1][7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 18){swp_mode, mir_mode[1:0]} <= cpu_dat[2:0];
	end
		else
	if(map_rst)
	begin
		prg[1] <= 1;
		prg[0] <= 0;
		swp_mode <= 0;
		mir_mode <= 3;
	end
		else
	if(!cpu_rw)
	begin
	
		if(cpu_addr[15:0] == 16'h9fff)mir_mode <= cpu_dat[1:0];//Kaiketsu Yanchamaru fix
		
		if(reg_addr[15:0] == 16'h9000)mir_mode <= cpu_dat[1:0];
		if(reg_addr[15:0] == 16'h9002)swp_mode <= cpu_dat[1] & vrc4;
		
		
		if({reg_addr[15:2],2'b0} == 16'h8000)prg[0][7:0] <= cpu_dat[7:0];
		if({reg_addr[15:2],2'b0} == 16'hA000)prg[1][7:0] <= cpu_dat[7:0];
		
		
		if(reg_addr[15:0] == 16'hB000)chr[0][3:0] <= cpu_dat[3:0];
		if(reg_addr[15:0] == 16'hB001)chr[0][8:4] <= cpu_dat[4:0];
		if(reg_addr[15:0] == 16'hB002)chr[1][3:0] <= cpu_dat[3:0];
		if(reg_addr[15:0] == 16'hB003)chr[1][8:4] <= cpu_dat[4:0];
		
		if(reg_addr[15:0] == 16'hC000)chr[2][3:0] <= cpu_dat[3:0];
		if(reg_addr[15:0] == 16'hC001)chr[2][8:4] <= cpu_dat[4:0];
		if(reg_addr[15:0] == 16'hC002)chr[3][3:0] <= cpu_dat[3:0];
		if(reg_addr[15:0] == 16'hC003)chr[3][8:4] <= cpu_dat[4:0];
		
		if(reg_addr[15:0] == 16'hD000)chr[4][3:0] <= cpu_dat[3:0];
		if(reg_addr[15:0] == 16'hD001)chr[4][8:4] <= cpu_dat[4:0];
		if(reg_addr[15:0] == 16'hD002)chr[5][3:0] <= cpu_dat[3:0];
		if(reg_addr[15:0] == 16'hD003)chr[5][8:4] <= cpu_dat[4:0];
		
		if(reg_addr[15:0] == 16'hE000)chr[6][3:0] <= cpu_dat[3:0];
		if(reg_addr[15:0] == 16'hE001)chr[6][8:4] <= cpu_dat[4:0];
		if(reg_addr[15:0] == 16'hE002)chr[7][3:0] <= cpu_dat[3:0];
		if(reg_addr[15:0] == 16'hE003)chr[7][8:4] <= cpu_dat[4:0];
		
		if(vrc2_latch_ce)vrc2_latch <= cpu_dat[0];
		
	end
	
	
	assign irq = irq_out & vrc4;
	wire irq_out;
	wire [7:0]irq_ss;
	irq_vrc(
		.bus(bus),
		.ss_ctrl(ss_ctrl),
		.ss_dout(irq_ss),
		.reg_addr(reg_addr),
		.map_idx(map_idx),
		.irq(irq_out)
	);

	
endmodule


