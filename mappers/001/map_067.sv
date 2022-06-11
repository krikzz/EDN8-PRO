
module map_067(

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
	sst.addr[7:2] == 0 	? chr_reg[sst.addr[1:0]] : 
	sst.addr[7:0] == 4 	? prg_reg : 
	sst.addr[7:0] == 5 	? irq_ctr[15:8] : 
	sst.addr[7:0] == 6 	? irq_ctr[7:0] : 
	sst.addr[7:0] == 7 	? {irq_pend, irq_on, mirror_mode[1:0]} : 	
	sst.addr[7:0] == 127 ? cfg.map_idx : 8'hff;
//************************************************************* mapper-controlled pins
	assign srm.ce				= 0;
	assign srm.oe				= 0;
	assign srm.we				= 0;
	assign srm.addr[12:0]	= cpu.addr[12:0];
	
	assign prg.ce				= cpu.addr[15];
	assign prg.oe 				= cpu.rw;
	assign prg.we				= 0;
	assign prg.addr[13:0]	= cpu.addr[13:0];
	assign prg.addr[16:14] 	= cpu.addr[14] ? 3'b111 : prg_reg[2:0];
	
	assign chr.ce 				= mao.ciram_ce;
	assign chr.oe 				= !ppu.oe;
	assign chr.we 				= cfg.chr_ram ? !ppu.we & mao.ciram_ce : 0;
	assign chr.addr[10:0]	= ppu.addr[10:0];
	assign chr.addr[16:11] 	= chr_bank[5:0];

	
	//A10-Vmir, A11-Hmir
	assign mao.ciram_a10 	=  mirror_mode[1] ? mirror_mode[0] : !mirror_mode[0] ? ppu.addr[10] : ppu.addr[11];
	assign mao.ciram_ce 		= !ppu.addr[13];
	
	assign mao.irq				= irq_pend;
//************************************************************* mapper implementation
		
	wire [5:0]chr_bank = chr_reg[ppu.addr[12:11]];
	
	
	reg [5:0]chr_reg[4];
	reg [2:0]prg_reg;
	reg [15:0]irq_ctr;
	reg [1:0]mirror_mode;
	reg irq_on;
	reg irq_pend;

	
	always @(negedge cpu.m2)
	if(sst.act)
	begin
		if(sst.we_reg & sst.addr[7:2] == 0)chr_reg[sst.addr[1:0]] <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 4)prg_reg <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 5)irq_ctr[15:8] <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 6)irq_ctr[7:0] <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 7){irq_pend, irq_on, mirror_mode[1:0]} <= sst.dato;
	end
		else
	begin
		
		if(irq_on)
		begin
			irq_ctr <= irq_ctr - 1;
			if(irq_ctr == 0){irq_on, irq_pend} <= 2'b01;
		end
		
		if(cpu.addr[15] & !cpu.rw)
		begin
			if(cpu.addr[14] == 0)chr_reg[cpu.addr[13:12]] 	<= cpu.data;
			if(cpu.addr[14:12] == 4)irq_ctr[15:0] 				<= {irq_ctr[7:0], cpu.data[7:0]};
			if(cpu.addr[14:12] == 5){irq_pend, irq_on} 		<= {1'b0, cpu.data[4]};
			if(cpu.addr[14:12] == 6)mirror_mode[1:0] 			<= cpu.data[1:0];
			if(cpu.addr[14:12] == 7)prg_reg[2:0] 				<= cpu.data[2:0];
		end
		
	
	end

	
endmodule
