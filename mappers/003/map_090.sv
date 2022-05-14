
module map_090(

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
	assign mao.sst_di[7:0] =
	sst.addr[7:3] == 0  	? chr_bank[sst.addr[2:0]][7:0] : 
	sst.addr[7:3] == 1  	? chr_bank[sst.addr[2:0]][15:8] : 
	
	sst.addr[7:0] == 16 	? acc : 
	sst.addr[7:0] == 17 	? acc_test : 
	sst.addr[7:0] == 18 	? irq_mod : 
	sst.addr[7:0] == 19 	? irq_pre : 
	sst.addr[7:0] == 20 	? irq_ctr : 
	sst.addr[7:0] == 21 	? irq_xor : 
	
	sst.addr[7:2] == 8  	? reg_B00X[sst.addr[1:0]][7:0] : 
	sst.addr[7:2] == 9  	? reg_B00X[sst.addr[1:0]][15:8] : 
	sst.addr[7:2] == 10 	? reg_800X[sst.addr[1:0]] : 
	sst.addr[7:0] == 44 	? reg_D000 : 
	sst.addr[7:0] == 45 	? reg_D001 : 
	sst.addr[7:0] == 46 	? reg_D002 : 
	sst.addr[7:0] == 47 	? reg_D003 : 
	sst.addr[7:0] == 48 	? mul_arg[0] : 
	sst.addr[7:0] == 49 	? mul_arg[1] : 
	sst.addr[7:0] == 50 	? mul_rez[7:0] : 
	sst.addr[7:0] == 51 	? mul_rez[15:8] : 
	sst.addr[7:0] == 52 	? {mul_req, irq_en, irq_pend, irq_en_st} : 
	sst.addr[7:0] == 127 ? cfg.map_idx : 8'hff;
//************************************************************* mapper-controlled pins
	assign srm.ce				= ce_60xx & reg_D000[7] == 1;
	assign srm.oe				= cpu.rw;
	assign srm.we				= !cpu.rw;
	assign srm.addr[12:0]	= cpu.addr[12:0];
	
	assign prg.ce				= cpu.addr[15] | (ce_60xx &  reg_D000[7] == 1);
	assign prg.oe 				= cpu.rw;
	assign prg.we				= 0;
	assign prg.addr[12:0]	= cpu.addr[12:0];
	assign prg.addr[20:13]	= prg_addr[20:13];
	
	assign chr.ce 				= mao.ciram_ce;
	assign chr.oe 				= !ppu.oe;
	assign chr.we 				= cfg.chr_ram ? !ppu.we & mao.ciram_ce : 0;
	assign chr.addr[9:0]		= ppu.addr[9:0];
	assign chr.addr[20:10]	= chr_addr[20:10];

	
	//A10-Vmir, A11-Hmir
	assign mao.ciram_a10 	= ciram_a10;
	assign mao.ciram_ce 		= ciram_ce;
	
	assign mao.irq				= irq_pend;
	assign int_cpu_oe			= map_cpu_oe;
	assign int_cpu_data		= map_cpu_dout;
//************************************************************* mapper implementation
	wire ce_60xx  = {cpu.addr[15:13], 13'd0} == 16'h6000;
	wire [1:0]dip	= 2'b00;
//************************************************************* mirroring
	
	wire rom_ntb		 = reg_D000[5];
	wire rom_ntb_sel	 = reg_D000[6];
	wire [1:0]mir_mode = reg_D001[1:0];
	wire mir_ext		 = reg_D001[3];//(reg_D001[3] & map_idx != 90) | map_idx == 211;
	
	
	wire ciram_a10 = 
	mir_ext					? reg_B00X[ppu.addr[11:10]][0] : 
	mir_mode == 0 			? ppu.addr[10] : 
	mir_mode == 1 			? ppu.addr[11] : mir_mode[0];
	
	
	wire ciram_ce = 
	!rom_ntb				? !ppu.addr[13] :
	ppu.addr[13] == 0 ? 1 :
	rom_ntb_sel			? 1 ://rom nt for whole vram
	(reg_D002[7] == reg_B00X[ppu.addr[11:10]][7] ? 0 : 1);
	
	
//************************************************************* prg mapping
	
	wire [2:0]prg_mode = reg_D000[2:0];
		
	wire [6:0]prg_map[8];
	
	assign prg_map[0] = cpu.addr[15] 	== 'b1	? {5'h1f, cpu.addr[14:13]} : prg_map[4];//32K
	assign prg_map[1] = cpu.addr[15:12] == 'b11	? {6'h3f, cpu.addr[13]} 	: prg_map[5];//16K
	assign prg_map[2] = cpu.addr[15:13] == 'b111	? 7'h7f 							: prg_map[6];//8K
	assign prg_map[3] = cpu.addr[15:13] == 'b111	? 7'h7f 							: prg_map[7];//8K reversed
	
	assign prg_map[4] = {reg_800X[3][4:0], cpu.addr[14:13]};//32K
	assign prg_map[5] = !cpu.addr[14] ? {reg_800X[1][5:0], cpu.addr[13]} : {reg_800X[3][5:0], cpu.addr[13]};//16K
	assign prg_map[6] = reg_800X[cpu.addr[14:13]][6:0];//8K
	assign prg_map[7] = {prg_map[6][0], prg_map[6][1], prg_map[6][2], prg_map[6][3], prg_map[6][4], prg_map[6][5], prg_map[6][6]};//8K reversed
	
	wire [20:13]prg_addr;
	assign prg_addr[18:13] 	= prg_map[prg_mode][5:0];
	assign prg_addr[20:19] 	= reg_D003[2:1];
	
