
module map_082(

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
	sst.addr[7:0] == 9 ? {prg_sel2, prg_sel1, prg_sel0, ram_on2, ram_on1, ram_on0, a12_invert, mirror_mode} :
	sst.addr[7:0] == 127 ? cfg.map_idx : 8'hff;
//************************************************************* mapper-controlled pins
	assign srm.ce				= ram0 | ram1 | ram2;
	assign srm.oe				= cpu.rw;
	assign srm.we				= !cpu.rw;
	assign srm.addr[12:0]	= cpu.addr[12:0];
	
	assign prg.ce				= cpu.addr[15];
	assign prg.oe 				= cpu.rw;
	assign prg.we				= 0;
	assign prg.addr[12:0]	= cpu.addr[12:0];
	assign prg.addr[18:13] 	= 
	cpu.addr[14:13] == 0 ? prg_reg[0][5:0] : 
	cpu.addr[14:13] == 1 ? prg_reg[1][5:0] : 
	cpu.addr[14:13] == 2 ? prg_reg[2][5:0] : 
	6'b111111;
	
	assign chr.ce 				= mao.ciram_ce;
	assign chr.oe 				= !ppu.oe;
	assign chr.we 				= cfg.chr_ram ? !ppu.we & mao.ciram_ce : 0;
	assign chr.addr[9:0]		= ppu.addr[9:0];
	assign chr.addr[17:10] 	= 
	ppu_bank[1:0] == 0 ? {chr_reg[0][6:0], ppu.addr[10]} :
	ppu_bank[1:0] == 1 ? {chr_reg[1][6:0], ppu.addr[10]} :
	ppu.addr[11:10] == 0 ? chr_reg[2][7:0] :
	ppu.addr[11:10] == 1 ? chr_reg[3][7:0] :
	ppu.addr[11:10] == 2 ? chr_reg[4][7:0] :
	chr_reg[5][6:0]; 

	
	//A10-Vmir, A11-Hmir
	assign mao.ciram_a10 	= mirror_mode ? ppu.addr[10] : ppu.addr[11];
	assign mao.ciram_ce 		= !ppu.addr[13];
	
	assign mao.irq				= 0;
//************************************************************* mapper implementation
	wire ram_area = {cpu.addr[15:13], 13'd0} == 16'h6000;
	wire ram0 = ram_area & cpu.addr[12:11] == 0 & ram_on0;
	wire ram1 = ram_area & cpu.addr[12:11] == 1 & ram_on1;
	wire ram2 = ram_area & cpu.addr[12:11] == 2 & ram_on2;
	
	wire [1:0]ppu_bank = !a12_invert ? ppu.addr[12:11] : {!ppu.addr[12], ppu.addr[11]};	
	
	reg [7:0]chr_reg[6];
	reg [5:0]prg_reg[3];

	reg mirror_mode;
	reg a12_invert;
	reg ram_on0;
	reg ram_on1;
	reg ram_on2;
	reg prg_sel0;
	reg prg_sel1;
	reg prg_sel2;
	

	always @(negedge cpu.m2)
	if(sst.act)
	begin
		if(sst.we_reg & sst.addr[7:2] == 0)chr_reg[sst.addr[1:0]] <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 4)chr_reg[4] <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 5)chr_reg[5] <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 6)prg_reg[0] <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 7)prg_reg[1] <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 8)prg_reg[2] <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 9){prg_sel2, prg_sel1, prg_sel0, ram_on2, ram_on1, ram_on0, a12_invert, mirror_mode} <= sst.dato;
	end
		else
	if({cpu.addr[15:4], 4'd0} == 16'h7EF0 & !cpu.rw)
	begin
		
		case(cpu.addr[3:0])
			0:begin
				chr_reg[0][6:0] 	<= cpu.data[7:1];
			end
			1:begin
				chr_reg[1][6:0] 	<= cpu.data[7:1];
			end
			2:begin
				chr_reg[2][7:0] 	<= cpu.data[7:0];
			end
			3:begin
				chr_reg[3][7:0] 	<= cpu.data[7:0];
			end
			4:begin
				chr_reg[4][7:0] 	<= cpu.data[7:0];
			end
			5:begin
				chr_reg[5][7:0] 	<= cpu.data[7:0];
			end
			6:begin
				mirror_mode 		<= cpu.data[0];
				a12_invert 			<= cpu.data[1];
			end
			7:begin
				ram_on0 				<= cpu.data[7:0] == 8'hCA;
			end
			8:begin
				ram_on1 				<= cpu.data[7:0] == 8'h69;
			end
			9:begin
				ram_on2 				<= cpu.data[7:0] == 8'h84;
			end
			10:begin
				prg_reg[0][5:0] 	<= cpu.data[7:2];
			end
			11:begin
				prg_reg[1][5:0] 	<= cpu.data[7:2];
			end
			12:begin
				prg_reg[2][5:0] 	<= cpu.data[7:2];
			end		
		endcase
		
	end

	
endmodule
