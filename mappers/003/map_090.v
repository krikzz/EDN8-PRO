
`include "../base/defs.v"

module map_090
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
	ss_addr[7:3] == 0  ? chr_bank[ss_addr[2:0]][7:0] : 
	ss_addr[7:3] == 1  ? chr_bank[ss_addr[2:0]][15:8] : 
	
	ss_addr[7:0] == 16 ? acc : 
	ss_addr[7:0] == 17 ? acc_test : 
	ss_addr[7:0] == 18 ? irq_mod : 
	ss_addr[7:0] == 19 ? irq_pre : 
	ss_addr[7:0] == 20 ? irq_ctr : 
	ss_addr[7:0] == 21 ? irq_xor : 
	
	ss_addr[7:2] == 8  ? reg_B00X[ss_addr[1:0]][7:0] : 
	ss_addr[7:2] == 9  ? reg_B00X[ss_addr[1:0]][15:8] : 
	ss_addr[7:2] == 10 ? reg_800X[ss_addr[1:0]] : 
	ss_addr[7:0] == 44 ? reg_D000 : 
	ss_addr[7:0] == 45 ? reg_D001 : 
	ss_addr[7:0] == 46 ? reg_D002 : 
	ss_addr[7:0] == 47 ? reg_D003 : 
	ss_addr[7:0] == 48 ? mul_arg[0] : 
	ss_addr[7:0] == 49 ? mul_arg[1] : 
	ss_addr[7:0] == 50 ? mul_rez[7:0] : 
	ss_addr[7:0] == 51 ? mul_rez[15:8] : 
	ss_addr[7:0] == 52 ? {mul_req, irq_en, irq_pend, irq_en_st} : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_we = !cpu_rw & ram_ce;
	assign ram_ce = ce_60xx & reg_D000[7] == 1;
	assign rom_ce = cpu_addr[15] | (ce_60xx &  reg_D000[7] == 1);
	assign chr_ce = ciram_ce;
	assign chr_we = 0;
	wire ce_60xx  = {cpu_addr[15:13], 13'd0} == 16'h6000;
	
	wire [1:0]dip	= 2'b00;
	
	//************************************************************* mirroring
	
	wire rom_ntb		 = reg_D000[5];
	wire rom_ntb_sel	 = reg_D000[6];
	wire [1:0]mir_mode = reg_D001[1:0];
	wire mir_ext		 = reg_D001[3];//(reg_D001[3] & map_idx != 90) | map_idx == 211;
	
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = 
	//(rom_ntb | mir_ext) 	? reg_B00X[ppu_addr[11:10]][0] : 
	mir_ext					? reg_B00X[ppu_addr[11:10]][0] : 
	mir_mode == 0 			? ppu_addr[10] : 
	mir_mode == 1 			? ppu_addr[11] : mir_mode[0];
	
	
	assign ciram_ce = 
	!rom_ntb				? !ppu_addr[13] :
	ppu_addr[13] == 0 ? 1 :
	rom_ntb_sel			? 1 ://rom nt for whole vram
	(reg_D002[7] == reg_B00X[ppu_addr[11:10]][7] ? 0 : 1);
	
	
	//************************************************************* prg mapping
	
	wire [2:0]prg_mode = reg_D000[2:0];
		
	wire [6:0]prg_map[8];
	
	assign prg_map[0] = cpu_addr[15] 	== 'b1	? {5'h1f, cpu_addr[14:13]} : prg_map[4];//32K
	assign prg_map[1] = cpu_addr[15:12] == 'b11	? {6'h3f, cpu_addr[13]} 	: prg_map[5];//16K
	assign prg_map[2] = cpu_addr[15:13] == 'b111	? 7'h7f 							: prg_map[6];//8K
	assign prg_map[3] = cpu_addr[15:13] == 'b111	? 7'h7f 							: prg_map[7];//8K reversed
	
	assign prg_map[4] = {reg_800X[3][4:0], cpu_addr[14:13]};//32K
	assign prg_map[5] = !cpu_addr[14] ? {reg_800X[1][5:0], cpu_addr[13]} : {reg_800X[3][5:0], cpu_addr[13]};//16K
	assign prg_map[6] = reg_800X[cpu_addr[14:13]][6:0];//8K
	assign prg_map[7] = {prg_map[6][0], prg_map[6][1], prg_map[6][2], prg_map[6][3], prg_map[6][4], prg_map[6][5], prg_map[6][6]};//8K reversed
	
	
	assign prg_addr[12:0] 	= cpu_addr[12:0];
	assign prg_addr[18:13] 	= prg_map[prg_mode][5:0];
	assign prg_addr[20:19] 	= reg_D003[2:1];
	
	//************************************************************* chr mapping
	
	wire [1:0]chr_mode 	= reg_D000[4:3];
	wire mmc_mode 			= reg_D003[7];
	
	
	wire [8:0]chr_map[4];
	
	assign chr_map[0] = {chr_bank[0][5:0], ppu_addr[12:10]};
	assign chr_map[1] = mmc_mode ? chr_4k_mmc : chr_4k_std;
	assign chr_map[2] = {chr_bank[{ppu_addr[12:11], 1'b0}][7:0], ppu_addr[10]};
	assign chr_map[3] = chr_bank[ppu_addr[12:10]][8:0];
	
	wire [8:0]chr_4k_std = {chr_bank[{ppu_addr[12], 2'd0}][6:0], ppu_addr[11:10]};
	wire [8:0]chr_4k_mmc = mmc_latch[ppu_addr[12]] == 0 ? chr_4k_std : 
	{chr_bank[{ppu_addr[12], 2'd0}+2][6:0], ppu_addr[11:10]};
	
	wire chr_a18 = !reg_D003[5] ? reg_D003[0] : chr_map[chr_mode][8];
	
	assign chr_addr[9:0] 	= ppu_addr[9:0];
	assign chr_addr[20:10] 	= 
	!ppu_addr[13] ? {reg_D003[4:3], chr_a18, chr_map[chr_mode][7:0]} : reg_B00X[ppu_addr[11:10]][8:0];
	
	//************************************************************* cpu do
	
	
	wire mul_ce = cpu_addr == 16'h5800 | cpu_addr == 16'h5801;
	wire acc_ce = cpu_addr == 16'h5802;
	wire act_ce = cpu_addr == 16'h5803;
	wire dip_ce = cpu_addr == 16'h5000 | cpu_addr == 16'h5400;
	
	assign map_cpu_oe = cpu_rw & (mul_ce | acc_ce | act_ce | dip_ce);
	
	assign map_cpu_dout[7:0] = 
	cpu_addr[15:0] == 16'h5800 ? mul_rez[7:0]  : 
	cpu_addr[15:0] == 16'h5801 ? mul_rez[15:8] : 
	cpu_addr[15:0] == 16'h5802 ? acc : 
	cpu_addr[15:0] == 16'h5803 ? acc_test : 
	dip_ce 							? {dip[1:0], 6'h00} :
										  8'hff;	
										  
	//************************************************************* irq
	
	assign irq = irq_pend;
	
	wire [1:0]irq_src 	= irq_mod[1:0];
	wire [7:0]irq_pmask 	= irq_mod[2] == 0 ? 8'hff : 8'h07;
	wire [1:0]irq_dir 	= irq_mod[7:6];
	
	
	wire irq_tick = 
	irq_src == 0 ? m2_pe 	 :			//m2
	irq_src == 1 ? ppu_12_pe : 		//a12 rise
	irq_src == 2 ? ppu_oe_ne : 		//ppu oe
						m2_pe & !cpu_rw; 	//cpu wr

	
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
	wire m2_pe 		= m2_st 		== 'b01111111;
	
	reg [1:0]mmc_latch;
	reg [7:0]ppu_oe_st;
	reg [7:0]ppu_12_st;
	reg [7:0]m2_st;
	
	always @(negedge clk)
	begin
		
		ppu_oe_st <= {ppu_oe_st[6:0], ppu_oe};
		ppu_12_st <= {ppu_12_st[6:0], ppu_addr[12]};
		m2_st		 <= {m2_st[6:0], m2};
		
		//mmc_latch[ppu_addr[12]]
		
		//mmc4-like chr switch
		if(ppu_oe_ne)
		case({ppu_addr[13:3], 3'd0})
			'h0FD8:mmc_latch[0] <= 0;
			'h1FD8:mmc_latch[1] <= 0;
			'h0FE8:mmc_latch[0] <= 1;
			'h1FE8:mmc_latch[1] <= 1;
		endcase
		
		
	end
	
	
	//************************************************************* mapper regs and logic
	always @(negedge clk)
	if(map_rst)
	begin
		reg_D000[2] <= 0;
		irq_pend		<= 0;
	end
		else
	if(ss_act)
	begin
		if(m2_pe & ss_we)
		begin
			if(ss_addr[7:3] == 0)chr_bank[ss_addr[2:0]][7:0] <= cpu_dat;
			if(ss_addr[7:3] == 1)chr_bank[ss_addr[2:0]][15:8] <= cpu_dat;

			if(ss_addr[7:0] == 16)acc <= cpu_dat;
			if(ss_addr[7:0] == 17)acc_test <= cpu_dat;
			if(ss_addr[7:0] == 18)irq_mod <= cpu_dat;
			if(ss_addr[7:0] == 19)irq_pre <= cpu_dat;
			if(ss_addr[7:0] == 20)irq_ctr <= cpu_dat;
			if(ss_addr[7:0] == 21)irq_xor <= cpu_dat;

			if(ss_addr[7:2] == 8)reg_B00X[ss_addr[1:0]][7:0] <= cpu_dat;
			if(ss_addr[7:2] == 9)reg_B00X[ss_addr[1:0]][15:8] <= cpu_dat;
			if(ss_addr[7:2] == 10)reg_800X[ss_addr[1:0]] <= cpu_dat;
			if(ss_addr[7:0] == 44)reg_D000 <= cpu_dat;
			if(ss_addr[7:0] == 45)reg_D001 <= cpu_dat;
			if(ss_addr[7:0] == 46)reg_D002 <= cpu_dat;
			if(ss_addr[7:0] == 47)reg_D003 <= cpu_dat;
			if(ss_addr[7:0] == 48)mul_arg[0] <= cpu_dat;
			if(ss_addr[7:0] == 49)mul_arg[1] <= cpu_dat;
			if(ss_addr[7:0] == 50)mul_rez[7:0] <= cpu_dat;
			if(ss_addr[7:0] == 51)mul_rez[15:8] <= cpu_dat;
			if(ss_addr[7:0] == 52){mul_req, irq_en, irq_pend, irq_en_st} <= cpu_dat;
		end
	end
		else
	begin
	
		//*************************************************************	regs
		if(m2_pe)
		begin
		
			//mul and accum
			if(!cpu_rw)
			case({cpu_addr[15:11], 9'd0, cpu_addr[1:0]})
				16'h5800:begin
					mul_arg[0] 	<= cpu_dat;
					mul_req 		<= 1;
				end
				16'h5801:begin
					mul_arg[1] 	<= cpu_dat;
					mul_req 		<= 1;
				end
				16'h5802:begin
					acc 			<= acc + cpu_dat;
				end
				16'h5803:begin
					acc 			<= 0;
					acc_test		<= cpu_dat;
				end
			endcase
			
			
			//banking
			if(!cpu_rw)
			case({cpu_addr[15:11], 11'd0})
				16'h8000:begin
					reg_800X[cpu_addr[1:0]]			<= cpu_dat;
				end
				16'h9000:begin
					chr_bank[cpu_addr[2:0]][7:0] 	<= cpu_dat;
				end
				16'hA000:begin
					chr_bank[cpu_addr[2:0]][15:8] <= cpu_dat;
				end
				16'hB000:begin
					if(cpu_addr[2] == 0)reg_B00X[cpu_addr[1:0]][7:0]	<= cpu_dat;
					if(cpu_addr[2] == 1)reg_B00X[cpu_addr[1:0]][15:8]	<= cpu_dat;
				end
			endcase
			
			
			//irq
			if(!cpu_rw)
			case({cpu_addr[15:11], 8'd0, cpu_addr[2:0]})
				16'hC000:irq_en	<= cpu_dat[0];
				16'hC001:irq_mod	<= cpu_dat;
				16'hC002:irq_en	<= 0;
				16'hC003:irq_en	<= 1;
				16'hC004:irq_pre 	<= cpu_dat ^ irq_xor;
				16'hC005:irq_ctr 	<= cpu_dat ^ irq_xor;
				16'hC006:irq_xor 	<= cpu_dat;
			endcase
			
			
			//mode regs
			if(!cpu_rw)
			case({cpu_addr[15:11], 9'd0, cpu_addr[1:0]})
				16'hD000:reg_D000 		<= cpu_dat;
				16'hD001:reg_D001 		<= cpu_dat;
				16'hD002:reg_D002[7:6] 	<= cpu_dat[7:6];
				16'hD003:reg_D003			<= cpu_dat;
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
	



