
`include "../base/defs.v"


module map_004
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
	wire cfg_mmc3a = map_sub == 4;
	//*************************************************************  save state setup
	assign ss_rdat[7:0] = 
	ss_addr[7:3] == 0   ? bank_dat[ss_addr[2:0]]:
	ss_addr[7:0] == 8   ? bank_sel : 
	ss_addr[7:0] == 9   ? mmc_ctrl[0] : 
	ss_addr[7:0] == 10  ? mmc_ctrl[1] : 
	ss_addr[7:3] == 2   ? irq_ss_dat : //addr 16-23 for irq
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = {cpu_addr[15:13], 13'd0} == 16'h6000 & ram_ce_on;
	assign ram_we = !cpu_rw & ram_ce & !ram_we_off;
	assign rom_ce = cpu_addr[15];
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram & !ppu_we;
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = !mir_mod ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	
	assign prg_addr[12:0] = cpu_addr[12:0];
	assign prg_addr[18:13] =
	cpu_addr[14:13] == 0 ? (prg_mod == 0 ? bank_dat[6][5:0] : 6'b111110) :
	cpu_addr[14:13] == 1 ? bank_dat[7][5:0] : 
	cpu_addr[14:13] == 2 ? (prg_mod == 1 ? bank_dat[6][5:0] : 6'b111110) : 
	6'b111111;
	
	
	assign chr_addr[9:0] = ppu_addr[9:0];
	assign chr_addr[17:10] = cfg_chr_ram ? chr[4:0] : chr[7:0];//ines 2.0 reuired to support 32k ram
	
	wire [7:0]chr = 
	ppu_addr[12:11] == {chr_mod, 1'b0} ? {bank_dat[0][7:1], ppu_addr[10]} :
	ppu_addr[12:11] == {chr_mod, 1'b1} ? {bank_dat[1][7:1], ppu_addr[10]} : 
	ppu_addr[11:10] == 0 ? bank_dat[2][7:0] : 
	ppu_addr[11:10] == 1 ? bank_dat[3][7:0] : 
	ppu_addr[11:10] == 2 ? bank_dat[4][7:0] : 
   bank_dat[5][7:0];
	
	wire [15:0]reg_addr = {cpu_addr[15:13], 12'd0,  cpu_addr[0]};
	
	wire prg_mod = bank_sel[6];
	wire chr_mod = bank_sel[7];
	wire mir_mod = mmc_ctrl[0][0];
	wire ram_we_off = mmc_ctrl[1][6];
	wire ram_ce_on = mmc_ctrl[1][7];
	
	reg [7:0]bank_sel;
	reg [7:0]bank_dat[8];
	reg [7:0]mmc_ctrl[2];
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:3] == 0)bank_dat[ss_addr[2:0]] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 8)bank_sel <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 9)mmc_ctrl[0] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 10)mmc_ctrl[1] <= cpu_dat;
	end
		else
	if(map_rst)
	begin
		bank_sel[7:0] <= 0;
		
		mmc_ctrl[0][0] <= !cfg_mir_v;
		mmc_ctrl[1][7:0] <= 0;
	
		bank_dat[0][7:0] <= 0;
		bank_dat[1][7:0] <= 2;
		bank_dat[2][7:0] <= 4;
		bank_dat[3][7:0] <= 5;
		bank_dat[4][7:0] <= 6;
		bank_dat[5][7:0] <= 7;
		bank_dat[6][7:0] <= 0;
		bank_dat[7][7:0] <= 1;
	end
		else
	if(!cpu_rw)
	case(reg_addr[15:0])
		16'h8000:bank_sel[7:0] <= cpu_dat[7:0];
		16'h8001:bank_dat[bank_sel[2:0]][7:0] <= cpu_dat[7:0];
		16'hA000:mmc_ctrl[0][7:0] <= cpu_dat[7:0];
		16'hA001:mmc_ctrl[1][7:0] <= cpu_dat[7:0];
	endcase

//***************************************************************************** IRQ	
	
	wire [7:0]irq_ss_dat;
	irq_mmc3 irq_inst(
		.bus(bus), 
		.ss_ctrl(ss_ctrl),
		.mmc3a(cfg_mmc3a),
		.irq(irq),
		.ss_dout(irq_ss_dat)
	);

	
endmodule



module irq_mmc3
(bus, ss_ctrl, mmc3a, irq, ss_dout);
	
	`include "../base/bus_in.v"
	`include "../base/ss_ctrl_in.v"
	input mmc3a;
	output irq;
	output [7:0]ss_dout;
	
	assign ss_dout[7:0] = 
	ss_addr[7:0] == 16 ? irq_latch : 
	ss_addr[7:0] == 17 ? irq_on : //irq_on should be saved befor irq_pend
	ss_addr[7:0] == 18 ? irq_ctr : 
	ss_addr[7:0] == 19 ? irq_pend : 
	8'hff;
	
	assign irq = irq_pend;
	
	wire ss_we_ctr = ss_act & ss_we & ss_addr[7:0] == 18 & m3;
	wire ss_we_pnd = ss_act & ss_we & ss_addr[7:0] == 19 & m3;
	
	wire [15:0]reg_addr = {cpu_addr[15:13], 12'd0,  cpu_addr[0]};
	
	reg [7:0]irq_latch;
	reg [7:0]irq_ctr;
	reg irq_on, irq_pend, irq_reload_req;

	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 16)irq_latch <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 17)irq_on <= cpu_dat[0];
	end
		else
	if(map_rst)irq_on <= 0;
		else
	if(!cpu_rw)
	case(reg_addr[15:0])
		16'hC000:irq_latch[7:0] <= cpu_dat[7:0];
		//16'hC001:ctr_reload <= 1;
		16'hE000:irq_on <= 0;
		16'hE001:irq_on <= 1;
	endcase

	wire ctr_reload = reg_addr[15:0] == 16'hC001 & !cpu_rw & m2;
	wire [7:0]ctr_next = irq_ctr == 0 ? irq_latch : irq_ctr - 1;
	wire irq_trigger = mmc3a ? ctr_next == 0 & (irq_ctr != 0 | irq_reload_req) : ctr_next == 0;
	
	wire a12d;
	deglitcher dg_inst(ppu_addr[12], a12d, clk);
	
	/*
	always @(posedge ppu_addr[12], negedge irq_on, posedge ss_we_pnd)
	if(ss_we_pnd)irq_pend <= cpu_dat;
		else*/
	always @(posedge a12d, negedge irq_on)
	if(!irq_on)
	begin
		if(!ss_act)irq_pend <= 0;
	end
		else
	if(a12_stb & !ss_act)
	begin
		if(irq_trigger)irq_pend <= 1;
	end
	
	 

	always @(posedge a12d, posedge ctr_reload, posedge ss_we_ctr)
	if(ss_we_ctr)irq_ctr <= cpu_dat;
		else
	if(ctr_reload)
	begin
		irq_reload_req <= 1;
		irq_ctr[7:0] <= 0;
	end
		else
	if(a12_stb & !ss_act)
	begin
		irq_reload_req <= 0;
		irq_ctr <= ctr_next;
	end
	
	
	reg [3:0]irq_a12_st;
	wire a12_stb = irq_a12_st[3:1] == 0;
	always @(negedge m2)
	begin
		irq_a12_st[3:0] <= {irq_a12_st[2:0], a12d};
	end

	
endmodule


module deglitcher
(in, out, clk);
	input in, clk;
	output reg out;

	reg [1:0]st;

	always @(negedge clk)
	begin
		st[1:0] <= {st[0], in};
		if(st[1:0] == 2'b11)out <= 1;
		if(st[1:0] == 2'b00)out <= 0;
	end
	
endmodule

