
`include "../base/defs.v"

module map_052 //MMC3
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
	ss_addr[7:0] == 0 ? prg0[7:0]:
	ss_addr[7:0] == 1 ? prg1[7:0]:
	ss_addr[7:0] == 2 ? chr0[7:0]:
	ss_addr[7:0] == 3 ? chr1[7:0]:
	ss_addr[7:0] == 4 ? chr2[7:0]:
	ss_addr[7:0] == 5 ? chr3[7:0]:
	ss_addr[7:0] == 6 ? chr4[7:0]:
	ss_addr[7:0] == 7 ? chr5[7:0]:
	
	ss_addr[7:0] == 8  ? {ram_allow,ram_on,select[2:0],mirror,prg_inver,chr_inver}:
	//ss_addr[7:0] == 9 ? irq_counter[7:0]:
	ss_addr[7:0] == 10 ? irq_latch[7:0]:
	ss_addr[7:0] == 11 ? {3'b000,irq_reload[1],1'b0,irq_reg[1],1'b0, irq_enable}:
	ss_addr[7:0] == 12 ? {prg_block[1:0],block_sel_bit,prg_block_size,chr_block[1:0],chr_block_size,we} :
	
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************

	assign ram_we = (!cpu_rw & ram_ce) | ram_allow;			//6 bit
	assign ram_ce = ram_on & cpu_addr[14:13] == 2'b11 & cpu_ce & m2; 		//7 bit
	assign rom_ce = !cpu_ce;
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;//if cfg_chr_ram == 1 means that we don't have CHR rom, only CHR ram
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = !mirror ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	//************************************************ prg
	assign prg_addr[12:0] = cpu_addr[12:0];
	assign prg_addr[19:13] = !prg_block_size ? {block_sel_bit, prg_block[1], prg_bk[4:0]} : {block_sel_bit, prg_block[1:0], prg_bk[3:0]};
	
	wire [5:0]prg_bk = cpu_ce ? 0 : !prg_inver ? prg_bank1[5:0] : prg_bank2[5:0];
	
	wire [5:0]prg_bank1 = 
	cpu_addr[14:13] == 2'b00 ? prg0[5:0] :
	cpu_addr[14:13] == 2'b01 ? prg1[5:0] : {5'b11111, cpu_addr[13]};
	wire [5:0]prg_bank2 = 
	cpu_addr[14:13] == 2'b01 ? prg1[5:0] : 
	cpu_addr[14:13] == 2'b10 ? prg0[5:0] : {5'b11111, cpu_addr[13]};		
	
	//************************************************** chr
	assign chr_addr[9:0] = ppu_addr[9:0];
	assign chr_addr[19:10] = !chr_block_size ? {block_sel_bit, chr_block[1], chr_bk[7:0]} : {block_sel_bit, chr_block[1:0], chr_bk[6:0]};
	
	wire [7:0]chr_bk = !chr_inver ? chr_bank1 : chr_bank2;
	
	wire [7:0]chr_bank1 = 
	ppu_addr[12:11] == 2'b00 ? {chr0[6:0], ppu_addr[10]} :
	ppu_addr[12:11] == 2'b01 ? {chr1[6:0], ppu_addr[10]} :
	ppu_addr[12:10] == 3'b100 ? chr2[7:0] :
	ppu_addr[12:10] == 3'b101 ? chr3[7:0] :
	ppu_addr[12:10] == 3'b110 ? chr4[7:0] : chr5[7:0];
	wire [7:0]chr_bank2 = 
	ppu_addr[12:10] == 3'b000 ? chr2[7:0] :
	ppu_addr[12:10] == 3'b001 ? chr3[7:0] :
	ppu_addr[12:10] == 3'b010 ? chr4[7:0] :
	ppu_addr[12:10] == 3'b011 ? chr5[7:0] :
	ppu_addr[12:11] == 2'b10 ? {chr0[6:0], ppu_addr[10]} : {chr1[6:0], ppu_addr[10]};
	
	reg mirror;
	reg prg_inver;
	reg chr_inver;
	reg [2:0]select;
	reg ram_on;
	reg ram_allow;
	
	reg [7:0]chr0;
	reg [7:0]chr1;
	reg [7:0]chr2;
	reg [7:0]chr3;
	reg [7:0]chr4;
	reg [7:0]chr5;
	reg [7:0]prg0;
	reg [7:0]prg1;
	
	reg [7:0]irq_counter;
	reg [7:0]irq_latch;
	reg [1:0]irq_reload;
	wire irq_reloaded = irq_reload[0] != irq_reload[1];
	
	reg irq_enable;
	reg [1:0]irq_reg;
	reg [7:0]ppua12_st;
	
	assign irq = irq_reg[0] != irq_reg[1];
	
	//multicart
	reg [1:0]prg_block;
	reg block_sel_bit;
	reg prg_block_size;
	reg [1:0]chr_block;
	reg chr_block_size;
	reg we;
	
	always @ (negedge m2)
	begin
	
		
	if(ss_act)
	begin
		if(ss_we)begin
			case(ss_addr[7:0])
				0: prg0[7:0] <= cpu_dat[7:0];
				1: prg1[7:0] <= cpu_dat[7:0];
				2: chr0[7:0] <= cpu_dat[7:0];
				3: chr1[7:0] <= cpu_dat[7:0];
				4: chr2[7:0] <= cpu_dat[7:0];
				5: chr3[7:0] <= cpu_dat[7:0];
				6: chr4[7:0] <= cpu_dat[7:0];
				7: chr5[7:0] <= cpu_dat[7:0];
				
				8: begin
					chr_inver <= cpu_dat[0];
					prg_inver <= cpu_dat[1];
					mirror <= cpu_dat[2];
					select[2:0] <= cpu_dat[5:3];
					ram_on <= cpu_dat[6];
					ram_allow <= cpu_dat[7];
				end
				//9  : irq_count[7:0]<= cpu_dat[7:0];
				10 : irq_latch[7:0] <= cpu_dat[7:0];
				11 : 
				begin
					irq_enable <= cpu_dat[0];
					irq_reg[0] <= cpu_dat[2] == cpu_dat[1] ? 0 : 1;
					irq_reload[1] <= cpu_dat[4] == cpu_dat[3] ? 0 : 1;
				end
				12 :
				begin
					we <= cpu_dat[0];
					chr_block_size <= cpu_dat[1];
					chr_block <= cpu_dat[3:2];
					prg_block_size <= cpu_dat[4];
					block_sel_bit <= cpu_dat[5];
					prg_block[1:0] <= cpu_dat[7:6];
				end
				
			endcase
		end
	end
		else
		 begin
		 
		if(map_rst) begin
			irq_enable <= 0;
			prg_block[1:0] <= 0;
			block_sel_bit <= 0;
			prg_block_size <= 0;
			chr_block[1:0] <= 0;
			chr_block_size <= 0;
			we <= 0;
		end else
		if(cpu_ce & cpu_addr[14:13] == 2'b11 & !cpu_rw & !we /*& ram_on & !ram_allow*/) begin
			
			prg_block[1:0] <= cpu_dat[1:0];
			block_sel_bit <= cpu_dat[2];
			prg_block_size <= cpu_dat[3];
			chr_block[1:0] <= cpu_dat[5:4];
			chr_block_size <= cpu_dat[6];
			we <= cpu_dat[7];
			
		end else
		if(!cpu_ce & !cpu_rw)
		case({cpu_addr[14:13], cpu_addr[0]})
		
			3'b000: begin
				select[2:0] <= cpu_dat[2:0];
				prg_inver <= cpu_dat[6];
				chr_inver <= cpu_dat[7];
			end
			
			3'b001: begin
				case(select)
				
					0: chr0[6:0] <= cpu_dat[7:1];
					1: chr1[6:0] <= cpu_dat[7:1];
					
					2: chr2[7:0] <= cpu_dat[7:0];
					3: chr3[7:0] <= cpu_dat[7:0];
					4: chr4[7:0] <= cpu_dat[7:0];
					5: chr5[7:0] <= cpu_dat[7:0];
					
					6: prg0[5:0] <= cpu_dat[5:0];
					7: prg1[5:0] <= cpu_dat[5:0];
				
				endcase
			end
			
			3'b010: mirror <= cpu_dat[0];
			
			3'b011: begin
				ram_on <= cpu_dat[7];
				ram_allow <= cpu_dat[6];
			end
			
			3'b100: irq_latch[7:0] <= cpu_dat[7:0];
			3'b101: irq_reload[1] <= !irq_reload[0];
			3'b110: begin 
				irq_enable <= 0;  
				irq_reg[0] <= irq_reg[1];
			end
			3'b111: irq_enable <= 1;
		
		endcase	
		
		ppua12_st[7:0] <= {ppua12_st[6:0], ppu_addr[12]};
		end
	end
	
	always @ (posedge m2) begin
		
		if(ppua12_st[4:0] == 4'b0001) begin
			
			if(irq_counter == 0 | irq_reloaded ) begin
				irq_counter[7:0] <= irq_latch[7:0];
				irq_reload[0] <= irq_reload[1];
			end 
			else irq_counter <= irq_counter - 1;
			
			if((irq_counter == 1 & irq_enable & !irq_reloaded) | (irq_enable & irq_reloaded & irq_latch == 0) | (map_cfg[4] & irq_counter == 0)) irq_reg[1] <= !irq_reg[0];
		end	
		
	end
	
endmodule
