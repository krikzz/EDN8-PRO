
`include "../base/defs.v"

module map_183
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
	ss_addr[7:2] == 2 ? {2'd0, prg_bank[ss_addr[1:0]][5:0]} :
	ss_addr[7:0] == 12 ? irq_counter[7:0] :
	ss_addr[7:0] == 13 ? irq_scaler[7:0] :
	ss_addr[7:0] == 14 ? {mirror[1:0], irq_reg, irq_enable, irq_turn, 3'd0} :
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************

	assign ram_we = !cpu_rw;
	assign ram_ce = 0;//cpu_addr[14:13] == 2'b11 & cpu_ce & m2;
	assign rom_ce = !cpu_ce | cpu_addr[15:13] == 3'b011;
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;//if cfg_chr_ram == 1 means that we don't have CHR rom, only CHR ram
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = 
	mirror == 0 ? ppu_addr[10] : 
	mirror == 1 ? ppu_addr[11] :
	mirror == 2 ? 0 : 1;
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[12:0] = cpu_addr[12:0];
	assign prg_addr[18:13] = cpu_ce ? prg_bank[3][5:0] : 
	cpu_addr[14:13] == 0 ? prg_bank[0][5:0] :
	cpu_addr[14:13] == 1 ? prg_bank[1][5:0] :
	cpu_addr[14:13] == 2 ? prg_bank[2][5:0] : 6'h3F;
	
	assign chr_addr[9:0] = ppu_addr[9:0];
	assign chr_addr[17:10] = chr_bank[ppu_addr[12:10]][7:0];
	
	reg [5:0]prg_bank[4];
	reg [7:0]chr_bank[8];
	reg [1:0]mirror;
	
	reg irq_reg;
	reg [7:0]irq_counter;
	reg irq_enable;
	reg [7:0]irq_scaler;
	reg irq_turn;
	
	assign irq = irq_reg;
	
	wire [15:0]mask = {cpu_addr[15:11], 7'd0, cpu_addr[3:2], 2'd0};
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:3] == 0) chr_bank[ss_addr[2:0]][7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:2] == 2) prg_bank[ss_addr[1:0]][5:0] <= cpu_dat[5:0];
		if(ss_we & ss_addr[7:0] == 12) irq_counter[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 13) irq_scaler[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 14) {mirror[1:0], irq_reg, irq_enable, irq_turn} <= cpu_dat[7:3];
	end
	else
	begin
		
		if(map_rst) begin
			
			irq_counter <= 0;
			irq_enable <= 0;
			prg_bank[0] <= 0;
			prg_bank[1] <= 1;
			prg_bank[2] <= 6'h3E;
			
		end else
		if(!cpu_rw) begin
				
			case(mask)
				
				16'h6800: prg_bank[3][5:0] <= cpu_addr[5:0];				
				16'h8800: prg_bank[0][5:0] <= cpu_dat[5:0];
				16'hA800: prg_bank[1][5:0] <= cpu_dat[5:0];
				16'hA000: prg_bank[2][5:0] <= cpu_dat[5:0];
				
				16'hB000: chr_bank[0][3:0] <= cpu_dat[3:0];
				16'hB004: chr_bank[0][7:4] <= cpu_dat[3:0];
				16'hB008: chr_bank[1][3:0] <= cpu_dat[3:0];
				16'hB00C: chr_bank[1][7:4] <= cpu_dat[3:0];
				16'hC000: chr_bank[2][3:0] <= cpu_dat[3:0];
				16'hC004: chr_bank[2][7:4] <= cpu_dat[3:0];
				16'hC008: chr_bank[3][3:0] <= cpu_dat[3:0];
				16'hC00C: chr_bank[3][7:4] <= cpu_dat[3:0];
				16'hD000: chr_bank[4][3:0] <= cpu_dat[3:0];
				16'hD004: chr_bank[4][7:4] <= cpu_dat[3:0];
				16'hD008: chr_bank[5][3:0] <= cpu_dat[3:0];
				16'hD00C: chr_bank[5][7:4] <= cpu_dat[3:0];
				16'hE000: chr_bank[6][3:0] <= cpu_dat[3:0];
				16'hE004: chr_bank[6][7:4] <= cpu_dat[3:0];
				16'hE008: chr_bank[7][3:0] <= cpu_dat[3:0];
				16'hE00C: chr_bank[7][7:4] <= cpu_dat[3:0];
				
				16'h9800: mirror[1:0] <= cpu_dat[1:0];
				16'hF000: irq_counter[3:0] <= cpu_dat[3:0];
				16'hF004: irq_counter[7:4] <= cpu_dat[3:0];
				16'hF008: begin
					irq_enable <= cpu_dat != 0;
					if(cpu_dat == 0) irq_scaler <= 0;
					irq_reg <= 0;
				end
				//16'hF00C: irq_pre <= 16;
				
			endcase
		end
		
		if(irq_turn) begin
			irq_reg <= 1;
			irq_turn <= 0;
		end
		
		if(irq_scaler == 113) begin
			irq_scaler <= 0;
			if(irq_enable) begin
				irq_counter <= irq_counter + 1;
				if(irq_counter == 8'hFF) begin
					irq_turn <= 1;
				end
			end
		end
		else irq_scaler <= irq_scaler + 1;
		
	end
	
endmodule
