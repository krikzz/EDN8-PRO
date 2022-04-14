
module map_001(//MMC1

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
//************************************************************* mapper output assignments
	assign srm.ce				= pin_ram_ce;
	assign srm.oe				= cpu.rw;
	assign srm.we				= !cpu.rw;
	assign srm.addr[12:0]	= cpu.addr[12:0];
	assign srm.addr[14:13]	= pin_srm_addr[14:13];
	
	assign prg.ce				= cpu.addr[15];
	assign prg.oe 				= cpu.rw;
	assign prg.we				= 0;
	assign prg.addr[13:0]	= cpu.addr[13:0];
	assign prg.addr[18:14]	= pin_prg_addr[18:14];
	
	assign chr.ce 				= mao.ciram_ce;
	assign chr.oe 				= !ppu.oe;
	assign chr.we 				= cfg.chr_ram ? !ppu.we & mao.ciram_ce : 0;
	assign chr.addr[11:0]	= ppu.addr[11:0];
	assign chr.addr[16:12]	= pin_chr_addr[16:12];

	
	//A10-Vmir, A11-Hmir
	assign mao.ciram_a10 	= pin_cir_a10;
	assign mao.ciram_ce 		= !ppu.addr[13];
	
	assign mao.irq				= 0;
//************************************************************* save state regs read
	assign mao.sst_di[7:0] = 
	sst.addr[7:2] == 0 ? map_regs[sst.addr[1:0]][4:0] :
	sst.addr[7:0] == 4 ? {4'b0000,  buff[4:0]} :
	sst.addr[7:0] == 127 ? cfg.map_idx : 8'hff;
//************************************************************* mapper-controlled pin
	wire pin_ram_ce;
	wire pin_cir_a10;
	wire [18:14]pin_prg_addr;
	wire [16:12]pin_chr_addr;
	wire [14:13]pin_srm_addr;
//************************************************************* mapper implementation below
	assign pin_ram_ce 			= {cpu.addr[15:13], 13'd0} == 16'h6000 & ram_on;
	assign pin_cir_a10			= !r0[1] ? r0[0] : !r0[0] ? ppu.addr[10] : ppu.addr[11];//may be should be fixed
	
	assign pin_prg_addr[14] 	= cfg.map_sub == 5 ? cpu.addr[14] : prg_bank[0];
	assign pin_prg_addr[18:15] = {chr_bank[4], prg_bank[3:1]};
	
	assign pin_chr_addr[16:12] = 
	cfg.chr_ram  ? {4'b0000, chr_bank[0]} : 
	chr_bank[4:0];

	assign pin_srm_addr[14:13]	= cfg.chr_ram ? chr_bank[3:2] : 2'b00;
	
	
	wire [3:0]prg_bank = prg_mode == 0 ? {r3[3:1], cpu.addr[14]} : r0[2] != cpu.addr[14] ? r3[3:0] : (!cpu.addr[14] ? 0 : 4'hf);

	wire [4:0]chr_bank = chr_mode == 0 ? {r1[4:1], ppu.addr[12]} : !ppu.addr[12] ? r1[4:0] : r2[4:0];
	
	
	wire chr_mode 	= r0[4];
	wire prg_mode 	= r0[3];
	wire ram_on   	= r3[4] == 0 | cfg.map_idx == 155;
	
	wire [4:0]r0 	= map_regs[0][4:0];
	wire [4:0]r1 	= map_regs[1][4:0];
	wire [4:0]r2 	= map_regs[2][4:0];
	wire [4:0]r3 	= map_regs[3][4:0];
		
	wire reg_we 	= cpu.addr[15] & !cpu.rw & !reg_we_st;
	wire reg_rst 	= reg_we & cpu.data[7];
	
	reg reg_we_st;
	reg [4:0]map_regs[4];
	reg [4:0]buff;
	
	always @(negedge cpu.m2)
	begin
		reg_we_st <= reg_we;
	end

	always @(negedge cpu.m2)
	if(sst.act)
	begin
		if(sst.we_reg & sst.addr[7:2] == 0)map_regs[sst.addr[1:0]][4:0] <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 4)buff[4:0] <= sst.dato;
	end
		else
	if(mai.map_rst)
	begin
		map_regs[0][4:0] 	<= 5'b11111;
		map_regs[3][4] 	<= 0;
	end
		else
	if(reg_rst)
	begin
		buff[4:0] 			<= 5'b10000;
		map_regs[0][3:2] 	<= 2'b11;
	end
		else
	if(reg_we)
	begin
		if(buff[0] == 0)buff[4:0] <= {cpu.data[0], buff[4:1]};
		if(buff[0] == 1)buff[4:0] <= 5'b10000;
		if(buff[0] == 1)map_regs[cpu.addr[14:13]][4:0] <= {cpu.data[0], buff[4:1]};
	end
endmodule
