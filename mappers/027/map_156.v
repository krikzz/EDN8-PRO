
`include "../base/defs.v"

module map_156
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
	ss_addr[7:3] == 1 ? chr_bank[ss_addr[2:0]][15:8] : 
	ss_addr[7:0] == 16 ? prg_bank[7:0] :  
	ss_addr[7:0] == 17 ? {mirror, mirror_enable} : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************

	assign ram_we = !cpu_rw & ram_ce;
	assign ram_ce = cpu_addr[14:13] == 2'b11 & cpu_ce & m2;
	assign rom_ce = !cpu_ce;
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;//if cfg_chr_ram == 1 means that we don't have CHR rom, only CHR ram
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = !mirror_enable ? 0 : !mirror ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[12:0] = cpu_addr[12:0];
	assign prg_addr[18:13] = cpu_ce ? 0 : !cpu_addr[14] ? {prg_bank[4:0], cpu_addr[13]} : {5'h1F, cpu_addr[13]};
	
	assign chr_addr[9:0] = ppu_addr[9:0];
	assign chr_addr[18:10] = chr_bank[ppu_addr[12:10]][8:0]; 
	
	reg [7:0]prg_bank;
	reg [15:0]chr_bank[8];
	reg mirror;
	reg mirror_enable;
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:3] == 0) chr_bank[ss_addr[2:0]][7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:3] == 1) chr_bank[ss_addr[2:0]][15:8] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 16) prg_bank[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 17) {mirror, mirror_enable} <= cpu_dat;
	end
	else
	begin
		
		if(map_rst) begin
			mirror_enable <= 0;
		end
		
		if({!cpu_ce, cpu_addr[14:4]} == 12'hC00 & !cpu_rw) begin
			case(cpu_addr[3:0])
				
				0: chr_bank[0][7:0] <= cpu_dat[7:0];
				1: chr_bank[1][7:0] <= cpu_dat[7:0];
				2: chr_bank[2][7:0] <= cpu_dat[7:0];
				3: chr_bank[3][7:0] <= cpu_dat[7:0];
				4: chr_bank[0][15:8] <= cpu_dat[7:0];
				5: chr_bank[1][15:8] <= cpu_dat[7:0];
				6: chr_bank[2][15:8] <= cpu_dat[7:0];
				7: chr_bank[3][15:8] <= cpu_dat[7:0];
				
				8: chr_bank[4][7:0] <= cpu_dat[7:0];
				9: chr_bank[5][7:0] <= cpu_dat[7:0];
				10: chr_bank[6][7:0] <= cpu_dat[7:0];
				11: chr_bank[7][7:0] <= cpu_dat[7:0];
				12: chr_bank[4][15:8] <= cpu_dat[7:0];
				13: chr_bank[5][15:8] <= cpu_dat[7:0];
				14: chr_bank[6][15:8] <= cpu_dat[7:0];
				15: chr_bank[7][15:8] <= cpu_dat[7:0];
				
			endcase
		end
		if({!cpu_ce, cpu_addr[14:4]} == 12'hC01 & !cpu_rw) begin
			if(cpu_addr[3:0] == 0) prg_bank[7:0] <= cpu_dat[7:0];
			if(cpu_addr[3:0] == 4) begin
				mirror <= cpu_dat[0];
				mirror_enable <= 1;
			end
		end
		
	end
	
endmodule
