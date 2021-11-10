
module irq_vrc//vrc4/6 irq
(bus, ss_ctrl, ss_dout, reg_addr, map_idx, irq);
	
	`include "../base/bus_in.v"
	`include "../base/ss_ctrl_in.v"
	output [7:0]ss_dout;
	input [15:0]reg_addr;
	input [7:0]map_idx;
	output irq;

	assign ss_dout[7:0] = 
	ss_addr == 32 ? {irq_pend, irq_cfg[2:0]}  : 
	ss_addr == 33 ? irq_latch[7:0] :
	ss_addr == 34 ? irq_ctr[7:0] :
	ss_addr == 35 ? prescal[7:0] : 
	ss_addr == 36 ? prescal[9:8] : 
	8'hff;
	
	assign irq = irq_on & irq_pend;
	
	wire vrc6 = map_idx == 24 | map_idx == 26;
	wire vrc4 = !vrc6;
	
	wire reg_laxx = vrc4 == 0 & reg_addr == 16'hf000;
	wire reg_lalo = vrc4 == 1 & reg_addr == 16'hf000;
	wire reg_lahi = vrc4 == 1 & reg_addr == 16'hf001;
	wire reg_ctrl = vrc4 == 1 ? reg_addr == 16'hf002 : reg_addr == 16'hf001;
	wire reg_ackn = vrc4 == 1 ? reg_addr == 16'hf003 : reg_addr == 16'hf002;
	
	wire irq_cyc_mode = irq_cfg[2];
	wire irq_on = irq_cfg[1];
	wire scan_tick =  prescal == 113 | prescal == 227 | prescal == 340;//prescal[9];
	wire ctr_tick = (irq_cyc_mode | scan_tick);
	
	reg irq_pend;
	reg [2:0]irq_cfg;
	reg [7:0]irq_latch;
	reg [7:0]irq_ctr;
	reg [9:0]prescal;
	
	always@(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 32){irq_pend, irq_cfg[2:0]} <= cpu_dat[3:0];
		if(ss_we & ss_addr[7:0] == 33)irq_latch[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 34)irq_ctr[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 35)prescal[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 36)prescal[9:8] <= cpu_dat[1:0];
	end
		else
	if(map_rst)
	begin
		irq_cfg <= 0;
		irq_pend <= 0;
	end
		else
	begin
	
		if(reg_laxx & !cpu_rw)irq_latch[7:0] <= cpu_dat[7:0];
		if(reg_lalo & !cpu_rw)irq_latch[3:0] <= cpu_dat[3:0];
		if(reg_lahi & !cpu_rw)irq_latch[7:4] <= cpu_dat[3:0];
		
		if(reg_ctrl & !cpu_rw)//ctrl
		begin
			irq_cfg[2:0] <= cpu_dat[2:0];
			irq_pend <= 0;
		end
			else
		if(reg_ackn & !cpu_rw)//ackn
		begin
			irq_cfg[1] <= irq_cfg[0];
			irq_pend <= 0;
		end
			else
		if(irq_on & ctr_tick & irq_ctr == 8'hff)irq_pend <= 1;
		
		
		if(reg_ctrl & !cpu_rw & cpu_dat[1])//control
		begin
			//prescal <= 338;
			prescal <= 0;
			irq_ctr[7:0] <= irq_latch[7:0];
		end
			else
		if(irq_on)
		begin
		
			if(ctr_tick)
			begin
				irq_ctr <= irq_ctr == 8'hff ? irq_latch :  irq_ctr + 1;
			end
			
			prescal <= prescal == 340 ? 0 : prescal + 1;
			//prescal <= prescal[9] ? prescal + 335 : prescal - 3;
		end
		
	end

endmodule