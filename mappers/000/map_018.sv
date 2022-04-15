
module map_018(

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
	sst.addr[7:0] == 8 	? prg_reg[0] : 
	sst.addr[7:0] == 9 	? prg_reg[1] : 
	sst.addr[7:0] == 10 	? prg_reg[2] : 
	sst.addr[7:0] == 11 	? irq_ctr[15:8] : 
	sst.addr[7:0] == 12 	? irq_ctr[7:0] : 
	sst.addr[7:0] == 13 	? irq_reload[15:8] : 
	sst.addr[7:0] == 14 	? irq_reload[7:0] : 
	sst.addr[7:0] == 15 	? {irq_pend, irq_on, mirror_mode[1:0], irq_cfg[2:0]} : 
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
	assign prg.addr[18:13]	= 
	cpu.addr[15] 	 == 0 ? 0 : 
	cpu.addr[14:13] == 0 ? prg_reg[0][5:0] : 
	cpu.addr[14:13] == 1 ? prg_reg[1][5:0] : 
	cpu.addr[14:13] == 2 ? prg_reg[2][5:0] : 6'b111111;
	
	assign chr.ce 				= mao.ciram_ce;
	assign chr.oe 				= !ppu.oe;
	assign chr.we 				= cfg.chr_ram ? !ppu.we & mao.ciram_ce : 0;
	assign chr.addr[9:0]		= ppu.addr[9:0];
	assign chr.addr[17:10]	= chr_reg[ppu.addr[12:10]][7:0];

	
	//A10-Vmir, A11-Hmir
	assign mao.ciram_a10 	= 
	mirror_mode == 1 ? ppu.addr[10] : 
	mirror_mode == 0 ? ppu.addr[11] : 
	mirror_mode[0];
	
	assign mao.ciram_ce 		= !ppu.addr[13];
	
	assign mao.irq				= irq_pend;
//************************************************************* mapper implementation
	
	wire [3:0]reg_addr = {cpu.addr[14:12], cpu.addr[1]};
	
	wire [15:0]irq_ctr_val = 
	irq_cfg[2] ? {12'd0, irq_ctr[3:0]} : 
	irq_cfg[1] ? {8'd0, irq_ctr[7:0]} : 
	irq_cfg[0] ? {4'd0, irq_ctr[11:0]} : irq_ctr[15:0];
	
	
	reg [7:0]chr_reg[8];
	reg [7:0]prg_reg[3];
	reg [15:0]irq_ctr;
	reg [15:0]irq_reload;
	reg [2:0]irq_cfg;
	reg [1:0]mirror_mode;
	reg irq_on;
	reg irq_pend;

	always @(negedge cpu.m2)
	if(sst.act)
	begin
		if(sst.we_reg & sst.addr[7:3] == 0)chr_reg[sst.addr[2:0]] <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 8)prg_reg[0]			<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 9)prg_reg[1]			<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 10)prg_reg[2]			<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 11)irq_ctr[15:8] 		<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 12)irq_ctr[7:0] 		<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 13)irq_reload[15:8] 	<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 14)irq_reload[7:0] 	<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 15){irq_pend, irq_on, mirror_mode[1:0], irq_cfg[2:0]} <= sst.dato;
	end
		else
	begin
	
		if(irq_on)
		begin
		
			irq_ctr <= irq_ctr - 1;
			
			if(irq_ctr_val == 1)
			begin
				irq_pend <= 1;
				irq_on 	<= 0;
			end
			
		end
	
		if(!cpu.rw & cpu.addr[15])
		case(reg_addr)
			0:begin
				if(cpu.addr[0] == 0)prg_reg[0][3:0] <= cpu.data[3:0]; 
				if(cpu.addr[0] == 1)prg_reg[0][7:4] <= cpu.data[3:0];
			end
			1:begin
				if(cpu.addr[0] == 0)prg_reg[1][3:0] <= cpu.data[3:0]; 
				if(cpu.addr[0] == 1)prg_reg[1][7:4] <= cpu.data[3:0];
			end
			2:begin
				if(cpu.addr[0] == 0)prg_reg[2][3:0] <= cpu.data[3:0];
				if(cpu.addr[0] == 1)prg_reg[2][7:4] <= cpu.data[3:0];
			end
			4:begin
				if(cpu.addr[0] == 0)chr_reg[0][3:0] <= cpu.data[3:0];
				if(cpu.addr[0] == 1)chr_reg[0][7:4] <= cpu.data[3:0];
			end
			5:begin
				if(cpu.addr[0] == 0)chr_reg[1][3:0] <= cpu.data[3:0];
				if(cpu.addr[0] == 1)chr_reg[1][7:4] <= cpu.data[3:0];
			end
			6:begin
				if(cpu.addr[0] == 0)chr_reg[2][3:0] <= cpu.data[3:0];
				if(cpu.addr[0] == 1)chr_reg[2][7:4] <= cpu.data[3:0];
			end
			7:begin
				if(cpu.addr[0] == 0)chr_reg[3][3:0] <= cpu.data[3:0];
				if(cpu.addr[0] == 1)chr_reg[3][7:4] <= cpu.data[3:0];
			end
			
			8:begin
				if(cpu.addr[0] == 0)chr_reg[4][3:0] <= cpu.data[3:0];
				if(cpu.addr[0] == 1)chr_reg[4][7:4] <= cpu.data[3:0];
			end
			9:begin
				if(cpu.addr[0] == 0)chr_reg[5][3:0] <= cpu.data[3:0];
				if(cpu.addr[0] == 1)chr_reg[5][7:4] <= cpu.data[3:0];
			end
			10:begin
				if(cpu.addr[0] == 0)chr_reg[6][3:0] <= cpu.data[3:0];
				if(cpu.addr[0] == 1)chr_reg[6][7:4] <= cpu.data[3:0];
			end
			11:begin
				if(cpu.addr[0] == 0)chr_reg[7][3:0] <= cpu.data[3:0];
				if(cpu.addr[0] == 1)chr_reg[7][7:4] <= cpu.data[3:0];
			end
			12:begin
				if(cpu.addr[0] == 0)irq_reload[3:0] <= cpu.data[3:0];
				if(cpu.addr[0] == 1)irq_reload[7:4] <= cpu.data[3:0];
			end
			13:begin
				if(cpu.addr[0] == 0)irq_reload[11:8] 	<= cpu.data[3:0];
				if(cpu.addr[0] == 1)irq_reload[15:12] 	<= cpu.data[3:0];
			end
			14:begin
				if(cpu.addr[0] == 0)irq_ctr 						<= irq_reload;
				if(cpu.addr[0] == 1){irq_cfg[2:0], irq_on} 	<= cpu.data[3:0];

				irq_pend <= 0;
			end
			15:begin
				if(!cpu.addr[0])mirror_mode[1:0]	<= cpu.data[1:0];
			end
			
		endcase
	
	end
//************************************************************* mapper implementation below

	
endmodule
