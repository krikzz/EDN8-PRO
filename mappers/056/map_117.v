
`include "../base/defs.v"

module map_117
(map_out, bus, sys_cfg, ss_ctrl); //no mapper

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
	parameter MAP_NUM = 8'd4;
	assign ss_rdat[7:0] = 
	ss_addr[7:3] == 0 ? chr_bank[ss_addr[2:0]][7:0] : 
	ss_addr[7:2] == 2 ? prg_bank[ss_addr[1:0]][7:0] : 
	ss_addr[7:0] == 12 ? irq_count[7:0] :
	ss_addr[7:0] == 13 ? irq_latch[7:0] :
	ss_addr[7:0] == 14 ? ppua12_st[7:0] :
	ss_addr[7:0] == 15 ? {4'd0, mirror, irq_enable[1:0], irq_reg} :
	ss_addr[7:0] == 127 ? MAP_NUM : 8'hff;
	//*************************************************************

	assign ram_we = !cpu_rw & ram_ce;
	assign ram_ce = 0;//cpu_addr[14:13] == 2'b11 & cpu_ce & m2;
	assign rom_ce = !cpu_ce;
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;//if cfg_chr_ram == 1 means that we don't have CHR rom, only CHR ram
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = !mirror ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[12:0] = cpu_addr[12:0];
	assign prg_addr[18:13] = prg_bank[cpu_addr[14:13]][5:0];
	
	assign chr_addr[9:0] = ppu_addr[9:0];
	assign chr_addr[17:10] = chr_bank[ppu_addr[12:10]][7:0];
	
	reg [7:0]prg_bank[4];
	reg [7:0]chr_bank[8];
	reg mirror;
	
	reg irq_reg;
	reg [7:0]irq_latch;
	reg [7:0]irq_count;
	reg [1:0]irq_enable;
	
	reg [7:0]ppua12_st;
	
	assign irq = irq_reg;
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:3] == 0) chr_bank[ss_addr[2:0]][7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:2] == 2) prg_bank[ss_addr[1:0]][7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 12) irq_count[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 13) irq_latch[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 14) ppua12_st[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 15) {mirror, irq_enable[1:0], irq_reg} <= cpu_dat[3:0];
	end
	else
	begin
		if(map_rst) begin
			
			prg_bank[0] <= 8'hfc;
			prg_bank[1] <= 8'hfd;
			prg_bank[2] <= 8'hfe;
			prg_bank[3] <= 8'hff;
			
			irq_enable[0] <= 0;
			irq_enable[1] <= 0;
			irq_count <= 0;
			
			chr_bank[0] <= 0;
			chr_bank[1] <= 1;
			chr_bank[2] <= 2;
			chr_bank[3] <= 3;
			chr_bank[4] <= 4;
			chr_bank[5] <= 5;
			chr_bank[6] <= 6;
			chr_bank[7] <= 7;
		end
		
		if(!cpu_rw) begin
			
			if({cpu_addr[15:2], 2'h0} == 16'h8000) prg_bank[cpu_addr[1:0]][7:0] <= cpu_dat[7:0];
			if({cpu_addr[15:3], 3'h0} == 16'hA000) chr_bank[cpu_addr[2:0]][7:0] <= cpu_dat[7:0];
			
			case(cpu_addr[15:0])
				
				16'hc001: irq_latch[7:0] <= cpu_dat[7:0];
				16'hc002: irq_reg <= 0;
				16'hc003: begin 
					irq_count[7:0] <= irq_latch[7:0];
					irq_enable[1] <= 1;
				end
				16'hd000: mirror <= cpu_dat[0];
				16'he000: begin 
					irq_reg <= 0;
					irq_enable[0] <= cpu_dat[0];
				end
				
			endcase
			
		end
		
		ppua12_st[7:0] <= {ppua12_st[6:0], ppu_addr[12]};
		
		if(ppua12_st[3:0] == 4'b0000 & ppu_addr[12]) begin
			
			if(irq_enable == 2'b11 & irq_count != 0) begin
				
				irq_count <= irq_count - 1;
				
				if(irq_count == 1) begin
					irq_enable[1] <= 0;
					irq_reg <= 1;
				end	
			end
		end
	end
	
endmodule
