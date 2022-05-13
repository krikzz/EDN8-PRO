

module map_019(

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
	sst.addr[7:3] == 0	? chr_reg[sst.addr[2:0]] :
	sst.addr[7:2] == 2	? mirror_reg[sst.addr[1:0]] :
	sst.addr[7:0] == 12	? prg_reg[0] :
	sst.addr[7:0] == 13 	? prg_reg[1] :
	sst.addr[7:0] == 14 	? prg_reg[2] :
	sst.addr[7:0] == 15 	? we_protect :
	sst.addr[7:0] == 16 	? irq_ctr[14:8] :
	sst.addr[7:0] == 17 	? irq_ctr[7:0] :
	sst.addr[7:0] == 18 	? {irq_pend, irq_on, chr_lo_off, chr_hi_off, mirr_cnt, chr_hilo[1:0]} :
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
	assign prg.addr[18:13] 	= cpu.addr[14:13] == 3 ? 6'b111111 : prg_reg[cpu.addr[14:13]][5:0];
	
	assign chr.ce 				= mao.ciram_ce;
	assign chr.oe 				= !ppu.oe;
	assign chr.we 				= !ppu.we & !ppu.addr[13] & mao.chr_xram_ce;
	assign chr.addr[9:0]		= ppu.addr[9:0];
	assign chr.addr[17:10]	= ppu.addr[13:12] == 2'b10 ? mirror[7:0] : chr_page[7:0];

	
	//A10-Vmir, A11-Hmir
	assign mao.ciram_a10 	= mirr_cnt ? mirror[0] : cfg.mir_v ? ppu.addr[10] : ppu.addr[11];
	assign mao.ciram_ce 		= 
	!mirr_cnt ? !ppu.addr[13] : 
	ppu.addr[13:12] == 2'b11 ? 0 : 
	mirror[7:5] == 3'b111 & ppu.addr[13:12] == 2'b10 ? 0 : 1;
							
	
	assign mao.irq				= irq_pend;
	assign mao.snd[15:0]		= {snd_vol[7:0], 8'd0};
	assign mao.chr_xram_ce 	= chr_page[7:5] != 3'b111 ? 0 : lo_ram_ce | hi_ram_ce;
	
	assign int_cpu_oe 		= cpu.rw & (reg_addr == 8'h48 | reg_addr == 8'h50 | reg_addr == 8'h58);
	assign int_cpu_data 		= 
	reg_addr == 8'h50 ? irq_ctr[7:0] : 
	reg_addr == 8'h58 ? {irq_on, irq_ctr[14:8]} : 
	sound_dout;
//************************************************************* mapper implementation
		
	wire [7:0]mirror 		= mirror_reg[ppu.addr[11:10]];
	
	wire lo_ram_ce 		= ppu.addr[12] == 0 & !chr_lo_off;
	wire hi_ram_ce 		= ppu.addr[12] == 1 & !chr_hi_off;
		
	wire [7:0]chr_page 	= chr_reg[ppu.addr[12:10]];
	wire [7:0]reg_addr 	= {cpu.addr[15], cpu.addr[14:11], 3'b000};
	

	reg [7:0]chr_reg[8];
	reg [7:0]mirror_reg[4];
	reg [5:0]prg_reg[3];
	reg [7:0]we_protect;
	reg [14:0]irq_ctr;
	
	reg irq_pend;
	reg irq_on;
	reg chr_lo_off;
	reg chr_hi_off;
	reg mirr_cnt;
	reg [1:0]chr_hilo;
	
	
	always @(negedge cpu.m2)
	if(sst.act)
	begin
		if(sst.we_reg & sst.addr[7:3] == 0)chr_reg[sst.addr[2:0]] 		<= sst.dato;
		if(sst.we_reg & sst.addr[7:2] == 2)mirror_reg[sst.addr[1:0]] 	<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 12)prg_reg[0]		<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 13)prg_reg[1]		<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 14)prg_reg[2]		<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 15)we_protect 		<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 16)irq_ctr[14:8] 	<= sst.dato; 
		if(sst.we_reg & sst.addr[7:0] == 17)irq_ctr[7:0] 	<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 18){irq_pend, irq_on, chr_lo_off, chr_hi_off, mirr_cnt, chr_hilo[1:0]} <= sst.dato;
	end
		else
	if(mai.map_rst)
	begin
		prg_reg[0] 	<= 0;
		prg_reg[1] 	<= 1;
		prg_reg[2] 	<= 2;
		irq_on 		<= 0;
		irq_pend 	<= 0;
		mirr_cnt 	<= 0;
	end
		else
	begin
		
		if(reg_addr == 8'h50 | reg_addr == 8'h58)
		begin
			irq_pend <= 0;
		end

		if(irq_on)
		begin
			if(irq_ctr != 15'h7FFF)irq_ctr 	<= irq_ctr + 1;			
			if(irq_ctr == 15'h7FFE)irq_pend 	<= 1;
		end
		
		
		if(!cpu.rw)
		case(reg_addr)
			8'h48:begin
			end
			8'h50:begin
				irq_ctr[7:0] 			<= cpu.data[7:0];
			end
			8'h58:begin
				irq_ctr[14:8]			<= cpu.data[6:0];
				irq_on 					<= cpu.data[7];
			end
			8'h80:begin
				chr_reg[0][7:0]		<= cpu.data[7:0];
			end
			8'h88:begin
				chr_reg[1][7:0] 		<= cpu.data[7:0];
			end
			8'h90:begin
				chr_reg[2][7:0] 		<= cpu.data[7:0];
			end
			8'h98:begin
				chr_reg[3][7:0] 		<= cpu.data[7:0];
			end
			8'hA0:begin
				chr_reg[4][7:0] 		<= cpu.data[7:0];
			end
			8'hA8:begin
				chr_reg[5][7:0] 		<= cpu.data[7:0];
			end
			8'hB0:begin
				chr_reg[6][7:0] 		<= cpu.data[7:0];
			end
			8'hB8:begin
				chr_reg[7][7:0] 		<= cpu.data[7:0];
			end
			8'hC0:begin
				mirror_reg[0][7:0]	<= cpu.data[7:0];
			end
			8'hC8:begin
				mirror_reg[1][7:0]	<= cpu.data[7:0];
				mirr_cnt <= 1;
			end
			8'hD0:begin
				mirror_reg[2][7:0] 	<= cpu.data[7:0];
			end
			8'hD8:begin
				mirror_reg[3][7:0] 	<= cpu.data[7:0];
			end
			8'hE0:begin
				prg_reg[0][5:0] 		<= cpu.data[5:0];
			end
			8'hE8:begin
				prg_reg[1][5:0] 		<= cpu.data[5:0];
				chr_hilo[1:0] 			<= cpu.data[7:6];
				chr_lo_off 				<= cpu.data[6];
				chr_hi_off 				<= cpu.data[7];
			end
			8'hF0:begin
				prg_reg[2][5:0] 		<= cpu.data[5:0];
			end
			8'hF8:begin
				we_protect[7:0] 		<= cpu.data[7:0];
			end
			
		endcase
		
	end
	
	
	wire [7:0]sound_dout;
	wire [7:0]snd_vol;
	
	snd_n163 snd_inst(
	
		.cpu(cpu),
		.map_rst(mai.map_rst),
		.dout(sound_dout),
		.vol(snd_vol)
	);
	
	
endmodule

