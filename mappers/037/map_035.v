
`include "../base/defs.v"

module map_035
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
	ss_addr[7:0] == 0 ? prg[0] :
	ss_addr[7:0] == 1 ? prg[1] :
	ss_addr[7:0] == 2 ? prg[2] :
	
	ss_addr[7:0] == 3 ? chr[0] :
	ss_addr[7:0] == 4 ? chr[1] :
	ss_addr[7:0] == 5 ? chr[2] :
	ss_addr[7:0] == 6 ? chr[3] :
	ss_addr[7:0] == 7 ? chr[4] :
	ss_addr[7:0] == 8 ? chr[5] :
	ss_addr[7:0] == 9 ? chr[6] :
	ss_addr[7:0] == 10 ? chr[7] :
	
	ss_addr[7:0] == 11 ? {7'h00, mirror} :
	ss_addr[7:0] == 12 ? irq_st :
	ss_addr[7:0] == 13 ? {6'h00, irq_T, irq_e}:
	ss_addr[7:0] == 14 ? irq_count[7:0] :
	ss_addr[7:0] == 15 ? irq_count[15:8] :
	
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************

	assign ram_we = !cpu_rw & ram_ce;
	assign ram_ce = cpu_addr[14:13] == 2'b11 & cpu_ce & m2;
	assign rom_ce = !cpu_ce;
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;//if cfg_chr_ram == 1 means that we don't have CHR rom, only CHR ram
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = !mirror ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[12:0] = cpu_addr[12:0];
	assign prg_addr[19:13] = cpu_ce ? 8'h10 : prg_bank[7:0];
	
	assign chr_addr[9:0] = ppu_addr[9:0];
	assign chr_addr[17:10] = chr_bank[7:0];
	
	assign map_cpu_oe = cpu_addr[15:0] == 16'h5800 & cpu_rw & m2;
	assign map_cpu_dout[7:0] = 8'h20;
	
	assign irq = irq_T;
	
	wire [7:0] prg_bank = 
	cpu_addr[14:13] == 0 ? prg[0] :
	cpu_addr[14:13] == 1 ? prg[1] :
	cpu_addr[14:13] == 2 ? prg[2] : ~0;
	
	wire [7:0] chr_bank = 
	ppu_addr[12:10] == 0 ? chr[0] :
	ppu_addr[12:10] == 1 ? chr[1] :
	ppu_addr[12:10] == 2 ? chr[2] :
	ppu_addr[12:10] == 3 ? chr[3] :
	ppu_addr[12:10] == 4 ? chr[4] :
	ppu_addr[12:10] == 5 ? chr[5] :
	ppu_addr[12:10] == 6 ? chr[6] : chr[7];
	
	reg [7:0] prg[2:0];
	reg [7:0] chr[7:0];
	reg  mirror;
	
	reg irq_e;
	reg irq_T;
	reg [15:0] irq_count;
	
	
	reg [7:0] irq_st;
	
	always @ (negedge m2)begin
		
		irq_st[7:0] <= {irq_st[6:0], ppu_addr[12]};
		
		 if(irq_st[4:0] == 4'b0001)begin
			if(irq_count > 0) begin
				irq_count <= irq_count - 1;
			end
			if(irq_count == 1)begin
				irq_T <= 1;
			end
		 end
		
		if(ss_act)
	begin
		if(ss_we)begin
			case(ss_addr[7:0])
				0: prg[0][7:0] <= cpu_dat[7:0];
				1: prg[1][7:0] <= cpu_dat[7:0];
				2: prg[2][7:0] <= cpu_dat[7:0];
				
				3: chr[0][7:0] <= cpu_dat[7:0];
				4: chr[1][7:0] <= cpu_dat[7:0];
				5: chr[2][7:0] <= cpu_dat[7:0];
				6: chr[3][7:0] <= cpu_dat[7:0];
				7: chr[4][7:0] <= cpu_dat[7:0];
				8: chr[5][7:0] <= cpu_dat[7:0];
				9: chr[6][7:0] <= cpu_dat[7:0];
				10: chr[7][7:0] <= cpu_dat[7:0];
				
				11: mirror <= cpu_dat[0];
				12: irq_st <= cpu_dat[7:0];
				13: begin
					irq_e <= cpu_dat[0];
					irq_T <= cpu_dat[1];
				end
				14: irq_count[7:0] <= cpu_dat[7:0];
				15: irq_count[15:8] <= cpu_dat[7:0];
			endcase
		end
	end
		else
		 begin
		
		if(map_rst)begin
			irq_e <= 0;
			irq_count <= 0;
		end
		
		if(!cpu_ce & !cpu_rw)begin
			case(cpu_addr[15:0])
			
			16'h8000 : prg[0] <= cpu_dat;
			16'h8001 : prg[1] <= cpu_dat;
			16'h8002 : prg[2] <= cpu_dat;
			
			16'h9000 : chr[0] <= cpu_dat;
			16'h9001 : chr[1] <= cpu_dat;
			16'h9002 : chr[2] <= cpu_dat;
			16'h9003 : chr[3] <= cpu_dat;
			16'h9004 : chr[4] <= cpu_dat;
			16'h9005 : chr[5] <= cpu_dat;
			16'h9006 : chr[6] <= cpu_dat;
			16'h9007 : chr[7] <= cpu_dat;
			
			16'hC002 : begin irq_e <= 0; irq_T <= 0; end
			16'hC003 : irq_e <= 1;
			16'hC005 : irq_count <= cpu_dat;
			
			16'hD001 : mirror <= cpu_dat[0];
			
			endcase
		end
	 end
	end
	
endmodule
