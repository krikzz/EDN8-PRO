
module chip_vrc3(

	input  cpu_m2,
	input  cpu_rw,
	input  cpu_a12,
	input  cpu_a13,
	input  cpu_a14,
	input  cpu_ce_n,
	input  [3:0]cpu_data,
	
	output irq_n,
	output wram_ce_n,
	output prg_ce_n,
	output [17:14]prg_addr,
	
	input  rst,
	input  SSTBus sst,
	output [7:0]sst_di
);

//************************************************************* sst
	assign sst_di[7:0] =
	sst.addr[7:0] == 0 ? prg_reg : 
	sst.addr[7:0] == 1 ? {irq_pend, irq_cfg[2:0]} : 
	sst.addr[7:0] == 2 ? irq_reload[15:8] : 
	sst.addr[7:0] == 3 ? irq_reload[7:0] : 
	sst.addr[7:0] == 4 ? irq_ctr[15:8] : 
	sst.addr[7:0] == 5 ? irq_ctr[7:0] : 
	8'hff;
//*************************************************************	
	assign irq_n				= !irq_pend;
	assign wram_ce_n			= !({cpu_addr[15:13], 13'd0} == 16'h6000);
	assign prg_ce_n			= !cpu_addr[15];
	assign prg_addr[17:14]	= !cpu_addr[14] ? prg_reg[3:0] : 4'b1111;
	
	wire [15:12]cpu_addr		= {!cpu_ce_n, cpu_a14, cpu_a13, cpu_a12};
	
	wire irq_mode8 			= irq_cfg[2];
	wire irq_on 				= irq_cfg[1];
	
	reg [3:0]prg_reg;
	reg [2:0]irq_cfg;
	reg [15:0]irq_reload, irq_ctr;
	reg irq_pend;
	
	always @(negedge cpu_m2)
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
	if(rst)
	begin
		irq_cfg	<= 0;
		irq_pend <= 0;
	end
		else
	begin
//************************************************************* regs
		if(!cpu_rw)
		case(cpu_addr[15:12])
			'h8:irq_reload[3:0] 				<= cpu_data[3:0];
			'h9:irq_reload[7:4] 				<= cpu_data[3:0];
			'hA:irq_reload[11:8] 			<= cpu_data[3:0];
			'hB:irq_reload[15:12] 			<= cpu_data[3:0];
			'hC:{irq_pend, irq_cfg[2:0]} 	<= {1'b0, cpu_data[2:0]};
			'hD:{irq_pend, irq_cfg[1]} 	<= {1'b0, irq_cfg[0]};
			'hF:prg_reg[3:0] 					<= cpu_data[3:0];
		endcase
//************************************************************* irq		
		if(cpu_addr[15:12] == 'hC & !cpu_rw)
		begin
			if(cpu_data[1])irq_ctr <= irq_reload;
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
//*************************************************************		
	end
	
endmodule
