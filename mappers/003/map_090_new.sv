
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
	
	assign ss_rdat[7:0] = ss_addr[7:0] == 127 ? map_idx : 8'hff;/*
	//ss_addr[7:0] == 0 ? prg_bank : 
	ss_addr[7:3] == 0 ? chr_reg[ss_addr[2:0]][7:0] : 
	ss_addr[7:3] == 1 ? chr_reg[ss_addr[2:0]][15:8] : 
	ss_addr[7:3] == 2 ? irq_reg[ss_addr[2:0]] : 
	//ss_addr[7:3] == 3 ? ram[ss_addr[2:0]] : 
	ss_addr[7:2] == 8 ? nt_reg[ss_addr[1:0]][7:0] : 
	ss_addr[7:2] == 9 ? nt_reg[ss_addr[1:0]][15:8] : 
	ss_addr[7:2] == 10 ? prg_reg[ss_addr[1:0]] : 
	ss_addr[7:2] == 11 ? control[ss_addr[1:0]] : 
	ss_addr[7:0] == 48 ? mul_inp[0] : 
	ss_addr[7:0] == 49 ? mul_inp[1] : 
	ss_addr[7:0] == 50 ? mul_rez[7:0] : 
	ss_addr[7:0] == 51 ? mul_rez[15:8] : 
	ss_addr[7:0] == 52 ? {mul_req, irq_on, irq_pend, irq_inc} : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;*/
	//*************************************************************
	assign ram_we = !cpu_rw & ram_ce;
	assign ram_ce = ce_60xx & mode_cfg[7] == 1;
	assign rom_ce = cpu_addr[15] | (ce_60xx &  mode_cfg[7] == 1);
	assign chr_ce = ciram_ce;
	assign chr_we = 0;
	wire ce_60xx  = {cpu_addr[15:13], 13'd0} == 16'h6000;
	
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = 0;/*
	nt_advanced ? nt_reg[ppu_addr[11:10]][0] :
	mirror_mode == 0 ? ppu_addr[10] : 
	mirror_mode == 1 ? ppu_addr[11] : mirror_mode[0];*/
	
	assign ciram_ce = 0;/*
	!nt_advanced ? !ppu_addr[13] : 
	ppu_addr[13] == 0 ? 1 :
	nt_ram_off ? 1 : (nt_ram_select == nt_reg[ppu_addr[11:10]][7] ? 0 : 1);*/
	
	
	//************** prg mapping
	
	assign prg_addr[12:0] 	= cpu_addr[12:0];
	assign prg_addr[18:13] 	= prg_map[prg_mode][5:0];
	assign prg_addr[20:19] 	= obank[2:1];
	
		
	wire [6:0]prg_map[8];
	
	assign prg_map[0] = cpu_addr[15] 	== 'b1	? {5'h1f, cpu_addr[14:13]} : prg_map[4];//32K
	assign prg_map[1] = cpu_addr[15:12] == 'b11	? {6'h3f, cpu_addr[13]} 	: prg_map[5];//16K
	assign prg_map[2] = cpu_addr[15:13] == 'b111	? 7'h7f 							: prg_map[6];//8K
	assign prg_map[3] = cpu_addr[15:13] == 'b111	? 7'h7f 							: prg_map[7];//8K reversed
	
	assign prg_map[4] = {prg_bank[3][4:0], cpu_addr[14:13]};//32K
	assign prg_map[5] = !cpu_addr[14] ? {prg_bank[1][5:0], cpu_addr[13]} : {prg_bank[3][5:0], cpu_addr[13]};//16K
	assign prg_map[6] = prg_bank[cpu_addr[14:13]][6:0];//8K
	assign prg_map[7] = {prg_map[6][0], prg_map[6][1], prg_map[6][2], prg_map[6][3], prg_map[6][4], prg_map[6][5], prg_map[6][6]};//8K reversed
	
	wire [2:0]prg_mode = mode_cfg[2:0];
	
	
	//************** chr mapping
	
	assign chr_addr[9:0] = ppu_addr[9:0];
	
	
	//**************
	
	assign irq 			= irq_pend;
	
	
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
	
	
	wire [1:0]dip 			= 2'b00;
	
	wire [1:0]irq_src 	= irq_mode[1:0];
	wire [7:0]irq_pmask 	= irq_mode[2] == 0 ? 8'hff : 8'h07;
	wire [1:0]irq_dir 	= irq_mode[7:6];
	
	wire irq_tick = 
	irq_src == 0 ? 1 : 						//m2
	irq_src == 1 ? ppu_12_st == 2'b01 : //a12 rise
	irq_src == 2 ? ppu_oe_st == 2'b10 : //ppu oe
						!cpu_rw;					//cpu wr
						
	
	reg [7:0]mul_arg[2];
	reg [15:0]mul_rez;
	reg mul_req;
	reg [7:0]acc;
	reg [7:0]acc_test;
	
	reg [6:0]prg_bank[4];
	reg [15:0]chr_bank[8];
	reg [15:0]ntb_bank[4];
	
	reg irq_en, irq_en_st;
	reg [7:0]irq_mode, irq_pre, irq_ctr, irq_xor;
	reg irq_pend;
	
	reg [7:0]mode_cfg;
	reg [3:0]mirr_cfg;
	reg [7:6]ppu_acfg;
	reg [7:0]obank;
	
	
	
	//this regs should ignored for save states
	reg [1:0]ppu_12_st;
	reg [1:0]ppu_oe_st;
	
	always @(negedge m2)
	begin
		ppu_12_st[1:0] <= {ppu_12_st[0], ppu_addr[12]};
		ppu_oe_st[1:0] <= {ppu_oe_st[0], ppu_oe};
	end
	
	
	
	always @(negedge m2)
	if(map_rst)
	begin
		mode_cfg[2] <= 0;
		irq_pend		<= 0;
	end
		else
	begin
	
