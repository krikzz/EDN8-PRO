
`include "../base/defs.v"

module map_252
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
	assign ss_rdat[7:0] = 
	ss_addr[7:3] == 0 ? chr_bank[ss_addr[2:0]][7:0] : 
	ss_addr[7:1] == 4 ? prg_bank[ss_addr[0]][7:0] :  
	ss_addr[7:0] == 10 ? {irq_enable_after, irq_reg, irq_enable, irq_cycle_mode, irq_prescaler_counter[8], 3'd0} : 
	ss_addr[7:0] == 11 ? irq_counter[7:0] :
	ss_addr[7:0] == 12 ? irq_latch[7:0] :
	ss_addr[7:0] == 13 ? irq_prescaler_counter[7:0] :
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************

	assign ram_we = !cpu_rw & ram_ce;
	assign ram_ce = cpu_addr[14:13] == 2'b11 & cpu_ce & m2;
	assign rom_ce = !cpu_ce;
	assign chr_ce = ciram_ce;
	assign chr_we = !ppu_we & ciram_ce;//if cfg_chr_ram == 1 means that we don't have CHR rom, only CHR ram
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = cfg_mir_v ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[12:0] = cpu_addr[12:0];
	assign prg_addr[18:13] = cpu_ce ? 0 :
	cpu_addr[14:13] == 0 ? prg_bank[0][5:0] :
	cpu_addr[14:13] == 1 ? prg_bank[1][5:0] : {5'h1F, cpu_addr[13]};
	
	assign chr_addr[9:0] = ppu_addr[9:0];
	assign chr_addr[17:10] = chr_bank[ppu_addr[12:10]][7:0];
	
	reg [7:0]prg_bank[2];
	reg [7:0]chr_bank[8];
	
	reg irq_reg;
	reg [7:0]irq_latch;
	reg [7:0]irq_counter;
	reg irq_enable;
	reg irq_enable_after;
	reg irq_cycle_mode;
	reg [8:0]irq_prescaler_counter;
	
	assign irq = irq_reg;
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:3] == 0) chr_bank[ss_addr[2:0]][7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:1] == 4) prg_bank[ss_addr[0]][7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 10) {irq_enable_after, irq_reg, irq_enable, irq_cycle_mode, irq_prescaler_counter[8]} <= cpu_dat[7:3];
		if(ss_we & ss_addr[7:0] == 11) irq_counter[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 12) irq_latch[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 13) irq_prescaler_counter[7:0] <= cpu_dat[7:0];
	end
	else
	begin
		
		if(!cpu_ce & !cpu_rw) begin
			
			if(cpu_addr[14:12] == 3'b000) prg_bank[0][7:0] <= cpu_dat[7:0];
			if(cpu_addr[14:12] == 3'b010) prg_bank[1][7:0] <= cpu_dat[7:0];
			
			case({cpu_addr[14:12], cpu_addr[3:2]})
				
				5'b011_00: chr_bank[0][3:0] <= cpu_dat[3:0];
				5'b011_01: chr_bank[0][7:4] <= cpu_dat[3:0];
				5'b011_10: chr_bank[1][3:0] <= cpu_dat[3:0];
				5'b011_11: chr_bank[1][7:4] <= cpu_dat[3:0];
				
				5'b100_00: chr_bank[2][3:0] <= cpu_dat[3:0];
				5'b100_01: chr_bank[2][7:4] <= cpu_dat[3:0];
				5'b100_10: chr_bank[3][3:0] <= cpu_dat[3:0];
				5'b100_11: chr_bank[3][7:4] <= cpu_dat[3:0];
				
				5'b101_00: chr_bank[4][3:0] <= cpu_dat[3:0];
				5'b101_01: chr_bank[4][7:4] <= cpu_dat[3:0];
				5'b101_10: chr_bank[5][3:0] <= cpu_dat[3:0];
				5'b101_11: chr_bank[5][7:4] <= cpu_dat[3:0];
				
				5'b110_00: chr_bank[6][3:0] <= cpu_dat[3:0];
				5'b110_01: chr_bank[6][7:4] <= cpu_dat[3:0];
				5'b110_10: chr_bank[7][3:0] <= cpu_dat[3:0];
				5'b110_11: chr_bank[7][7:4] <= cpu_dat[3:0];
				
				5'b111_00: irq_latch[3:0] <= cpu_dat[3:0];
				5'b111_01: irq_latch[7:4] <= cpu_dat[3:0];
				5'b111_10: begin
					irq_enable_after <= cpu_dat[0];
					irq_enable <= cpu_dat[1];
					irq_cycle_mode <= cpu_dat[2];
					irq_reg <= 0;
					
					if(cpu_dat[1]) begin
						irq_counter <= irq_latch;
						irq_prescaler_counter <= 341;
					end
				end
				5'b111_11: begin
					irq_enable <= irq_enable_after;
					irq_reg <= 0;
				end
				
			endcase
		end
		
		if(irq_enable) begin
			
			if(irq_cycle_mode | (irq_prescaler_counter == 2 & !irq_cycle_mode)) begin
			
				if(irq_counter == 0) begin
					irq_counter <= irq_latch;
					irq_reg <= 1;
				end
				else irq_counter <= irq_counter + 1;
				
				irq_prescaler_counter <= 341;
			end
			else irq_prescaler_counter <= irq_prescaler_counter - 3;
			
		end
	end
	
endmodule
