
module irq_mmc3
(bus, ss_ctrl, mmc3a, irq, ss_dout);
	
	`include "../base/bus_in.v"
	`include "../base/ss_ctrl_in.v"
	input mmc3a;
	output irq;
	output [7:0]ss_dout;
	
	assign ss_dout[7:0] = 
	ss_addr[7:0] == 16 ? irq_latch : 
	ss_addr[7:0] == 17 ? irq_on : //irq_on should be saved befor irq_pend
	ss_addr[7:0] == 18 ? irq_ctr : 
	ss_addr[7:0] == 19 ? irq_pend : 
	8'hff;
	
	assign irq = irq_pend;
	
	wire ss_we_ctr = ss_act & ss_we & ss_addr[7:0] == 18 & m3;
	wire ss_we_pnd = ss_act & ss_we & ss_addr[7:0] == 19 & m3;
	
	wire [15:0]reg_addr = {cpu_addr[15:13], 12'd0,  cpu_addr[0]};
	
	reg [7:0]irq_latch;
	reg [7:0]irq_ctr;
	reg irq_on, irq_pend, irq_reload_req;

	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 16)irq_latch <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 17)irq_on <= cpu_dat[0];
	end
		else
	if(map_rst)irq_on <= 0;
		else
	if(!cpu_rw)
	case(reg_addr[15:0])
		16'hC000:irq_latch[7:0] <= cpu_dat[7:0];
		//16'hC001:ctr_reload <= 1;
		16'hE000:irq_on <= 0;
		16'hE001:irq_on <= 1;
	endcase

	wire ctr_reload = reg_addr[15:0] == 16'hC001 & !cpu_rw & m2;
	wire [7:0]ctr_next = irq_ctr == 0 ? irq_latch : irq_ctr - 1;
	wire irq_trigger = mmc3a ? ctr_next == 0 & (irq_ctr != 0 | irq_reload_req) : ctr_next == 0;
	
	wire a12d;
	deglitcher dg_inst(ppu_addr[12], a12d, clk);
	
	/*
	always @(posedge ppu_addr[12], negedge irq_on, posedge ss_we_pnd)
	if(ss_we_pnd)irq_pend <= cpu_dat;
		else*/
	always @(posedge a12d, negedge irq_on)
	if(!irq_on)
	begin
		if(!ss_act)irq_pend <= 0;
	end
		else
	if(a12_stb & !ss_act)
	begin
		if(irq_trigger)irq_pend <= 1;
	end
	
	 

	always @(posedge a12d, posedge ctr_reload, posedge ss_we_ctr)
	if(ss_we_ctr)irq_ctr <= cpu_dat;
		else
	if(ctr_reload)
	begin
		irq_reload_req <= 1;
		irq_ctr[7:0] <= 0;
	end
		else
	if(a12_stb & !ss_act)
	begin
		irq_reload_req <= 0;
		irq_ctr <= ctr_next;
	end
	
	
	reg [3:0]irq_a12_st;
	wire a12_stb = irq_a12_st[3:1] == 0;
	always @(negedge m2)
	begin
		irq_a12_st[3:0] <= {irq_a12_st[2:0], a12d};
	end

	
endmodule


module deglitcher
(in, out, clk);
	input in, clk;
	output reg out;

	reg [1:0]st;

	always @(negedge clk)
	begin
		st[1:0] <= {st[0], in};
		if(st[1:0] == 2'b11)out <= 1;
		if(st[1:0] == 2'b00)out <= 0;
	end
	
endmodule
