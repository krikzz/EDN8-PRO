
module map_075(

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
	sst.addr[7:0] == 0 ? prg0 : 
	sst.addr[7:0] == 1 ? prg1 : 
	sst.addr[7:0] == 2 ? prg2 : 
	sst.addr[7:0] == 3 ? chr0 : 
	sst.addr[7:0] == 4 ? chr1 : 
	sst.addr[7:0] == 5 ? mir_mode : 
	sst.addr[7:0] == 127 ? cfg.map_idx : 8'hff;
//************************************************************* mapper-controlled pins
	assign srm.ce				= 0;
	assign srm.oe				= 0;
	assign srm.we				= 0;
	assign srm.addr[12:0]	= 0;
	
	assign prg.ce				= cpu.addr[15];
	assign prg.oe 				= cpu.rw;
	assign prg.we				= 0;
	assign prg.addr[12:0]	= cpu.addr[12:0];
	assign prg.addr[16:13] 	=
	cpu.addr[14:13] == 0 ? prg0[3:0] : 
	cpu.addr[14:13] == 1 ? prg1[3:0] : 
	cpu.addr[14:13] == 2 ? prg2[3:0] : 
	4'b1111; 
	
	assign chr.ce 				= mao.ciram_ce;
	assign chr.oe 				= !ppu.oe;
	assign chr.we 				= cfg.chr_ram ? !ppu.we & mao.ciram_ce : 0;
	assign chr.addr[11:0]	= ppu.addr[11:0];
	assign chr.addr[16:12] 	= !ppu.addr[12] ? chr0[4:0] : chr1[4:0];

	
	//A10-Vmir, A11-Hmir
	assign mao.ciram_a10 	= cfg.map_idx == 151 ? mir_std : !mir_mode ? ppu.addr[10] : ppu.addr[11];
	assign mao.ciram_ce 		= !ppu.addr[13];
	
	assign mao.irq				= 0;
//************************************************************* mapper implementation

	wire mir_std 				= cfg.mir_v ? ppu.addr[10] : ppu.addr[11];

	wire [15:0]reg_addr 		= {cpu.addr[15:12], 12'd0};
	
	reg [3:0]prg0, prg1, prg2;
	reg [4:0]chr0, chr1;
	reg mir_mode;
	
	always @(negedge cpu.m2)
	if(sst.act)
	begin
		if(sst.we_reg & sst.addr[7:0] == 0)prg0 <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 1)prg1 <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 2)prg2 <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 3)chr0 <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 4)chr1 <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 5)mir_mode <= sst.dato[0];
	end
		else
	if(!cpu.rw)
	case(reg_addr[15:0])
		16'h8000:prg0[3:0] <= cpu.data[3:0];
		16'h9000:{chr1[4], chr0[4], mir_mode} <= cpu.data[2:0];
		16'hA000:prg1[3:0] <= cpu.data[3:0];
		16'hC000:prg2[3:0] <= cpu.data[3:0];
		16'hE000:chr0[3:0] <= cpu.data[3:0];
		16'hF000:chr1[3:0] <= cpu.data[3:0];
	endcase
	
endmodule
