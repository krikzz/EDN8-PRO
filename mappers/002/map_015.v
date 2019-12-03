
`include "../base/defs.v"

module map_015
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
	ss_addr[7:0] == 0 ? {bnk_half, mirro_mode, prg[5:0]} : 
	ss_addr[7:0] == 1 ? bank_mode[1:0] : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = {cpu_addr[15:13], 13'd0} == 16'h6000;
	assign ram_we = !cpu_rw & ram_ce;
	assign rom_ce = !cpu_ce;
	assign chr_ce = ciram_ce;
	assign chr_we = !ppu_we & ciram_ce;// & bank_mode != 0 & bank_mode != 3;
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = !mirro_mode ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[12:0] = cpu_addr[12:0];
	assign prg_addr[13] = bank_mode == 2 ? prg_sw : cpu_addr[13];

	assign prg_addr[19:14] = 
	bank_mode == 0 ? prg0 : //32k
	bank_mode == 1 ? prg1 : //128k
	bank_mode == 2 ? prg2 : //8k
	prg3;//16k
	
	assign chr_addr[12:0] = ppu_addr[12:0];
	
	wire [4:0]prg_lo = prg0[4:0];
	wire [4:0]prg_hi = prg1[4:0];
	reg [1:0]bank_mode;
	
	reg [5:0]prg;
	reg mirro_mode;
	reg bnk_half;
	wire prg_sw  = prg[5];
	
	wire [5:0]prg0 = !cpu_addr[14] ? prg : prg | 1;		//32k
	wire [5:0]prg1 = !cpu_addr[14] ? prg : 6'b111111;	//128k
	wire [5:0]prg2 = {prg[4:0], bnk_half};					//8k
	wire [5:0]prg3 = prg[5:0];									//16k
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 0){bnk_half, mirro_mode, prg[5:0]} <= cpu_dat[6:0];
		if(ss_we & ss_addr[7:0] == 1)bank_mode[1:0] <= cpu_dat[1:0];
	end
		else
	begin
		
		if(map_rst)
		begin
			prg <= 0;
			bank_mode <= 0;
			bnk_half <= 0;
		end
			else
		if(!cpu_rw & !cpu_ce)
		begin
			
			{bnk_half, mirro_mode, prg[5:0]} <= cpu_dat[7:0];
			bank_mode[1:0] <= cpu_addr[1:0];
			
		end
	
	end
	
	
endmodule
