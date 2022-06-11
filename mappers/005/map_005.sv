
module map_005(

	input  MapIn  mai,
	output MapOut mao
);
//************************************************************* base header
	CpuBus cpu;
	PpuBus ppu;
	SysCfg cfg;
	SSTBus sst;
	assign cpu = mai.cpu;
	assign ppu = mai.ppu;
	assign cfg = mai.cfg;
	assign sst = mai.sst;
	
	MemCtrl prg;
	MemCtrl chr;
	MemCtrl srm;
	assign mao.prg = prg;
	assign mao.chr = chr;
	assign mao.srm = srm;

	assign prg.dati			= cpu.data;
	assign chr.dati			= ppu.data;
	assign srm.dati			= cpu.data;
	
	wire int_cpu_oe;
	wire int_ppu_oe;
	wire [7:0]int_cpu_data;
	wire [7:0]int_ppu_data;
	
	assign mao.map_cpu_oe	= int_cpu_oe | (srm.ce & srm.oe) | (prg.ce & prg.oe);
	assign mao.map_cpu_do	= int_cpu_oe ? int_cpu_data : srm.ce ? mai.srm_do : mai.prg_do;
	
	assign mao.map_ppu_oe	= int_ppu_oe | (chr.ce & chr.oe);
	assign mao.map_ppu_do	= int_ppu_oe ? int_ppu_data : mai.chr_do;
//************************************************************* configuration
	assign mao.prg_mask_off = 0;
	assign mao.chr_mask_off = 0;
	assign mao.srm_mask_off = 0;
	assign mao.mir_4sc		= 0;//enable support for 4-screen mirroring. for activation should be enabled in cfg.mir_4 also
	assign mao.bus_cf 		= 0;//bus conflicts
//************************************************************* save state regs read
	wire xram_ce_sst = sst.addr[12:10] == 1;
	wire xram_we_sst = xram_ce_sst & sst.we_mem;
	
	assign mao.sst_di[7:0] =
	xram_ce_sst 			? xram_dout[7:0] : 
	sst.addr[7:3] == 0 	? chr_a[sst.addr[2:0]][7:0] :
	sst.addr[7:2] == 2 	? chr_b[sst.addr[1:0]][7:0] :
	sst.addr[7:2] == 3 	? prg_bank[sst.addr[1:0]] :
	sst.addr[7:0] == 16 	? {exram_mode[1:0], chr_mode[1:0], prg_mode[1:0], chr_hi[1:0]} : 
	sst.addr[7:0] == 17 	? {nt_map[3][1:0], nt_map[2][1:0], nt_map[1][1:0], nt_map[0][1:0]} :
	sst.addr[7:0] == 18 	? fill_tile :
	sst.addr[7:0] == 19 	? fill_color :
	sst.addr[7:0] == 20 	? ram_bank :
	sst.addr[7:0] == 21 	? irq_val :
	sst.addr[7:0] == 22 	? ram_protect :
	sst.addr[7:0] == 23 	? mul_a :
	sst.addr[7:0] == 24 	? mul_b :
	sst.addr[7:0] == 25 	? mul_rez[15:8] :
	sst.addr[7:0] == 26 	? mul_rez[7:0] :
	sst.addr[7:0] == 27 	? split_mode :
	sst.addr[7:0] == 28 	? split_scrl :
	sst.addr[7:0] == 29 	? split_bank :
	sst.addr[7:0] == 30 	? {last_set, bgr_on, sprite_mode, irq_on} :
	sst.addr[7:0] == 127 ? cfg.map_idx : 8'hff;
