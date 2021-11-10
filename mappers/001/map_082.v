
`include "../base/defs.v"

module map_082
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
	ss_addr[7:2] == 0 ? chr[ss_addr[1:0]] : 
	ss_addr[7:0] == 4 ? chr[4] :
	ss_addr[7:0] == 5 ? chr[5] :
	ss_addr[7:0] == 6 ? prg[0] :
	ss_addr[7:0] == 7 ? prg[1] :
	ss_addr[7:0] == 8 ? prg[2] :
	ss_addr[7:0] == 9 ? {prg_sel2, prg_sel1, prg_sel0, ram_on2, ram_on1, ram_on0, a12_invert, mirror_mode} :
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	wire ram_area = {cpu_addr[15:13], 13'd0} == 16'h6000;
	wire ram0 = ram_area & cpu_addr[12:11] == 0 & ram_on0;
	wire ram1 = ram_area & cpu_addr[12:11] == 1 & ram_on1;
	wire ram2 = ram_area & cpu_addr[12:11] == 2 & ram_on2;
	assign ram_ce = ram0 | ram1 | ram2;
	assign ram_we = !cpu_rw & ram_ce;
	assign rom_ce = !cpu_ce;
	assign chr_ce = ciram_ce;
	assign chr_we = 0;
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = mirror_mode ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[12:0] = cpu_addr[12:0];
	//assign prg_addr[14:13] = cpu_ce ? 0 : cpu_addr[14:13];
	assign prg_addr[18:13] = 
	cpu_ce ? 0 : 
	cpu_addr[14:13] == 0 ? prg[0][5:0] : 
	cpu_addr[14:13] == 1 ? prg[1][5:0] : 
	cpu_addr[14:13] == 2 ? prg[2][5:0] : 
	6'b111111;
	
	wire [1:0]ppu_bank = !a12_invert ? ppu_addr[12:11] : {!ppu_addr[12], ppu_addr[11]};
	assign chr_addr[9:0] = ppu_addr[9:0];
	assign chr_addr[17:10] = 
	ppu_bank[1:0] == 0 ? {chr[0][6:0], ppu_addr[10]} : 
	ppu_bank[1:0] == 1 ? {chr[1][6:0], ppu_addr[10]} : 
	ppu_addr[11:10] == 0 ? chr[2][7:0] : 
	ppu_addr[11:10] == 1 ? chr[3][7:0] : 
	ppu_addr[11:10] == 2 ? chr[4][7:0] : 
	chr[5][6:0]; 
	
	
	reg [7:0]chr[6];
	reg [5:0]prg[3];

	reg mirror_mode;
	reg a12_invert;
	reg ram_on0;
	reg ram_on1;
	reg ram_on2;
	reg prg_sel0;
	reg prg_sel1;
	reg prg_sel2;
	

	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:2] == 0)chr[ss_addr[1:0]] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 4)chr[4] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 5)chr[5] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 6)prg[0] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 7)prg[1] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 8)prg[2] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 9){prg_sel2, prg_sel1, prg_sel0, ram_on2, ram_on1, ram_on0, a12_invert, mirror_mode} <= cpu_dat;
	end
		else
	if({cpu_addr[15:4], 4'd0} == 16'h7EF0 & !cpu_rw)
	begin
		
		case(cpu_addr[3:0])
			0:begin
				chr[0][6:0] <= cpu_dat[7:1];
			end
			1:begin
				chr[1][6:0] <= cpu_dat[7:1];
			end
			2:begin
				chr[2][7:0] <= cpu_dat[7:0];
			end
			3:begin
				chr[3][7:0] <= cpu_dat[7:0];
			end
			4:begin
				chr[4][7:0] <= cpu_dat[7:0];
			end
			5:begin
				chr[5][7:0] <= cpu_dat[7:0];
			end
			6:begin
				mirror_mode <= cpu_dat[0];
				a12_invert <= cpu_dat[1];
			end
			7:begin
				ram_on0 <= cpu_dat[7:0] == 8'hCA;
			end
			8:begin
				ram_on1 <= cpu_dat[7:0] == 8'h69;
			end
			9:begin
				ram_on2 <= cpu_dat[7:0] == 8'h84;
			end
			10:begin
				prg[0][5:0] <= cpu_dat[7:2];
			end
			11:begin
				prg[1][5:0] <= cpu_dat[7:2];
			end
			12:begin
				prg[2][5:0] <= cpu_dat[7:2];
			end		
		endcase
		
	end
	
	
	
endmodule


