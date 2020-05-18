
`include "../base/defs.v"


module map_219
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
	
	{ss_addr[7:3], 3'd0} == 32  ? ext_chr[ss_addr[2:0]] : 
	{ss_addr[7:2], 2'd0} == 40  ? ext_prg[ss_addr[1:0]] : 
	ss_addr[7:0] == 44 ? ext_reg_sel :
	ss_addr[7:0] == 45 ? chr_sel :
	ss_addr[7:0] == 46 ? {set_prg, set_chr} :
	
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = {cpu_addr[15:13], 13'd0} == 16'h6000;
	assign ram_we = !cpu_rw & ram_ce;
	assign rom_ce = cpu_addr[15];
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram & !ppu_we;
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = !mir_mod ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	
	
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

//***************************************************************************** extension
	assign prg_addr[12:0] = cpu_addr[12:0];
	assign prg_addr[18:13] = {ext_prg[cpu_addr[14:13]][3:0]};
	
	assign chr_addr[9:0] = ppu_addr[9:0];
	assign chr_addr[17:10] =  ext_chr[ppu_addr[12:10]][7:0];
	
	wire [15:0]ext_reg_addr = cpu_addr[15:0] & 16'hE003;
	
	
	reg [3:0]ext_prg[4];
	reg [7:0]ext_chr[8];
	reg [7:0]ext_reg_sel;
	reg [3:0]chr_sel;
	reg set_prg, set_chr;
	
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & {ss_addr[7:3], 3'd0} == 32) ext_chr[ss_addr[2:0]] <= cpu_dat;
		if(ss_we & {ss_addr[7:2], 2'd0} == 40) ext_prg[ss_addr[1:0]] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 44)ext_reg_sel <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 45)chr_sel <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 46){set_prg, set_chr} <= cpu_dat;
	end
		else
	if(map_rst)
	begin
		
		ext_prg[0] <= 4'hc;
		ext_prg[1] <= 4'hd;
		ext_prg[2] <= 4'he;
		ext_prg[3] <= 4'hf;
		
		ext_chr[0] <= 0;
		ext_chr[1] <= 1;
		ext_chr[2] <= 2;
		ext_chr[3] <= 3;
		ext_chr[4] <= 4;
		ext_chr[5] <= 5;
		ext_chr[6] <= 6;
		ext_chr[7] <= 7;
				
		set_prg <= 0;
		set_chr <= 0;
	end
		else
	if(!cpu_rw)
	begin
		
		
		if(ext_reg_addr[15:0] == 16'h8000)
		begin
			ext_reg_sel[7:0] <= cpu_dat[7:0];
			set_prg <= 0;
			set_chr <= 1;
		end
		
		if(ext_reg_addr[15:0] == 16'h8002)
		begin
			ext_reg_sel[7:0] <= cpu_dat[7:0];
			set_prg <= 1;
			set_chr <= 0;
		end
		
		
		if(ext_reg_addr[15:0] == 16'h8001 & set_prg)
		begin
			if(ext_reg_sel == 8'h26)ext_prg[0][3:0] <= {cpu_dat[2], cpu_dat[3], cpu_dat[4], cpu_dat[5]};
			if(ext_reg_sel == 8'h25)ext_prg[1][3:0] <= {cpu_dat[2], cpu_dat[3], cpu_dat[4], cpu_dat[5]};
			if(ext_reg_sel == 8'h24)ext_prg[2][3:0] <= {cpu_dat[2], cpu_dat[3], cpu_dat[4], cpu_dat[5]};
			if(ext_reg_sel == 8'h23)ext_prg[3][3:0] <= {cpu_dat[2], cpu_dat[3], cpu_dat[4], cpu_dat[5]};
		end
		
		
		if(ext_reg_addr[15:0] == 16'h8001 & set_chr)
		begin
			if(ext_reg_sel == 8'h08 | ext_reg_sel == 8'h0A | ext_reg_sel == 8'h0E)chr_sel[3:0] <= cpu_dat[3:0];
			if(ext_reg_sel == 8'h12 | ext_reg_sel == 8'h16 | ext_reg_sel == 8'h1A | ext_reg_sel == 8'h1E)chr_sel[3:0] <= cpu_dat[3:0];
		end
		
		if(ext_reg_addr[15:0] == 16'h8001 & set_chr)
		begin
		
			if(ext_reg_sel == 8'h09)ext_chr[0] <= {chr_sel[3:0], cpu_dat[4:2], 1'b0};
			if(ext_reg_sel == 8'h0B)ext_chr[1] <= {chr_sel[3:0], cpu_dat[4:2], 1'b1};
			
			if(ext_reg_sel == 8'h0C | ext_reg_sel == 8'h0D)ext_chr[2] <= {chr_sel[3:0], cpu_dat[4:2], 1'b0};
			if(ext_reg_sel == 8'h0F)ext_chr[3] <= {chr_sel[3:0], cpu_dat[4:2], 1'b1};
			
			if(ext_reg_sel == 8'h10 | ext_reg_sel == 8'h11)ext_chr[4] <= {chr_sel[3:0], cpu_dat[4:1]};
			if(ext_reg_sel == 8'h14 | ext_reg_sel == 8'h15)ext_chr[5] <= {chr_sel[3:0], cpu_dat[4:1]};
			if(ext_reg_sel == 8'h18 | ext_reg_sel == 8'h19)ext_chr[6] <= {chr_sel[3:0], cpu_dat[4:1]};
			if(ext_reg_sel == 8'h1C | ext_reg_sel == 8'h1D)ext_chr[7] <= {chr_sel[3:0], cpu_dat[4:1]};

		end
		
	end
	
endmodule
