
`include "../base/defs.v"

module map_111
(map_out, bus, sys_cfg, ss_ctrl);

	`include "../base/bus_in.v"
	`include "../base/map_out.v"
	`include "../base/sys_cfg_in.v"
	`include "../base/ss_ctrl_in.v"
	
	output [`BW_MAP_OUT-1:0]map_out;
	input [`BW_SYS_CFG-1:0]sys_cfg;
	
	
	assign chr_mask_off = 1;
	assign sync_m2 = 1;
	assign mir_4sc = 0;//enable support for 4-screen mirroring. for activation should be ensabled in sys_cfg also
	assign srm_addr[12:0] = cpu_addr[12:0];
	assign prg_oe = cpu_rw;
	assign chr_oe = !ppu_oe;
	//*************************************************************  save state setup
	assign ss_rdat[7:0] = 
	ss_addr[7:0] == 0   ? regs[0] : 
	ss_addr[7:0] == 1   ? regs[1] : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = {cpu_addr[15:13], 13'd0} == 16'h6000;
	assign ram_we = !cpu_rw & ram_ce;
	assign rom_ce = cpu_addr[15];
	assign rom_we = fla_we;
	assign chr_ce = !ppu_oe | !ppu_we;
	assign chr_we = !ppu_we;
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = cfg_mir_v ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = 1;//!ppu_addr[13];
	
	assign prg_addr[14:0] = cpu_addr[14:0];
	assign prg_addr[18:15] = prg[3:0];
	
	assign chr_addr[12:0] = ppu_addr[12:0];
	assign chr_addr[13] = ppu_addr[13] == 0 ? chr_bank_pt : chr_bank_nt;
	assign chr_addr[14] = ppu_addr[13];
	
	wire [3:0]prg = regs[0][3:0];
	wire chr_bank_pt = regs[0][4];
	wire chr_bank_nt = regs[0][5];
	assign map_led = regs[0][6];
	wire [1:0]fla_state = regs[1][1:0];
	wire fla_we	= cpu_addr[15] & fla_state == 3 & !cpu_rw;
	
	
	reg [7:0]regs[2];
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 0)regs[0] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 1)regs[1] <= cpu_dat;
	end
		else
	if(map_rst)
	begin
		regs[0] <= 0;
		regs[1] <= 0;
	end
		else
	if(!cpu_rw)
	begin
		
		if((cpu_addr & 16'hd000) == 16'h5000)regs[0] <= cpu_dat;
		
		if(cpu_addr[15])
		case(regs[1][1:0])
			0:regs[1][1:0] <= prg_addr[14:0] == 15'h5555 & cpu_dat == 8'hAA ? 1 : 0;
			1:regs[1][1:0] <= prg_addr[14:0] == 15'h2AAA & cpu_dat == 8'h55 ? 2 : 0;
			2:regs[1][1:0] <= prg_addr[14:0] == 15'h5555 & cpu_dat == 8'hA0 ? 3 : 0;
			3:regs[1][1:0] <= 0;
		endcase
		
	end
	

	
endmodule