//************************************************************* mapper-controlled pins
	assign srm.ce				= ram_bnk_flag | {cpu.addr[15:13], 13'd0} == 16'h6000;
	assign srm.oe				= cpu.rw;
	assign srm.we				= !cpu.rw;
	assign srm.addr[16:0]	= cfg.srm_size == 16384 ? {prg.addr[15], prg.addr[12:0]} : prg.addr[16:0];//specific mapping for 16K sram
	
	assign prg.ce				= cpu.addr[15] & !ram_bnk_flag;
	assign prg.oe 				= cpu.rw;
	assign prg.we				= 0;
	assign prg.addr[12:0]	= cpu.addr[12:0];
	assign prg.addr[19:13] 	= prg_addr[19:13];
	
	assign chr.ce 				= ppu.addr[13] == 0;
	assign chr.oe 				= !ppu.oe;
	assign chr.we 				= cfg.chr_ram ? !ppu.we & mao.ciram_ce : 0;
	assign chr.addr[9:0]		= ppu.addr[9:0];
	assign chr.addr[19:10]	= chr_addr[19:10];

	
	//A10-Vmir, A11-Hmir
	assign mao.ciram_a10 	= vram_ce_pg0 ? 0 : 1;
	assign mao.ciram_ce 		= (vram_ce_pg0 | vram_ce_pg1) & !ext_atr_ce ? 0 : 1;
	
	assign mao.irq				= irq_pend & irq_on;
	assign mao.snd 			= {vol[9:0], 6'd0};
	assign int_ppu_oe			= map_ppu_oe;
	assign int_ppu_data		= map_ppu_dout;
	assign int_cpu_oe			= map_cpu_oe;
	assign int_cpu_data		= map_cpu_dout;
//********************************************************************************* chr mapping	
	
	wire [19:10]chr_addr = 
	split_act ? {split_bank[7:0], ppu.addr[11:10]} :
	!in_frame & sprite_mode == 1 ? (last_set ? chr_bx[9:0] : chr_ax[9:0]) : 
	!in_frame & sprite_mode == 0 ? chr_ax[9:0] : 
	exram_mode == 1 & ppu_pat_ce & !spr_fetch ? {ext_atr[5:0], ppu.addr[11:10]} : //any addr range expand required?
	sprite_mode ? (spr_fetch ? chr_ax[9:0] : chr_bx[9:0]) : 
	chr_ax[9:0];
	
	
	wire [9:0]chr_ax = chr_md_a[chr_mode];
	wire [9:0]chr_bx = chr_md_b[chr_mode];
	
	wire [9:0]chr_md_a[4];
	assign chr_md_a[0] = {chr_a[7][6:0], ppu.addr[12:10]};
	assign chr_md_a[1] = !ppu.addr[12] ? {chr_a[3][7:0], ppu.addr[11:10]} : {chr_a[7][7:0], ppu.addr[11:10]};
	assign chr_md_a[2] = 
	ppu.addr[12:11] == 0 ? {chr_a[1][8:0], ppu.addr[10]} : 
	ppu.addr[12:11] == 1 ? {chr_a[3][8:0], ppu.addr[10]} : 
	ppu.addr[12:11] == 2 ? {chr_a[5][8:0], ppu.addr[10]} : {chr_a[7][8:0], ppu.addr[10]}; 
	assign chr_md_a[3][9:0] = chr_a[ppu.addr[12:10]][9:0];
	
	wire [9:0]chr_md_b[4];
	assign chr_md_b[0] = {chr_b[3][6:0], ppu.addr[12:10]};
	assign chr_md_b[1] = {chr_b[3][7:0], ppu.addr[11:10]};
	assign chr_md_b[2] = !ppu.addr[11] ? {chr_b[1][8:0], ppu.addr[10]} : {chr_b[3][8:0], ppu.addr[10]};
	assign chr_md_b[3] = chr_b[ppu.addr[11:10]];
	
	wire map_ppu_oe = ppu.oe ? 0 : vram_ce_exr | vram_ce_fda | vram_ce_fcl | ext_atr_ce;
	wire [7:0]map_ppu_dout = 
	vram_ce_exr & exram_mode[1] ? 8'h00 : 
	ext_atr_ce ? {ext_atr[7:6], ext_atr[7:6], ext_atr[7:6], ext_atr[7:6]} : 
	split_act & ppu_atr_ce ? split_pal : 
	vram_ce_exr ? xram_dout[7:0] : 
	vram_ce_fda ? fill_tile[7:0] : 
	vram_ce_fcl ? {fill_color[1:0], fill_color[1:0], fill_color[1:0], fill_color[1:0]} : 8'h00;
//********************************************************************************* prg mapping

	wire [19:13]prg_addr = !cpu.addr[15] ? ram_bank[3:0] : prg_rom[prg_mode][6:0];
	

	wire [7:0]prg_rom[4];
	assign prg_rom[0][7:0] = {prg_bank[3][7:2], cpu.addr[14:13]};
	assign prg_rom[1][7:0] = !cpu.addr[14] ? {prg_bank[1][7:1], cpu.addr[13]} : {prg_bank[3][7:1], cpu.addr[13]};
	assign prg_rom[2][7:0] = !cpu.addr[14] ? {prg_bank[1][7:1], cpu.addr[13]} : !cpu.addr[13] ? prg_bank[2][7:0] : prg_bank[3][7:0];
	assign prg_rom[3][7:0] = cpu.addr[14:13] == 3 ? prg_bank[3][7:0] : prg_bank[cpu.addr[14:13]][7:0];
	
	wire map_cpu_oe = !cpu.m2 | !cpu.rw ? 0 : xram_oe_cpu | status_oe | mul_oe_lo | mul_oe_hi;
	wire [7:0]map_cpu_dout = 
	status_oe ? {irq_pend, in_frame, 6'd0} :
	mul_oe_lo ? mul_rez[7:0] : 
	mul_oe_hi ? mul_rez[15:8] : 
	xram_oe_cpu ? xram_dout[7:0] : 0;
	
//*********************************************************************************
	//assign irq = irq_pend & irq_on;
	
	wire [1:0]cur_nt = nt_map[ppu.addr[11:10]][1:0];
	
	wire ppu_pat_ce = ppu.addr[13] == 0;
	wire ppu_ntb_ce = ppu.addr[13] == 1 & ppu.addr[9:6] != 4'b1111;
	wire ppu_atr_ce = ppu.addr[13] == 1 & ppu.addr[9:6] == 4'b1111;
	
	//chip selects for vram area
	wire vram_ce_pg0 = ppu.addr[13] & (cur_nt[1:0] == 0 & !split_act);
	wire vram_ce_pg1 = ppu.addr[13] & (cur_nt[1:0] == 1 & !split_act);
	wire vram_ce_exr = ppu.addr[13] & (cur_nt[1:0] == 2 | split_act);
	wire vram_ce_fda = ppu.addr[13] & cur_nt[1:0] == 3 & ppu_ntb_ce;
	wire vram_ce_fcl = ppu.addr[13] & cur_nt[1:0] == 3 & ppu_atr_ce;
	
	wire ext_atr_ce = exram_mode == 1 & ppu_atr_ce;
	wire status_oe = cpu.rw & cpu.addr[15:0] == 16'h5204;
	wire ram_we_on = ram_protect[3:0] == 4'b0110;
	wire ram_bnk_flag = prg_rom[prg_mode][7] == 0 & cpu.addr[15];
	wire mul_oe_lo = cpu.rw & cpu.addr[15:0] == 16'h5205;
	wire mul_oe_hi = cpu.rw & cpu.addr[15:0] == 16'h5206;
	//wire ppu_io_oe = cpu.rw & cpu.addr[15:13] == 3'b001 & cpu.m2 & cpu.addr[2:0] == 7;//{cpu.addr[15:13], 10'd0, cpu.addr[2:0]} == 16'h2007 & cpu.m2;
	
	
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

	
	
	always @(negedge cpu.m2)
	if(sst.act)
	begin
		if(sst.we_reg & sst.addr[7:3] == 0)chr_a[sst.addr[2:0]][7:0] 	<= sst.dato;
		if(sst.we_reg & sst.addr[7:2] == 2)chr_b[sst.addr[1:0]][7:0] 	<= sst.dato;
		if(sst.we_reg & sst.addr[7:2] == 3)prg_bank[sst.addr[1:0]] 		<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 16){exram_mode[1:0], chr_mode[1:0], prg_mode[1:0], chr_hi[1:0]} 		<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 17){nt_map[3][1:0], nt_map[2][1:0], nt_map[1][1:0], nt_map[0][1:0]} 	<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 18)fill_tile 		<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 19)fill_color 		<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 20)ram_bank 		<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 21)irq_val 			<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 22)ram_protect 	<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 23)mul_a 			<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 24)mul_b 			<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 25)mul_rez[15:8] 	<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 26)mul_rez[7:0] 	<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 27)split_mode 		<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 28)split_scrl 		<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 29)split_bank 		<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 30){last_set, bgr_on, sprite_mode, irq_on} <= sst.dato;
	end
		else
	if(mai.map_rst)
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
		
		if(!cpu.rw & cpu.addr[15:0] == 16'h2000)sprite_mode 		<= cpu.data[5];
		if(!cpu.rw & cpu.addr[15:0] == 16'h2001)bgr_on 				<= cpu.data[3] | cpu.data[4] ;
		
		if(!cpu.rw & cpu.addr[15:0] == 16'h5100)prg_mode[1:0] 	<= cpu.data[1:0];
		if(!cpu.rw & cpu.addr[15:0] == 16'h5101)chr_mode[1:0] 	<= cpu.data[1:0];
		if(!cpu.rw & cpu.addr[15:0] == 16'h5102)ram_protect[1:0] <= cpu.data[1:0];
		if(!cpu.rw & cpu.addr[15:0] == 16'h5103)ram_protect[3:2] <= cpu.data[1:0];
		if(!cpu.rw & cpu.addr[15:0] == 16'h5104)exram_mode[1:0] 	<= cpu.data[1:0];
		if(!cpu.rw & cpu.addr[15:0] == 16'h5105){nt_map[3][1:0], nt_map[2][1:0], nt_map[1][1:0], nt_map[0][1:0]} <= cpu.data[7:0];
		if(!cpu.rw & cpu.addr[15:0] == 16'h5106)fill_tile[7:0] 	<= cpu.data[7:0];
		if(!cpu.rw & cpu.addr[15:0] == 16'h5107)fill_color[1:0] 	<= cpu.data[1:0];
		if(!cpu.rw & cpu.addr[15:0] == 16'h5113)ram_bank[3:0] 	<= cpu.data[3:0];
		
		if(!cpu.rw & cpu.addr[15:0] == 16'h5114)prg_bank[0][7:0] <= cpu.data[7:0];
		if(!cpu.rw & cpu.addr[15:0] == 16'h5115)prg_bank[1][7:0] <= cpu.data[7:0];
		if(!cpu.rw & cpu.addr[15:0] == 16'h5116)prg_bank[2][7:0] <= cpu.data[7:0];
		if(!cpu.rw & cpu.addr[15:0] == 16'h5117)prg_bank[3][7:0] <= {1'b1, cpu.data[6:0]};
		
		//if(!cpu.rw & {cpu.addr[15:2], 2'd0} == 16'h5114)prg_bank[cpu.addr[1:0]] <= cpu.addr[1:0] == 3 ? {1'b1, cpu.data[6:0]} : cpu.data[7:0];
		if(!cpu.rw & {cpu.addr[15:3], 3'd0} == 16'h5120){last_set, chr_a[cpu.addr[2:0]][9:0]} <= {1'b0, chr_hi[1:0], cpu.data[7:0]};
		if(!cpu.rw & {cpu.addr[15:2], 2'd0} == 16'h5128){last_set, chr_b[cpu.addr[1:0]][9:0]} <= {1'b1, chr_hi[1:0], cpu.data[7:0]};
		if(!cpu.rw & cpu.addr[15:0] == 	      16'h5130)chr_hi[1:0] <= cpu.data[1:0];
		
		if(!cpu.rw & cpu.addr[15:0] == 16'h5200)split_mode[7:0] 	<= cpu.data[7:0];
		if(!cpu.rw & cpu.addr[15:0] == 16'h5201)split_scrl[7:0] 	<= cpu.data[7:0];
		if(!cpu.rw & cpu.addr[15:0] == 16'h5202)split_bank[7:0] 	<= cpu.data[7:0];
		
		if(!cpu.rw & cpu.addr[15:0] == 16'h5203)irq_val[7:0] 		<= cpu.data[7:0];
		if(!cpu.rw & cpu.addr[15:0] == 16'h5204)irq_on 				<= cpu.data[7];

		if(!cpu.rw & cpu.addr[15:0] == 16'h5205)
		begin
			mul_a 	<= cpu.data[7:0];
			mul_rez 	<= cpu.data * mul_b;
		end
		
		if(!cpu.rw & cpu.addr[15:0] == 16'h5206)
		begin
			mul_b 	<= cpu.data[7:0];
			mul_rez 	<= cpu.data * mul_a;
		end
		
		
	end
	
	
//********************************************************************************* exram	
	wire [7:0]xram_dout;
	
	wire [9:0]xram_addr_ppu = !split_act ? ppu.addr[9:0] : split_addr[9:0];//{(y_pos[7:3] + split_scrl[6:3]), ppu.addr[4:0] };
	wire [9:0]xram_addr_rw = sst.act ? sst.addr[9:0] : exram_mode[1] ? cpu.addr[9:0] : xram_addr_ppu[9:0];//ppu+cpu rd and ppu wr
	wire [9:0]xram_addr_wo = sst.act ? sst.addr[9:0] : cpu.addr[9:0];//cpu wr only
	
	wire xram_we_ppu = !sst.act & vram_ce_exr & !ppu.we & !exram_mode[1];
	
	wire xram_ce_cpu = {cpu.addr[15:10], 10'd0} == 16'h5C00;
	wire xram_oe_cpu = xram_ce_cpu & cpu.rw & exram_mode[1] == 1;
	wire xram_we_cpu = sst.act ? xram_we_sst : xram_ce_cpu & !cpu.rw & exram_mode[1:0] != 2'b11;
	

	xram xram_inst(
	
		.clk_a(!cpu.m2), 
		.din_a(cpu.data[7:0]), 
		.addr_a(xram_addr_wo[9:0]), 
		.we_a(xram_we_cpu), 
		
		.clk_b(mai.clk),
		.din_b(ppu.data[7:0]), 
		.addr_b(xram_addr_rw[9:0]), 
		.we_b(xram_we_ppu), 
		.dout_b(xram_dout[7:0])
	);
	
	reg [7:0]ext_atr;
	reg [3:0]nt_rd_st;
	always @(posedge mai.clk)
	begin
		nt_rd_st[3:0] <= {nt_rd_st[2:0], (ppu_ntb_ce & !ppu.oe)};
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
	
	always @(posedge ppu.oe, negedge in_frame)
	if(!in_frame)
	begin
		y_pos <= {split_scrl[7:3], 3'd0};
	end
		else
	begin
		if(line_ctr == 128)y_pos <=  y_pos + 1;
		x_pos <= spr_fetch ? 0 : line_start ? x_pos - 1 : x_pos + 1;
	end

//********************************************************************************* irq handler
	
	reg irq_pend;
	reg [7:0]irq_ctr;
	reg irq_ack;
	always @(negedge cpu.m2)irq_ack = cpu.rw & cpu.addr[15:0] == 16'h5204;
	
	
	always @(negedge ppu.oe, negedge in_frame)
	if(!in_frame)
	begin
		irq_ctr <= 0;
	end
		else
	if(addr_eq & addr_eq_st)//line_start
	begin
		irq_ctr <= irq_ctr + 1;
	end
	
	always @(negedge ppu.oe, negedge in_frame, posedge irq_ack)//changed
	if(!in_frame)
	begin
		irq_pend <= 0;
	end
		else
	if(irq_ack)irq_pend <= 0;
		else
	if(addr_eq & addr_eq_st)//line_start
	begin
		if(irq_ctr == irq_val)irq_pend <= 1;
	end

	
//********************************************************************************* scanline handler	
	wire spr_fetch = line_ctr > 127 & line_ctr < 159;
	wire in_frame = in_frame_ctr != 0 & bgr_on;
	wire addr_eq = ppu_addr_st == ppu.addr & ppu_addr_st[13];
	
	reg [7:0]line_ctr;
	reg [13:0]ppu_addr_st;
	reg [3:0]in_frame_ctr;
	reg line_start;
	reg addr_eq_st;
	
	
	
	always @(negedge cpu.m2, negedge ppu.oe)
	if(!ppu.oe)in_frame_ctr <= 4;
		else
	if(in_frame_ctr != 0)in_frame_ctr <= in_frame_ctr - 1;

	
	always @(negedge ppu.oe)
	begin
	
		ppu_addr_st[13:0] <= ppu.addr[13:0];
		addr_eq_st 			<= addr_eq;
		
		line_start 			<= addr_eq & addr_eq_st;
		line_ctr 			<= line_start ? 0 : line_ctr + 1;//fixed blocked statement

	end

//*********************************************************************************
	
	
	wire [9:0]vol;
	
	snd_mmc5 snd_inst(
		
		.cpu(cpu),
		.map_rst(mai.map_rst),
		.vol(vol)
	);

endmodule


module xram(

	input  clk_a,
	input  [7:0]din_a,
	input  [9:0]addr_a,
	input  we_a,
	output reg [7:0]dout_a,
	
	input  clk_b,
	input  [7:0]din_b,
	input  [9:0]addr_b,
	input  we_b,
	output reg [7:0]dout_b
);

	reg [7:0]ram[1024];
	
	
	always @(posedge clk_a)
	begin
		dout_a <= we_a ? din_a : ram[addr_a];
		if(we_a)ram[addr_a] <= din_a;
	end
	
	always @(posedge clk_b)
	begin
		dout_b <= we_b ? din_b : ram[addr_b];
		if(we_b)ram[addr_b] <= din_b;
	end
	
endmodule

