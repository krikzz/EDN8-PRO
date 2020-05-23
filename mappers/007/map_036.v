
`include "../base/defs.v"

module map_036
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
	ss_addr[7:0] ==   0 ? chr :
	ss_addr[7:0] ==   1 ? prg :
	ss_addr[7:0] ==   2 ? {rr[1:0], pp[1:0], inv, inc} :
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = {cpu_addr[15:13], 13'd0} == 16'h6000;
	assign ram_we = !cpu_rw & ram_ce;
	assign rom_ce = cpu_addr[15];
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = cfg_mir_v ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
		
	assign chr_addr[12:0] = ppu_addr[12:0];
	assign chr_addr[16:13] = chr[3:0];
	
	assign prg_addr[14:0] = cpu_addr[14:0];
	assign prg_addr[16:15] = prg[1:0];
	
	assign map_cpu_oe = (cpu_addr[15:0] & 16'hE100) == 16'h4100 & cpu_rw;
	assign map_cpu_dout[7:0] = {cpu_addr[15:14], rr[1:0], cpu_addr[11:8]};
	
	reg [3:0]chr;
	reg [1:0]prg, rr, pp;
	reg inv, inc;
	
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 0)chr <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 1)prg <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 2){rr[1:0], pp[1:0], inv, inc} <= cpu_dat;
	end
		else
	if(map_rst)
	begin
		chr <= 0;
		prg <= 0;
		rr <= 0;
		pp <= 0;
		inv <= 0;
		inc <= 0;
	end
		else
	if(!cpu_rw)
	begin
		
		if((cpu_addr[15:0] & 16'hE200) == 16'h4200)chr[3:0] <= cpu_dat[3:0];
		
		if((cpu_addr[15:0] & 16'hE103) == 16'h4100)begin
			rr <= inc ? rr + 1 : inv ? pp ^ 2'b11 : pp;
		end
		
		if((cpu_addr[15:0] & 16'hE103) == 16'h4101)inv <= cpu_dat[4];
		if((cpu_addr[15:0] & 16'hE103) == 16'h4102)pp[1:0] <= cpu_dat[5:4];
		if((cpu_addr[15:0] & 16'hE103) == 16'h4103)inc <= cpu_dat[4];
		if((cpu_addr[15:0] & 16'h8000) == 16'h8000)prg[1:0] <= rr[1:0];
		
	end
	
	
endmodule
