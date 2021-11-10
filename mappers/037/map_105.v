
`include "../base/defs.v"

module map_105
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
	ss_addr[7:0] == 0 ? {3'b000, r0[4:0]}:
	ss_addr[7:0] == 1 ? {3'b000, r1[4:0]}:
	ss_addr[7:0] == 2 ? {3'b000, r3[4:0]}:
	
	ss_addr[7:0] == 3 ? {4'h0, buff[3:0]}:
	ss_addr[7:0] == 4 ? {5'h00, ctr[2:0]}:
	ss_addr[7:0] == 5 ? {5'h00, WRAM,we_st,irq_T}:
	
	ss_addr[7:0] == 6 ? irq_count[7:0]:
	ss_addr[7:0] == 7 ? irq_count[15:8]:
	ss_addr[7:0] == 8 ? irq_count[23:16]:
	ss_addr[7:0] == 9 ? {2'b00,irq_count[29:24]}:
	
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	wire ram_area = cpu_addr[14:13] == 2'b11 && cpu_ce && m2 && !WRAM;//
	assign ram_we = !cpu_rw & ram_ce;
	assign ram_ce = ram_area;
	assign rom_ce = !cpu_ce;
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;//if cfg_chr_ram == 1 means that we don't have CHR rom, only CHR ram
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = mirror; //control[1] ? control[0] : !control[0] ? ppu_addr[10] : ppu_addr[11]; //
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[11:0] = cpu_addr[11:0];
	assign prg_addr[18:12] = ram_area ? {6'b0000, cpu_addr[13:12]} : prg_bank;
	
	wire [6:0] prg_bank = 
	!r1[3] ? {2'b00, r1[2:1],cpu_addr[14:12]} :
	r0[3:2] == 0 ? {2'b01, r3[2:1], cpu_addr[14:12]} :
	r0[3:2] == 1 ? {2'b01, r3[2:1], cpu_addr[14:12]} :
	r0[3:2] == 2 ? prgMode0 : prgMode1;
	
	wire [6:0]prgMode0 = !cpu_addr[14] ? {5'b01000, cpu_addr[13:12]} : {2'b01, r3[2:0], cpu_addr[13:12]};
	wire [6:0]prgMode1 = !cpu_addr[14] ? {2'b01, r3[2:0], cpu_addr[13:12]} : {5'b01111, cpu_addr[13:12]};
	
	assign chr_addr[12:0] = ppu_addr[12:0];
	
	assign irq = irq_T;
	//assign irq_e = r1[4];
	
	wire mirror = 
	r0[1:0] == 0 ? 0 :
	r0[1:0] == 1 ? 1 : 
	r0[1:0] == 2 ? ppu_addr[10] : ppu_addr[11];
	
	reg DIP_SWITCH_4 = 1;
	reg DIP_SWITCH_3 = 1;
	reg DIP_SWITCH_2 = 0;
	reg DIP_SWITCH_1 = 0;
	
	//0011 - 9.07
	//1100 - 6.15
	
	/*reg [19:0]DIP_SWITCH_XXX = 20'b11111111111111111111; // test
	reg [9:0]DIP_SWITCH_XX = 10'b1111111111;*/
		/*
			
			DIP switches: O - closed (1), C - opened (0)
			OOOO - 5.001
			OOOC - 5.316
			OOCO - 5.629
			OOCC - 5.942 //6.15
			OCOO - 6.254 //default // 6.34 ?
			OCOC - 6.567
			OCCO - 6.880
			OCCC - 7.193
			COOO - 7.505
			COOC - 7.818
			COCO - 8.131
			COCC - 8.444 // 0100
			CCOO - 8.756 
			CCOC - 9.070 
			CCCO - 9.318 
			CCCC - 9.695
		*/
		
	
	reg [4:0]r0;
	reg [4:0]r1;
	reg [4:0]r3;
	
	reg [3:0]buff;
	reg [2:0]ctr;
	
	reg [29:0] irq_count;
	reg irq_T;
	
	reg we_st;
	reg WRAM;
	
	
	always @ (negedge m2)begin
		
		if(ss_act)
	begin
		if(ss_we)begin
			case(ss_addr[7:0])
				0: r0 <= cpu_dat[4:0];
				1: r1 <= cpu_dat[4:0];
				2: r3 <= cpu_dat[4:0];
				
				3: buff <= cpu_dat[3:0];
				4: ctr <= cpu_dat[2:0];
				5: 
				begin
					irq_T <= cpu_dat[0];
					we_st <= cpu_dat[1];
					WRAM <= cpu_dat[2];
				end
				
				6: irq_count[7:0] <= cpu_dat[7:0];
				7: irq_count[15:8] <= cpu_dat[7:0];
				8: irq_count[23:16] <= cpu_dat[7:0];
				9: irq_count[29:24] <= cpu_dat[7:0];
				
			endcase
		end
	end
		else
		 begin
		
		if (r1[4]) begin
				irq_count <= {1'b0, DIP_SWITCH_4, DIP_SWITCH_3, DIP_SWITCH_2, DIP_SWITCH_1,25'b0_0000_0000_0000_0000_0000_0000}; // 25'b0000000000000000000000000
				irq_T <= 0;
			end else begin
				irq_count <= irq_count + 1;
				if (irq_count[29:0] == 30'b111111111111111111111111111110)irq_T <= 1;
			end
		
		we_st <= cpu_rw | cpu_ce;
		
		if(map_rst)begin 
			r0 <= 5'b01100;
			r1 <= 5'b00000;
			r3 <= 5'b10000;
			buff <= 4'b0000;
			irq_count <= 0;
			ctr <= 0;
			end
			else
		if(!cpu_ce & !cpu_rw & we_st)
		begin
			
			if(cpu_dat[7])
			begin
				ctr <= 0;
				r0[3:2] <= 2'b11; 
			end
				else
			begin
				if(ctr == 4)
				begin
					ctr <= 0;
					case(cpu_addr[14:13])
						0:	r0[4:0] <= {cpu_dat[0], buff[3:0]};
		
						1:	r1[4:0] <= {cpu_dat[0], buff[3:0]};
					
						3:	r3[4:0] <= {cpu_dat[0], buff[3:0]};
						
					endcase
				end
					else
				begin
					buff[3:0] <= {cpu_dat[0], buff[3:1]};
					ctr <= ctr + 1;
				end
			end
		end
	 end
	end
	endmodule