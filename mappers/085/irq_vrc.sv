
module irq_vrc(
			
	input  [7:0]cpu_data,
	input  cpu_m2,
	input  cpu_rw,
	input  map_rst,
	input  ce_latx,//latch 8 bit (vrc6)
	input  ce_latl,//latch 4 lo bits (vrc4)
	input  ce_lath,//latch 4 hi bits (vrc4)
	input  ce_ctrl,//control
	input  ce_ackn,//acknowledge
	
	output irq,
	
	input  SSTBus sst,
	output [7:0]ss_dout
);


	assign ss_dout[7:0] = 
	sst.addr == 32 ? {irq_pend, irq_cfg[2:0]}  : 
	sst.addr == 33 ? irq_latch[7:0] :
	sst.addr == 34 ? irq_ctr[7:0] :
	sst.addr == 35 ? prescal[7:0] : 
	sst.addr == 36 ? prescal[8] : 
	8'hff;
	
	assign irq 			= irq_on & irq_pend;
	
	
	wire irq_cyc_mode = irq_cfg[2];
	wire irq_on 		= irq_cfg[1];
	wire scan_tick 	= prescal == 113 | prescal == 227 | prescal == 340;//prescal[9];
	wire ctr_tick 		= (irq_cyc_mode | scan_tick);
	
	reg irq_pend;
	reg [2:0]irq_cfg;
	reg [7:0]irq_latch;
	reg [7:0]irq_ctr;
	reg [8:0]prescal;
	
	always @(negedge cpu_m2)
	if(sst.act)
	begin
		if(sst.we_reg & sst.addr[7:0] == 32){irq_pend, irq_cfg[2:0]} 	<= sst.dato[3:0];
		if(sst.we_reg & sst.addr[7:0] == 33)irq_latch[7:0] 				<= sst.dato[7:0];
		if(sst.we_reg & sst.addr[7:0] == 34)irq_ctr[7:0] 					<= sst.dato[7:0];
		if(sst.we_reg & sst.addr[7:0] == 35)prescal[7:0] 					<= sst.dato[7:0];
		if(sst.we_reg & sst.addr[7:0] == 36)prescal[8] 						<= sst.dato[1:0];
	end
		else
	if(map_rst)
	begin
		irq_cfg 	<= 0;
		irq_pend <= 0;
	end
		else
	begin
	
		if(ce_latx & !cpu_rw)irq_latch[7:0] <= cpu_data[7:0];
		if(ce_latl & !cpu_rw)irq_latch[3:0] <= cpu_data[3:0];
		if(ce_lath & !cpu_rw)irq_latch[7:4] <= cpu_data[3:0];
		
		if(ce_ctrl & !cpu_rw)//ctrl
		begin
			irq_cfg[2:0] 	<= cpu_data[2:0];
			irq_pend 		<= 0;
		end
			else
		if(ce_ackn & !cpu_rw)//ackn
		begin
			irq_cfg[1] 		<= irq_cfg[0];
			irq_pend 		<= 0;
		end
			else
		if(irq_on & ctr_tick & irq_ctr == 8'hff)
		begin
			irq_pend <= 1;
		end
		
		
		if(ce_ctrl & !cpu_rw & cpu_data[1])//control
		begin
			prescal 			<= 0;
			irq_ctr[7:0] 	<= irq_latch[7:0];
		end
			else
		if(irq_on)
		begin
		
			if(ctr_tick)
			begin
				irq_ctr <= irq_ctr == 8'hff ? irq_latch : irq_ctr + 1;
			end
			
			prescal <= prescal == 340 ? 0 : prescal + 1;
			
		end
		
	end

endmodule
