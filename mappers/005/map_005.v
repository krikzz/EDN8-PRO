
`include "../base/defs.v"

module map_005 //MMC5
	(map_out, bus, sys_cfg, ss_ctrl);
	
	`include "../base/bus_in.v"
	`include "../base/map_out.v"
	`include "../base/sys_cfg_in.v"
	`include "../base/ss_ctrl_in.v"
	
	output [`BW_MAP_OUT-1:0]map_out;
	input [`BW_SYS_CFG-1:0]sys_cfg;
	
	
	
	assign sync_m2 = 1;
	assign mir_4sc = 0;//enable support for 4-screen mirroring. for activation should be ensabled in sys_cfg also
	assign srm_addr[16:0] = prg_addr[16:0];
	assign prg_oe = cpu_rw;
	assign chr_oe = !ppu_oe;
	//*************************************************************  save state setup
	wire xram_ce_sst = ss_bank1KB == 1;
	wire xram_we_sst = xram_ce_sst & ss_wr_req;
	
	assign ss_rdat[7:0] = 
		xram_ce_sst ? xram_dout[7:0] : 
		ss_addr[7:3] == 0 ? chr_a[ss_addr[2:0]][7:0] :
		ss_addr[7:2] == 2 ? chr_b[ss_addr[1:0]][7:0] :
		ss_addr[7:2] == 3 ? prg_bank[ss_addr[1:0]] :
		ss_addr[7:0] == 16 ? {exram_mode[1:0], chr_mode[1:0], prg_mode[1:0], chr_hi[1:0]} : 
		ss_addr[7:0] == 17 ? {nt_map[3][1:0], nt_map[2][1:0], nt_map[1][1:0], nt_map[0][1:0]} :
		ss_addr[7:0] == 18 ? fill_tile :
		ss_addr[7:0] == 19 ? fill_color :
		ss_addr[7:0] == 20 ? ram_bank :
		ss_addr[7:0] == 21 ? irq_val :
		ss_addr[7:0] == 22 ? ram_protect :
		ss_addr[7:0] == 23 ? mul_a :
		ss_addr[7:0] == 24 ? mul_b :
		ss_addr[7:0] == 25 ? mul_rez[15:8] :
		ss_addr[7:0] == 26 ? mul_rez[7:0] :
		ss_addr[7:0] == 27 ? split_mode :
		ss_addr[7:0] == 28 ? split_scrl :
		ss_addr[7:0] == 29 ? split_bank :
		ss_addr[7:0] == 30 ? {last_set, bgr_on, sprite_mode, irq_on} :
		ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = ram_bnk_flag | {cpu_addr[15:13], 13'd0} == 16'h6000;
	assign ram_we = !cpu_rw;// & ram_we_on;
	assign rom_ce = !cpu_ce & !ram_bnk_flag;
	assign chr_ce = ppu_addr[13] == 0;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;
	
	assign ciram_a10 = vram_ce_pg0 ? 0 : 1;
	assign ciram_ce = (vram_ce_pg0 | vram_ce_pg1) & !ext_atr_ce ? 0 : 1;
	

	
	assign irq = irq_pend & irq_on;

//********************************************************************************* chr mapping	
	assign chr_addr[9:0] = ppu_addr[9:0];
	
	assign chr_addr[19:10] = 
	split_act ? {split_bank[7:0], ppu_addr[11:10]} :
	!in_frame & sprite_mode == 1 ? (last_set ? chr_bx[9:0] : chr_ax[9:0]) : 
	!in_frame & sprite_mode == 0 ? chr_ax[9:0] : 
	exram_mode == 1 & ppu_pat_ce & !spr_fetch ? {ext_atr[5:0], ppu_addr[11:10]} : //any addr range expand required?
	sprite_mode ? (spr_fetch ? chr_ax[9:0] : chr_bx[9:0]) : 
	chr_ax[9:0];
	
	
	wire [9:0]chr_ax = chr_md_a[chr_mode];
	wire [9:0]chr_bx = chr_md_b[chr_mode];
	
	wire [9:0]chr_md_a[4];
	assign chr_md_a[0] = {chr_a[7][6:0], ppu_addr[12:10]};
	assign chr_md_a[1] = !ppu_addr[12] ? {chr_a[3][7:0], ppu_addr[11:10]} : {chr_a[7][7:0], ppu_addr[11:10]};
	assign chr_md_a[2] = 
	ppu_addr[12:11] == 0 ? {chr_a[1][8:0], ppu_addr[10]} : 
	ppu_addr[12:11] == 1 ? {chr_a[3][8:0], ppu_addr[10]} : 
	ppu_addr[12:11] == 2 ? {chr_a[5][8:0], ppu_addr[10]} : {chr_a[7][8:0], ppu_addr[10]}; 
	assign chr_md_a[3][9:0] = chr_a[ppu_addr[12:10]][9:0];
	
	wire [9:0]chr_md_b[4];
	assign chr_md_b[0] = {chr_b[3][6:0], ppu_addr[12:10]};
	assign chr_md_b[1] = {chr_b[3][7:0], ppu_addr[11:10]};
	assign chr_md_b[2] = !ppu_addr[11] ? {chr_b[1][8:0], ppu_addr[10]} : {chr_b[3][8:0], ppu_addr[10]};
	assign chr_md_b[3] = chr_b[ppu_addr[11:10]];
	
	assign map_ppu_oe = ppu_oe ? 0 : vram_ce_exr | vram_ce_fda | vram_ce_fcl | ext_atr_ce;
	assign map_ppu_dout[7:0] = 
	exram_mode[1] == 1 ? 8'h00 : 
	ext_atr_ce ? {ext_atr[7:6], ext_atr[7:6], ext_atr[7:6], ext_atr[7:6]} : 
	split_act & ppu_atr_ce ? split_pal : 
	vram_ce_exr ? xram_dout[7:0] : 
	vram_ce_fda ? fill_tile[7:0] : 
	vram_ce_fcl ? {fill_color[1:0], fill_color[1:0], fill_color[1:0], fill_color[1:0]} : 8'h00;
//********************************************************************************* prg mapping

	assign prg_addr[12:0] = cpu_addr[12:0];
	assign prg_addr[19:13] = 
	cpu_ce ? ram_bank[3:0] : 
	prg_rom[prg_mode][6:0];

	
	wire [7:0]prg_rom[4];
	assign prg_rom[0][7:0] = {prg_bank[3][7:2], cpu_addr[14:13]};
	assign prg_rom[1][7:0] = !cpu_addr[14] ? {prg_bank[1][7:1], cpu_addr[13]} : {prg_bank[3][7:1], cpu_addr[13]};
	assign prg_rom[2][7:0] = !cpu_addr[14] ? {prg_bank[1][7:1], cpu_addr[13]} : !cpu_addr[13] ? prg_bank[2][7:0] : prg_bank[3][7:0];
	assign prg_rom[3][7:0] = cpu_addr[14:13] == 3 ? prg_bank[3][7:0] : prg_bank[cpu_addr[14:13]][7:0];
	assign map_cpu_oe = !m2 | !cpu_rw ? 0 : xram_oe_cpu | status_oe | mul_oe_lo | mul_oe_hi;
	assign map_cpu_dout[7:0] = 
	status_oe ? {irq_pend, in_frame, 6'd0} :
	mul_oe_lo ? mul_rez[7:0] : 
	mul_oe_hi ? mul_rez[15:8] : 
	xram_oe_cpu ? xram_dout[7:0] : 0;
	
//*********************************************************************************
	//assign irq = irq_pend & irq_on;
	
	wire [1:0]cur_nt = nt_map[ppu_addr[11:10]][1:0];
	
	wire ppu_pat_ce = ppu_addr[13] == 0;
	wire ppu_ntb_ce = ppu_addr[13] == 1 & ppu_addr[9:6] != 4'b1111;
	wire ppu_atr_ce = ppu_addr[13] == 1 & ppu_addr[9:6] == 4'b1111;
	
	//chip selects for vram area
	wire vram_ce_pg0 = ppu_addr[13] & (cur_nt[1:0] == 0 & !split_act);
	wire vram_ce_pg1 = ppu_addr[13] & (cur_nt[1:0] == 1 & !split_act);
	wire vram_ce_exr = ppu_addr[13] & (cur_nt[1:0] == 2 | split_act);
	wire vram_ce_fda = ppu_addr[13] & cur_nt[1:0] == 3 & ppu_ntb_ce;
	wire vram_ce_fcl = ppu_addr[13] & cur_nt[1:0] == 3 & ppu_atr_ce;
	
	wire ext_atr_ce = exram_mode == 1 & ppu_atr_ce;
	wire status_oe = cpu_rw & cpu_addr[15:0] == 16'h5204;
	wire ram_we_on = ram_protect[3:0] == 4'b0110;
	wire ram_bnk_flag = prg_rom[prg_mode][7] == 0 & !cpu_ce;
	wire mul_oe_lo = cpu_rw & cpu_addr[15:0] == 16'h5205;
	wire mul_oe_hi = cpu_rw & cpu_addr[15:0] == 16'h5206;
	//wire ppu_io_oe = cpu_rw & cpu_addr[15:13] == 3'b001 & m2 & cpu_addr[2:0] == 7;//{cpu_addr[15:13], 10'd0, cpu_addr[2:0]} == 16'h2007 & m2;
	
	
	reg [9:0]chr_a[8];
	reg [9:0]chr_b[4];
	reg [7:0]prg_bank[4];
	
	reg [1:0]chr_hi;
	reg [1:0]prg_mode;
	reg [1:0]chr_mode;
	reg [1:0]exram_mode;
	
	reg [1:0]nt_map[4];
	reg [7:0]fill_tile;
	reg [1:0]fill_color;
	
	reg [3:0]ram_bank;
	
	
	reg [7:0]irq_val;
	reg [3:0]ram_protect;
	
	reg [7:0]mul_a;
	reg [7:0]mul_b;
	reg [15:0]mul_rez;
	reg [7:0]split_mode;
	reg [7:0]split_scrl;
	reg [7:0]split_bank;
	
	reg irq_on;
	reg sprite_mode;
	reg bgr_on;
	reg last_set;

	
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:3] == 0)chr_a[ss_addr[2:0]][7:0] <= cpu_dat;
		if(ss_we & ss_addr[7:2] == 2)chr_b[ss_addr[1:0]][7:0] <= cpu_dat;
		if(ss_we & ss_addr[7:2] == 3)prg_bank[ss_addr[1:0]] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 16){exram_mode[1:0], chr_mode[1:0], prg_mode[1:0], chr_hi[1:0]} <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 17){nt_map[3][1:0], nt_map[2][1:0], nt_map[1][1:0], nt_map[0][1:0]} <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 18)fill_tile <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 19)fill_color <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 20)ram_bank <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 21)irq_val <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 22)ram_protect <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 23)mul_a <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 24)mul_b <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 25)mul_rez[15:8] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 26)mul_rez[7:0] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 27)split_mode <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 28)split_scrl <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 29)split_bank <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 30){last_set, bgr_on, sprite_mode, irq_on} <= cpu_dat;
	end
		else
	if(map_rst)
	begin
		exram_mode <= 0;
		{nt_map[3][1:0], nt_map[2][1:0], nt_map[1][1:0], nt_map[0][1:0]} <= 0;
		
		prg_bank[0] <= 0;//changed
		prg_bank[1] <= 0;//changed
		prg_bank[2] <= 0;//changed
		prg_bank[3] <= 8'hff;
		prg_mode[1:0] <= 2'h3;
		irq_on <= 0;
		split_mode <= 0;
	end
		else
	begin
		
		if(!cpu_rw & cpu_addr[15:0] == 16'h2000)sprite_mode <= cpu_dat[5];
		if(!cpu_rw & cpu_addr[15:0] == 16'h2001)bgr_on <= cpu_dat[3];
		
		if(!cpu_rw & cpu_addr[15:0] == 16'h5100)prg_mode[1:0] <= cpu_dat[1:0];
		if(!cpu_rw & cpu_addr[15:0] == 16'h5101)chr_mode[1:0] <= cpu_dat[1:0];
		if(!cpu_rw & cpu_addr[15:0] == 16'h5102)ram_protect[1:0] <= cpu_dat[1:0];
		if(!cpu_rw & cpu_addr[15:0] == 16'h5103)ram_protect[3:2] <= cpu_dat[1:0];
		if(!cpu_rw & cpu_addr[15:0] == 16'h5104)exram_mode[1:0] <= cpu_dat[1:0];
		if(!cpu_rw & cpu_addr[15:0] == 16'h5105){nt_map[3][1:0], nt_map[2][1:0], nt_map[1][1:0], nt_map[0][1:0]} <= cpu_dat[7:0];
		if(!cpu_rw & cpu_addr[15:0] == 16'h5106)fill_tile[7:0] <= cpu_dat[7:0];
		if(!cpu_rw & cpu_addr[15:0] == 16'h5107)fill_color[1:0] <= cpu_dat[1:0];
		if(!cpu_rw & cpu_addr[15:0] == 16'h5113)ram_bank[3:0] <= cpu_dat[3:0];
		
		if(!cpu_rw & cpu_addr[15:0] == 16'h5114)prg_bank[0][7:0] <= cpu_dat[7:0];
		if(!cpu_rw & cpu_addr[15:0] == 16'h5115)prg_bank[1][7:0] <= cpu_dat[7:0];
		if(!cpu_rw & cpu_addr[15:0] == 16'h5116)prg_bank[2][7:0] <= cpu_dat[7:0];
		if(!cpu_rw & cpu_addr[15:0] == 16'h5117)prg_bank[3][7:0] <= {1'b1, cpu_dat[6:0]};
		
		//if(!cpu_rw & {cpu_addr[15:2], 2'd0} == 16'h5114)prg_bank[cpu_addr[1:0]] <= cpu_addr[1:0] == 3 ? {1'b1, cpu_dat[6:0]} : cpu_dat[7:0];
		if(!cpu_rw & {cpu_addr[15:3], 3'd0} == 16'h5120){last_set, chr_a[cpu_addr[2:0]][9:0]} <= {1'b0, chr_hi[1:0], cpu_dat[7:0]};
		if(!cpu_rw & {cpu_addr[15:2], 2'd0} == 16'h5128){last_set, chr_b[cpu_addr[1:0]][9:0]} <= {1'b1, chr_hi[1:0], cpu_dat[7:0]};
		if(!cpu_rw & cpu_addr[15:0] == 	      16'h5130)chr_hi[1:0] <= cpu_dat[1:0];
		
		if(!cpu_rw & cpu_addr[15:0] == 16'h5200)split_mode[7:0] <= cpu_dat[7:0];
		if(!cpu_rw & cpu_addr[15:0] == 16'h5201)split_scrl[7:0] <= cpu_dat[7:0];
		if(!cpu_rw & cpu_addr[15:0] == 16'h5202)split_bank[7:0] <= cpu_dat[7:0];
		
		if(!cpu_rw & cpu_addr[15:0] == 16'h5203)irq_val[7:0] <= cpu_dat[7:0];
		if(!cpu_rw & cpu_addr[15:0] == 16'h5204)irq_on <= cpu_dat[7];

		if(!cpu_rw & cpu_addr[15:0] == 16'h5205)
		begin
			mul_a <= cpu_dat[7:0];
			mul_rez <= cpu_dat * mul_b;
		end
		
		if(!cpu_rw & cpu_addr[15:0] == 16'h5206)
		begin
			mul_b <= cpu_dat[7:0];
			mul_rez <= cpu_dat * mul_a;
		end
		
		
	end
	
	
//********************************************************************************* exram	
	wire [7:0]xram_dout;
	
	wire [9:0]xram_addr_ppu = !split_act ? ppu_addr[9:0] : split_addr[9:0];//{(y_pos[7:3] + split_scrl[6:3]), ppu_addr[4:0] };
	wire [9:0]xram_addr_rw = ss_act ? ss_addr[9:0] : exram_mode[1] ? cpu_addr[9:0] : xram_addr_ppu[9:0];//ppu+cpu rd and ppu wr
	wire [9:0]xram_addr_wo = ss_act ? ss_addr[9:0] : cpu_addr[9:0];//cpu wr only
	
	wire xram_we_ppu = !ss_act & vram_ce_exr & !ppu_we & !exram_mode[1];
	
	wire xram_ce_cpu = {cpu_addr[15:10], 10'd0} == 16'h5C00;
	wire xram_oe_cpu = xram_ce_cpu & cpu_rw & exram_mode[1] == 1;
	wire xram_we_cpu = ss_act ? xram_we_sst : xram_ce_cpu & !cpu_rw & exram_mode[1:0] != 2'b11;
	

	xram xram_inst(
		.din_a(cpu_dat[7:0]), 
		.addr_a(xram_addr_wo[9:0]), 
		.we_a(xram_we_cpu), 
		.clk_a(m2), 
		.din_b(ppu_dat[7:0]), 
		.addr_b(xram_addr_rw[9:0]), 
		.we_b(xram_we_ppu), 
		.dout_b(xram_dout[7:0]), 
		.clk_b(clk)
	);
	
	reg [7:0]ext_atr;
	reg [3:0]nt_rd_st;
	always @(negedge clk)
	begin
		nt_rd_st[3:0] <= {nt_rd_st[2:0], (ppu_ntb_ce & !ppu_oe)};
		if(nt_rd_st[3:0] == 4'b0111)ext_atr[7:0] <= xram_dout[7:0];
	end
	
	
//********************************************************************************* split mode
	
	wire split_on = split_mode[7];
	wire split_side = split_mode[6];
	wire [5:0]split_pos = split_mode[5:0];
	wire split1 = split_pos > x_pos[6:2];
	wire split2 = split_pos > x_pos[6:2];
	wire split = ppu_pat_ce ? split1 : split2;
	wire split_act = !split_on ? 0 : !split_side ? split : !split;	
	wire [9:0]split_addr = ppu_atr_ce ? split_at : split_nt[9:6] == 4'b1111 ? split_nt[5:0] : split_nt;
	wire [9:0]split_nt = {y_pos[7:3], x_pos[6:2]};
	wire [9:0]split_at = {4'b1111, split_nt[9:7], split_nt[4:2]};
	wire [7:0]split_pal = y_pos[4] == 0 ? {xram_dout[3:0], xram_dout[3:0]} : {xram_dout[7:4], xram_dout[7:4]};
	
	
	reg [7:0]y_pos;
	reg [6:0]x_pos;
	
	always @(posedge ppu_oe, negedge in_frame)
	if(!in_frame)
	begin
		y_pos <= {split_scrl[7:3], 3'd0};
	end
		else
	begin
		if(line_ctr == 128)y_pos <=  y_pos + 1;
		x_pos <= spr_fetch ? 0 : line_start ? x_pos - 1 : x_pos + 1;//look at mapper 163 for more accurate scanline timer
	end

//********************************************************************************* irq handler
	
	reg irq_pend;
	reg [7:0]irq_ctr;
	reg irq_ack;
	always @(negedge m2)irq_ack = cpu_rw & cpu_addr[15:0] == 16'h5204;
	
	always @(negedge ppu_oe, negedge in_frame, posedge irq_ack)//changed
	if(!in_frame)
	begin
		irq_pend <= 0;
		irq_ctr <= 0;
	end
		else
	if(irq_ack)irq_pend <= 0;
		else
	if(line_start)
	begin
		irq_ctr <= irq_ctr + 1;
		if(irq_ctr == irq_val)irq_pend <= 1;
	end

	
//********************************************************************************* scanline handler	
	//wire spr_fetch = line_ctr > 128-3 & line_ctr < 171 - 11;
	wire spr_fetch = line_ctr > 127 & line_ctr < 159;//wtf? line_start reset couter at first sprite fetch
	wire in_frame = in_frame_ctr != 0 & bgr_on;
	wire addr_eq = ppu_addr_st == ppu_addr & ppu_addr_st[13];
	
	reg [7:0]line_ctr;
	reg [13:0]ppu_addr_st;
	reg [3:0]in_frame_ctr;
	reg line_start;
	reg addr_eq_st;
	
	
	
	
	always @(negedge m2, negedge ppu_oe)
	if(!ppu_oe)in_frame_ctr <= 4;//changed
		else
	if(in_frame_ctr != 0)in_frame_ctr <= in_frame_ctr - 1;

	
	
	always @(negedge ppu_oe)//changed
	begin
	
		ppu_addr_st[13:0] <= ppu_addr[13:0];
		addr_eq_st <= addr_eq;
		
		line_start <= addr_eq & addr_eq_st;
		line_ctr = line_start ? 0 : line_ctr + 1;//look at mapper 163 for more accurate scanline timer

	end

//*********************************************************************************
	
	wire [9:0]vol;
	
	snd_mmc5 snd_inst(
		.bus(bus), 
		.vol(vol)
	);

	dac_ds dac_inst(clk, m2, vol, master_vol, pwm);

endmodule



module dac_ds
(clk, m2, vol, master_vol, snd);
	
	parameter DEPTH = 10;
	
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

	
	
	always @(negedge m2)
	begin
		vol_st[DEPTH-1:0] <= (vol[DEPTH-1:0] * master_vol) / 128;
	end
	
	
	always @(negedge clk) 
	begin
		sigma_st[DEPTH+1:0] <= sigma[DEPTH+1:0];
		snd <= sigma_st[DEPTH+1];
	end
	
endmodule  



module xram
(din_a, addr_a, we_a, dout_a, clk_a, din_b, addr_b, we_b, dout_b, clk_b);

	input [7:0]din_a, din_b;
	input [9:0]addr_a, addr_b;
	input we_a, we_b, clk_a, clk_b;
	output reg [7:0]dout_a, dout_b;

	
	reg [7:0]ram[1024];
	
	
	always @(negedge clk_a)
	begin
		dout_a <= we_a ? din_a : ram[addr_a];
		if(we_a)ram[addr_a] <= din_a;
	end
	
	always @(negedge clk_b)
	begin
		dout_b <= we_b ? din_b : ram[addr_b];
		if(we_b)ram[addr_b] <= din_b;
	end
	
endmodule


