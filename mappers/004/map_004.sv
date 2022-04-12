 

module map_004(

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
	assign mao.srm_mask_off = 0;
	assign mao.chr_mask_off = 0;
	assign mao.prg_mask_off = 0;
	assign mao.mir_4sc		= 1;//enable support for 4-screen mirroring. for activation should be ensabled in cfg also
	assign mao.bus_cf 		= 0;//bus conflicts
//************************************************************* mapper output assignments
	assign srm.ce				= pin_ram_ce;
	assign srm.oe				= cpu.rw;
	assign srm.we				= pin_ram_we;
	assign srm.addr[12:0]	= cpu.addr[12:0];
	
	assign prg.ce				= pin_rom_ce;
	assign prg.oe 				= cpu.rw;
	assign prg.we				= 0;
	assign prg.addr[12:0]	= cpu.addr[12:0];
	assign prg.addr[18:13]	= pin_prg_addr[18:13];
	
	assign chr.ce 				= mao.ciram_ce;
	assign chr.oe 				= !ppu.oe;
	assign chr.we 				= cfg.chr_ram ? !ppu.we & mao.ciram_ce : 0;
	assign chr.addr[9:0]		= ppu.addr[9:0];
	assign chr.addr[17:10]	= cfg.chr_ram ? pin_chr_addr[14:10] : pin_chr_addr[17:10];//ines 2.0 reuired to support 32k ram
	
	//A10-Vmir, A11-Hmir
	assign mao.ciram_a10 	= pin_cir_a10;
	assign mao.ciram_ce 		= !ppu.addr[13];
	
	assign mao.irq				= pin_irq;
//************************************************************* mapper-controlled pin
	wire pin_ram_ce;
	wire pin_ram_we;
	wire pin_rom_ce;
	wire pin_cir_a10;
	wire pin_irq;
	wire [18:13]pin_prg_addr;
	wire [17:10]pin_chr_addr;
//************************************************************* mapper implementation below
	assign pin_ram_ce 	= {cpu.addr[15:13], 13'd0} == 16'h6000 & ram_ce_on;// & (!ram_we_off | cpu.rw);
	assign pin_ram_we 	= !cpu.rw & !ram_we_off;
	assign pin_rom_ce 	= cpu.addr[15];
	
	assign pin_cir_a10 	= !mir_mod ? ppu.addr[10] : ppu.addr[11];
	
	assign pin_prg_addr[18:13] =
	cpu.addr[14:13] == 0 ? (prg_mod == 0 ? r8001[6][5:0] : 6'b111110) :
	cpu.addr[14:13] == 1 ? r8001[7][5:0] : 
	cpu.addr[14:13] == 2 ? (prg_mod == 1 ? r8001[6][5:0] : 6'b111110) : 
	6'b111111;

	
	assign pin_chr_addr[17:10] = 
	ppu.addr[12:11] == {chr_mod, 1'b0} ? {r8001[0][7:1], ppu.addr[10]} :
	ppu.addr[12:11] == {chr_mod, 1'b1} ? {r8001[1][7:1], ppu.addr[10]} :
	ppu.addr[11:10] == 0 ? r8001[2][7:0] : 
	ppu.addr[11:10] == 1 ? r8001[3][7:0] : 
	ppu.addr[11:10] == 2 ? r8001[4][7:0] : 
   r8001[5][7:0];
	
	wire [3:0]reg_addr	= {cpu.addr[15:13], cpu.addr[0]};
	
	wire prg_mod 			= r8000[6];
	wire chr_mod 			= r8000[7];
	wire mir_mod 			= rA000[0];
	wire ram_we_off 		= rA001[6];
	wire ram_ce_on 		= rA001[7];
	
	reg [7:0]r8000;
	reg [7:0]r8001[8];
	reg [7:0]rA000;
	reg [7:0]rA001;
	
	
	always @(posedge mai.clk)
	if(sst.act & decode_en)
	begin
		if(sst.we_reg & sst.addr[7:3] == 0)r8001[sst.addr[2:0]] <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 8)r8000 	<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 9)rA000 	<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 10)rA001	<= sst.dato;
	end
		else
	if(mai.map_rst)
	begin
		r8000[7:0] 		<= 0;
	
		rA000[0] 		<= !cfg.mir_v;
		rA001[7:0] 		<= 0;
	
		r8001[0][7:0]	<= 0;
		r8001[1][7:0] 	<= 2;
		r8001[2][7:0] 	<= 4;
		r8001[3][7:0] 	<= 5;
		r8001[4][7:0] 	<= 6;
		r8001[5][7:0] 	<= 7;
		r8001[6][7:0] 	<= 0;
		r8001[7][7:0] 	<= 1;
	end
		else
	if(decode_en)
	case(reg_addr[3:0])
		4'h8:r8000[7:0] 					<= cpu.data[7:0];
		4'h9:r8001[r8000[2:0]][7:0]	<= cpu.data[7:0];
		4'hA:rA000[7:0] 					<= cpu.data[7:0];
		4'hB:rA001[7:0] 					<= cpu.data[7:0];
	endcase
	

//************************************************************* irq	
	irq_mmc3 irq_inst(
		
		.clk(mai.clk),
		.decode_en(decode_en),
		.cpu_m2(cpu.m2),
		.cpu_data(cpu.data),
		.reg_addr(reg_addr),
		.ppu_a12(ppu.addr[12]),
		.map_rst(mai.map_rst),
		.mmc3a(mai.cfg.map_sub == 4),
		.irq(pin_irq)
	);
//************************************************************* decode
	wire decode_en 	= m2_st[5:0] == 'b011111 & !cpu.rw;
	
	reg [7:0]m2_st;
	
	always @(posedge mai.clk)
	begin
		m2_st[7:0] 		<= {m2_st[6:0], cpu.m2};
	end
	
endmodule

module irq_mmc3(

	input clk,
	input decode_en,
	input cpu_m2,
	input [7:0]cpu_data,
	input [3:0]reg_addr,
	input ppu_a12,
	input map_rst,
	input mmc3a,
	
	output reg irq,
	output [7:0]sst_do
);
	
	
	wire [7:0]ctr_next	= irq_ctr == 0 ? reload_val : irq_ctr - 1;
	wire irq_trigger 		= mmc3a ? ctr_next == 0 & (irq_ctr != 0 | reload_req) : ctr_next == 0;
	
	reg [7:0]reload_val;
	reg [7:0]irq_ctr;
	reg irq_on, reload_req;

	always @(posedge clk)
	if(map_rst)
	begin
		irq_on 	<= 0;
		irq		<= 0;
	end
		else
	begin
		
		if(decode_en)
		case(reg_addr[3:0])
			4'hC:reload_val[7:0] <= cpu_data[7:0];//C000
			4'hE:irq_on 			<= 0;//E000
			4'hF:irq_on 			<= 1;//E001
		endcase
		
		
		if(decode_en & reg_addr == 4'hD)//C001
		begin
			reload_req		<= 1;
			irq_ctr[7:0] 	<= 0;
		end
			else
		if(a12_edge)
		begin
			reload_req		<= 0;
			irq_ctr 			<= ctr_next;
		end
		
	
		if(!irq_on)
		begin
			irq <= 0;
		end
			else
		if(a12_edge & irq_trigger)
		begin
			irq <= 1;
		end
		
	end
	
//************************************************************* m2 edge
	wire m2_ne = m2_st[2:0] == 3'b110;
	
	reg [3:0]m2_st;
	always @(posedge clk)
	begin
		m2_st[3:0]	<= {m2_st[2:0], cpu_m2};
	end	
//************************************************************* a12 filter (IC level)	
	wire a12_edge = a12_filter[2:0] == 'b111 & a12d;
	
	reg [2:0]a12_filter;
		
	always @(posedge clk)
	begin
		
		if(a12d)
		begin
			a12_filter[2:0] <= 0;
		end
			else
		if(m2_ne)
		begin
			a12_filter[2:0] <= {a12_filter[1:0], 1'b1};
		end
		
	end
//************************************************************* a12 deglitcher (onboard cap)
	reg a12d;
	reg [1:0]a12_st;
	
	//negedge used to reduce filter delay
	//from a12 rise to irq triggering should be around 50ns
	always @(negedge clk)
	begin
		a12_st[1:0] <= {a12_st[0], ppu_a12};
		if(a12_st[1:0] == 2'b11)a12d <= 1;
		if(a12_st[1:0] == 2'b00)a12d <= 0;
	end
	
endmodule
