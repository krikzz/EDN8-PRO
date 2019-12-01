
`include "../base/defs.v"

module map_106
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
	ss_addr[7:0] == 8 ? {3'd0, prg_bank[0][4:0]} : 
	ss_addr[7:0] == 9 ? {3'd0, prg_bank[1][4:0]} : 
	ss_addr[7:0] == 10 ? {3'd0, prg_bank[2][4:0]} : 
	ss_addr[7:0] == 11 ? {3'd0, prg_bank[3][4:0]} :  
	ss_addr[7:0] == 12 ? {mirror, irq_reg, irq_enable, 5'd0} : 
	ss_addr[7:0] == 13 ? irq_counter[7:0] :
	ss_addr[7:0] == 14 ? irq_counter[15:8] :
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************

	assign ram_we = !cpu_rw & ram_ce;
	assign ram_ce = cpu_addr[14:13] == 2'b11 & cpu_ce & m2;
	assign rom_ce = !cpu_ce;
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;//if cfg_chr_ram == 1 means that we don't have CHR rom, only CHR ram
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = cfg_mir_v ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[12:0] = cpu_addr[12:0];
	assign prg_addr[18:13] = cpu_ce ? 0 : prg;
	
	wire [5:0]prg = 
	cpu_addr[14:13] == 0 ? {1'b1, prg_bank[0][3:0]} :
	cpu_addr[14:13] == 1 ? prg_bank[1][4:0] :
	cpu_addr[14:13] == 2 ? prg_bank[2][4:0] : {1'b1, prg_bank[3][3:0]};
	
	assign chr_addr[9:0] = ppu_addr[9:0];
	assign chr_addr[17:10] = 
	ppu_addr[12:10] == 0 ? {chr_bank[0][7:1], 1'b0} :
	ppu_addr[12:10] == 1 ? {chr_bank[1][7:1], 1'b1} :
	ppu_addr[12:10] == 2 ? {chr_bank[2][7:1], 1'b0} :
	ppu_addr[12:10] == 3 ? {chr_bank[3][7:1], 1'b1} :
	ppu_addr[12:10] == 4 ? chr_bank[4][7:0] :
	ppu_addr[12:10] == 5 ? chr_bank[5][7:0] :
	ppu_addr[12:10] == 6 ? chr_bank[6][7:0] : chr_bank[7][7:0];
	
	reg [7:0]chr_bank[8];
	reg [4:0]prg_bank[4];
	reg mirror;
	
	reg irq_reg;
	reg irq_enable;
	reg [15:0]irq_counter;
	
	assign irq = irq_reg;
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:3] == 0) chr_bank[ss_addr[2:0]][7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 8) prg_bank[0][4:0] <= cpu_dat[4:0];
		if(ss_we & ss_addr[7:0] == 9) prg_bank[1][4:0] <= cpu_dat[4:0];
		if(ss_we & ss_addr[7:0] == 10) prg_bank[2][4:0] <= cpu_dat[4:0];
		if(ss_we & ss_addr[7:0] == 11) prg_bank[3][4:0] <= cpu_dat[4:0];
		if(ss_we & ss_addr[7:0] == 12) {mirror, irq_reg, irq_enable} <= cpu_dat[7:5];
		if(ss_we & ss_addr[7:0] == 13) irq_counter[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 14) irq_counter[15:8] <= cpu_dat[7:0];
	end
	else
	begin
		
		if(map_rst) begin
			prg_bank[0] <= 5'h1f;
			prg_bank[1] <= 5'h1f;
			prg_bank[2] <= 5'h1f;
			prg_bank[3] <= 5'h1f;
		end
		
		if(!cpu_ce & !cpu_rw) begin
			
			if(!cpu_addr[3]) chr_bank[cpu_addr[2:0]][7:0] <= cpu_dat[7:0];
			if(cpu_addr[3:2] == 2'b10) prg_bank[cpu_addr[1:0]][4:0] <= cpu_dat[4:0];
			
			case(cpu_addr[3:0])
				
				4'hc: mirror <= cpu_dat[0];
				4'hd: begin
					irq_enable <= 0;
					irq_counter <= 0;
					irq_reg <= 0;
				end
				4'he: irq_counter[7:0] <= cpu_dat[7:0];
				4'hf: begin
					irq_counter[15:8] <= cpu_dat[7:0];
					irq_enable <= 1;
				end
				
			endcase
		end
		
		if(irq_enable) begin
			irq_counter <= irq_counter + 1;
			if(irq_counter == 16'hFFFF) begin
				irq_reg <= 1;
				irq_enable <= 0;
			end
		end
		
	end
	
endmodule