//************************************************************* chr mapping
	
	wire [1:0]chr_mode 	= reg_D000[4:3];
	wire mmc_mode 			= reg_D003[7];
	
	
	wire [8:0]chr_map[4];
	
	assign chr_map[0] = {chr_bank[0][5:0], ppu.addr[12:10]};
	assign chr_map[1] = mmc_mode ? chr_4k_mmc : chr_4k_std;
	assign chr_map[2] = {chr_bank[{ppu.addr[12:11], 1'b0}][7:0], ppu.addr[10]};
	assign chr_map[3] = chr_bank[ppu.addr[12:10]][8:0];
	
	wire [8:0]chr_4k_std = {chr_bank[{ppu.addr[12], 2'd0}][6:0], ppu.addr[11:10]};
	wire [8:0]chr_4k_mmc = mmc_latch[ppu.addr[12]] == 0 ? chr_4k_std : 
	{chr_bank[{ppu.addr[12], 2'd0}+2][6:0], ppu.addr[11:10]};
	
	wire chr_a18 = !reg_D003[5] ? reg_D003[0] : chr_map[chr_mode][8];
	
	wire [20:10]chr_addr;
	assign chr_addr[20:10] 	= 
	!ppu.addr[13] ? {reg_D003[4:3], chr_a18, chr_map[chr_mode][7:0]} : reg_B00X[ppu.addr[11:10]][8:0];
	
//************************************************************* cpu do
	
	
	wire mul_ce = cpu.addr == 16'h5800 | cpu.addr == 16'h5801;
	wire acc_ce = cpu.addr == 16'h5802;
	wire act_ce = cpu.addr == 16'h5803;
	wire dip_ce = cpu.addr == 16'h5000 | cpu.addr == 16'h5400;
	
	wire map_cpu_oe = cpu.rw & (mul_ce | acc_ce | act_ce | dip_ce);
	
	wire [7:0]map_cpu_dout = 
	cpu.addr[15:0] == 16'h5800 ? mul_rez[7:0]  : 
	cpu.addr[15:0] == 16'h5801 ? mul_rez[15:8] : 
	cpu.addr[15:0] == 16'h5802 ? acc : 
	cpu.addr[15:0] == 16'h5803 ? acc_test : 
	dip_ce 							? {dip[1:0], 6'h00} :
										  8'hff;	
										  
//************************************************************* irq
	
	
	wire [1:0]irq_src 	= irq_mod[1:0];
	wire [7:0]irq_pmask 	= irq_mod[2] == 0 ? 8'hff : 8'h07;
	wire [1:0]irq_dir 	= irq_mod[7:6];
	
	
	wire irq_tick = 
	irq_src == 0 ? m2_pe 	 :			//m2
	irq_src == 1 ? ppu_12_pe : 		//a12 rise
	irq_src == 2 ? ppu_oe_ne : 		//ppu oe
						m2_pe & !cpu.rw; 	//cpu wr

	
//************************************************************* regs
	
	
	reg [7:0]mul_arg[2];
	reg [15:0]mul_rez;
	reg mul_req;
	reg [7:0]acc;
	reg [7:0]acc_test;
	
	reg [6:0]reg_800X[4];//prg bank
	reg [15:0]chr_bank[8];
	reg [15:0]reg_B00X[4];//nametable
	
	reg irq_en, irq_en_st,irq_pend;
	reg [7:0]irq_mod, irq_pre, irq_ctr, irq_xor;
	
	reg [7:0]reg_D000;
	reg [3:0]reg_D001;
	reg [7:0]reg_D002;//[7:6]
	reg [7:0]reg_D003;
	
	
//************************************************************* oe/we sync stuff
	wire ppu_oe_ne = ppu_oe_st == 'b10000000;
	wire ppu_12_pe = ppu_12_st == 'b01111111;
	wire m2_pe 		= cpu.m3;//m2_st 		== 'b01111111;
	
	reg [1:0]mmc_latch;
	reg [7:0]ppu_oe_st;
	reg [7:0]ppu_12_st;
	reg [7:0]m2_st;
	
	always @(posedge mai.clk)
	begin
		
		ppu_oe_st <= {ppu_oe_st[6:0], ppu.oe};
		ppu_12_st <= {ppu_12_st[6:0], ppu.addr[12]};
		m2_st		 <= {m2_st[6:0], cpu.m2};
		
		//mmc_latch[ppu.addr[12]]
		
		//mmc4-like chr switch
		if(ppu_oe_ne)
		case({ppu.addr[13:3], 3'd0})
			'h0FD8:mmc_latch[0] <= 0;
			'h1FD8:mmc_latch[1] <= 0;
			'h0FE8:mmc_latch[0] <= 1;
			'h1FE8:mmc_latch[1] <= 1;
		endcase
		
		
	end
	
	
//************************************************************* mapper regs and logic
	always @(posedge mai.clk)
	if(mai.map_rst)
	begin
		reg_D000[2] <= 0;
		irq_pend		<= 0;
	end
		else
	if(sst.act)
	begin
		if(m2_pe & sst.we_reg)
		begin
			if(sst.addr[7:3] == 0)chr_bank[sst.addr[2:0]][7:0] 	<= sst.dato;
			if(sst.addr[7:3] == 1)chr_bank[sst.addr[2:0]][15:8] 	<= sst.dato;

			if(sst.addr[7:0] == 16)acc 		<= sst.dato;
			if(sst.addr[7:0] == 17)acc_test 	<= sst.dato;
			if(sst.addr[7:0] == 18)irq_mod 	<= sst.dato;
			if(sst.addr[7:0] == 19)irq_pre 	<= sst.dato;
			if(sst.addr[7:0] == 20)irq_ctr 	<= sst.dato;
			if(sst.addr[7:0] == 21)irq_xor 	<= sst.dato;

			if(sst.addr[7:2] == 8)reg_B00X[sst.addr[1:0]][7:0] 	<= sst.dato;
			if(sst.addr[7:2] == 9)reg_B00X[sst.addr[1:0]][15:8] 	<= sst.dato;
			if(sst.addr[7:2] == 10)reg_800X[sst.addr[1:0]] 			<= sst.dato;
			if(sst.addr[7:0] == 44)reg_D000 			<= sst.dato;
			if(sst.addr[7:0] == 45)reg_D001 			<= sst.dato;
			if(sst.addr[7:0] == 46)reg_D002 			<= sst.dato;
			if(sst.addr[7:0] == 47)reg_D003 			<= sst.dato;
			if(sst.addr[7:0] == 48)mul_arg[0] 		<= sst.dato;
			if(sst.addr[7:0] == 49)mul_arg[1] 		<= sst.dato;
			if(sst.addr[7:0] == 50)mul_rez[7:0] 	<= sst.dato;
			if(sst.addr[7:0] == 51)mul_rez[15:8] 	<= sst.dato;
			if(sst.addr[7:0] == 52){mul_req, irq_en, irq_pend, irq_en_st} <= sst.dato;
		end
	end
		else
	begin
	
//*************************************************************	regs
		if(m2_pe)
		begin
		
			//mul and accum
			if(!cpu.rw)
			case({cpu.addr[15:11], 9'd0, cpu.addr[1:0]})
				16'h5800:begin
					mul_arg[0] 	<= cpu.data;
					mul_req 		<= 1;
				end
				16'h5801:begin
					mul_arg[1] 	<= cpu.data;
					mul_req 		<= 1;
				end
				16'h5802:begin
					acc 			<= cpu.data + acc;
				end
				16'h5803:begin
					acc 			<= 0;
					acc_test		<= cpu.data;
				end
			endcase
			
			
			//banking
			if(!cpu.rw)
			case({cpu.addr[15:11], 11'd0})
				16'h8000:begin
					reg_800X[cpu.addr[1:0]]			<= cpu.data;
				end
				16'h9000:begin
					chr_bank[cpu.addr[2:0]][7:0] 	<= cpu.data;
				end
				16'hA000:begin
					chr_bank[cpu.addr[2:0]][15:8] <= cpu.data;
				end
				16'hB000:begin
					if(cpu.addr[2] == 0)reg_B00X[cpu.addr[1:0]][7:0]	<= cpu.data;
					if(cpu.addr[2] == 1)reg_B00X[cpu.addr[1:0]][15:8]	<= cpu.data;
				end
			endcase
			
			
			//irq
			if(!cpu.rw)
			case({cpu.addr[15:11], 8'd0, cpu.addr[2:0]})
				16'hC000:irq_en	<= cpu.data[0];
				16'hC001:irq_mod	<= cpu.data;
				16'hC002:irq_en	<= 0;
				16'hC003:irq_en	<= 1;
				16'hC004:irq_pre 	<= cpu.data ^ irq_xor;
				16'hC005:irq_ctr 	<= cpu.data ^ irq_xor;
				16'hC006:irq_xor 	<= cpu.data;
			endcase
			
			
			//mode regs
			if(!cpu.rw)
			case({cpu.addr[15:11], 9'd0, cpu.addr[1:0]})
				16'hD000:reg_D000 		<= cpu.data;
				16'hD001:reg_D001 		<= cpu.data;
				16'hD002:reg_D002[7:6] 	<= cpu.data[7:6];
				16'hD003:reg_D003			<= cpu.data;
			endcase

		
//************************************************************* mul
			if(mul_req)
			begin
				mul_rez <= mul_arg[0] * mul_arg[1];
				mul_req <= 0;
			end
		
		end
		
//************************************************************* irq
		irq_en_st <= irq_en;
		
		if(irq_en == 0 & irq_en_st == 1)
		begin
			irq_pre 	<= 0;
			irq_pend	<= 0;
		end
			else
		if(irq_en & irq_tick)
		begin
		
			if(irq_dir == 1)irq_pre <= irq_pre + 1;
			if(irq_dir == 2)irq_pre <= irq_pre - 1;
			
			if(irq_dir == 1 & ((irq_pre + 1) & irq_pmask) == 0)
			begin
				irq_ctr <= irq_ctr + 1;
				if(irq_ctr == 8'hff)irq_pend <= 1;
			end
			
			if(irq_dir == 2 & ((irq_pre - 1) & irq_pmask) == irq_pmask)
			begin
				irq_ctr <= irq_ctr - 1;
				if(irq_ctr == 8'h00)irq_pend <= 1;
			end
		end
		
		
	end
	
endmodule
