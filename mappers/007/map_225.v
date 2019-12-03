
`include "../base/defs.v"

module map_225
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
	ss_addr[7:0] == 0   ? regs[0] : 
	ss_addr[7:0] == 1   ? regs[1] : 
	ss_addr[7:0] == 2   ? regs[2] : 
	ss_addr[7:0] == 3   ? regs[3] : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = {cpu_addr[15:13], 13'd0} == 16'h6000;
	assign ram_we = !cpu_rw & ram_ce;
	assign rom_ce = cpu_addr[15];
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = !mir_mode ? ppu_addr[10] : ppu_addr[11];
	
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[13:0] = cpu_addr[13:0];
	assign prg_addr[20:14] = prg_mode == 0 ? {prg[6:1], cpu_addr[14]} : prg[6:0];

	assign chr_addr[12:0] = ppu_addr[12:0];
	assign chr_addr[19:13] = chr[6:0];
	
	assign map_cpu_oe = (cpu_addr & 16'hF800) == 16'h5800 & cpu_rw;
	assign map_cpu_dout[7:4] = cpu_addr[15:12];
	assign map_cpu_dout[3:0] = 
	(cpu_addr & 16'hF803) == 16'h5800 ? regs[2][7:4] : 
	(cpu_addr & 16'hF803) == 16'h5801 ? regs[2][3:0] : 
	(cpu_addr & 16'hF803) == 16'h5802 ? regs[3][7:4] : 
	(cpu_addr & 16'hF803) == 16'h5803 ? regs[3][3:0] : cpu_addr[3:0];
	
	wire [6:0]chr = {regs[1][6], regs[0][5:0]};
	wire [6:0]prg = {regs[1][6], regs[1][3:0], regs[0][7:6]};
	wire prg_mode = regs[1][4];
	wire mir_mode = regs[1][5];
	
	
	reg [7:0]regs[4];
	
	always @(negedge m2, posedge sys_rst)
	if(sys_rst)
	begin
		regs[0] <= 0;
		regs[1] <= 0;
	end
		else
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 0)regs[0] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 1)regs[1] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 2)regs[2] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 3)regs[3] <= cpu_dat;
	end
		else
	if(map_rst)
	begin
		regs[0] <= 0;
		regs[1] <= 0;
	end
		else
	begin
	
		if(!cpu_rw & cpu_addr[15]){regs[1][7:0], regs[0][7:0]} <= cpu_addr[15:0];
		
		if((cpu_addr & 16'hF803) == 16'h5800)regs[2][7:4] <= cpu_dat[3:0];
		if((cpu_addr & 16'hF803) == 16'h5801)regs[2][3:0] <= cpu_dat[3:0];
		if((cpu_addr & 16'hF803) == 16'h5802)regs[3][7:4] <= cpu_dat[3:0];
		if((cpu_addr & 16'hF803) == 16'h5803)regs[3][3:0] <= cpu_dat[3:0];
		
	end

	
endmodule
