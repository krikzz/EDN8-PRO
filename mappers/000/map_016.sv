
module map_016(

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
	assign srm.dati			= eep_mem_dati;//cpu.data;
	
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
	sst.addr[7:3] == 0 	? chr_reg[sst.addr[2:0]] :
	sst.addr[7:0] == 8 	? prg_reg : 
	sst.addr[7:0] == 9 	? irq_ctr[15:8] : 
	sst.addr[7:0] == 10 	? irq_ctr[7:0] : 
	sst.addr[7:0] == 11 	? irq_latch[15:8] : 
	sst.addr[7:0] == 12 	? irq_latch[7:0] : 
	sst.addr[7:0] == 13 	? {irq_on, irq_pend, mirror_mode[1:0]} : 
	sst.addr[7:0] == 127 ? cfg.map_idx : 8'hff;
//************************************************************* mapper-controlled pins
	assign srm.ce				= eep_mem_ce;
	assign srm.oe				= eep_mem_oe;
	assign srm.we				= eep_mem_we;
	assign srm.addr[7:0]		= eep_mem_addr[7:0];
	assign srm.async_io		= 1;//direct access without reference to m2
	
	assign prg.ce				= cpu.addr[15];
	assign prg.oe 				= cpu.rw;
	assign prg.we				= 0;
	assign prg.addr[13:0]	= cpu.addr[13:0];
	assign prg.addr[21:14]	= !cpu.addr[14] ? prg_reg[7:0] : 8'hff;
	
	assign chr.ce 				= mao.ciram_ce;
	assign chr.oe 				= !ppu.oe;
	assign chr.we 				= cfg.chr_ram ? !ppu.we & mao.ciram_ce : 0;
	assign chr.addr[9:0]		= ppu.addr[9:0];
	assign chr.addr[17:10]	= chr_reg[ppu.addr[12:10]];

	
	//A10-Vmir, A11-Hmir
	assign mao.ciram_a10 	= 
	mirror_mode == 0 ? ppu.addr[10] : 
	mirror_mode == 1 ? ppu.addr[11] : 
	mirror_mode[0];
	assign mao.ciram_ce 		= !ppu.addr[13];
	
	assign mao.irq				= irq_pend;
	assign mao.led				= eep_led;
	
	assign int_cpu_oe 		= eep_oe_cp;
	assign int_cpu_data 		= eep_do_cp[7:0];
//************************************************************* mapper implementation
	
	wire regs_ce_s4 = (cpu.addr[15:0] & 16'hE000) == 16'h6000;
	wire regs_ce_s5 = (cpu.addr[15:0] & 16'h8000) == 16'h8000;
	wire regs_ce = 
	cfg.map_idx == 16 & cfg.map_sub == 4 ? regs_ce_s4 : 
	cfg.map_idx == 16 & cfg.map_sub == 5 ? regs_ce_s5 : 
	cfg.map_idx == 159 ? regs_ce_s5 : 
	regs_ce_s4 | regs_ce_s5;
	
	
	reg [7:0]chr_reg[8];
	reg [7:0]prg_reg;
	reg [15:0]irq_ctr;
	reg [15:0]irq_latch;
	reg [1:0]mirror_mode;
	reg irq_pend;
	reg irq_on;
	
	
	always @(negedge cpu.m2)
	if(sst.act)
	begin
		if(sst.we_reg & sst.addr[7:3] == 0)chr_reg[sst.addr[2:0]] 	<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 8)prg_reg 						<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 9)irq_ctr[15:8] 				<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 10)irq_ctr[7:0] 				<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 11)irq_latch[15:8] 			<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 12)irq_latch[7:0] 			<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 13){irq_on, irq_pend, mirror_mode[1:0]} <= sst.dato;
	end
		else
	if(mai.map_rst)
	begin
		irq_on 	<= 0;
		irq_pend <= 0;
		prg_reg 	<= 0;
	end
		else
	begin

	
		if(!cpu.rw & regs_ce_s5 & cpu.addr[3:0] == 4'hA)
		begin
			irq_ctr <= irq_latch;
		end
			else
		if(irq_on)
		begin
			irq_ctr <= irq_ctr - 1;
			if(irq_ctr == 0 & irq_pend == 0)irq_pend <= 1;
		end
			
			
				
		if(!cpu.rw & regs_ce & cpu.addr[3] == 0)
		begin
			chr_reg[cpu.addr[2:0]][7:0] <= cpu.data[7:0];
		end
		
		
		if(!cpu.rw & regs_ce)
		case(cpu.addr[3:0])
			4'h8:begin
				prg_reg[7:0] 		<= cpu.data[7:0];
			end
			4'h9:begin
				mirror_mode[1:0] 	<= cpu.data[1:0];
			end
			4'hA:begin
				irq_on 				<= cpu.data[0];
				irq_pend 			<= 0;
			end
			4'hB:begin
				if(regs_ce_s4)irq_ctr[7:0] 	<= cpu.data[7:0];
				if(regs_ce_s5)irq_latch[7:0] 	<= cpu.data[7:0];
			end
			4'hC:begin
				if(regs_ce_s4)irq_ctr[15:8] 	<= cpu.data[7:0];
				if(regs_ce_s5)irq_latch[15:8] <= cpu.data[7:0];
			end
		endcase
	
	end
//************************************************************* eeprom section

	parameter BRAM_OFF    	= 4'h0;
	parameter BRAM_24X01    = 4'h3;
	parameter BRAM_24C01    = 4'h4;
	parameter BRAM_24C02    = 4'h5;
		
	wire [3:0]bram_type =
	cfg.srm_size == 128 ? BRAM_24X01 :
	cfg.srm_size == 256 ? BRAM_24C02 :
	cfg.map_idx  == 159 ? BRAM_24X01 :
	cfg.map_idx  == 16  & cfg.map_sub != 4 ? BRAM_24C02 :
	BRAM_OFF;

	wire eep_on 			= bram_type != BRAM_OFF;
	wire eep_oe_cp			= eep_on & cpu.rw & {cpu.addr[15:13], 13'd0} == 16'h6000;
	wire [7:0]eep_do_cp	= {cpu.addr[15:13], eep_do, cpu.addr[11:8]};
	wire eep_led 			= eep_on & led_eep;
	wire eep_mem_ce 		= eep_on & (eep_mem_oe | eep_mem_we);
	wire eep_mem_oe;
	wire eep_mem_we;
	wire [7:0]eep_mem_dati;
	wire [7:0]eep_mem_addr;
	

	wire led_eep, eep_do;
	
	eep_24cXX_sync eep_inst(

		.clk(mai.clk),
		.rst(mai.map_rst | mai.sys_rst | !eep_on),
		.bram_type(bram_type),
		
		.scl(eep_scl),
		.sda_in(eep_di),
		.sda_out(eep_do),

		.ram_do(mai.srm_do),
		.ram_di(eep_mem_dati),
		.ram_addr(eep_mem_addr),
		.ram_oe(eep_mem_oe), 
		.ram_we(eep_mem_we),
		.led(led_eep)
	);
	
	
	reg eep_dir, eep_di, eep_scl;
	
	always @(negedge cpu.m2)
	if(mai.map_rst)
	begin
		eep_dir 	<= 1;
		eep_di 	<= 1;
		eep_scl 	<= 1;
	end
		else
	if(!cpu.rw & (cpu.addr[15:0] & 16'h800F) == 16'h800D)
	begin
		{eep_dir, eep_di, eep_scl} <= cpu.data[7:5];
	end

	
endmodule
