
`include "../base/defs.v"

module map_165
(map_out, bus, sys_cfg, ss_ctrl); //no mapper

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
	ss_addr[7:2] == 0 ? {2'd0, chr_bank[ss_addr[1:0]][5:0]} : 
	ss_addr[7:0] == 4 ? {mirror, prg_inver, chr_inver, select[2:0], ram_on, ram_allow} : 
	ss_addr[7:0] == 5 ? {irq_reload[1:0], irq_enable, irq_reg[1:0], latch_0, latch_1, 1'b0} : 
	ss_addr[7:0] == 6 ? irq_counter[7:0] :
	ss_addr[7:0] == 7 ? irq_latch[7:0] :
	ss_addr[7:0] == 8 ? {2'd0, prg0[5:0]} :  
	ss_addr[7:0] == 9 ? {2'd0, prg1[5:0]} :
	ss_addr[7:0] == 10 ? ppua12_st[7:0] :	
	ss_addr[7:0] == 11 ? ppu_oe_st[7:0] :
	ss_addr[7:0] == 12 ? ppu_addr_st[7:0] :
	ss_addr[7:0] == 13 ? {6'd0, ppu_addr_st[9:8]} :
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************

	assign ram_we = (!cpu_rw & ram_ce) | ram_allow;			//6 bit
	assign ram_ce = ram_on & cpu_addr[14:13] == 2'b11 & cpu_ce & m2; 		//7 bit
	assign rom_ce = !cpu_ce;
	assign chr_ce = ciram_ce;
	assign chr_we = chr == 0 ? !ppu_we & ciram_ce : 0;//if cfg_chr_ram == 1 means that we don't have CHR rom, only CHR ram
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = !mirror ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[12:0] = cpu_addr[12:0];
	assign prg_addr[18:13] = cpu_ce ? 0 : !prg_inver ? prg_bank1[5:0] : prg_bank2[5:0];
	
	wire [5:0]prg_bank1 = 
	cpu_addr[14:13] == 2'b00 ? prg0[5:0] :
	cpu_addr[14:13] == 2'b01 ? prg1[5:0] : {5'b11111, cpu_addr[13]};
	wire [5:0]prg_bank2 = 
	cpu_addr[14:13] == 2'b01 ? prg1[5:0] : 
	cpu_addr[14:13] == 2'b10 ? prg0[5:0] : {5'b11111, cpu_addr[13]};		
	
	
	assign chr_addr[11:0] = ppu_addr[11:0];
	assign chr_addr[17:12] = chr;
	
	wire [5:0]chr = !ppu_addr[12] ? (!latch_0 ? chr_bank[0] : chr_bank[1]) : (!latch_1 ? chr_bank[2] : chr_bank[3]);
	
	reg mirror;
	reg prg_inver;
	reg chr_inver;
	reg [2:0]select;
	reg ram_on;
	reg ram_allow;
	
	reg [5:0]chr_bank[4];
	reg [5:0]prg0;
	reg [5:0]prg1;
	
	reg [7:0]irq_counter;
	reg [7:0]irq_latch;
	reg [1:0]irq_reload;
	wire irq_reloaded = irq_reload[0] != irq_reload[1];
	
	reg irq_enable;
	reg [1:0]irq_reg;
	reg [7:0]ppua12_st;
	
	assign irq = irq_reg[0] != irq_reg[1];
	
	always @ (negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:2] == 0) chr_bank[ss_addr[1:0]][5:0] <= cpu_dat[5:0];
		if(ss_we & ss_addr[7:0] == 4) {mirror, prg_inver, chr_inver, select[2:0], ram_on, ram_allow} <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 5) {irq_reload[0], irq_enable, irq_reg[0]} <= {cpu_dat[6:5], cpu_dat[3]};
		if(ss_we & ss_addr[7:0] == 7) irq_latch[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 8) prg0[5:0] <= cpu_dat[5:0];
		if(ss_we & ss_addr[7:0] == 9) prg1[5:0] <= cpu_dat[5:0];
		if(ss_we & ss_addr[7:0] == 10) ppua12_st[7:0] <= cpu_dat[7:0];
	end
	else
	begin
		if(map_rst) begin
			irq_enable <= 0;
		end
		if(!cpu_ce & !cpu_rw)
		case({cpu_addr[14:13], cpu_addr[0]})
		
			3'b000: begin
				select[2:0] <= cpu_dat[2:0];
				prg_inver <= cpu_dat[6];
				chr_inver <= cpu_dat[7];
			end
			
			3'b001: begin
				case(select)
				
					0: chr_bank[0][5:0] <= cpu_dat[7:2];
					1: chr_bank[1][5:0] <= cpu_dat[7:2];
					2: chr_bank[2][5:0] <= cpu_dat[7:2];
					4: chr_bank[3][5:0] <= cpu_dat[7:2];
					
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
			3'b101: irq_reload[0] <= !irq_reload[1];
			3'b110: begin 
				irq_enable <= 0;  
				irq_reg[0] <= irq_reg[1];
			end
			3'b111: irq_enable <= 1;
		
		endcase	
		
		ppua12_st[7:0] <= {ppua12_st[6:0], ppu_addr[12]};
	
	end
	
	always @ (posedge m2) 
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 5) {irq_reload[1], irq_reg[1]} <= {cpu_dat[7], cpu_dat[4]};
		if(ss_we & ss_addr[7:0] == 6) irq_counter[7:0] <= cpu_dat[7:0];
	end
	else
	begin
		
		if(ppua12_st[4:0] == 5'b00001) begin
			
			if(irq_counter == 0 | irq_reloaded ) begin
				irq_counter[7:0] <= irq_latch[7:0];
				irq_reload[1] <= irq_reload[0];
			end 
			else irq_counter <= irq_counter - 1;
			
			if((irq_counter == 1 & irq_enable & !irq_reloaded) | (irq_enable & irq_reloaded & irq_latch == 0) | (map_cfg[4] & irq_counter == 0)) irq_reg[1] <= !irq_reg[0];
		end	
		
	end
	
	
	reg latch_0;
	reg latch_1;
	reg [7:0]ppu_oe_st;
	reg [9:0]ppu_addr_st;
	
	always @ (negedge clk)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 5) {latch_0, latch_1} <= cpu_dat[2:1];
		if(ss_we & ss_addr[7:0] == 11) ppu_oe_st[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 12) ppu_addr_st[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 13) ppu_addr_st[9:8] <= cpu_dat[1:0];
	end
	else
	begin
	
		if(map_rst)
		begin
			latch_0 <= 0;
			latch_1 <= 0;
		end
	
		ppu_oe_st[7:0] <= {ppu_oe_st[6:0], ppu_oe};
		if(ppu_oe_st[3:0] == 4'b1000) ppu_addr_st[9:0] <= ppu_addr[13:4];
	
		if(ppu_oe_st[3:0] == 4'b0001) 
		case(ppu_addr_st[9:0])
		
			10'h0fd: latch_0 <= 0;
			
			10'h0fe: latch_0 <= 1;
			
			10'h1fd: latch_1 <= 0;
			
			10'h1fe: latch_1 <= 1;
		endcase
	end
	
endmodule
