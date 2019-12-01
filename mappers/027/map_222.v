
`include "../base/defs.v"

module map_222
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
	ss_addr[7:0] == 10 ? {mirror, irq_reg, 6'd0} : 
	ss_addr[7:0] == 11 ? irq_counter[7:0] :
	ss_addr[7:0] == 12 ? ppu_st[7:0] :
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
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
	assign prg_addr[18:13] = 
	cpu_addr[14:13] == 0 ? prg_bank[0][5:0] :
	cpu_addr[14:13] == 1 ? prg_bank[1][5:0] : 
	cpu_addr[14:13] == 2 ? 6'h3E : 6'h3F;
	
	assign chr_addr[9:0] = ppu_addr[9:0];
	assign chr_addr[17:10] = chr_bank[ppu_addr[12:10]][7:0];
	
	reg [7:0]prg_bank[2];
	reg [7:0]chr_bank[8];
	reg mirror;
	
	reg irq_reg;
	reg [7:0]irq_counter;
	
	assign irq = irq_reg;
	reg [7:0]ppu_st;
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:3] == 0) chr_bank[ss_addr[2:0]][7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:1] == 4) prg_bank[ss_addr[0]][7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 10) {mirror, irq_reg} <= cpu_dat[7:6];
		if(ss_we & ss_addr[7:0] == 11) irq_counter[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 12) ppu_st[7:0] <= cpu_dat[7:0];
	end
	else
	begin
		
		if(!cpu_rw)
		case({!cpu_ce, cpu_addr[14:0]})
			
			16'h8000: prg_bank[0][7:0] <= cpu_dat[7:0];
			16'h9000: mirror <= cpu_dat[0];
			16'hA000: prg_bank[1][7:0] <= cpu_dat[7:0];
			16'hB000: chr_bank[0][7:0] <= cpu_dat[7:0];
			16'hB002: chr_bank[1][7:0] <= cpu_dat[7:0];
			16'hC000: chr_bank[2][7:0] <= cpu_dat[7:0];
			16'hC002: chr_bank[3][7:0] <= cpu_dat[7:0];
			16'hD000: chr_bank[4][7:0] <= cpu_dat[7:0];
			16'hD002: chr_bank[5][7:0] <= cpu_dat[7:0];
			16'hE000: chr_bank[6][7:0] <= cpu_dat[7:0];
			16'hE002: chr_bank[7][7:0] <= cpu_dat[7:0];
			16'hF000: begin
				irq_reg <= 0;
				irq_counter[7:0] <= cpu_dat[7:0];
			end
			
		endcase
		
		ppu_st[7:0] <= {ppu_st[6:0], ppu_addr[12]};
		
		if(ppu_st[3:0] == 4'b0001) begin
			
			if(irq_counter != 0) begin
			
				if(irq_counter >= 240) begin
					irq_reg <= 1;
					irq_counter <= 0;
				end 
				else irq_counter <= irq_counter + 1;
			end
		end
	end
	
endmodule
