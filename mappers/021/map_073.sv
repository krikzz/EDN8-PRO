
module map_073(

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
	sst.addr[7:0] == 0 ? prg_reg : 
	sst.addr[7:0] == 1 ? {irq_pend, irq_cfg[2:0]} : 
	sst.addr[7:0] == 2 ? irq_reload[15:8] : 
	sst.addr[7:0] == 3 ? irq_reload[7:0] : 
	sst.addr[7:0] == 4 ? irq_ctr[15:8] : 
	sst.addr[7:0] == 5 ? irq_ctr[7:0] : 
	sst.addr[7:0] == 127 ? cfg.map_idx : 8'hff;
//************************************************************* mapper-controlled pins
	assign srm.ce				= {cpu.addr[15:13], 13'd0} == 16'h6000;
	assign srm.oe				= cpu.rw;
	assign srm.we				= !cpu.rw;
	assign srm.addr[12:0]	= cpu.addr[12:0];
	
	assign prg.ce				= cpu.addr[15];
	assign prg.oe 				= cpu.rw;
	assign prg.we				= 0;
	assign prg.addr[13:0]	= cpu.addr[13:0];
	assign prg.addr[17:14] = !cpu.addr[14] ? prg_reg[3:0] : 4'b1111;
	
	assign chr.ce 				= mao.ciram_ce;
	assign chr.oe 				= !ppu.oe;
	assign chr.we 				= cfg.chr_ram ? !ppu.we & mao.ciram_ce : 0;
	assign chr.addr[12:0]	= ppu.addr[12:0];

	
	//A10-Vmir, A11-Hmir
	assign mao.ciram_a10 	= cfg.mir_v ? ppu.addr[10] : ppu.addr[11];
	assign mao.ciram_ce 		= !ppu.addr[13];
	
	assign mao.irq				= irq_pend;
//************************************************************* mapper implementation

	wire irq_mode8 		= irq_cfg[2];
	wire irq_on 			= irq_cfg[1];
	
	wire [15:0]reg_addr 	= {cpu.addr[15:12], 12'd0};
	
	reg [3:0]prg_reg;
	reg [2:0]irq_cfg;
	reg [15:0]irq_reload, irq_ctr;
	reg irq_pend;
	
	
	always @(negedge cpu.m2)
	if(sst.act)
	begin
		if(sst.we_reg & sst.addr[7:0] == 0)prg_reg[3:0] <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 1){irq_pend, irq_cfg[2:0]} <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 2)irq_reload[15:8] <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 3)irq_reload[7:0] <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 4)irq_ctr[15:8] <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 5)irq_ctr[7:0] <= sst.dato;
	end
		else
	begin
		
		if(!cpu.rw)
		case(reg_addr[15:0])
			16'h8000:irq_reload[3:0] 				<= cpu.data[3:0];
			16'h9000:irq_reload[7:4] 				<= cpu.data[3:0];
			16'hA000:irq_reload[11:8] 				<= cpu.data[3:0];
			16'hB000:irq_reload[15:12] 			<= cpu.data[3:0];
			16'hC000:{irq_pend, irq_cfg[2:0]} 	<= {1'b0, cpu.data[2:0]};
			16'hD000:{irq_pend, irq_cfg[1]} 		<= {1'b0, irq_cfg[0]};
			16'hF000:prg_reg[3:0] 					<= cpu.data[3:0];
		endcase
		
		
		
		if(reg_addr[15:0] == 16'hC000 & !cpu.rw)
		begin
			if(cpu.data[1])irq_ctr <= irq_reload;
		end
			else
		if(irq_on & irq_mode8 == 1)
		begin
			
			if(irq_ctr[7:0] == 8'hff)
			begin
				irq_pend 		<= 1;
				irq_ctr[7:0] 	<= irq_reload[7:0];
			end
				else
			begin
				irq_ctr[7:0] 	<= irq_ctr[7:0] + 1;
			end
			
		end
			else
		if(irq_on & irq_mode8 == 0)
		begin
		
			if(irq_ctr[15:0] == 16'hffff)
			begin
				irq_pend <= 1;
				irq_ctr[15:0] 	<= irq_reload[15:0];
			end
				else
			begin
				irq_ctr[15:0] 	<= irq_ctr[15:0] + 1;
			end
			
		end
		
		
	end
	
endmodule
