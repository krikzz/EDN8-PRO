
module map_033(

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
	sst.addr[7:0] == 0 	? chr_reg[0] : 
	sst.addr[7:0] == 1 	? chr_reg[1] :
	sst.addr[7:0] == 2 	? chr_reg[2] :
	sst.addr[7:0] == 3 	? chr_reg[3] :
	sst.addr[7:0] == 4 	? chr_reg[4] :
	sst.addr[7:0] == 5 	? chr_reg[5] :
	sst.addr[7:0] == 6 	? prg_reg[0] :
	sst.addr[7:0] == 7 	? prg_reg[1] :
	sst.addr[7:0] == 8 	? ctr_reload :
	sst.addr[7:0] == 9 	? irq_ctr :
	sst.addr[7:0] == 10 	? {map_48_mode, irq_pend, irq_reload_req, irq_on, mirror_mode} :
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
	assign prg.addr[18:13]	= cpu.addr[14] ? {5'b11111, cpu.addr[13]} : !cpu.addr[13] ? prg_reg[0][5:0] : prg_reg[1][5:0];
	
	assign chr.ce 				= mao.ciram_ce;
	assign chr.oe 				= !ppu.oe;
	assign chr.we 				= cfg.chr_ram ? !ppu.we & mao.ciram_ce : 0;
	assign chr.addr[9:0]		= ppu.addr[9:0];
	assign chr.addr[18:10]	= !ppu.addr[12] ? {chr_addr[7:0], ppu.addr[10]} : {1'b0, chr_addr[7:0]};

	
	//A10-Vmir, A11-Hmir
	assign mao.ciram_a10 	= !mirror_mode ? ppu.addr[10] : ppu.addr[11];
	assign mao.ciram_ce 		= !ppu.addr[13];
	
	assign mao.irq				= irq_pend;
//************************************************************* mapper implementation

	wire [7:0]chr_addr = 
	ppu.addr[12:11] == 0 ? chr_reg[0][7:0] : 
	ppu.addr[12:11] == 1 ? chr_reg[1][7:0] : 
	ppu.addr[12:10] == 4 ? chr_reg[2][7:0] : 
	ppu.addr[12:10] == 5 ? chr_reg[3][7:0] : 
	ppu.addr[12:10] == 6 ? chr_reg[4][7:0] : chr_reg[5][7:0];
	
	reg [5:0]prg_reg[2];
	reg [7:0]chr_reg[6];
	
	reg [7:0]ctr_reload;
	reg [7:0]irq_ctr;
	reg mirror_mode;
	reg irq_on;
	reg irq_reload_req;
	reg irq_pend;
	reg map_48_mode;
	
	
	reg [10:0]a12_filter;
	wire mmc3b_mode 		= 0;
	wire next_ctr_zero 	= (irq_ctr == 1 & !irq_reload_req) | (irq_reload_req & ctr_reload == 0) | (irq_ctr == 0 & ctr_reload == 0 & mmc3b_mode);

	 
	always @(negedge cpu.m2)
	if(sst.act)
	begin
		if(sst.we_reg & sst.addr[7:0] == 0)chr_reg[0] <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 1)chr_reg[1] <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 2)chr_reg[2] <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 3)chr_reg[3] <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 4)chr_reg[4] <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 5)chr_reg[5] <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 6)prg_reg[0] <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 7)prg_reg[1] <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 8)ctr_reload <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 9)irq_ctr <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 10){map_48_mode, irq_pend, irq_reload_req, irq_on, mirror_mode} <= sst.dato;
	end
		else
	begin
	
		if(mai.map_rst)
		begin
			map_48_mode <= 0;
		end
			else
		if(cfg.map_idx == 48)
		begin
			map_48_mode <= 1;
		end
			else
		if(cpu.addr[15:14] == 2'b11 & !cpu.rw)
		begin
			map_48_mode <= 1;
		end
	 
	 
		a12_filter[10:0] <= {a12_filter[9:0], ppu.addr[12]};
	 
		if(a12_filter[7:4] == 4'b0001)
		begin
			if(irq_on & next_ctr_zero)irq_pend 	<= 1;
			if(irq_reload_req)irq_reload_req 	<= 0;
			irq_ctr <= irq_ctr == 0 | irq_reload_req ? ctr_reload : irq_ctr - 1;
		end
		
		
		if(!cpu.rw)
		case({cpu.addr[15:13], 11'd0, cpu.addr[1:0]})
			16'h8000:begin
				prg_reg[0][5:0] 				<= cpu.data[5:0];
				if(!map_48_mode)
				begin
					mirror_mode 				<= cpu.data[6];
				end
			end
			16'h8001:prg_reg[1][5:0] 		<= cpu.data[5:0];
			16'h8002:chr_reg[0][7:0] 		<= cpu.data[7:0];
			16'h8003:chr_reg[1][7:0] 		<= cpu.data[7:0];
			
			16'hA000:chr_reg[2][7:0] 		<= cpu.data[7:0];
			16'hA001:chr_reg[3][7:0] 		<= cpu.data[7:0];
			16'hA002:chr_reg[4][7:0] 		<= cpu.data[7:0];
			16'hA003:chr_reg[5][7:0] 		<= cpu.data[7:0];
			
			16'hC000:ctr_reload[7:0] 		<= cpu.data[7:0] ^ 8'hff;
			16'hC001:irq_reload_req  		<= 1;
			16'hC002:irq_on 			 		<= 1;
			16'hC003:{irq_on, irq_pend}	<= 0;
			
			16'hE000:mirror_mode 			<= cpu.data[6];
		endcase
		
	end

	
endmodule
