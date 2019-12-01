
`include "../base/defs.v"

module map_056
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
	ss_addr[7:0] == 8 ? {3'b000, prg_bank[0][4:0]} :
	ss_addr[7:0] == 9 ? {3'b000, prg_bank[1][4:0]} :
	ss_addr[7:0] == 10 ? {3'b000, prg_bank[2][4:0]} :
	ss_addr[7:0] == 11 ? {3'b000, prg_bank[3][4:0]} :
	ss_addr[7:0] == 12 ? {1'b0, irq_enable, irq_reg, mirror, prg_cntr[3:0]} :
	ss_addr[7:0] == 13 ? irq_counter[7:0] :
	ss_addr[7:0] == 14 ? irq_counter[15:8] :
	ss_addr[7:0] == 15 ? irq_latch[7:0] :
	ss_addr[7:0] == 16 ? irq_latch[15:8] :
	ss_addr[7:0] == 127 ? MAP_NUM : 8'hff;
	//*************************************************************

	assign ram_we = !cpu_rw;
	assign ram_ce = cpu_addr[14:13] == 2'b11 & cpu_ce & m2;
	assign rom_ce = !cpu_ce;
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;//if cfg_chr_ram == 1 means that we don't have CHR rom, only CHR ram
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = cfg_mir_v ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[12:0] = cpu_addr[12:0];
	assign prg_addr[17:13] = cpu_ce ? prg_bank[3][4:0] :
	cpu_addr[14:13] == 0 ? prg_bank[0][4:0] :
	cpu_addr[14:13] == 1 ? prg_bank[1][4:0] :
	cpu_addr[14:13] == 2 ? prg_bank[2][4:0] : 5'h1F;
	
	assign chr_addr[9:0] = ppu_addr[9:0];
	assign chr_addr[17:10] = chr_bank[ppu_addr[12:10]][7:0];
	
	reg [4:0]prg_bank[4];
	reg [3:0]prg_cntr;
	reg [7:0]chr_bank[8];
	reg mirror;
	
	reg [15:0]irq_counter;
	reg [15:0]irq_latch;
	reg irq_enable;
	reg irq_reg;
	
	assign irq = irq_reg;
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:3] == 0) chr_bank[ss_addr[2:0]][7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:2] == 2) prg_bank[ss_addr[1:0]][4:0] <= cpu_dat[4:0];
		if(ss_we & ss_addr[7:0] == 12) {irq_enable, irq_reg, mirror, prg_cntr[3:0]} <= cpu_dat[6:0];
		if(ss_we & ss_addr[7:0] == 13) irq_counter[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 14) irq_counter[15:8] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 15) irq_latch[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 16) irq_latch[15:8] <= cpu_dat[7:0];
	end
	else
	begin
		if(map_rst) begin
			irq_reg <= 0;
			irq_enable <= 0;
		end
		if(!cpu_rw)
		case(cpu_addr[15:12])
			
			4'h8: begin irq_reg <= 0; irq_latch[3:0] <= cpu_dat[3:0]; end
			4'h9: begin irq_reg <= 0; irq_latch[7:4] <= cpu_dat[3:0]; end
			4'ha: begin irq_reg <= 0; irq_latch[11:8] <= cpu_dat[3:0]; end 
			4'hb: begin irq_reg <= 0; irq_latch[15:12] <= cpu_dat[3:0]; end 
			
			4'hc: begin 
				irq_enable <= cpu_dat != 0;
				if(cpu_dat != 0) irq_counter <= irq_latch;
				irq_reg <= 0;
			end
			4'hd: irq_reg <= 0;
			
			4'he: prg_cntr[3:0] <= cpu_dat[3:0] - 1;
			4'hf: begin
				case(prg_cntr)	
				
					0: prg_bank[0][3:0] <= cpu_dat[3:0];
					1: prg_bank[1][3:0] <= cpu_dat[3:0];
					2: prg_bank[2][3:0] <= cpu_dat[3:0];
					3: prg_bank[3][4:0] <= cpu_dat[4:0];
					
				endcase
				
				if(cpu_addr[11:10] == 2'b00 & cpu_addr[1:0] != 3) prg_bank[cpu_addr[1:0]][4] <= cpu_dat[4];
				if(cpu_addr[11:10] == 2'b10) mirror <= cpu_dat[0];
				if(cpu_addr[11:10] == 2'b11) chr_bank[cpu_addr[2:0]][7:0] <= cpu_dat[7:0];
				
			end
			
		endcase
		
		if(irq_enable) begin
			if(irq_counter == 16'hFFFE) begin
				irq_counter <= irq_latch;
				irq_enable <= 0;
				irq_reg <= 1;
			end
			else irq_counter <= irq_counter + 1;
		end
		
	end
	
endmodule