//*************************************************************	regs
		
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
				prg_bank[cpu_addr[1:0]]			<= cpu_dat;
			end
			16'h9000:begin
				chr_bank[cpu_addr[2:0]][7:0] 	<= cpu_dat;
			end
			16'hA000:begin
				chr_bank[cpu_addr[2:0]][15:8] <= cpu_dat;
			end
			16'hB000:begin
				if(cpu_addr[2] == 0)ntb_bank[cpu_addr[1:0]][7:0]	<= cpu_dat;
				if(cpu_addr[2] == 1)ntb_bank[cpu_addr[1:0]][15:8]	<= cpu_dat;
			end
		endcase
		
		
		//irq
		if(!cpu_rw)
		case({cpu_addr[15:11], 8'd0, cpu_addr[2:0]})
			16'hC000:irq_en	<= cpu_dat[0];
			16'hC001:irq_mode	<= 0;
			16'hC002:irq_en	<= 0;
			16'hC003:irq_en	<= 1;
			16'hC004:irq_pre <= cpu_dat ^ irq_xor;
			16'hC005:irq_ctr <= cpu_dat ^ irq_xor;
			16'hC006:irq_xor <= cpu_dat;
		endcase
		
		
		//mode regs
		if(!cpu_rw)
		case({cpu_addr[15:11], 9'd0, cpu_addr[1:0]})
			16'hD000:mode_cfg 		<= cpu_dat;
			16'hD001:mirr_cfg 		<= cpu_dat;
			16'hD002:ppu_acfg[7:6] 	<= cpu_dat[7:6];
			16'hD003:obank 			<= cpu_dat;
		endcase

	
		//************************************************************* mul
		if(mul_req)
		begin
			mul_rez <= mul_arg[0] * mul_arg[1];
			mul_req <= 0;
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
			
			if(irq_dir == 1 & ((irq_pre & irq_pmask) + 1 ) == 0)
			begin
				irq_ctr <= irq_ctr + 1;
				if(irq_ctr == 8'hff)irq_pend <= 1;
			end
			
			if(irq_dir == 2 & ((irq_pre & irq_pmask) - 1 ) == irq_pmask)
			begin
				irq_ctr <= irq_ctr - 1;
				if(irq_ctr == 8'h00)irq_pend <= 1;
			end
		end
		
		
	
		
	end
	
	
endmodule
	


/*
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
	//ss_addr[7:0] == 0 ? prg_bank : 
	ss_addr[7:3] == 0 ? chr_reg[ss_addr[2:0]][7:0] : 
	ss_addr[7:3] == 1 ? chr_reg[ss_addr[2:0]][15:8] : 
	ss_addr[7:3] == 2 ? irq_reg[ss_addr[2:0]] : 
	//ss_addr[7:3] == 3 ? ram[ss_addr[2:0]] : 
	ss_addr[7:2] == 8 ? nt_reg[ss_addr[1:0]][7:0] : 
	ss_addr[7:2] == 9 ? nt_reg[ss_addr[1:0]][15:8] : 
	ss_addr[7:2] == 10 ? prg_reg[ss_addr[1:0]] : 
	ss_addr[7:2] == 11 ? control[ss_addr[1:0]] : 
	ss_addr[7:0] == 48 ? mul_inp[0] : 
	ss_addr[7:0] == 49 ? mul_inp[1] : 
	ss_addr[7:0] == 50 ? mul_rez[7:0] : 
	ss_addr[7:0] == 51 ? mul_rez[15:8] : 
	ss_addr[7:0] == 52 ? {mul_req, irq_on, irq_pend, irq_inc} : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	
	assign ram_we = 0;//!cpu_rw & ram_ce;
	assign ram_ce = 0;//cpu_addr[14:13] == 2'b11 & cpu_ce & m2;
	assign rom_ce = !cpu_ce | (cpu_addr[14:13] == 2'b11 & cpu_ce & m2 & control[0][7]);
	assign chr_ce = ciram_ce;
	assign chr_we = 0;//cfg_chr_ram ? !ppu_we & ciram_ce : 0;
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = 
	nt_advanced ? nt_reg[ppu_addr[11:10]][0] :
	mirror_mode == 0 ? ppu_addr[10] : 
	mirror_mode == 1 ? ppu_addr[11] : mirror_mode[0];
	
	assign ciram_ce = 
	!nt_advanced ? !ppu_addr[13] : 
	ppu_addr[13] == 0 ? 1 :
	nt_ram_off ? 1 : (nt_ram_select == nt_reg[ppu_addr[11:10]][7] ? 0 : 1);
	
	
	assign prg_addr[12:0] = cpu_addr[12:0];
	assign prg_addr[18:13] = prg_map[prg_mode][5:0];
	assign prg_addr[20:19] = obank[2:1];
	
	wire [7:0]obank = control[3][7:0];
	
	wire chr_a18 = chr_block_mode == 0 ? obank[0] : chr_map[chr_mode][8];
	
	assign chr_addr[9:0] = ppu_addr[9:0];
	assign chr_addr[20:10] = 
	!ppu_addr[13] ? {obank[4:3], chr_a18, chr_map[chr_mode][7:0]} : nt_reg[ppu_addr[11:10]][8:0];
	
	
	
	reg [15:0]chr_reg[8];
	reg [7:0]irq_reg[8];
	//reg [7:0]ram[8];
	
	reg [15:0]nt_reg[4];
	reg [6:0]prg_reg[4];
	reg [7:0]control[4];
		
	reg [7:0]mul_inp[2];	
	reg [15:0]mul_rez;
	
	reg mul_req;
	reg irq_on;
	reg irq_pend;
	reg irq_inc;
	
	reg [7:0] accum;
	reg [7:0] accumtest;
	wire [1:0] dip = 2'b00;
	
	assign irq = irq_pend;
	
	assign map_cpu_dout[7:0] = 
	cpu_addr[15:0] == 16'h5800 ? mul_rez[7:0]  : 
	cpu_addr[15:0] == 16'h5801 ? mul_rez[15:8] : 
	cpu_addr[15:0] == 16'h5802 ? accum : 
	cpu_addr[15:0] == 16'h5803 ? accumtest : 
	dip_oe 							? {dip[1:0], 6'h00} :
										  8'hff;

	
	assign map_cpu_oe = mul_oe | acc_oe | act_oe | dip_oe;// | ram_oe;
	
	wire mul_oe = {!cpu_ce, cpu_addr[14:1], 1'b0}   == 16'h5800 & cpu_rw & m2;
	//wire ram_oe = {!cpu_ce, cpu_addr[14:3], 3'b000} == 16'h5800 & cpu_rw & m2 & !mul_oe;
	wire acc_oe = cpu_addr == 16'h5802 & cpu_rw;
	wire act_oe = cpu_addr == 16'h5803 & cpu_rw;
	wire dip_oe = cpu_addr == 16'h5000 | cpu_addr == 16'h5400;
	
	wire nt_advanced = control[0][5];
	wire nt_ram_off = control[0][6];
	wire nt_ram_select = control[2][7];
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:3] == 0)chr_reg[ss_addr[2:0]][7:0] <= cpu_dat;
		if(ss_we & ss_addr[7:3] == 1)chr_reg[ss_addr[2:0]][15:8] <= cpu_dat;
		if(ss_we & ss_addr[7:3] == 2)irq_reg[ss_addr[2:0]] <= cpu_dat;
		//if(ss_we & ss_addr[7:3] == 3)ram[ss_addr[2:0]] <= cpu_dat;
		if(ss_we & ss_addr[7:2] == 8)nt_reg[ss_addr[1:0]][7:0] <= cpu_dat;
		if(ss_we & ss_addr[7:2] == 9)nt_reg[ss_addr[1:0]][15:8] <= cpu_dat;
		if(ss_we & ss_addr[7:2] == 10)prg_reg[ss_addr[1:0]] <= cpu_dat;
		if(ss_we & ss_addr[7:2] == 11)control[ss_addr[1:0]] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 48)mul_inp[0] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 49)mul_inp[1] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 50)mul_rez[7:0] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 51)mul_rez[15:8] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 52){mul_req, irq_on, irq_pend, irq_inc} <= cpu_dat;
	end
		else
	begin
	
		if(map_rst)
		begin
			control[0] <= 0;
			control[3] <= 0;
			irq_on <= 0;
			irq_pend <= 0;
			control[0][5] <= 0;
		end
		
		if(!map_rst & map_idx == 90)control[0][5] <= 0;
		if(!map_rst & map_idx == 211)control[0][5] <= 1;
		
			
		
		
		if(!map_rst & !cpu_rw)
		case({cpu_addr[15:11], 11'd0})
		
			16'h5800:begin
			
				if(cpu_addr[1] == 0 | cpu_addr[1:0] == 1)mul_req <= 1;
				
				if(cpu_addr[1:0] == 0)mul_inp[0] <= cpu_dat[7:0];
				if(cpu_addr[1:0] == 1)mul_inp[1] <= cpu_dat[7:0];
				if(cpu_addr[1:0] == 2) accum <= accum + cpu_dat;
				if(cpu_addr[1:0] == 3)begin accum <= 0; accumtest <= cpu_dat; end
			end
			
			//16'h5800:ram[cpu_addr[2:0]] <= cpu_dat[7:0];
			16'h8000:prg_reg[cpu_addr[1:0]] <= cpu_dat[6:0];
			16'h9000:chr_reg[cpu_addr[2:0]][7:0] <= cpu_dat[7:0];
			16'hA000:chr_reg[cpu_addr[2:0]][15:8] <= cpu_dat[7:0];
			16'hB000:begin
				if(cpu_addr[2] == 0)nt_reg[cpu_addr[1:0]][7:0] <= cpu_dat[7:0];
				if(cpu_addr[2] == 1)nt_reg[cpu_addr[1:0]][15:8] <= cpu_dat[7:0];
			end
			16'hD000:control[cpu_addr[1:0]] <= cpu_dat[7:0];
			16'hC000:
			begin
			
				if(cpu_addr[2:0] == 1)irq_reg[cpu_addr[2:0]] <= cpu_dat[7:0];
				if(cpu_addr[2:0] == 6)irq_reg[cpu_addr[2:0]] <= cpu_dat[7:0];
				if(cpu_addr[2:0] == 4)irq_reg[cpu_addr[2:0]] <= cpu_dat[7:0] ^ irq_reg[6];
				if(cpu_addr[2:0] == 5)irq_reg[cpu_addr[2:0]] <= cpu_dat[7:0] ^ irq_reg[6];
				
				
				if(cpu_addr[2:0] == 2 | (cpu_addr[2:0] == 0 & cpu_dat[0] == 0))
				begin
					irq_on <= 0;
					irq_pend <= 0;
				end
				
				if(cpu_addr[2:0] == 3 | (cpu_addr[2:0] == 0 & cpu_dat[0] == 1))
				begin
					irq_on <= 1;
				end
				
			end
		endcase
		
		

		
		if(mul_req)
		begin
			mul_req <= 0;
			mul_rez <= mul_inp[0] * mul_inp[1];
		end
		
		
		
		if((irq_src == 0 | a12_st == 2'b01) & !irq_update)
		begin
			if(prescal_mode == 0)
			begin
				irq_reg[4][7:0] <= irq_reg[4][7:0] + 1;
				if(irq_reg[4][7:0] == 0)irq_inc <= 1;
			end
				else
			begin
				irq_reg[4][2:0] <= irq_reg[4][2:0] + 1;
				if(irq_reg[4][2:0] == 0)irq_inc <= 1;
			end
			
			if(irq_inc & irq_dir == 2'b10)
			begin
				irq_reg[5] <= irq_reg[5] - 1;
				if(irq_on & irq_reg[5] == 8'h00)irq_pend <= 1;
			end
			
			if(irq_inc & irq_dir == 2'b01)
			begin
				irq_reg[5] <= irq_reg[5] + 1;
				if(irq_on & irq_reg[5] == 8'hff)irq_pend <= 1;
			end
		
			if(irq_inc)irq_inc <= 0;
		end
		
		
		
		a12_st[0] <= ppu_addr[12];
		a12_st[1] <= a12_st[0];
	end
	
	wire irq_update = !cpu_rw & {!cpu_ce, cpu_addr[14:3], 3'b000} == 16'hC000;
	wire pre_update = !cpu_rw & {!cpu_ce, cpu_addr[14:0]} == 16'hC004;
	wire ctr_update = !cpu_rw & {!cpu_ce, cpu_addr[14:0]} == 16'hC004;
	
	reg [1:0]a12_st;
	
	
	wire prescal_mode = irq_reg[1][2];
	wire [1:0]irq_src = irq_reg[1][1:0];
	wire [1:0]irq_dir = irq_reg[1][7:6];


	
	wire [2:0]prg_mode 	= control[0][2:0];
	wire [1:0]chr_mode 	= control[0][4:3];
	wire [1:0]mirror_mode = control[1][1:0];
	
	
	//wire [4:0]chr_block 	= control[3][4:0];
	wire chr_block_mode 	= control[3][5];
	wire mirror_chr 		= control[3][7];

	wire [6:0]prg_map[8];
	assign prg_map[0] = cpu_ce ? {prg_reg[3][4:0], 2'b11} : {5'h1f, cpu_addr[14:13]};
	assign prg_map[1] = cpu_ce ? {prg_reg[3][5:0], 1'b1} : !cpu_addr[14] ? {prg_reg[1][5:0], cpu_addr[13]} : {6'h3f, cpu_addr[13]};	
	assign prg_map[2] = cpu_ce ? prg_reg[3][6:0] : cpu_addr[14:13] == 2'b11 ? 7'h7f : prg_reg[cpu_addr[14:13]];
	assign prg_map[3] = {prg_map[2][0], prg_map[2][1], prg_map[2][2], prg_map[2][3], prg_map[2][4], prg_map[2][5], prg_map[2][6]};
	
	assign prg_map[4] = cpu_ce ? prg_map[0] : {prg_reg[3][4:0], cpu_addr[14:13]};
	assign prg_map[5] = cpu_ce ? prg_map[1] : !cpu_addr[14] ? {prg_reg[1][5:0], cpu_addr[13]} : {prg_reg[3][5:0], cpu_addr[13]};
	assign prg_map[6] = cpu_ce ? prg_reg[3][6:0] : prg_reg[cpu_addr[14:13]][6:0];
	assign prg_map[7] = {prg_map[6][0], prg_map[6][1], prg_map[6][2], prg_map[6][3], prg_map[6][4], prg_map[6][5], prg_map[6][6]};
	
	
	wire [8:0]chr_map[4];
	assign chr_map[0] = {chr_reg[0][5:0], ppu_addr[12:10]};
	assign chr_map[1] = {(!ppu_addr[12] ? chr_reg[0][6:0] : chr_reg[4][6:0]), ppu_addr[11:10]};
	assign chr_map[2] = 
	ppu_mad[2:1] == 0 ? {chr_reg[0][7:0], ppu_addr[10]} : 
	ppu_mad[2:1] == 1 ? {chr_reg[2][7:0], ppu_addr[10]} : 
	ppu_mad[2:1] == 3 ? {chr_reg[4][7:0], ppu_addr[10]} : {chr_reg[6][7:0], ppu_addr[10]};
	assign chr_map[3] = chr_reg[ppu_mad[2:0]][8:0];
	
	
	wire [2:0]ppu_mad = mirror_chr == 0 ? ppu_addr[12:10] : 
	ppu_addr[12:10] == 2 ? 0 :
	ppu_addr[12:10] == 3 ? 1 : ppu_addr[12:10];

	
endmodule
*/

