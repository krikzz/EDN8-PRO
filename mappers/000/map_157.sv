
module map_157(

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
	assign srm.addr[8:0]		= eep_mem_addr[8:0];
	assign srm.async_io		= 1;//direct access without reference to m2
	
	assign prg.ce				= cpu.addr[15];
	assign prg.oe 				= cpu.rw;
	assign prg.we				= 0;
	assign prg.addr[13:0]	= cpu.addr[13:0];
	assign prg.addr[17:14]	= !cpu.addr[14] ? prg_reg[3:0] : 4'b1111;
	
	assign chr.ce 				= mao.ciram_ce;
	assign chr.oe 				= !ppu.oe;
	assign chr.we 				= cfg.chr_ram ? !ppu.we & mao.ciram_ce : 0;
	assign chr.addr[12:0]	= ppu.addr[12:0];

	
	//A10-Vmir, A11-Hmir
	assign mao.ciram_a10 	= 
	mirror_mode == 0 ? ppu.addr[10] : 
	mirror_mode == 1 ? ppu.addr[11] : mirror_mode[0];
	
	assign mao.ciram_ce 		= !ppu.addr[13];
	
	assign mao.irq				= irq_pend;
	assign mao.led				= eep_led;
	
	assign int_cpu_oe 		= eep_oe_cp;
	assign int_cpu_data 		= eep_do_cp[7:0];
//************************************************************* mapper implementation below

	wire regs_ce = (cpu.addr[15:0] & 16'h8000) == 16'h8000;
	
	reg [7:0]chr_reg[8];
	reg [4:0]prg_reg;
	reg [15:0]irq_ctr;
	reg [15:0]irq_latch;
	reg [1:0]mirror_mode;
	reg irq_pend;
	reg irq_on;
	
	always @(negedge cpu.m2)
	if(sst.act)
	begin
		if(sst.we_reg & sst.addr[7:3] == 0)chr_reg[sst.addr[2:0]]	<= sst.dato;
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
		prg_reg	<= 0;
	end
		else
	begin
			
		if(!cpu.rw & regs_ce & cpu.addr[3:0] == 4'hA)
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
				prg_reg[4:0] 		<= cpu.data[4:0];
			end
			4'h9:begin
				mirror_mode[1:0] 	<= cpu.data[1:0];
			end
			4'hA:begin
				irq_on 				<= cpu.data[0];
				irq_pend 			<= 0;
			end
			4'hB:begin
				irq_latch[7:0] 	<= cpu.data[7:0];
			end
			4'hC:begin
				irq_latch[15:8] 	<= cpu.data[7:0];
			end
		endcase
	
	end


//************************************************************* eeprom section
	parameter BRAM_OFF    	= 4'h0;
	parameter BRAM_24X01    = 4'h3;
	parameter BRAM_24C01    = 4'h4;
	parameter BRAM_24C02    = 4'h5;
		
	wire eep_oe_cp 			= cpu.rw & {cpu.addr[15:13], 13'd0} == 16'h6000;
	wire [7:0]eep_do_cp		= {cpu.addr[15:13], (eep_do[0] & eep_do[1]), 1'b0, cpu.addr[10:8]};
	wire eep_led 				= led_eep[0] | led_eep[1];
	wire eep_mem_ce			= (eep_mem_oe | eep_mem_we);
	wire eep_mem_oe 			= ram_oe_eep[0] | ram_oe_eep[1];
	wire eep_mem_we 			= ram_we_eep[0] | ram_we_eep[1];
	wire [7:0]eep_mem_dati	= ram_we_eep[1] ? eep_mem_di[1] : eep_mem_di[0];
	wire [8:0]eep_mem_addr 	= ram_we_eep[1] | ram_oe_eep[1] ? {1'b1, eep_addr[1][7:0]} :  {1'b0, eep_addr[0][7:0]};
	
	wire [7:0]eep_mem_di[2];
	wire [7:0]eep_addr[2];
	wire [1:0]ram_oe_eep, ram_we_eep, led_eep, eep_do;
	
	eep_24cXX_sync eep_int(

		.clk(mai.clk),
		.rst(mai.map_rst | mai.sys_rst),
		.bram_type(BRAM_24C02),
		
		.scl(eep_scl),
		.sda_in(eep_di),
		.sda_out(eep_do[0]),

		.ram_do(mai.srm_do),
		.ram_di(eep_mem_di[0]),
		.ram_addr(eep_addr[0]),
		.ram_oe(ram_oe_eep[0]), 
		.ram_we(ram_we_eep[0]),
		.led(led_eep[0])
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
	if(!cpu.rw)
	begin
		if((cpu.addr[15:0] & 16'h800F) == 16'h800D){eep_dir, eep_di, eep_scl} <= cpu.data[7:5];
	end
	
	
	wire [17:10]chr_a = chr_reg[ppu.addr[11:10]];
	
	eep_24cXX_sync eep_ext(

		.clk(mai.clk),
		.rst(mai.map_rst | mai.sys_rst),
		.bram_type(BRAM_24X01),
		
		.scl(chr_a[13]),
		.sda_in(eep_di),
		.sda_out(eep_do[1]),

		.ram_do(mai.srm_do),
		.ram_di(eep_mem_di[1]),
		.ram_addr(eep_addr[1]),
		.ram_oe(ram_oe_eep[1]), 
		.ram_we(ram_we_eep[1]),
		.led(led_eep[1])
	);

	
endmodule
