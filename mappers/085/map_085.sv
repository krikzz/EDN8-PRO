
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
	sst.addr[7:0]  < 127 ? sst_di :
	sst.addr[7:0] == 127 ? cfg.map_idx : 8'hff;
//************************************************************* mapper-controlled pins
	assign srm.ce				= !wram_ce_n;
	assign srm.oe				= cpu.rw;
	assign srm.we				= !cpu.rw;
	assign srm.addr[12:0]	= cpu.addr[12:0];
	
	assign prg.ce				= cpu.addr[15];
	assign prg.oe 				= cpu.rw;
	assign prg.we				= 0;
	assign prg.addr[12:0]	= cpu.addr[12:0];
	assign prg.addr[20:13] 	= prg_addr[20:13];
	
	assign chr.ce 				= mao.ciram_ce;
	assign chr.oe 				= !ppu.oe;
	assign chr.we 				= cfg.chr_ram ? !ppu.we & mao.ciram_ce : 0;
	assign chr.addr[9:0]		= ppu.addr[9:0];
	assign chr.addr[17:10] 	= chr_addr[17:10];

	//A10-Vmir, A11-Hmir
	assign mao.ciram_a10 	= ciram_a10;
	assign mao.ciram_ce 		= !ppu.addr[13];
	
	assign mao.irq				= !irq_n;
	assign mao.snd[15:0]		= {snd_vol[10:0], 5'd0};
//************************************************************* mapper implementation

	wire irq_n;
	wire ciram_a10;
	wire wram_ce_n;
	wire prg_ce_n;
	wire [20:13]prg_addr;
	wire [17:10]chr_addr;
	wire [10:0]snd_vol;
	wire [7:0]sst_di;
	
	chip_vrc7 vrc7_inst(
	
		.cpu_m2(cpu.m2),
		.cpu_rw(cpu.rw),
		.cpu_a4(cpu.addr[4] | cpu.addr[3]),//works for both VRC7a/b
		.cpu_a5(cpu.addr[5]),
		.cpu_a12(cpu.addr[12]),
		.cpu_a13(cpu.addr[13]),
		.cpu_a14(cpu.addr[14]),
		.cpu_ce_n(!cpu.addr[15]),
		.ppu_oe_n(ppu.oe),
		
		.cpu_data(cpu.data),
		.ppu_addr(ppu.addr[13:10]),
		
		.irq_n(irq_n),
		.ciram_a10(ciram_a10),
		.wram_ce_n(wram_ce_n),
		.prg_ce_n(prg_ce_n),
		.prg_addr(prg_addr),
		.chr_addr(chr_addr),
		.snd_vol(snd_vol),
		
		.rst(mai.map_rst),
		.sst(sst),
		.sst_di(sst_di)
	);
		
	
endmodule


module chip_vrc7(
	
	input  cpu_m2,
	input  cpu_rw,
	input  cpu_a4,
	input  cpu_a5,
	input  cpu_a12,
	input  cpu_a13,
	input  cpu_a14,
	input  cpu_ce_n,
	input  ppu_oe_n,
	
	input  [7:0]cpu_data,
	input  [13:10]ppu_addr,
	
	output irq_n,
	output ciram_a10,
	output wram_ce_n,
	output prg_ce_n,
	output [20:13]prg_addr,
	output [17:10]chr_addr,
	output [10:0]snd_vol,
	
	input  rst,
	input  SSTBus sst,
	output [7:0]sst_di
);
//************************************************************* sst
	assign sst_di[7:0] =
	sst.addr[7:0]  <  8	? chr_reg[sst.addr[2:0]][7:0] :
	sst.addr[7:0] == 16 	? prg_reg[0][7:0] :
	sst.addr[7:0] == 17 	? prg_reg[1][7:0] :
	sst.addr[7:0] == 18 	? {audio_mute, mir_mode[1:0]} :
	sst.addr[7:0] == 19 	? prg_reg[2][7:0] :
	sst.addr[7:0] == 32 	? irq_ss :
	sst.addr[7:0] == 33 	? irq_ss :
	sst.addr[7:0] == 34 	? irq_ss :
	sst.addr[7:0] == 35 	? irq_ss :
	sst.addr[7:0] == 36 	? irq_ss :
	8'hff;
//************************************************************* supa mapper
	assign irq_n				= !irq_pend;
	assign ciram_a10 			= 
	mir_mode[1:0] == 0 ? ppu_addr[10] : 
	mir_mode[1:0] == 1 ? ppu_addr[11] : 
	mir_mode[1:0] == 2 ? 0 : 1;
	assign wram_ce_n			= !({cpu_addr[15:13], 13'd0} == 16'h6000);
	assign prg_ce_n			= !cpu_addr[15];
	
	assign prg_addr[20:13] 	=
	cpu_addr[14:13] == 0 ? prg_reg[0] :
	cpu_addr[14:13] == 1 ? prg_reg[1] :
	cpu_addr[14:13] == 2 ? prg_reg[2] : 8'hFF;
	
	assign chr_addr[17:10]	= chr_reg[ppu_addr[12:10]][7:0];
	
	
	wire [15:0]cpu_addr = {!cpu_ce_n, cpu_a14, cpu_a13, cpu_a12, 6'd0, cpu_a5, cpu_a4, 4'd0};

	reg [7:0]prg_reg[3];
	reg [7:0]chr_reg[8];
	reg [1:0]mir_mode;
	reg audio_mute;
	

	always @(negedge cpu_m2)
	if(sst.act)
	begin
		if(sst.we_reg & sst.addr[7:3] == 0)chr_reg[sst.addr[2:0]][7:0] <= sst.dato[7:0];
		if(sst.we_reg & sst.addr == 16)prg_reg[0][7:0] 						<= sst.dato[7:0];
		if(sst.we_reg & sst.addr == 17)prg_reg[1][7:0] 						<= sst.dato[7:0];
		if(sst.we_reg & sst.addr == 18){audio_mute, mir_mode[1:0]} 		<= sst.dato[2:0];
		if(sst.we_reg & sst.addr == 19)prg_reg[2][7:0] 						<= sst.dato[7:0];
	end
		else
	if(rst)
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
	if(!cpu_rw)
	case(cpu_addr[15:0])
	
		16'h8000:prg_reg[0] <= cpu_data[5:0];
		16'h8010:prg_reg[1] <= cpu_data[5:0];
		16'h9000:prg_reg[2] <= cpu_data[5:0];
		
		16'hA000:chr_reg[0] <= cpu_data[7:0];
		16'hA010:chr_reg[1] <= cpu_data[7:0];
		16'hB000:chr_reg[2] <= cpu_data[7:0];
		16'hB010:chr_reg[3] <= cpu_data[7:0];
		
		16'hC000:chr_reg[4] <= cpu_data[7:0];
		16'hC010:chr_reg[5] <= cpu_data[7:0];
		16'hD000:chr_reg[6] <= cpu_data[7:0];
		16'hD010:chr_reg[7] <= cpu_data[7:0];
		
		16'hE000:{audio_mute, mir_mode[1:0]} <= {cpu_data[6], cpu_data[1:0]};
		
	endcase
//************************************************************* irq	
	wire irq_pend;
	wire [7:0]irq_ss;
	
	irq_vrc irq_vrc_inst(
		
		.cpu_data(cpu_data[7:0]),
		.cpu_m2(cpu_m2),
		.cpu_rw(cpu_rw),
		.map_rst(rst),
		.ce_latx(cpu_addr == 16'hE010),
		.ce_ctrl(cpu_addr == 16'hF000),
		.ce_ackn(cpu_addr == 16'hF010),		
		.irq(irq_pend),
		
		.sst(sst),
		.ss_dout(irq_ss)
	);
//************************************************************* audio
	ym2413_audio ym2413_inst(
	
		.clk(cpu_m2),
		.res_n(!rst),
		.cpu_d(cpu_data),
		.cpu_a(cpu_addr[14:0]),
		.cpu_ce_n(!cpu_addr[15]),
		.cpu_rw(cpu_rw),
		.audio_out(snd_vol[10:0]),
		.instrument_set(audio_mute)
	);

endmodule
