
`include "../base/defs.v"

module map_163
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
	ss_addr[7:0] == 4   ? regs[4] : 
	ss_addr[7:0] == 5   ? {bank3, trig} : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = {cpu_addr[15:13], 13'd0} == 16'h6000;
	assign ram_we = !cpu_rw & ram_ce;
	assign rom_ce = cpu_addr[15];
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = cfg_mir_v ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[14:0] = cpu_addr[14:0];
	assign prg_addr[20:15] = bank3 ? 3 : prg[5:0];
	
	assign chr_addr[12:0] = 
	chr_mode == 0 ? ppu_addr[12:0] : 
	{chr_bank, ppu_addr[11:0]};
	
	assign map_cpu_oe = reg_rd_51 | reg_rd_55;
	assign map_cpu_dout[7:0] = 
	reg_rd_51 ? regs[3] | regs[1] | regs[0] | (regs[2] ^ 8'hff): 
	reg_rd_55 & trig == 0 ? 8'h00 : regs[3] | regs[0];
	
	wire reg_rd_51 = reg_addr_r[15:0] == 16'h5100 & cpu_rw;
	wire reg_rd_55 = reg_addr_r[15:0] == 16'h5500 & cpu_rw;
	
	wire [15:0]reg_addr_r = cpu_addr[15:0] & 16'hF700;
	wire [15:0]reg_addr_w = cpu_addr[15:0] & 16'hF300;
	
	wire chr_mode = regs[0][7];
	wire [7:0]prg = {regs[2][3:0], regs[0][3:0]};
	
	reg bank3, trig;
	reg [7:0]regs[5];
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 0)regs[0] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 1)regs[1] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 2)regs[2] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 3)regs[3] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 4)regs[4] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 5){bank3, trig} <= cpu_dat;
	end
		else
	if(map_rst)
	begin
		regs[4] <= 1;
		trig <= 0;
	end
		else
	if(!cpu_rw)
	begin
		
		if(reg_addr_w == 16'h5000)regs[0] <= cpu_dat[7:0];
		if(reg_addr_w == 16'h5100)regs[1] <= cpu_dat[7:0];
		if(reg_addr_w == 16'h5200)regs[2] <= cpu_dat[7:0];
		if(reg_addr_w == 16'h5300)regs[3] <= cpu_dat[7:0];
		
		if(reg_addr_w == 16'h5000 | reg_addr_w == 16'h5200 )bank3 <= 0;
		if(reg_addr_w == 16'h5100 & cpu_dat[7:0] == 6)bank3 <= 1;
		if(reg_addr_w == 16'h5100 & cpu_addr[0] == 1)
		begin
			regs[4] <= cpu_dat;
			if(regs[4] != 0 & cpu_dat[7:0] == 0)trig <= !trig;
		end
		
		
		
		//if(reg_addr_w[15:0] == 16'h5100 & cpu_dat[7:0] == 6)bank3 <= 1;
		
		//if(reg_addr_w[15:0] == 16'h5000){bank3, chr_mode, prg[3:0]} <= {1'b0, cpu_dat[7], cpu_dat[3:0]};
		//if(reg_addr_w[15:0] == 16'h5200){bank3, prg[7:4]} <= {1'b0, cpu_dat[3:0]};
		
	end
	
	
	wire chr_bank = y_pos[7];//128
	wire [5:0]x_pos;
	wire [7:0]y_pos;
	scanline_ctr(
		.bus(bus), 
		.x_pos(x_pos),//not used for this mapper
		.y_pos(y_pos)
	);

	
endmodule


module scanline_ctr
(bus, x_pos, y_pos);

	`include "../base/bus_in.v"
	output reg [7:0]y_pos;
	output reg [5:0]x_pos;
	
	reg [7:0]nt_st;
	reg [3:0]idle_ctr;
	reg [2:0]state;
	reg pre_render;
	
	
	wire ppu_at = (ppu_addr[13:0] & 14'h23C0) == 14'h23C0;
	wire ppu_nt = (ppu_addr[13:0] & 14'h2000) == 14'h2000 & !ppu_at;
	wire vblank = idle_ctr == 0;
	
	always @(negedge ppu_oe)//ppu_oe pos or neg edge for stable addr?
	begin
		nt_st[7:0] <= {nt_st[6:0], ppu_nt};
	end
	
	always @(posedge ppu_oe, posedge vblank)
	if(vblank)
	begin
		x_pos <= 2;
		y_pos <= 0;
		pre_render <= 1;
	end
		else
	if(nt_st[7:0] == 8'b11001100)x_pos <= 0;
		else
	if(nt_st[3:0] == 4'b1000)
	begin
		x_pos <= x_pos + 1;
		if(x_pos == 31)pre_render <= 0;
		if(x_pos == 31 & !pre_render)y_pos <= y_pos + 1;//may be 33 if thos two usused fetches care
	end
	

	always @(negedge m2, negedge ppu_oe)
	if(!ppu_oe)idle_ctr <= 4;
		else
	if(idle_ctr != 0)idle_ctr <= idle_ctr - 1;

endmodule
