
module map_083(

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
	{sst.addr[7:3], 3'd0} == 0  ? chr_reg[sst.addr[2:0]] : 
	{sst.addr[7:2], 2'd0} == 8  ? prg_reg[sst.addr[1:0]] : 
	{sst.addr[7:2], 2'd0} == 12 ? skram[sst.addr[1:0]] :
	sst.addr[7:0] == 16  ? mode :
	sst.addr[7:0] == 17  ? outer :
	sst.addr[7:0] == 18  ? irq_ctr[15:8] :
	sst.addr[7:0] == 19  ? irq_ctr[7:0] :
	sst.addr[7:0] == 20  ? {irq_pend, irq_on} :
	sst.addr[7:0] == 127 ? cfg.map_idx : 8'hff;
//************************************************************* mapper-controlled pins
	assign srm.ce				= ram_ce;
	assign srm.oe				= cpu.rw;
	assign srm.we				= !cpu.rw;
	assign srm.addr[12:0]	= cpu.addr[12:0];
	assign srm.addr[14:13]	= srm_addr[14:13];
	
	assign prg.ce				= rom_ce;
	assign prg.oe 				= cpu.rw;
	assign prg.we				= 0;
	assign prg.addr[12:0]	= cpu.addr[12:0];
	assign prg.addr[19:13]	=	prg_addr[19:13];
	
	assign chr.ce 				= mao.ciram_ce;
	assign chr.oe 				= !ppu.oe;
	assign chr.we 				= cfg.chr_ram ? !ppu.we & mao.ciram_ce : 0;
	assign chr.addr[9:0]		= ppu.addr[9:0];
	assign chr.addr[19:10]	= chr_addr[19:10];

	
	//A10-Vmir, A11-Hmir
	assign mao.ciram_a10 	= ciram_a10;
	assign mao.ciram_ce 		= !ppu.addr[13];
	
	assign mao.irq				= irq_pend;
	assign int_cpu_oe			= map_cpu_oe;
	assign int_cpu_data		= map_cpu_dout;
//************************************************************* mapper implementation
	wire ram_ce = ram_area & cfg.map_sub == 2;
	wire rom_ce = cpu.addr[15] | (prg_ext & ram_area);
	
	wire map_cpu_oe 			= cpu.rw & (dsw_ce | skram_ce);
	wire [7:0]map_cpu_dout 	= 
	dsw_ce ? {cpu.addr[15:10], cfg.jumper[1:0]} : 
	skram[cpu.addr[1:0]][7:0];
	
	wire ciram_a10 			= 
	mir_mode == 0 ? ppu.addr[10] : 
	mir_mode == 1 ? ppu.addr[11] : 
	mir_mode[0];
	
	wire [19:10]chr_addr 	= 
	cfg.map_sub == 1 & ppu.addr[12:11] == 0 ? {chr_reg[0][7:0], ppu.addr[10]} :
	cfg.map_sub == 1 & ppu.addr[12:11] == 1 ? {chr_reg[1][7:0], ppu.addr[10]} :
	cfg.map_sub == 1 & ppu.addr[12:11] == 2 ? {chr_reg[6][7:0], ppu.addr[10]} :
	cfg.map_sub == 1 & ppu.addr[12:11] == 3 ? {chr_reg[7][7:0], ppu.addr[10]} :
	{outer[5:4], chr_reg[ppu.addr[12:10]][7:0]};
	
	
	
	wire [19:13]prg_addr;
	
	assign prg_addr[17:13] 	=
	ram_area ? prg_reg[3] :
	prg_mode == 0 & cpu.addr[14] == 0 ? {outer[3:0], cpu.addr[13]} :
	prg_mode == 0 & cpu.addr[14] == 1 ? {4'b1111, cpu.addr[13]} :
	prg_mode == 1 ? {outer[3:1], cpu.addr[14:13]} : 
	cpu.addr[14:13] == 0 ? prg_reg[0] :
	cpu.addr[14:13] == 1 ? prg_reg[1] :
	cpu.addr[14:13] == 2 ? prg_reg[2] : 5'b11111;
	
	assign prg_addr[19:18]	= outer[5:4];
	
	wire [14:13]srm_addr 	= outer[7:6];
	
	
	wire ram_area 			= {cpu.addr[15:13], 13'd0} == 16'h6000;
	wire dsw_ce  			= (cpu.addr[15:0] & 16'hDF00) == 16'h5000;
	wire skram_ce 			= (cpu.addr[15:0] & 16'hDF00) == 16'h5100;
	wire irq_we   			= (cpu.addr[15:0] & 16'h8301) == 16'h8200 & !cpu.rw;
	
	
	wire [1:0]mir_mode 	= mode[1:0];
	wire [1:0]prg_mode 	= mode[4:3];
	wire prg_ext 			= mode[5] & cfg.map_sub != 2;
	wire irq_mode 			= mode[6];
	
	reg [7:0]mode;
	reg [7:0]chr_reg[8];
	reg [7:0]prg_reg[4];
	reg [7:0]outer;
	reg [7:0]skram[4];
	reg [15:0]irq_ctr;
	reg irq_pend, irq_on;
	
	
	always @(negedge cpu.m2)
	if(sst.act)
	begin
		if(sst.we_reg & {sst.addr[7:3], 3'd0} == 0)chr_reg[sst.addr[2:0]] 		<= sst.dato;
		if(sst.we_reg & {sst.addr[7:2], 2'd0} == 8)prg_reg[sst.addr[1:0]] 		<= sst.dato;
		if(sst.we_reg & {sst.addr[7:2], 2'd0} == 12)skram[sst.addr[1:0]] 	<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 16)mode 									<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 17)outer 								<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 18)irq_ctr[15:8] 						<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 19)irq_ctr[7:0] 						<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 20){irq_pend, irq_on}				<= sst.dato;
	end
		else
	if(mai.map_rst)
	begin
		mode <= 0;
		irq_pend <= 0;
		irq_on <= 0;
	end
		else
	begin
	
		if(irq_we)
		begin
			if(cpu.addr[0] == 0)irq_ctr[7:0] 	<= cpu.data[7:0];
			if(cpu.addr[0] == 0)irq_pend 			<= 0;
			if(cpu.addr[0] == 1)irq_ctr[15:8] 	<= cpu.data[7:0];
			if(cpu.addr[0] == 1)irq_on 			<= mode[7];
		end
			else
		if(irq_on)
		begin
			
			irq_ctr <= irq_mode ? irq_ctr - 1 : irq_ctr + 1;
			if(irq_ctr == 16'h0000){irq_on, irq_pend} <= 2'b01;
			
		end
	
		if(!cpu.rw & (cpu.addr[15:0] & 16'h8300) == 16'h8000)outer[7:0] 	<= cpu.data[7:0];
		
		if(!cpu.rw & (cpu.addr[15:0] & 16'h8300) == 16'h8100)mode[7:0] 	<= cpu.data[7:0];
		
		if(!cpu.rw & (cpu.addr[15:0] & 16'h8318) == 16'h8300)prg_reg[cpu.addr[1:0]][7:0] <= cpu.data[7:0];
		
		if(!cpu.rw & (cpu.addr[15:0] & 16'h8318) == 16'h8310)chr_reg[cpu.addr[2:0]][7:0] <= cpu.data[7:0];
		
		if(!cpu.rw & skram_ce)skram[cpu.addr[1:0]][7:0] <= cpu.data[7:0];
		
	
	end

	
endmodule
