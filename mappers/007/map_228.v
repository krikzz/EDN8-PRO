
`include "../base/defs.v"

module map_228
(map_out, bus, sys_cfg, ss_ctrl); 

	`include "../base/bus_in.v"
	`include "../base/map_out.v"
	`include "../base/sys_cfg_in.v"
	`include "../base/ss_ctrl_in.v"
	
	output [`BW_MAP_OUT-1:0]map_out;
	input [`BW_SYS_CFG-1:0]sys_cfg;
	
	
	assign sync_m2 = 1;
	assign mir_4sc = 0;//enable support for 4-screen mirroring. for activation should be ensabled in sys_cfg also
	assign srm_addr[12:0] = cpu_addr[1:0];
	assign prg_oe = cpu_rw;
	assign chr_oe = !ppu_oe;
	//*************************************************************  save state setup
	assign ss_rdat[7:0] = 
	ss_addr[7:0] == 0 ? regs[7:0]  :
	ss_addr[7:0] == 1 ? regs[15:8] :
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = cpu_addr[15:8] == 8'h40 & cpu_addr[7:0] > 8'h1F;
	assign ram_we = !cpu_rw & ram_ce;
	assign rom_ce = !cpu_ce & chip != 2;
	assign chr_ce = ciram_ce;
	assign chr_we = 0;//if cfg_chr_ram == 1 means that we don't have CHR rom, only CHR ram
	
	//A10-Vmir, A11-Hmirы
	assign ciram_a10 = !mir_mod ? ppu_addr[10] : ppu_addr[11]; // !mirror
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[13:0] = cpu_addr[13:0];
	assign prg_addr[18:14] = prg_mod == 0 ? {prg[4:1], cpu_addr[14]} : prg[4:0];
	assign prg_addr[20:19] = chip[1:0] == 3 ? 2 : chip[1:0];
	
	
	assign chr_addr[12:0] = ppu_addr[12:0];
	assign chr_addr[18:13] = chr[5:0];
	
	wire [5:0]chr = {regs[3:0], regs[15:14]};
	wire prg_mod = regs[5];
	wire [4:0]prg  = regs[10:6];
	wire [1:0]chip = regs[12:11];
	wire mir_mod = regs[13];
	
	reg [15:0]regs;
	
	always @(negedge m2)begin
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 0)regs[7:0] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 1)regs[15:8] <= cpu_dat;
	end 
		else 
	if(map_rst)
	begin
		regs <= 0;
	end
		else
	if(!cpu_rw & cpu_addr[15])
	begin
	
		regs[15:0] <= {cpu_dat[1:0], cpu_addr[13:0]};
		
	end
end
endmodule
