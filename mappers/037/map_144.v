
`include "../base/defs.v"

module map_144 
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
	ss_addr[7:0] == 0 ? latche:
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	wire chr_ram_on = cfg_chr_ram;
	assign ram_we = 0;
	assign chr_we = chr_ram_on ? !ppu_we & ciram_ce : 0;
	assign ram_ce = 0;
	assign rom_ce = !cpu_ce;
	assign chr_ce = ciram_ce;
	
	assign ciram_a10 = cfg_mir_v ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[14:0] = cpu_addr[14:0];
	assign prg_addr[16:15] = latche[3:0];
	
	assign chr_addr[12:0] = ppu_addr[12:0];
	assign chr_addr[16:13] = chr_ram_on ? 4'b0000 : latche[7:4];
	
	reg [7:0]latche;
	
	always @(negedge m2)
	begin
		
		if(ss_act)
	begin
		if(ss_we)begin
			case(ss_addr[7:0])
				0: latche <= cpu_dat;
			endcase
		end
	end else if(!cpu_ce & !cpu_rw)		
		begin
		
			if(map_rst)begin
				latche <= 0;
			end
			
			if(cpu_addr[15:0] >= 16'h8001)begin
				latche <= cpu_dat;
			end
		end
	end
	
	
	
endmodule