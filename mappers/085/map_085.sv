
module map_085(

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
	{sst.addr[7:3], 3'd0} == 0 ? chr_reg[sst.addr[2:0]][7:0] :
	sst.addr[7:0] == 16 	? prg_reg[0][7:0] :
	sst.addr[7:0] == 17 	? prg_reg[1][7:0] :
	sst.addr[7:0] == 18 	? {audio_mute, mir_mode[1:0]} :
	sst.addr[7:0] == 19 	? prg_reg[2][7:0] :
	sst.addr[7:0] == 32 	? irq_ss :
	sst.addr[7:0] == 33 	? irq_ss :
	sst.addr[7:0] == 34 	? irq_ss :
	sst.addr[7:0] == 35 	? irq_ss :
	sst.addr[7:0] == 36 	? irq_ss :
	sst.addr[7:0] == 127 ? cfg.map_idx : 8'hff;
//************************************************************* mapper-controlled pins
	assign srm.ce				= {cpu.addr[15:13], 13'd0} == 16'h6000;
	assign srm.oe				= cpu.rw;
	assign srm.we				= !cpu.rw;
	assign srm.addr[12:0]	= cpu.addr[12:0];
	
	assign prg.ce				= cpu.addr[15];
	assign prg.oe 				= cpu.rw;
	assign prg.we				= 0;
	assign prg.addr[12:0]	= cpu.addr[12:0];
	assign prg.addr[20:13] 	=
	cpu.addr[14:13] == 0 ? prg_reg[0] :
	cpu.addr[14:13] == 1 ? prg_reg[1] :
	cpu.addr[14:13] == 2 ? prg_reg[2] : 8'hFF;
	
	assign chr.ce 				= mao.ciram_ce;
	assign chr.oe 				= !ppu.oe;
	assign chr.we 				= cfg.chr_ram ? !ppu.we & mao.ciram_ce : 0;
	assign chr.addr[9:0]		= ppu.addr[9:0];
	assign chr.addr[17:10] 	= chr_reg[ppu.addr[12:10]][7:0];

	
	//A10-Vmir, A11-Hmir
	assign mao.ciram_a10 	= 
	mir_mode[1:0] == 0 ? ppu.addr[10] : 
	mir_mode[1:0] == 1 ? ppu.addr[11] : 
	mir_mode[1:0] == 2 ? 0 : 1;
	
	assign mao.ciram_ce 		= !ppu.addr[13];
	
	assign mao.irq				= irq_pend;
	assign mao.snd[15:0]		= {vol[10:0], 5'd0};
//************************************************************* mapper implementation
	wire [15:0]reg_addr = {cpu.addr[15:12], 6'd0, cpu.addr[5:4] | cpu.addr[3], 1'b0, cpu.addr[2:0]};
	
	
	reg [7:0]prg_reg[3];
	reg [7:0]chr_reg[8];
	reg [1:0]mir_mode;
	reg audio_mute;
	

	always @(negedge cpu.m2)
	if(sst.act)
	begin
		if(sst.we_reg & sst.addr[7:3] == 0)chr_reg[sst.addr[2:0]][7:0] <= sst.dato[7:0];
		if(sst.we_reg & sst.addr == 16)prg_reg[0][7:0] 						<= sst.dato[7:0];
		if(sst.we_reg & sst.addr == 17)prg_reg[1][7:0] 						<= sst.dato[7:0];
		if(sst.we_reg & sst.addr == 18){audio_mute, mir_mode[1:0]} 		<= sst.dato[2:0];
		if(sst.we_reg & sst.addr == 19)prg_reg[2][7:0] 						<= sst.dato[7:0];
	end
		else
	if(mai.map_rst)
	begin
		chr_reg[0] <= 0;
		chr_reg[1] <= 1;
		chr_reg[2] <= 2;
		chr_reg[3] <= 3;
		chr_reg[4] <= 4;
		chr_reg[5] <= 5;
		chr_reg[6] <= 6;
		chr_reg[7] <= 7;
		mir_mode <= 0;
		audio_mute <= 1;
	end
		else
	if(!cpu.rw)
	case(reg_addr[15:0])
	
		16'h8000:prg_reg[0] <= cpu.data[5:0];
		16'h8010:prg_reg[1] <= cpu.data[5:0];
		16'h9000:prg_reg[2] <= cpu.data[5:0];
		
		16'hA000:chr_reg[0] <= cpu.data[7:0];
		16'hA010:chr_reg[1] <= cpu.data[7:0];
		16'hB000:chr_reg[2] <= cpu.data[7:0];
		16'hB010:chr_reg[3] <= cpu.data[7:0];
		
		16'hC000:chr_reg[4] <= cpu.data[7:0];
		16'hC010:chr_reg[5] <= cpu.data[7:0];
		16'hD000:chr_reg[6] <= cpu.data[7:0];
		16'hD010:chr_reg[7] <= cpu.data[7:0];
		
		16'hE000:{audio_mute, mir_mode[1:0]} <= {cpu.data[6], cpu.data[1:0]};
		
	endcase
	
	
	wire irq_pend;
	wire [7:0]irq_ss;
	
	irq_vrc irq_vrc_inst(
		
		.cpu_data(cpu.data[7:0]),
		.cpu_m2(cpu.m2),
		.cpu_rw(cpu.rw),
		.map_rst(mai.map_rst),
		.ce_latx(reg_addr == 16'hE010),
		.ce_ctrl(reg_addr == 16'hF000),
		.ce_ackn(reg_addr == 16'hF010),		
		.irq(irq_pend),
		
		.sst(sst),
		.ss_dout(irq_ss)
	);
	
	
	
	
	wire [10:0]vol;	
	
	ym2413_audio ym2413_inst(
	
		.clk(cpu.m2),
		.res_n(!mai.map_rst),
		.cpu_d(cpu.data),
		.cpu_a(cpu.addr[14:0]),
		.cpu_ce_n(!cpu.addr[15]),
		.cpu_rw(cpu.rw),
		.audio_out(vol[10:0]),
		.instrument_set(audio_mute)
	);

	
	
endmodule
