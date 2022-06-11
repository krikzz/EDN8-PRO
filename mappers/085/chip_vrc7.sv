
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