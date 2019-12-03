
`include "../base/defs.v"

module map_030
(map_out, bus, sys_cfg, ss_ctrl);

	`include "../base/bus_in.v"
	`include "../base/map_out.v"
	`include "../base/sys_cfg_in.v"
	`include "../base/ss_ctrl_in.v"
	
	output [`BW_MAP_OUT-1:0]map_out;
	input [`BW_SYS_CFG-1:0]sys_cfg;
	
	
	assign chr_mask_off = 1;
	assign sync_m2 = 1;
	assign mir_4sc = 1;//enable support for 4-screen mirroring. for activation should be ensabled in sys_cfg also
	assign srm_addr[12:0] = cpu_addr[12:0];
	assign prg_oe = cpu_rw;
	assign chr_oe = !ppu_oe;
	wire cfg_fla_mod = map_sub == 1;
	//*************************************************************  save state setup
	assign ss_rdat[7:0] = 
	ss_addr[7:0] == 0   ? regs : 
	ss_addr[7:0] == 1   ? fla_state : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = {cpu_addr[15:13], 13'd0} == 16'h6000;
	assign ram_we = !cpu_rw & ram_ce;
	assign rom_ce = cpu_addr[15];
	assign rom_we = fla_we;
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = cfg_mir_1 ? one_scr : cfg_mir_v ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[13:0] = cpu_addr[13:0];
	assign prg_addr[18:14] = cpu_addr[14] == 0 ? prg[4:0] : 5'b11111;
	
	
	assign chr_addr[12:0] = ppu_addr[12:0];
	assign chr_addr[14:13] = chr[1:0];
	
	
	wire fla_area = cfg_fla_mod & cpu_addr[15:14] == 2'b10;
	wire reg_area = cfg_fla_mod ? cpu_addr[15:14] == 2'b11 : cpu_addr[15];
	wire fla_we   = fla_area & fla_state == 3 & !cpu_rw;
	
	wire [4:0]prg = regs[4:0];
	wire [1:0]chr = regs[6:5];
	wire one_scr = regs[7];
	
	reg [7:0]regs;
	reg [1:0]fla_state;
	
	assign map_led = fla_state != 0;
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 0)regs <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 1)fla_state <= cpu_dat;
	end
		else
	if(map_rst)
	begin
		regs <= 0;
		fla_state <= 0;
	end
		else
	if(!cpu_rw)
	begin
		
		if(reg_area)regs[7:0] <= cpu_dat[7:0];
		
		if(fla_area)
		case(fla_state)
			0:fla_state <= prg_addr[14:0] == 15'h5555 & cpu_dat == 8'hAA ? 1 : 0;
			1:fla_state <= prg_addr[14:0] == 15'h2AAA & cpu_dat == 8'h55 ? 2 : 0;
			2:fla_state <= prg_addr[14:0] == 15'h5555 & cpu_dat == 8'hA0 ? 3 : 0;
			3:fla_state <= 0;
		endcase
		
	end
	
endmodule


