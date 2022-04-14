

module irq_acc(//for Acclaim mapper

	input clk,
	input decode_en,
	input cpu_m2,
	input [7:0]cpu_data,
	input [3:0]reg_addr,
	input ppu_a12,
	input map_rst,
	
	output irq,
	
	input  SSTBus sst,
	output sst_ce,
	output [7:0]sst_do
);
	
	assign sst_ce = sst.addr[7:0] >= 16 & sst.addr[7:0] <= 19;
	assign sst_do = 
	sst.addr[7:0] == 16 ? reload_val : 
	sst.addr[7:0] == 17 ? irq_on : //irq_on should be saved befor irq_pend
	sst.addr[7:0] == 18 ? irq_ctr : 
	sst.addr[7:0] == 19 ? {reload_req, irq_pend} :
	8'hff;
	
	
	assign irq 				= irq_pend_ne;
	
	
	wire [7:0]ctr_next	= irq_ctr == 0 ? reload_val : irq_ctr - 1;
	wire irq_trigger 		= ctr_next == 0 & (irq_ctr != 0 | reload_req);
	
	reg [7:0]reload_val;
	reg [7:0]irq_ctr;
	reg irq_on, reload_req, irq_pend, irq_pend_ne;
	reg [2:0]edge_ctr;

	always @(posedge clk)
	if(sst.act)
	begin
		if(decode_en)
		begin
			if(sst.we_reg & sst.addr[7:0] == 16)reload_val 	<= sst.dato;
			if(sst.we_reg & sst.addr[7:0] == 17)irq_on 		<= sst.dato[0];
			if(sst.we_reg & sst.addr[7:0] == 18)irq_ctr		<= sst.dato;
			if(sst.we_reg & sst.addr[7:0] == 19){reload_req, irq_pend} <= sst.dato;
		end
		irq_pend_ne	<= irq_pend;
	end
		else
	if(map_rst)
	begin
		irq_on 	<= 0;
		irq_pend	<= 0;
	end
		else
	begin
		
		if(decode_en)
		case(reg_addr[3:0])
			4'hC:reload_val[7:0] <= cpu_data[7:0];//C000
			4'hE:irq_on 			<= 0;//E000
			4'hF:irq_on 			<= 1;//E001
		endcase
		
		
		if(decode_en & reg_addr == 4'hD)//C001
		begin
			reload_req		<= 1;
			irq_ctr[7:0] 	<= 0;
			edge_ctr			<= 0;
		end
			else
		if(a12_pe)
		begin
		
			if(edge_ctr == 0)
			begin
				reload_req	<= 0;
				irq_ctr 		<= ctr_next;
			end
			
			edge_ctr			<= edge_ctr + 1;
		end
		
	
		if(!irq_on)
		begin
			irq_pend <= 0;
		end
			else
		if(a12_pe & irq_trigger & edge_ctr == 0)
		begin
			irq_pend <= 1;
		end
		
		
		if(!irq_on)
		begin
			irq_pend_ne	<= 0;
		end
			else
		if(a12_ne)
		begin
			irq_pend_ne <= irq_pend;
		end
		
	end

//************************************************************* a12 edge detector
	wire a12_pe = a12d_st == 0 & a12d == 1;
	wire a12_ne = a12d_st == 1 & a12d == 0;
	
	reg a12d_st;
	
	always @(posedge clk)
	begin
		a12d_st	<= a12d;
	end
//************************************************************* a12 deglitcher (onboard cap)
	reg a12d;
	reg [1:0]a12_st;
	
	//negedge used to reduce filter delay
	//from a12 rise to irq triggering should be around 50ns
	always @(negedge clk)
	begin
		a12_st[1:0] <= {a12_st[0], ppu_a12};
		if(a12_st[1:0] == 2'b11)a12d <= 1;
		if(a12_st[1:0] == 2'b00)a12d <= 0;
	end
	
endmodule
