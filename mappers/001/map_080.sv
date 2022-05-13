
module map_080(

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
	sst.addr[7:2] == 0 ? chr_reg[sst.addr[1:0]] : 
	sst.addr[7:0] == 4 ? chr_reg[4] :
	sst.addr[7:0] == 5 ? chr_reg[5] :
	sst.addr[7:0] == 6 ? prg_reg[0] :
	sst.addr[7:0] == 7 ? prg_reg[1] :
	sst.addr[7:0] == 8 ? prg_reg[2] :
	sst.addr[7:0] == 9 ? {ram_on, mirror_mode, mir[1:0]} :
	sst.addr[7:0] == 127 ? cfg.map_idx : 8'hff;
//************************************************************* mapper-controlled pins
	assign srm.ce				= {cpu.addr[15:8], 8'd0} == 16'h7F00 & ram_on;
	assign srm.oe				= cpu.rw;
	assign srm.we				= !cpu.rw;
	assign srm.addr[12:0]	= cpu.addr[12:0];
	
	assign prg.ce				= cpu.addr[15];
	assign prg.oe 				= cpu.rw;
	assign prg.we				= 0;
	assign prg.addr[12:0]	= cpu.addr[12:0];
	assign prg.addr[17:13] = 
	cpu.addr[14:13] == 0 ? prg_reg[0][4:0] : 
	cpu.addr[14:13] == 1 ? prg_reg[1][4:0] : 
	cpu.addr[14:13] == 2 ? prg_reg[2][4:0] : 
	5'b11111;
	
	assign chr.ce 				= mao.ciram_ce;
	assign chr.oe 				= !ppu.oe;
	assign chr.we 				= cfg.chr_ram ? !ppu.we & mao.ciram_ce : 0;
	assign chr.addr[9:0]		= ppu.addr[9:0];
	assign chr.addr[16:10] 	= 
	ppu.addr[12:11] == 0 ? {chr_reg[0][5:0], ppu.addr[10]} : 
	ppu.addr[12:11] == 1 ? {chr_reg[1][5:0], ppu.addr[10]} : 
	ppu.addr[11:10] == 0 ? chr_reg[2][6:0] : 
	ppu.addr[11:10] == 1 ? chr_reg[3][6:0] : 
	ppu.addr[11:10] == 2 ? chr_reg[4][6:0] : 
	chr_reg[5][6:0]; 

	
	//A10-Vmir, A11-Hmir
	assign mao.ciram_a10 	= mirror_mode ? ppu.addr[10] : ppu.addr[11];
	assign mao.ciram_ce 		= !ppu.addr[13];
	
	assign mao.irq				= 0;
//************************************************************* mapper implementation
	
	reg [6:0]chr_reg[6];
	reg [4:0]prg_reg[3];
	
	reg [1:0]mir;
	reg mirror_mode;
	reg ram_on;

	always @(negedge cpu.m2)
	if(sst.act)
	begin
		if(sst.we_reg & sst.addr[7:2] == 0)chr_reg[sst.addr[1:0]] <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 4)chr_reg[4] <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 5)chr_reg[5] <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 6)prg_reg[0] <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 7)prg_reg[1] <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 8)prg_reg[2] <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 9){ram_on, mirror_mode, mir[1:0]} <= sst.dato;
	end
		else
	if({cpu.addr[15:4], 4'd0} == 16'h7EF0 & !cpu.rw)
	begin
		
		case(cpu.addr[3:1])
			0:begin
				chr_reg[cpu.addr[0]][5:0] 		<= cpu.data[6:1];
				mir[cpu.addr[0]] 					<= cpu.data[7];
			end
			1:begin
				chr_reg[2+cpu.addr[0]][6:0] 	<= cpu.data[6:0];
			end
			2:begin
				chr_reg[4+cpu.addr[0]][6:0] 	<= cpu.data[6:0];
			end
			3:begin
				mirror_mode 		<= cpu.data[0];
			end
			4:begin
				ram_on 				<= cpu.data[7:0] == 8'hA3;
			end
			5:begin
				prg_reg[0][4:0] 	<= cpu.data[4:0];
			end
			6:begin
				prg_reg[1][4:0] 	<= cpu.data[4:0];
			end
			7:begin
				prg_reg[2][4:0] 	<= cpu.data[4:0];
			end			
		endcase
		
	end
	
endmodule
