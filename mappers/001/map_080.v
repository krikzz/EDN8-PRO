
`include "../base/defs.v"

module map_080
(map_out, bus, sys_cfg, ss_ctrl);

	`include "../base/bus_in.v"
	`include "../base/map_out.v"
	`include "../base/sys_cfg_in.v"
	`include "../base/ss_ctrl_in.v"
	
	output [`BW_MAP_OUT-1:0]map_out;
	input [`BW_SYS_CFG-1:0]sys_cfg;
	
	
	assign sync_m2 = 1;
	assign mir_4sc = 0;//enable support for 4-screen mirroring. for activation should be ensabled in sys_cfg also
	assign srm_addr[6:0] = cpu_addr[6:0];//128 bytes of ram. mirrored once
	assign prg_oe = cpu_rw;
	assign chr_oe = !ppu_oe;
	//wire mir_cfg = map_cfg[4];
	//*************************************************************  save state setup
	assign ss_rdat[7:0] = 
	ss_addr[7:2] == 0 ? chr[ss_addr[1:0]] : 
	ss_addr[7:0] == 4 ? chr[4] :
	ss_addr[7:0] == 5 ? chr[5] :
	ss_addr[7:0] == 6 ? prg[0] :
	ss_addr[7:0] == 7 ? prg[1] :
	ss_addr[7:0] == 8 ? prg[2] :
	ss_addr[7:0] == 9 ? {ram_on, mirror_mode, mir[1:0]} :
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = {cpu_addr[15:8], 8'd0} == 16'h7F00 & ram_on;
	assign ram_we = !cpu_rw & ram_ce;
	assign rom_ce = cpu_addr[15];
	assign chr_ce = ciram_ce;
	assign chr_we = 0;
	
	//A10-Vmir, A11-Hmir
	wire mirror_80 = mirror_mode ? ppu_addr[10] : ppu_addr[11];
	wire mirror_205 = mir[ppu_addr[11]];
	assign ciram_a10 = mirror_80;//controlled by prg_mask[3] in old version
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[12:0] = cpu_addr[12:0];

	assign prg_addr[17:13] = 
	cpu_addr[14:13] == 0 ? prg[0][4:0] : 
	cpu_addr[14:13] == 1 ? prg[1][4:0] : 
	cpu_addr[14:13] == 2 ? prg[2][4:0] : 
	5'b11111;
	
	assign chr_addr[9:0] = ppu_addr[9:0];
	assign chr_addr[16:10] = 
	ppu_addr[12:11] == 0 ? {chr[0][5:0], ppu_addr[10]} : 
	ppu_addr[12:11] == 1 ? {chr[1][5:0], ppu_addr[10]} : 
	ppu_addr[11:10] == 0 ? chr[2][6:0] : 
	ppu_addr[11:10] == 1 ? chr[3][6:0] : 
	ppu_addr[11:10] == 2 ? chr[4][6:0] : 
	chr[5][6:0]; 
	
	reg [6:0]chr[6];
	reg [4:0]prg[3];
	
	reg [1:0]mir;
	reg mirror_mode;
	reg ram_on;
	
	
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:2] == 0)chr[ss_addr[1:0]] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 4)chr[4] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 5)chr[5] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 6)prg[0] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 7)prg[1] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 8)prg[2] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 9){ram_on, mirror_mode, mir[1:0]} <= cpu_dat;
	end
		else
	if({cpu_addr[15:4], 4'd0} == 16'h7EF0 & !cpu_rw)
	begin
		
		case(cpu_addr[3:1])
			0:begin
				chr[cpu_addr[0]][5:0] <= cpu_dat[6:1];
				mir[cpu_addr[0]] <= cpu_dat[7];
			end
			1:begin
				chr[2+cpu_addr[0]][6:0] <= cpu_dat[6:0];
			end
			2:begin
				chr[4+cpu_addr[0]][6:0] <= cpu_dat[6:0];
			end
			3:begin
				mirror_mode <= cpu_dat[0];
			end
			4:begin
				ram_on <= cpu_dat[7:0] == 8'hA3;
			end
			5:begin
				prg[0][4:0] <= cpu_dat[4:0];
			end
			6:begin
				prg[1][4:0] <= cpu_dat[4:0];
			end
			7:begin
				prg[2][4:0] <= cpu_dat[4:0];
			end		
		endcase
		
	end
	
	
	
endmodule


