 
module map_009(//MMC2

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
	assign srm.ce				= {cpu.addr[15:13], 13'd0} == 16'h6000;
	assign srm.oe				= cpu.rw;
	assign srm.we				= !cpu.rw;
	assign srm.addr[12:0]	= cpu.addr[12:0];
	
	assign prg.ce				= cpu.addr[15];
	assign prg.oe 				= cpu.rw;
	assign prg.we				= 0;
	assign prg.addr[12:0]	= cpu.addr[12:0];
	assign prg.addr[17:13]	= pin_prg_addr[17:13];
	
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
	sst.addr[7:0] == 0 ? prg_bank: 
	sst.addr[7:0] == 1 ? chr_bank1: 
	sst.addr[7:0] == 2 ? chr_bank2: 
	sst.addr[7:0] == 3 ? chr_bank3: 
	sst.addr[7:0] == 4 ? chr_bank4: 
	sst.addr[7:0] == 5 ? {5'd0, clatch2, clatch1, mir_mode}: 
	sst.addr[7:0] == 127 ? cfg.map_idx : 8'hff;
//************************************************************* mapper-controlled pin
	wire pin_cir_a10;
	wire [17:13]pin_prg_addr;
	wire [16:12]pin_chr_addr;
//************************************************************* mapper implementation below
	assign pin_cir_a10 			= !mir_mode ? ppu.addr[10] : ppu.addr[11];
	assign pin_prg_addr[17:13]	= cfg.map_idx == 9 ? map_prg09 : map_prg10;
	assign pin_chr_addr[16:12] = !ppu.addr[12] ? (!clatch1 ? chr_bank1 : chr_bank2) : (!clatch2 ? chr_bank3 : chr_bank4);
	
	
	wire [4:0]map_prg09 			= cpu.addr[14:13] == 0 ? {1'b1, prg_bank[3:0]} : {3'b111, cpu.addr[14:13]};
	wire [4:0]map_prg10 			= cpu.addr[14] 	== 0 ? {prg_bank[3:0], cpu.addr[13]} : {3'b111, cpu.addr[14:13]};
	
	
	reg [3:0]prg_bank;
	reg [4:0]chr_bank1;
	reg [4:0]chr_bank2;
	reg [4:0]chr_bank3;
	reg [4:0]chr_bank4;
	reg mir_mode;
	reg clatch1;
	reg clatch2;
	
	reg [7:0]ppu_oe_st;
	reg [10:0]ppu_addr_st;
	
	
	always @(posedge mai.clk)
	begin
	
		ppu_oe_st[7:0] <= {ppu_oe_st[6:0], ppu.oe};
		
		if(ppu_oe_st[3:0] == 4'b1000)
		begin
			ppu_addr_st[10:0] <= ppu.addr[13:3];
		end

		if(sst.act)
		begin
			if(sst.we_reg & sst.addr == 5 & cpu.m3)clatch1 <= cpu.data[1];
			if(sst.we_reg & sst.addr == 5 & cpu.m3)clatch2 <= cpu.data[2];
		end
			else
		if(ppu_oe_st[3:0] == 4'b0001 & ppu_addr_st[0])
		case(ppu_addr_st[10:1])
			10'h0fd:begin
				clatch1 <= 0;
			end
			10'h0fe:begin
				clatch1 <= 1;
			end
			10'h1fd:begin
				clatch2 <= 0;
			end
			10'h1fe:begin
				clatch2 <= 1;
			end
		endcase
	
		
	end


	always @(negedge cpu.m2)
	if(sst.act)
	begin
		if(sst.we_reg & sst.addr == 0)prg_bank  <= sst.dato;
		if(sst.we_reg & sst.addr == 1)chr_bank1 <= sst.dato;
		if(sst.we_reg & sst.addr == 2)chr_bank2 <= sst.dato;
		if(sst.we_reg & sst.addr == 3)chr_bank3 <= sst.dato;
		if(sst.we_reg & sst.addr == 4)chr_bank4 <= sst.dato;
		if(sst.we_reg & sst.addr == 5)mir_mode  <= sst.dato[0];
	end
		else
	if(cpu.addr[15] & !cpu.rw)
	case(cpu.addr[14:12])
		
		2:begin
			prg_bank[3:0] 	<= cpu.data[3:0];
		end
		
		3:begin
			chr_bank1[4:0] <= cpu.data[4:0];
		end
		
		4:begin
			chr_bank2[4:0] <= cpu.data[4:0];
		end
		
		5:begin
			chr_bank3[4:0] <= cpu.data[4:0];
		end
		
		6:begin
			chr_bank4[4:0] <= cpu.data[4:0];
		end
		
		7:begin
			mir_mode 		<= cpu.data[0];
		end
		
	endcase
		
	
endmodule
