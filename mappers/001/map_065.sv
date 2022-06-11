
module map_065(

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
	sst.addr[7:0] == 8 	? prg0  : 
	sst.addr[7:0] == 9 	? prg1  : 
	sst.addr[7:0] == 10 	? prg2 : 
	sst.addr[7:0] == 11 	? irq_ctr[7:0] : 
	sst.addr[7:0] == 12 	? irq_ctr[15:8]  : 
	sst.addr[7:0] == 13 	? irq_reload[7:0] : 
	sst.addr[7:0] == 14 	? irq_reload[15:8] : 
	sst.addr[7:0] == 15 	? {mirror_mode, irq_reload_req, irq_pend, irq_on} : 
	sst.addr[7:0] == 127 ? cfg.map_idx : 8'hff;
//************************************************************* mapper-controlled pins
	assign srm.ce				= 0;
	assign srm.oe				= 0;
	assign srm.we				= 0;
	assign srm.addr[12:0]	= cpu.addr[12:0];
	
	assign prg.ce				= cpu.addr[15];
	assign prg.oe 				= cpu.rw;
	assign prg.we				= 0;
	assign prg.addr[12:0]	= cpu.addr[12:0];
	assign prg.addr[17:13] = 
	cpu.addr[14:13] == 0 ? prg0[4:0] : 
	cpu.addr[14:13] == 1 ? prg1[4:0] : 
	cpu.addr[14:13] == 2 ? prg2[4:0] : 
	5'b11111;
	
	assign chr.ce 				= mao.ciram_ce;
	assign chr.oe 				= !ppu.oe;
	assign chr.we 				= cfg.chr_ram ? !ppu.we & mao.ciram_ce : 0;
	assign chr.addr[9:0]		= ppu.addr[9:0];
	assign chr.addr[17:10] 	= chr_reg[ppu.addr[12:10]];

	
	//A10-Vmir, A11-Hmir
	assign mao.ciram_a10 	= !mirror_mode ? ppu.addr[10] : ppu.addr[11];
	assign mao.ciram_ce 		= !ppu.addr[13];
	
	assign mao.irq				= irq_pend;
//************************************************************* mapper implementation

	reg [7:0]chr_reg[8];
	reg [4:0]prg0;
	reg [4:0]prg1;
	reg [4:0]prg2;
	reg [15:0]irq_ctr;
	reg [15:0]irq_reload;
	reg irq_on;
	reg irq_pend;
	reg irq_reload_req;
	reg mirror_mode;
    
    
   always @(negedge cpu.m2)
   begin
       
	if(sst.act)
	begin
		if(sst.we_reg & sst.addr[7:3] == 0)chr_reg[sst.addr[2:0]] <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 8)prg0 <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 9)prg1 <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 10)prg2 <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 11)irq_ctr[7:0] <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 12)irq_ctr[15:8] <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 13)irq_reload[7:0] <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 14)irq_reload[15:8] <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 15){mirror_mode, irq_reload_req, irq_pend, irq_on} <= sst.dato[3:0];
	end
		else
	 if(mai.map_rst)
	 begin
		prg0 <= 5'h00;
		prg1 <= 5'h01;
		prg2 <= 5'h1E;
		irq_on <= 0;
		irq_pend <= 0;
	 end
		else
	 begin
	 
		if(irq_reload_req)
		begin
			 irq_reload_req <= 0;
			 irq_pend <= 0;
			 irq_ctr[15:0] <= irq_reload[15:0];
		end
			 else
		if(irq_on)
		begin
			 if(irq_ctr != 0)irq_ctr <= irq_ctr - 1;
			 if(irq_ctr == 1)irq_pend <= 1;
		end
	 
		if(cpu.addr[15] & !cpu.rw)
		case(cpu.addr[14:12])
			 0:begin
				  prg0[4:0] <= cpu.data[4:0];
			 end
			 1:begin
				  if(cpu.addr[2:0] == 1)mirror_mode <= cpu.data[7];
						else
				  if(cpu.addr[2:0] == 3)
				  begin
						irq_pend <= 0;
						irq_on 	<= cpu.data[7];
				  end
						else
				  if(cpu.addr[2:0] == 4)irq_reload_req 	<= 1;
						else
				  if(cpu.addr[2:0] == 5)irq_reload[15:8] 	<= cpu.data[7:0];
						else
				  if(cpu.addr[2:0] == 6)irq_reload[7:0] 	<= cpu.data[7:0];
			 end
			 2:begin
				  prg1[4:0]	<= cpu.data[4:0];
			 end
			 3:begin
				  chr_reg[cpu.addr[2:0]]	<= cpu.data[7:0];
			 end
			 4:begin
				  prg2[4:0]	<= cpu.data[4:0];
			 end
		endcase
		
       end
   end
   
	
endmodule
