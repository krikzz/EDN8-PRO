
module map_079(

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
	sst.addr[7:0] == 0 ? prg_reg : 
	sst.addr[7:0] == 1 ? chr_reg : 
	sst.addr[7:0] == 2 ? mirror_mode : 
	sst.addr[7:0] == 127 ? cfg.map_idx : 8'hff;
//************************************************************* mapper-controlled pins
	assign srm.ce				= 0;
	assign srm.oe				= 0;
	assign srm.we				= 0;
	assign srm.addr[12:0]	= cpu.addr[12:0];
	
	assign prg.ce				= cpu.addr[15];
	assign prg.oe 				= cpu.rw;
	assign prg.we				= 0;
	assign prg.addr[14:0]	= cpu.addr[14:0];
	assign prg.addr[17:15] 	= prg_reg[2:0];
	
	assign chr.ce 				= mao.ciram_ce;
	assign chr.oe 				= !ppu.oe;
	assign chr.we 				= cfg.chr_ram ? !ppu.we & mao.ciram_ce : 0;
	assign chr.addr[12:0]	= ppu.addr[12:0];
	assign chr.addr[16:13] 	= chr_reg[3:0];

	
	//A10-Vmir, A11-Hmir
	assign mao.ciram_a10 	= cfg.map_idx == 113 ? mirror_113 : cfg.mir_v ? ppu.addr[10] : ppu.addr[11];
	assign mao.ciram_ce 		= !ppu.addr[13];
	
	assign mao.irq				= 0;
//************************************************************* mapper implementation
	
	wire mirror_113	= mirror_mode ? ppu.addr[10] : ppu.addr[11];
		
	reg [2:0]prg_reg;
	reg [3:0]chr_reg;
	reg mirror_mode;
	
	always @(negedge cpu.m2)
	if(sst.act)
	begin
		if(sst.we_reg & sst.addr[7:0] == 0)prg_reg 		<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 1)chr_reg 		<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 2)mirror_mode 	<= sst.dato;
	end
		else
	begin
	
		if(mai.map_rst)
		begin
			chr_reg <= 0;
			prg_reg <= 0;
		end
			else
		if(!cpu.rw & cpu.addr[15:13] == 'b010 & cpu.addr[8] == 1)
		begin
			prg_reg[2:0] 	<= cpu.data[5:3];
			chr_reg[2:0] 	<= cpu.data[2:0];
			chr_reg[3] 		<= cpu.data[6];
			mirror_mode 	<= cpu.data[7];
		end
	
	end

	
endmodule
