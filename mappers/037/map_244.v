
`include "../base/defs.v"

module map_244 
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
	ss_addr[7:0] == 0 ? {6'h00, prg[1:0]} :
	ss_addr[7:0] == 1 ? {5'h00, chr[2:0]} :
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************

	assign ram_we = !cpu_rw & ram_ce;
	assign ram_ce = cpu_addr[14:13] == 2'b11 & cpu_ce & m2;
	assign rom_ce = !cpu_ce;
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;//if cfg_chr_ram == 1 means that we don't have CHR rom, only CHR ram
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = cfg_mir_v ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[14:0] = cpu_addr[14:0];
	assign prg_addr[16:15] = cpu_ce ? 0 : prg;
	
	assign chr_addr[12:0] = ppu_addr[12:0];
	assign chr_addr[15:13] = chr;
	
	wire [1:0] pbank = cpu_addr[7:0] - 8'h65;
	wire [2:0] cbank = cpu_addr[7:0] - 8'hA5;
	
	 
	reg [1:0] prg;
	reg [2:0] chr;
	
	always @ (negedge m2)begin
		if(ss_act)
	begin
		if(ss_we)begin
			case(ss_addr[7:0])
				0: prg <= cpu_dat[1:0];
				1: chr <= cpu_dat[2:0];
			endcase
		end
	end
		else
		 begin
		if(map_rst)begin
			prg <= 0;
		end
		
		if(!cpu_ce & !cpu_rw)begin
		if(cpu_addr[14:8] == 0)begin
				if(cpu_addr[7:0] >= 8'h0065 & cpu_addr[7:0] <= 8'hA4)begin
					prg[1:0] <= pbank;
				end
				
			   if(cpu_addr[7:0] >= 8'hA5 & cpu_addr[7:0] <= 8'hE4)begin
					chr[2:0] <= cbank;
				end
			end
		end
	end
	end
endmodule
