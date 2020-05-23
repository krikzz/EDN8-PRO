`include "../base/defs.v"

module map_153
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
	ss_addr[7:3] == 0 ? chr[ss_addr[2:0]] :
	ss_addr[7:0] == 8 ? prg : 
	ss_addr[7:0] == 9 ? irq_ctr[15:8] : 
	ss_addr[7:0] == 10 ? irq_ctr[7:0] : 
	ss_addr[7:0] == 11 ? irq_latch[15:8] : 
	ss_addr[7:0] == 12 ? irq_latch[7:0] : 
	ss_addr[7:0] == 13 ? {ram_on, irq_on, irq_pend, mirror_mode[1:0]} : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = {cpu_addr[15:13], 13'd0} == 16'h6000 & ram_on;
	assign ram_we = !cpu_rw & ram_ce;
	assign rom_ce = cpu_addr[15];
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = 
	mirror_mode == 0 ? ppu_addr[10] : 
	mirror_mode == 1 ? ppu_addr[11] : mirror_mode[0];
	
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[13:0] = cpu_addr[13:0];
	assign prg_addr[17:14] = !cpu_addr[14] ? prg[3:0] : 4'b1111;
	assign prg_addr[18] = chr[ppu_addr[11:10]][0];

	
	assign chr_addr[12:0] = ppu_addr[12:0];
	//assign chr_addr[17:10] = chr[ppu_addr[12:10]];
	
	
	wire regs_ce = (cpu_addr[15:0] & 16'h8000) == 16'h8000;

	
	reg [7:0]chr[8];
	reg [4:0]prg;
	
	reg [15:0]irq_ctr;
	reg [15:0]irq_latch;
	
	reg [1:0]mirror_mode;
	reg irq_pend;
	reg irq_on;
	reg ram_on;
	
	assign irq = irq_pend;
	
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:3] == 0)chr[ss_addr[2:0]] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 8)prg <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 9)irq_ctr[15:8] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 10)irq_ctr[7:0] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 11)irq_latch[15:8] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 12)irq_latch[7:0] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 13){ram_on, irq_on, irq_pend, mirror_mode[1:0]} <= cpu_dat;
	end
		else
	if(map_rst)
	begin
		irq_on <= 0;
		irq_pend <= 0;
		prg <= 0;
		ram_on <= 0;
	end
		else
	begin
			
		if(!cpu_rw & regs_ce & cpu_addr[3:0] == 4'hA)
		begin
			irq_ctr <= irq_latch;
		end
			else
		if(irq_on)
		begin
			irq_ctr <= irq_ctr - 1;
			if(irq_ctr == 0 & irq_pend == 0)irq_pend <= 1;
		end
			
			
				
		if(!cpu_rw & regs_ce & cpu_addr[3] == 0)
		begin
			chr[cpu_addr[2:0]][7:0] <= cpu_dat[7:0];
		end
		
		
		if(!cpu_rw & regs_ce)
		case(cpu_addr[3:0])
			4'h8:begin
				prg[4:0] <= cpu_dat[4:0];
			end
			4'h9:begin
				mirror_mode[1:0] <= cpu_dat[1:0];
			end
			4'hA:begin
				irq_on <= cpu_dat[0];
				irq_pend <= 0;
			end
			4'hB:begin
				irq_latch[7:0] <= cpu_dat[7:0];
			end
			4'hC:begin
				irq_latch[15:8] <= cpu_dat[7:0];
			end
		endcase
	
	
		if(!cpu_rw & (cpu_addr[15:0] & 16'h800F) == 16'h800D)ram_on <= cpu_dat[5];
		
	end

	
	
endmodule


