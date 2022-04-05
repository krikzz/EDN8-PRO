
`include "../base/defs.v"

module map_009 //MMC2
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
	ss_addr[7:0] == 0 ? prg_bank: 
	ss_addr[7:0] == 1 ? chr_bank1: 
	ss_addr[7:0] == 2 ? chr_bank2: 
	ss_addr[7:0] == 3 ? chr_bank3: 
	ss_addr[7:0] == 4 ? chr_bank4: 
	ss_addr[7:0] == 5 ? {5'd0, clatch2, clatch1, mir_mode}: 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	wire ram_area = {cpu_addr[15:13], 13'd0} == 16'h6000;
	assign ram_we = !cpu_rw & ram_ce;
	assign chr_we = 0;//cfg_chr_ram ? !ppu_we & ciram_ce : 0;
	assign ram_ce = ram_area;
	assign rom_ce = cpu_addr[15];
	assign chr_ce = ciram_ce;
	

	
	assign ciram_a10 = !mir_mode ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	
	assign prg_addr[12:0] = cpu_addr[12:0];
	assign prg_addr[17:13] = map_idx == 9 ?  map_prg9 : map_prg10;
	
	wire [4:0]map_prg9 = cpu_addr[14:13] == 0 ? {1'b1, prg_bank[3:0]} : {3'b111, cpu_addr[14:13]};
	wire [4:0]map_prg10 = cpu_addr[14] == 0 ? {prg_bank[3:0], cpu_addr[13]} : {3'b111, cpu_addr[14:13]};
	
	assign chr_addr[11:0] = ppu_addr[11:0];
	assign chr_addr[16:12]  = !ppu_addr[12] ? (!clatch1 ? chr_bank1 : chr_bank2) : (!clatch2 ? chr_bank3 : chr_bank4);
	
	
	
	reg [3:0]prg_bank;
	reg [4:0]chr_bank1;
	reg [4:0]chr_bank2;
	reg [4:0]chr_bank3;
	reg [4:0]chr_bank4;
	reg mir_mode;
	reg clatch1;
	reg clatch2;
	
	reg [7:0]ppu_oe_st;
	reg [10:0]ppu_addr_st;
	
	
	
	always @(negedge clk)
	begin
	
	
		ppu_oe_st[7:0] <= {ppu_oe_st[6:0], ppu_oe};
		if(ppu_oe_st[3:0] == 4'b1000)ppu_addr_st[10:0] <= ppu_addr[13:3];

		if(ss_act)
		begin
			if(ss_we & ss_addr == 5 & m2)clatch1 <= cpu_dat[1];
			if(ss_we & ss_addr == 5 & m2)clatch2 <= cpu_dat[2];
		end
			else
		if(ppu_oe_st[3:0] == 4'b0001 & ppu_addr_st[0])
		case(ppu_addr_st[10:1])
			10'h0fd:begin
				clatch1 <= 0;
			end
			10'h0fe:begin
				clatch1 <= 1;
			end
			10'h1fd:begin
				clatch2 <= 0;
			end
			10'h1fe:begin
				clatch2 <= 1;
			end
		endcase
	
		
	end


	always @(negedge m2)
	begin
		
		
		if(ss_act)
		begin
			if(ss_we & ss_addr == 0)prg_bank <= cpu_dat;
			if(ss_we & ss_addr == 1)chr_bank1 <= cpu_dat;
			if(ss_we & ss_addr == 2)chr_bank2 <= cpu_dat;
			if(ss_we & ss_addr == 3)chr_bank3 <= cpu_dat;
			if(ss_we & ss_addr == 4)chr_bank4 <= cpu_dat;
			if(ss_we & ss_addr == 5)mir_mode <= cpu_dat[0];
		end
			else
		if(cpu_addr[15] & !cpu_rw)
		case(cpu_addr[14:12])
			
			2:begin
				prg_bank[3:0] <= cpu_dat[3:0];
			end
			
			3:begin
				chr_bank1[4:0] <= cpu_dat[4:0];
			end
			
			4:begin
				chr_bank2[4:0] <= cpu_dat[4:0];
			end
			
			5:begin
				chr_bank3[4:0] <= cpu_dat[4:0];
			end
			
			6:begin
				chr_bank4[4:0] <= cpu_dat[4:0];
			end
			
			7:begin
				mir_mode <= cpu_dat[0];
			end
			
		endcase
		
	end
	
endmodule
