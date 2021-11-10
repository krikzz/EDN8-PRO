
`include "../base/defs.v"

module map_045 //MMC3
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
	ss_addr[7:0] == 0 ? prg[0][7:0]:
	ss_addr[7:0] == 1 ? prg[1][7:0]:
	ss_addr[7:0] == 2 ? chr[0][7:0]:
	ss_addr[7:0] == 3 ? chr[1][7:0]:
	ss_addr[7:0] == 4 ? chr[2][7:0]:
	ss_addr[7:0] == 5 ? chr[3][7:0]:
	ss_addr[7:0] == 6 ? chr[4][7:0]:
	ss_addr[7:0] == 7 ? chr[5][7:0]:
	
	ss_addr[7:0] == 8  ? {ram_protect[1:0],select[2:0],mirror,prg_Mode,chr_A12}:
	//ss_addr[7:0] == 9  ? irq_count[7:0]:
	ss_addr[7:0] == 10 ? irq_st[7:0]:
	ss_addr[7:0] == 11 ? irq_latch[7:0]:
	ss_addr[7:0] == 12 ? {3'b000,irq_reload[1],1'b0,irq_T[1],1'b0, irq_e}:
	
	ss_addr[7:0] == 13 ? exReg[0] :
	ss_addr[7:0] == 14 ? exReg[1] :
	ss_addr[7:0] == 14 ? exReg[2] :
	ss_addr[7:0] == 15 ? exReg[3] :
	ss_addr[7:0] == 16 ? {6'h00, index[1:0]} :
	
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_we = (!cpu_rw & ram_ce) | ram_protect[0]; //!cpu_rw & ram_ce;
	assign ram_ce = ram_protect[1] & cpu_ce & m2  & cpu_addr[14:13] == 2'b11 & !lock;
	assign rom_ce = !cpu_ce ;//& (cpu_addr[14:13] == 2'b11 & cpu_ce);
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;//if cfg_chr_ram == 1 means that we don't have CHR rom, only CHR ram
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = !mirror ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[12:0] = cpu_addr[12:0];
	assign prg_addr[19:13] = exprg[6:0];
	
	assign chr_addr[9:0] = ppu_addr[9:0];
	assign chr_addr[19:10] = exchr[9:0];
	
	assign irq = irq_val;
	
	wire irq_R = irq_reload[0] != irq_reload[1];
	wire irq_val = irq_T[0] != irq_T[1];
	
	wire [11:0] exchr = lock ? bankC : chr_bank;
	
	wire [11:0] bankC = (chr_bank & (8'hFF >> (8'h0F - exReg[2][3:0]))) | exReg[0] | {exReg[2][7:4], 8'h00};
	
	wire [7:0] chr_bank = 
	!chr_A12 ? chr_bank1[7:0] : chr_bank2[7:0];
	
	//wire [5:0] exprg =  bankP[5:0] | exReg[1];
	
	//wire [6:0] exprg = !lock ? (exReg[1][6:0] | bank) : prg_bank;
	
	//wire [6:0] bankP = (prg_bank | exReg[1]) & (exReg[3][5:0]^6'h3f); 
	
	wire [6:0] exprg = (prg_bank & (6'h3f ^ exReg[3][5:0])) | exReg[1]; // >_< OMG
	
	wire [7:0] prg_bank =
	!prg_Mode ? prg_bank1 : prg_bank2;
	
	wire [7:0]chr_bank1 = 
	ppu_addr[12:11] == 0 ? {chr[0][7:1], ppu_addr[10]} :
	ppu_addr[12:11] == 1 ? {chr[1][7:1], ppu_addr[10]} :
	ppu_addr[12:10] == 4 ? chr[2][7:0] :
	ppu_addr[12:10] == 5 ? chr[3][7:0] :
	ppu_addr[12:10] == 6 ? chr[4][7:0] : chr[5][7:0];
	
	wire [7:0]chr_bank2 = 
	ppu_addr[12:10] == 0 ? chr[2][7:0] :
	ppu_addr[12:10] == 1 ? chr[3][7:0] :
	ppu_addr[12:10] == 2 ? chr[4][7:0] :
	ppu_addr[12:10] == 3 ? chr[5][7:0] :
	ppu_addr[12:11] == 3 ? {chr[0][7:1], ppu_addr[10]} : {chr[1][7:1], ppu_addr[10]};
	
	wire [7:0] prg_bank1 =
	cpu_addr[14:13] == 0 ? prg[0][7:0] :
	cpu_addr[14:13] == 1 ? prg[1][7:0] : 
	cpu_addr[14:13] == 2 ? 8'b11111110 : 8'b11111111;
	
	wire [7:0] prg_bank2 = 
	cpu_addr[14:13] == 0 ? 8'b11111110 :
	cpu_addr[14:13] == 1 ? prg[1][7:0] : 
	cpu_addr[14:13] == 2 ? prg[0][7:0] : 8'b11111111;
	
	reg mirror;
	reg [7:0]prg[1:0];
	reg [7:0]chr[5:0];
	
	reg chr_A12;
	reg prg_Mode;
	reg [2:0]select;
	reg [1:0]ram_protect;
	
	reg [7:0]irq_latch;
	reg irq_reload[1:0];
	reg irq_e;
	reg irq_T[1:0];
	reg [7:0]irq_count;
	reg [7:0]irq_st;
	
	reg[7:0] exReg[3:0];
	
	reg[1:0] index;
	
	always @ (posedge m2)begin
	
		if(irq_st[4:0] == 4'b0001)begin	
			if(irq_R || irq_count == 0)begin
			
				irq_count[7:0] <= irq_latch[7:0];
				irq_reload[1] <= irq_reload[0];
				
			end else	irq_count <= irq_count - 1;
			
			if((irq_count == 1 & irq_e & !irq_R) || (irq_latch == 0 & irq_e & irq_R) ||(map_cfg[4] & irq_count == 0))begin
				irq_T[1] <= !irq_T[0];
			end
			
		end 
	end
	
	wire lock = exReg[3][6];
	
	always @ (negedge m2) begin
	
	if(ss_act)
	begin
		if(ss_we)begin
			case(ss_addr[7:0])
				0: prg[0][7:0] <= cpu_dat[7:0];
				1: prg[1][7:0] <= cpu_dat[7:0];
				2: chr[0][7:0] <= cpu_dat[7:0];
				3: chr[1][7:0] <= cpu_dat[7:0];
				4: chr[2][7:0] <= cpu_dat[7:0];
				5: chr[3][7:0] <= cpu_dat[7:0];
				6: chr[4][7:0] <= cpu_dat[7:0];
				7: chr[5][7:0] <= cpu_dat[7:0];
				
				8: begin
					chr_A12 <= cpu_dat[0];
					prg_Mode <= cpu_dat[1];
					mirror <= cpu_dat[2];
					select[2:0] <= cpu_dat[5:3];
					ram_protect[1:0] <= cpu_dat[7:6];
				end
				//9  : irq_count[7:0]<= cpu_dat[7:0];
				10 : irq_st[7:0] <= cpu_dat[7:0];
				11 : irq_latch[7:0] <= cpu_dat[7:0];
				12 : 
				begin
					irq_e <= cpu_dat[0];
					irq_T[0] <= cpu_dat[2] == cpu_dat[1] ? 0 : 1;
					irq_reload[0] <= cpu_dat[4] == cpu_dat[3] ? 0 : 1;
				end
				13 : exReg[0] <= cpu_dat[7:0] ;
				14 : exReg[1] <= cpu_dat[7:0] ;
				14 : exReg[2] <= cpu_dat[7:0] ;
				15 : exReg[3] <= cpu_dat[7:0] ;
				16 : index[1:0] <= cpu_dat[1:0];
				
			endcase
			end
	end
		else
	begin
	
		if(map_rst) begin
			irq_e <= 0;
			
			exReg[0] <= 0;
			exReg[1] <= 0;
			exReg[2] <= 0;
			exReg[3] <= 0;
			
			index <= 0;
			
			//Needed by Famicom Yarou Vol 1 - Game apparently writes to CHR RAM before initializing the registers
			chr[0] = 0;
			chr[1] = 2;
			chr[2] = 4;
			chr[3] = 5;
			chr[4] = 6;
			chr[5] = 7;
		/**/
		
		end 
		
		
		irq_st[7:0] <= {irq_st[6:0], ppu_addr[12]};
		
		if(cpu_ce & !cpu_rw & cpu_addr[14:13] == 2'b11)begin //6000-7fff?
			
			if(!lock)begin
				exReg[index] <= cpu_dat[7:0];
				index <= index + 1;
			end
		end
		
		
		if(!cpu_ce & !cpu_rw)begin
			case({cpu_addr[14:13], cpu_addr[0]})
			
			0: begin 
				select[2:0] <= cpu_dat[2:0];
				prg_Mode <= cpu_dat[6];
				chr_A12 <= cpu_dat[7];
			end
			
			1: begin
				case(select[2:0])
					 0: chr[0][7:1] <= cpu_dat[7:1];
					 1: chr[1][7:1] <= cpu_dat[7:1];
						 
					 2: chr[2] <= cpu_dat[7:0];
					 3: chr[3] <= cpu_dat[7:0];
					 4: chr[4] <= cpu_dat[7:0];
					 5: chr[5] <= cpu_dat[7:0];
						 
					 6: prg[0][7:0] <= cpu_dat[7:0];
					 7: prg[1][7:0] <= cpu_dat[7:0];
				endcase
				end
				
			2: mirror <= cpu_dat[0];
			
			3: ram_protect[1:0] <= cpu_dat[7:6];
			
			4: begin 
				irq_latch[7:0] <= cpu_dat[7:0];//c0
				end
				
			5: begin 
				irq_reload[0] <= !irq_reload[1];
				end
				
			6: begin //e0
				irq_e <= 0;
				irq_T[0] <= irq_T[1];
				end
				
			7: irq_e <= 1;
			
			endcase
		end
	end
	end
endmodule
