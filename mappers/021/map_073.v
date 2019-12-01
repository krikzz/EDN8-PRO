
`include "../base/defs.v"

module map_073 //VRC3
	(map_out, bus, sys_cfg, ss_ctrl);
	
	`include "../base/bus_in.v"
	`include "../base/map_out.v"
	`include "../base/sys_cfg_in.v"
	`include "../base/ss_ctrl_in.v"
	
	output [`BW_MAP_OUT-1:0]map_out;
	input [`BW_SYS_CFG-1:0]sys_cfg;
	
	
	
	assign sync_m2 = 1;
	assign mir_4sc = 0;//enable support for 4-screen mirroring. for activation should be ensabled in sys_cfg also
	assign srm_addr[12:0] = cpu_addr[12:0];
	assign prg_oe = cpu_rw;
	assign chr_oe = !ppu_oe;
	//*************************************************************  save state setup
	assign ss_rdat[7:0] = 
	ss_addr[7:0] == 0 ? prg : 
	ss_addr[7:0] == 1 ? {irq_pend, irq_cfg[2:0]} : 
	ss_addr[7:0] == 2 ? irq_reload[15:8] : 
	ss_addr[7:0] == 3 ? irq_reload[7:0] : 
	ss_addr[7:0] == 4 ? irq_ctr[15:8] : 
	ss_addr[7:0] == 5 ? irq_ctr[7:0] : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = {cpu_addr[15:13], 13'd0} == 16'h6000;
	assign ram_we = !cpu_rw & ram_ce;
	assign rom_ce = cpu_addr[15];
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = cfg_mir_v ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[13:0] = cpu_addr[13:0];
	assign prg_addr[17:14] = !cpu_addr[14] ? prg[3:0] : 4'b1111;
	
	assign chr_addr[12:0] = ppu_addr[12:0];
	
	assign irq = irq_pend;
	
	wire irq_mode8 = irq_cfg[2];
	wire irq_on = irq_cfg[1];
	
	wire [15:0]reg_addr = {cpu_addr[15:12], 12'd0};
	
	reg [3:0]prg;
	reg [2:0]irq_cfg;
	reg [15:0]irq_reload, irq_ctr;
	reg irq_pend;
	
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 0)prg[3:0] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 1){irq_pend, irq_cfg[2:0]} <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 2)irq_reload[15:8] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 3)irq_reload[7:0] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 4)irq_ctr[15:8] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 5)irq_ctr[7:0] <= cpu_dat;
	end
		else
	begin
		
	
		if(reg_addr[15:0] == 16'h8000 & !cpu_rw)irq_reload[3:0] <= cpu_dat[3:0];
		if(reg_addr[15:0] == 16'h9000 & !cpu_rw)irq_reload[7:4] <= cpu_dat[3:0];
		if(reg_addr[15:0] == 16'hA000 & !cpu_rw)irq_reload[11:8] <= cpu_dat[3:0];
		if(reg_addr[15:0] == 16'hB000 & !cpu_rw)irq_reload[15:12] <= cpu_dat[3:0];
		if(reg_addr[15:0] == 16'hC000 & !cpu_rw){irq_pend, irq_cfg[2:0]} <= {1'b0, cpu_dat[2:0]};
		if(reg_addr[15:0] == 16'hD000 & !cpu_rw){irq_pend, irq_cfg[1]} <= {1'b0, irq_cfg[0]};
		if(reg_addr[15:0] == 16'hF000 & !cpu_rw)prg[3:0] <= cpu_dat[3:0];
		
		
		
		if(reg_addr[15:0] == 16'hC000 & !cpu_rw)
		begin
			if(cpu_dat[1])irq_ctr <= irq_reload;
		end
			else
		if(irq_on & irq_mode8 == 1)
		begin
			
			if(irq_ctr[7:0] == 8'hff)
			begin
				irq_pend <= 1;
				irq_ctr[7:0] <= irq_reload[7:0];
			end
				else
			begin
				irq_ctr[7:0] <= irq_ctr[7:0] + 1;
			end
			
		end
			else
		if(irq_on & irq_mode8 == 0)
		begin
		
			if(irq_ctr[15:0] == 16'hffff)
			begin
				irq_pend <= 1;
				irq_ctr[15:0] <= irq_reload[15:0];
			end
				else
			begin
				irq_ctr[15:0] <= irq_ctr[15:0] + 1;
			end
			
		end
		
		
	end
	
	
endmodule
