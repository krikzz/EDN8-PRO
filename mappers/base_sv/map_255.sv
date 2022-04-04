


module map_255(
	
	input  MapIn mai,
	output MapOut mao
	
);
	
	CpuBus cpu;// 		= mai.cpu;
	PpuBus ppu;// 		= mai.ppu;
	
	MemCtrl prg;
	MemCtrl srm;
	MemCtrl chr;
	
	wire map_cpu_oe;
	wire map_ppu_oe;
	wire [7:0]map_cpu_do;
	wire [7:0]map_ppu_do;
		
	assign cpu = mai.cpu;
	assign ppu = mai.ppu;
	
	assign mao.prg	= prg;
	assign mao.srm	= srm;
	assign mao.chr	= chr;
		
	assign mao.map_cpu_oe = map_cpu_oe | (prg.ce & prg.oe) | (srm.ce & srm.oe);
	assign mao.map_ppu_oe = map_ppu_oe | (chr.ce & chr.oe);
	
	assign mao.map_cpu_do = map_cpu_oe ? map_cpu_do : srm.ce ? mai.srm_do : mai.prg_do;
	assign mao.map_ppu_do = map_ppu_oe ? map_ppu_do : mai.chr_do;
//*************************************************************
	parameter REG_VRAM_CTRL		= 0;//4registers
	parameter REG_TIMER			= 4;//2 registers
	parameter REG_APP_BANK		= 6;

	
	assign prg.ce =  rom_area | ram_area | app_area;
	assign prg.we = (ram_area | app_area) & !cpu.rw;

	assign prg.addr[22:17] 	= 6'h3F;//system rom mapped to 0x7E0000
	assign prg.addr[16:0] 	= 
	ram_area ? {5'd0, cpu.addr[11:0]} :
	app_area ? {app_bank[3:0], cpu.addr[12:0]} :
				  {2'b11, cpu.addr[14:0]};
	
	assign map_cpu_do[7:0] = 
	bank_ce 		? app_bank[3:0] : 
	timer_ce 	? timer_do[7:0] : 
	vram_ce_cpu ? vram_do_cpu[7:0] : 
	8'h00;
	
	
	assign chr.ce = !ppu.addr[13];
	assign chr.we = !ppu.we & ppu_off;

	//A10-Vmir, A11-Hmir
	assign ciram_a10 	= ppu.addr[10];
	assign ciram_ce 	= ppu_off & !int_vram_tst ? !ppu.addr[13] : !int_vram_ce;
	
	assign chr.addr[11:0]  = ppu.addr[11:0];
	assign chr.addr[13:12] = ppu_off ? {1'b0, ppu.addr[12]} : atr_do[3:2];
	assign chr.addr[22:17] = ppu_off ? 6'h20 : 6'h3F;
	
	
	assign map_cpu_oe = regs_oe;
	assign map_ppu_oe = vram_oe_ppu & !ppu_off;
	
	wire reg_area = {cpu.addr[15:8], 8'h00}  == 16'h4100;
	wire ram_area = {cpu.addr[15:12], 12'd0} == 16'h5000;
	wire app_area = {cpu.addr[15:13], 13'd0} == 16'h6000;
	wire rom_area = cpu.addr[15];

	
	wire [7:0]reg_addr = cpu.addr[7:0];
	wire regs_ce 	= reg_area & mai.os_act & !mai.sys_rst;
	wire regs_oe 	= regs_ce & cpu.rw == 1;
	wire regs_we 	= regs_ce & cpu.rw == 0;
	
	wire bank_ce 	= regs_ce & reg_addr == REG_APP_BANK;
	wire timer_ce 	= regs_ce & {reg_addr[7:1], 1'b0} == REG_TIMER;
	
	reg [3:0]app_bank;
	reg ppu_off;//required for save state vram access. if ppu off int vram on and first 8k chr bank mapped
	
	always @(negedge cpu.m2)
	begin
	
		if(regs_we & bank_ce)
		begin
			app_bank[3:0] <= cpu.data[3:0];
		end
		
		if(!cpu.rw & cpu.addr[15:0] == 16'h2001)
		begin
			ppu_off <= !cpu.data[3];
		end
		
	end
	

	
//************************************************************* vram
	wire vram_ce_cpu = regs_ce & {reg_addr[7:2], 2'b00} == REG_VRAM_CTRL;//4x registers
	wire vram_oe_ppu, int_vram_ce, int_vram_tst;
	wire [7:0]vram_do_cpu;
	wire [3:0]atr_do;

	vram vram_inst(
		
		.clk(mai.clk),
		.m2(cpu.m2),
		.cpu_data(cpu.data),
		.cpu_addr(cpu.addr),
		.cpu_rw(cpu.rw),
		.ppu_addr(ppu.addr),
		
		.cpu_do(vram_do_cpu),
		.ppu_do(map_ppu_dout), 
		.vram_ce(vram_ce_cpu), 
		.vram_oe_ppu(vram_oe_ppu), 
		.atr_do(atr_do),
		.int_vram_ce(int_vram_ce),
		.int_vram_tst(int_vram_tst)
	);
	
//************************************************************* timer
	wire [7:0]timer_do;
	
	timer timer_inst(

		.clk(mai.clk),
		.m2(cpu.m2),
		.cpu_addr(cpu.addr),
		.timer_ce(timer_ce),
		.timer_do(timer_do)
	);
	
endmodule





module vram(
	
	input clk,
	input m2,
	input [7:0]cpu_data,
	input [15:0]cpu_addr,
	input cpu_rw,
	input [13:0]ppu_addr,
	
	input vram_ce,
	
	output [7:0]cpu_do, 
	output [7:0]ppu_do,	
	output vram_oe_ppu,
	output int_vram_ce, 
	output int_vram_tst,
	output [3:0]atr_do
);

	parameter REG_VRM_ADDR_LO	= 0;
	parameter REG_VRM_ADDR_HI	= 1;
	parameter REG_VRM_DATA 		= 2;
	parameter REG_VRM_ATTR		= 3;
	
	parameter VRAM_MODE_STD	= 0;
	parameter VRAM_MODE_SAF	= 1;
	parameter VRAM_MODE_TST	= 2;
	
	assign ppu_do[7:0] = ppu_atr_ce ? atr_val[7:0] : vram_do_ppu[7:0];
	
	assign cpu_do[7:0] = 
	ce_addr_lo ? vram_addr_cpu[7:0] : 
	ce_addr_hi ? vram_addr_cpu[15:8] : 
	ce_data ? vram_do_cpu[7:0] : 8'h00;
	
	wire [10:0]ppu_atr_addr;
	wire ppu_atr_ce;

	atr_ctrl atr_inst(
		.ppu_addr({ppu_addr[13:12], ppu_addr[10], ppu_addr[11], ppu_addr[9:0]}), 
		.ppu_oe(ppu_oe), 
		.clk(clk), 
		.ppu_atr_addr(ppu_atr_addr),
		.ppu_atr_ce(ppu_atr_ce)
	);
	
	wire vram_ce_ppu = ppu_addr[13];
	assign vram_oe_ppu = vram_ce_ppu & !ppu_oe & vram_mode == VRAM_MODE_STD;
	wire vram_we_ppu = 0;//vram_ce_ppu & !ppu_we;
	
	assign int_vram_ce = vram_ce_ppu & vram_mode == VRAM_MODE_SAF;
	assign int_vram_tst = vram_mode == VRAM_MODE_TST;
	
	wire vram_oe_cpu = ce_data & cpu_rw;
	wire vram_we_cpu = ce_data & !cpu_rw & m2 & vram_addr_cpu[15] == 0;//so attrib can be updated without name table changes
	wire ppu_dat_ce = cpu_addr[15:0] == 16'h2007;

	
	
	wire ce_addr_lo = vram_ce & cpu_addr[1:0] == REG_VRM_ADDR_LO;
	wire ce_addr_hi = vram_ce & cpu_addr[1:0] == REG_VRM_ADDR_HI;
	wire ce_data = vram_ce & cpu_addr[1:0] == REG_VRM_DATA;
	wire ce_attr = vram_ce & cpu_addr[1:0] == REG_VRM_ATTR;
	
	always @(negedge m2)
	begin
		if(!cpu_rw & ce_addr_lo)vram_addr_cpu[7:0] 	<= cpu_data[7:0];
		if(!cpu_rw & ce_addr_hi)vram_addr_cpu[15:8] 	<= cpu_data[7:0];
		if(!cpu_rw & (ce_data | ppu_dat_ce))vram_addr_cpu[15:0] <= vram_addr_cpu[15:0] + 1;
		if(cpu_rw & ce_data)cur_atr[3:0] <= atr_do_cpu[3:0];//used for back buffer copy
		
		//if(!cpu_rw & ce_attr)vram_mode[2] <= cpu_data[7];
		if(!cpu_rw & ce_attr & cpu_data[7:4] != 4'ha)cur_atr[3:0] <= {cpu_data[5:4], cpu_data[1:0]};
		if(!cpu_rw & ce_attr & cpu_data[7:4] == 4'ha)vram_mode[1:0] <= cpu_data[1:0];
	end
	
	
	wire [7:0]vram_do_ppu;
	wire [7:0]vram_do_cpu;
	reg [15:0]vram_addr_cpu;
	reg [2:0]vram_mode;
	wire vram_a10 = !cpu_rw ? vram_addr_cpu[10] : !vram_addr_cpu[10];
	
	
	ram_dp_sv ntb_ram(
	
		.clk_a(m2),
		.dati_a(cpu_data),
		.addr_a({vram_a10, vram_addr_cpu[9:0]}),
		.we_a(vram_we_cpu),
		.dato_a(vram_do_cpu),
		
		.clk_b(clk),
		.dati_b(ppu_dat),
		.addr_b({ppu_addr[11], ppu_addr[9:0]}),
		.we_b(vram_we_ppu),
		.dato_b(vram_do_ppu)
		
	);
	
	wire [3:0]atr_do_cpu;
	reg [3:0]cur_atr;
	wire atr_we = ce_data & !cpu_rw & m2;
	wire [7:0]atr_val = {atr_do[1:0], atr_do[1:0], atr_do[1:0], atr_do[1:0]};

	ram_dp_sv atr_ram(
	
		.clk_a(m2),
		.dati_a(cur_atr[3:0]),
		.addr_a({vram_a10, vram_addr_cpu[9:0]}),
		.we_a(atr_we),
		.dato_a(atr_do_cpu[3:0]),
		
		.clk_b(clk),
		.addr_b(ppu_atr_addr[10:0]),
		.dato_b(atr_do[3:0])
		
	);
	
endmodule


module atr_ctrl(

	input clk,
	input [13:0]ppu_addr,
	input ppu_oe, 
	output reg[10:0]ppu_atr_addr,
	output ppu_atr_ce
);

	
	
	assign ppu_atr_ce = ppu_addr[13] == 1 & ppu_addr[9:6] == 4'b1111;
	wire ppu_ntb_ce 	= ppu_addr[13] == 1 & ppu_addr[9:6] != 4'b1111;
	
	
	always @(negedge ppu_oe)
	begin
		if(!ppu_oe & ppu_ntb_ce)
		begin
			ppu_atr_addr[10:0] <= ppu_addr[10:0];
		end
	end
	
endmodule



module timer(

	input clk,
	input m2,
	input [15:0]cpu_addr,
	input  timer_ce,
	output [7:0]timer_do
);

	
	assign timer_do[7:0] = cpu_addr[0] == 0 ? timer_ms[7:0] : time_ms_hi[7:0];
	
	reg [15:0]timer_1khz;
	reg tick_1khz;
	
	
	wire timer_ce_lo = timer_ce & cpu_addr[0] == 0;
	wire timer_ce_hi = timer_ce & cpu_addr[0] == 1;
	
	always @(posedge clk)
	if(timer_1khz == 16'd49999)
	begin
		timer_1khz 	<= 0;
		tick_1khz 	<= !tick_1khz;
	end
		else
	begin
		timer_1khz	<= timer_1khz + 1;
	end
	
	
	reg[15:0]timer_ms;
	reg [7:0]time_ms_hi;
	reg [1:0]tick_1khz_st;
	
	always @(negedge m2)
	begin
	
		tick_1khz_st[1:0] 	<= {tick_1khz_st[0], tick_1khz};
		
		if(tick_1khz_st[0] != tick_1khz_st[1])
		begin
			timer_ms 			<= timer_ms + 1;
		end
		
		if(timer_ce & cpu_addr[0] == 0)
		begin
			time_ms_hi[7:0] 	<= timer_ms[15:8];
		end
	end
	
endmodule
 
