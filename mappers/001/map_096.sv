
module map_096(

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
	assign mao.chr_mask_off = 1;
	assign mao.srm_mask_off = 0;
	assign mao.mir_4sc		= 0;//enable support for 4-screen mirroring. for activation should be enabled in cfg.mir_4 also
	assign mao.bus_cf 		= 0;//bus conflicts
//************************************************************* save state regs read
	assign mao.sst_di[7:0] =
	sst.addr[7:0] == 0 	? {chr_page, prg_reg[1:0]} :
	sst.addr[7:0] == 1 	? chr_bank : 
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
	assign prg.addr[16:15] 	= prg_reg[1:0];
	
	assign chr.ce 				= mao.ciram_ce;
	assign chr.oe 				= !ppu.oe;
	assign chr.we 				= cfg.chr_ram ? !ppu.we & mao.ciram_ce : 0;
	assign chr.addr[11:0]	= ppu.addr[12:0];
	assign chr.addr[13:12] 	= ppu.addr[12] ? 2'b11 : chr_bank[1:0];
	assign chr.addr[14] 		= chr_page;

	
	//A10-Vmir, A11-Hmir
	assign mao.ciram_a10 	= cfg.mir_v ? ppu.addr[10] : ppu.addr[11];
	assign mao.ciram_ce 		= !ppu.addr[13];
	
	assign mao.irq				= 0;
//************************************************************* mapper implementation	

	//wire ppu_clk = ppu_oe & ppu_we;
	reg [4:0]pa13_st;
	
	always @(posedge mai.clk)
	if(sst.act)
	begin
		if(sst.we_reg & sst.addr[7:0] == 1 & cpu.m3)chr_bank <= sst.dato;
	end
		else
	begin
	
		pa13_st[4:0] 		<= {pa13_st[3:0], ppu.addr[13]};
		
		if(pa13_st[4:3] == 2'b01 & ppu.addr[12] == 0 & ppu.we & ppu.oe)
		begin
			chr_bank[1:0] 	<= ppu.addr[9:8];
		end
		
	end
	
	
	reg [1:0]prg_reg;
	reg [1:0]chr_bank;
	reg chr_page;
	
	always @(negedge cpu.m2)
	if(sst.act)
	begin
		if(sst.we_reg & sst.addr[7:0] == 0){chr_page, prg_reg[1:0]} <= sst.dato;
	end
		else
	if(cpu.addr[15] & !cpu.rw)
	begin
		prg_reg[1:0] 	<= cpu.data[1:0];
		chr_page 		<= cpu.data[2];
	end
	
	
endmodule
