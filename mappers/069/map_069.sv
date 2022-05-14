
module map_069(

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
	sst.addr[7:3] == 0 	? chr_reg[sst.addr[2:0]] :
	sst.addr[7:2] == 2 	? prg_reg[sst.addr[1:0]] :
	sst.addr[7:0] == 12 	? irq_ctr[15:8] :
	sst.addr[7:0] == 13 	? irq_ctr[7:0] :
	sst.addr[7:0] == 14 	? {r_c[1:0], r_d[1:0], raddr[3:0]} : 
	sst.addr[7:0] == 15 	? irq_st :
	sst.addr[7:0] == 127 ? cfg.map_idx : 8'hff;
//************************************************************* mapper-controlled pins
	assign srm.ce				= ram_area & ram_on;
	assign srm.oe				= cpu.rw;
	assign srm.we				= !cpu.rw;
	assign srm.addr[14:0]	= prg.addr[14:0];
	
	assign prg.ce				= cpu.addr[15] | (ram_area & ext_rom_on);
	assign prg.oe 				= cpu.rw;
	assign prg.we				= 0;
	assign prg.addr[12:0]	= cpu.addr[12:0];
	assign prg.addr[20:13] 	=
	cpu.addr[15] == 0			? prg_reg[0][7:0] : 
	cpu.addr[14:13] == 3 	? 8'hff : 
									  prg_reg[1 + cpu.addr[14:13]][7:0];
	
	assign chr.ce 				= mao.ciram_ce;
	assign chr.oe 				= !ppu.oe;
	assign chr.we 				= cfg.chr_ram ? !ppu.we & mao.ciram_ce : 0;
	assign chr.addr[9:0]		= ppu.addr[9:0];
	assign chr.addr[17:10] 	= chr_reg[ppu.addr[12:10]];	

	
	//A10-Vmir, A11-Hmir
	assign mao.ciram_a10 	= !r_c[1] ? (!r_c[0] ? ppu.addr[10] : ppu.addr[11]) : r_c[0];
	assign mao.ciram_ce 		= !ppu.addr[13];
	
	assign mao.irq				= irq_st;
	assign mao.snd[15:0]		= {snd_vol[11:0], 4'd0};
//************************************************************* mapper implementation
	wire ram_area 		= {cpu.addr[15:13], 13'd0} == 16'h6000;

	wire ram_on 		= prg_reg[0][7:6] == 2'b11;
	wire ext_rom_on 	= prg_reg[0][6] == 0;
	wire reg_addr_we 	= cpu.addr[14:13] == 0 & cpu.addr[15] & !cpu.rw;
	wire reg_data_we 	= cpu.addr[14:13] == 1 & cpu.addr[15] & !cpu.rw;
	
	
	reg [7:0]chr_reg[8];
	reg [7:0]prg_reg[4];
	reg [15:0]irq_ctr;
	reg [3:0]raddr;
	reg [1:0]r_c;
	reg [1:0]r_d;
	reg irq_st;

	always @(negedge cpu.m2)
	if(sst.act)
	begin
		if(sst.we_reg & sst.addr[7:3] == 0)chr_reg[sst.addr[2:0]] 	<= sst.dato;
		if(sst.we_reg & sst.addr[7:2] == 2)prg_reg[sst.addr[1:0]] 	<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 12)irq_ctr[15:8] 				<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 13)irq_ctr[7:0] 				<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 14){r_c[1:0], r_d[1:0], raddr[3:0]} <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 15)irq_st 						<= sst.dato;
	end
		else
	begin
		
		if(r_d[1])
		begin
			irq_ctr <= irq_ctr - 1;
			if(irq_ctr == 0 & r_d[0])irq_st <= 1;
		end
		
		if(reg_addr_we)raddr[3:0] 										<= cpu.data[3:0];
		if(reg_data_we & raddr[3] == 0)chr_reg[raddr[2:0]] 	<= cpu.data[7:0];
		if(reg_data_we & raddr[3:2] == 2)prg_reg[raddr[1:0]] 	<= cpu.data[7:0];
		if(reg_data_we & raddr[3:0] == 12)r_c[1:0] 				<= cpu.data[1:0];
		if(reg_data_we & raddr[3:0] == 13){irq_st, r_d[1:0]} 	<= {1'b0, cpu.data[7],cpu.data[0]};
		if(reg_data_we & raddr[3:0] == 14)irq_ctr[7:0] 			<= cpu.data;
		if(reg_data_we & raddr[3:0] == 15)irq_ctr[15:8] 		<= cpu.data;
		
		
	end
	

	wire [11:0]snd_vol;
	
	ym2149 ym2149_inst(
	
		.phi_2(cpu.m2),
		.cpu_d(cpu.data),
		.cpu_a(cpu.addr[14:10]),
		.cpu_ce_n(!cpu.addr[15]),
		.cpu_rw(cpu.rw),
		
		.audio_clk(mai.clk),
		.audio_out(snd_vol),

		.map_enable(!mai.map_rst)
	);
	
endmodule
