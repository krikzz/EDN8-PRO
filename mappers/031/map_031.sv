
module map_031(

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
	assign mao.prg_mask_off = 1;
	assign mao.chr_mask_off = 0;
	assign mao.srm_mask_off = 0;
	assign mao.mir_4sc		= 0;//enable support for 4-screen mirroring. for activation should be enabled in cfg.mir_4 also
	assign mao.bus_cf 		= 0;//bus conflicts
//************************************************************* save state regs read
	assign mao.sst_di[7:0] =
	sst.addr[7:0] == 127 ? cfg.map_idx : 8'hff;
//************************************************************* mapper-controlled pins
	assign srm.ce				= 0;
	assign srm.oe				= 0;
	assign srm.we				= 0;
	assign srm.addr[12:0]	= cpu.addr[12:0];
	
	assign prg.ce				= cpu.addr[15] | ram_ce_x;
	assign prg.oe 				= cpu.rw;
	assign prg.we				= !cpu.rw & (ram_ce_x | ram_ce_fds);
	assign prg.addr[11:0]	= cpu.addr[11:0];
	assign prg.addr[20:12]	= prg_addr[20:12];
	
	assign chr.ce 				= mao.ciram_ce;
	assign chr.oe 				= !ppu.oe;
	assign chr.we 				= cfg.chr_ram ? !ppu.we & mao.ciram_ce : 0;
	assign chr.addr[12:0]	= ppu.addr[12:0];

	
	//A10-Vmir, A11-Hmir
	assign mao.ciram_a10 	= cfg.mir_v ? ppu.addr[10] : ppu.addr[11];
	assign mao.ciram_ce 		= !ppu.addr[13];
	
	assign mao.irq				= 0;
	assign int_cpu_oe 		= map_oe_n163 | map_oe_fds;
	assign int_cpu_data 		= 
	map_oe_fds 	? dout_fds[7:0] : 
	map_oe_n163 ? dout_n163[7:0] : 
	8'hff;
//************************************************************* mapper implementation	
	wire [20:12]prg_addr;
	
	assign prg_addr[19:12] = 
	player_bank ? 8'hff : 
	ram_ce_std & act_fds ? bank_fds[cpu.addr[12]][7:0] :
	ram_ce_std  ? {5'd0, 2'd0, cpu.addr[12]}: 
	ram_ce_pla  ? {5'd1, 3'd0} :
	ram_ce_mmc5 ? {5'd2, 3'd0} :
	bank[cpu.addr[14:12]][7:0];
	
	assign prg_addr[20] = ram_ce_std & act_fds ? 0 : ram_ce_x;
	
	
	wire ram_ce_x = ram_ce_mmc5 | ram_ce_std | ram_ce_pla;
	wire ram_ce_std = {cpu.addr[15:13], 13'd0} == 16'h6000;
	wire ram_ce_pla = {cpu.addr[15:8], 8'd0} == 16'h4200;
	wire player_bank = {cpu.addr[15:12], 12'd0} == 16'hF000 & mode == 0;

	reg [7:0]bank[8];
	reg [7:0]bank_fds[2];
	reg mode;

	
	always @(negedge cpu.m2)
	if(sst.act)
	begin
		if(sst.we_reg & sst.addr[7:3] == 0)bank[sst.addr[2:0]] 	<= cpu.data;
		if(sst.we_reg & sst.addr[7:0] == 8)bank_fds[0] 				<= cpu.data;
		if(sst.we_reg & sst.addr[7:0] == 9)bank_fds[1] 				<= cpu.data;
		if(sst.we_reg & sst.addr[7:0] == 10)mode 						<= cpu.data[0];
	end
		else
	if(mai.map_rst)
	begin
		bank[7][7:0] <= 8'hff;
		mode <= 1;
		bank_fds[0] <= 6;
		bank_fds[1] <= 7;
	end
		else
	if(!cpu.rw)
	begin
		
		if(cpu.addr[15:0] == 16'h42FE)mode <= 0;
		if(cpu.addr[15:0] == 16'h42FF)mode <= 1;
		
		if(cpu.addr[15:0] == 16'h5FF6)bank_fds[0] <= cpu.data;
		if(cpu.addr[15:0] == 16'h5FF7)bank_fds[1] <= cpu.data;
		
		if ({cpu.addr[15:12], 12'd0} === 16'h5000)
		begin
			bank[cpu.addr[2:0]][7:0] <= cpu.data[7:0];
		end
		
	end
	
//************************************************************* expansion sound
	reg [7:0]exp_setup;
	always @(negedge cpu.m2)
	if(cpu.addr[15:0] == 16'h42FC & !cpu.rw)
	begin
		exp_setup[7:0] <= cpu.data[7:0];
	end
	
	wire act_vrc6 = exp_setup[0];
	wire act_vrc7 = exp_setup[1];
	wire act_fds  = exp_setup[2];
	wire act_mmc5 = exp_setup[3];
	wire act_n163 = exp_setup[4];
	wire act_su5b = exp_setup[5];
		
	
	assign mao.snd[15:0] = 
	act_vrc6 ? snd_vol_vrc6 : 
	act_vrc7 ? snd_vol_vrc7 : 
	act_fds  ? snd_vol_fds : 
	act_n163 ? snd_vol_n163 : 
	act_su5b ? snd_vol_su5b : 0;
	
//************************************************************* vrc6
	wire map_24 				= 1;
	wire [1:0]reg_map24 		= cpu.addr[3:2] == 0 ?  cpu.addr[1:0] : cpu.addr[3:2];
	wire [1:0]reg_map26 		= cpu.addr[3:2] == 0 ? {cpu.addr[0], cpu.addr[1]} : {cpu.addr[2], cpu.addr[3]};
	wire [15:0]reg_addr 		= {cpu.addr[15:12], 10'd0, (map_24 ? reg_map24[1:0] : reg_map26[1:0])};
	wire [15:0]snd_vol_vrc6;
	
	snd_vrc6 snd_vrc6_inst(
	
		.cpu_m2(cpu.m2),
		.cpu_rw(cpu.rw),	
		.cpu_data(cpu.data),
		.cpu_addr(reg_addr),
		.rst(mai.map_rst),
	
		.snd_vol(snd_vol_vrc6[15:9]),
	);
	
//************************************************************* n163
	wire map_oe_n163 			= {cpu.addr[15:11], 11'd0} == 16'h4800 & cpu.rw & act_n163;
	wire [7:0]dout_n163;
	wire [15:0]snd_vol_n163;
	
	snd_n163 snd_n163_inst(
	
		.cpu(cpu),
		.map_rst(mai.map_rst),
		.dout(dout_n163),
		.vol(snd_vol_n163[15:8])
	);
	
//************************************************************* sunsoft5b
	wire [15:0]snd_vol_su5b;
		
	ym2149 ym2149_inst(
	
		.phi_2(cpu.m2),
		.cpu_d(cpu.data),
		.cpu_a(cpu.addr[14:10]),
		.cpu_ce_n(!cpu.addr[15]),
		.cpu_rw(cpu.rw),
		.audio_out(snd_vol_su5b[15:4]),
		.map_enable(!mai.map_rst)
	);
	
//************************************************************* fds
	wire ram_ce_fds 		= {cpu.addr[15:13], 13'd0} != 16'hE000 & cpu.addr[15] & act_fds;
	wire map_oe_fds 		= map_oe_fds_int & act_fds;
	wire map_oe_fds_int;
	wire [15:0]snd_vol_fds;
	wire [7:0]dout_fds;
	
	fds_snd fds_snd_inst(

		.cpu(cpu),
		.bus_oe(map_oe_fds_int),
		.dout(dout_fds),
		.vol(snd_vol_fds[15:4])
	);

//************************************************************* vrc7
	wire [15:0]snd_vol_vrc7;
	
	ym2413_audio ym2413_inst(
	
		.clk(cpu.m2),
		.res_n(!mai.map_rst),
		.cpu_d(cpu.data),
		.cpu_a(cpu.addr[14:0]),
		.cpu_ce_n(!cpu.addr[15]),
		.cpu_rw(cpu.rw),
		.audio_out(snd_vol_vrc7[15:5]),
		.instrument_set(0)
	);
	
//************************************************************* mmc5
	wire ram_ce_mmc5 = {cpu.addr[15:10], 10'd0} == 16'h5C00 & act_mmc5;

	
endmodule
