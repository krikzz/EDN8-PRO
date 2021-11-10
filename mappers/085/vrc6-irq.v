

//********************************************************************************** VRC6 IRQ
	
	assign irq = irq_on & irq_pend;
	
	wire irq_cyc_mode = irq_cfg[2];
	wire irq_on = irq_cfg[1];
	wire scan_tick =  prescal == 113 | prescal == 227 | prescal == 340;
	
	reg irq_pend;
	reg [2:0]irq_cfg;
	reg [7:0]irq_latch;
	reg [7:0]irq_ctr;
	reg [8:0]prescal;
	
	always@(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 32){prescal[8], irq_pend, irq_cfg[2:0]} <= cpu_dat[4:0];
		if(ss_we & ss_addr[7:0] == 33)irq_latch[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 34)irq_ctr[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 35)prescal[7:0] <= cpu_dat[7:0];
	end
		else
	if(map_rst)
	begin
		irq_cfg <= 0;
		irq_pend <= 0;
	end
		else
	begin
	
	
		if(reg_addr[15:0] == IRQ_REG_LAT & !cpu_rw)irq_latch[7:0] <= cpu_dat[7:0];
		
		if(reg_addr[15:0] == IRQ_REG_CFG & !cpu_rw)
		begin
			irq_cfg[2:0] <= cpu_dat[2:0];
			irq_pend <= 0;
		end
		
		if(reg_addr[15:0] == IRQ_REG_ACK & !cpu_rw)
		begin
			irq_cfg[1] <= irq_cfg[0];
			irq_pend <= 0;
		end
		

		
		
		if(reg_addr[15:0] == IRQ_REG_CFG & !cpu_rw & cpu_dat[1])
		begin
			prescal <= 0;
			irq_ctr[7:0] <= irq_latch[7:0];
		end
			else
		if(irq_on)
		begin
			
			if(irq_cyc_mode | scan_tick)
			begin
				irq_ctr <= irq_ctr == 8'hff ? irq_latch :  irq_ctr + 1;
				if(irq_ctr == 8'hff)irq_pend <= 1;
			end
			
			prescal <= prescal == 340 ? 0 : prescal + 1;
		end
		
	end
	