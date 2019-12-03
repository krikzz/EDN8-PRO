
`include "../base/defs.v"

module map_234
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
	ss_addr[7:0] == 0 ? o_bank : 
	ss_addr[7:0] == 1 ? i_bank : 
	ss_addr[7:0] == 2 ? lock : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************

	assign ram_we = 0;//!cpu_rw & ram_ce;
	assign ram_ce = cpu_addr[14:13] == 2'b11 & cpu_ce & m2;
	assign rom_ce = !cpu_ce;
	assign chr_ce = ciram_ce;
	assign chr_we = 0;//cfg_chr_ram ? !ppu_we & ciram_ce : 0;
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = !mirror_mode ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[14:0] = cpu_addr[14:0];
	assign prg_addr[18:15] = !mode ? o_bank[3:0] : {o_bank[3:1], i_bank[0]};
	
	assign chr_addr[12:0] = ppu_addr[12:0];
	assign chr_addr[18:13] = !mode ? {o_bank[3:0], i_bank[5:4]} : {o_bank[3:1], i_bank[6:4]};
	
	reg [7:0]o_bank;
	reg [7:0]i_bank;
	reg lock;
	
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 0)o_bank <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 1)i_bank <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 2)lock <= cpu_dat;
	end
		else
	begin
		if(map_rst)
		begin
			lock <= 0;
			o_bank <= 0;
			i_bank <= 0;
		end
			else
		begin
			if({!cpu_ce, cpu_addr[14:5], 5'd0} == 16'hff80 & !lock)
			begin
				o_bank[7:0] <= cpu_dat[7:0];
				lock <= 1;
			end
			if({!cpu_ce, cpu_addr[14:0]} > 16'hffe7 & {!cpu_ce, cpu_addr[14:0]} < 16'hFFF8)i_bank[7:0] <= cpu_dat[7:0];
		end
	end
	
	wire [3:0]block = o_bank[3:0];
	wire mode = o_bank[6];
	wire mirror_mode = o_bank[7];
	
endmodule
