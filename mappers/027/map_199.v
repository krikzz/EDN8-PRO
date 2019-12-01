
`include "../base/defs.v"

module map_199
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
	ss_addr[7:0] == 0 ? chr0[7:0] : 
	ss_addr[7:0] == 1 ? chr1[7:0] : 
	ss_addr[7:0] == 2 ? chr2[7:0] : 
	ss_addr[7:0] == 3 ? chr3[7:0] : 
	ss_addr[7:0] == 4 ? chr4[7:0] : 
	ss_addr[7:0] == 5 ? chr5[7:0] : 
	ss_addr[7:0] == 6 ? {2'd0, prg0[5:0]} : 
	ss_addr[7:0] == 7 ? {2'd0, prg1[5:0]} :
	ss_addr[7:0] == 8 ? {mirror[1:0], prg_inver, chr_inver, select[2:0], ram_on} :
	ss_addr[7:0] == 9 ? {1'b0, ram_allow, irq_reload[1:0], irq_enable, irq_reg[1:0], exreg_enable} :
	ss_addr[7:0] == 10 ? irq_counter[7:0] : 
	ss_addr[7:0] == 11 ? irq_latch[7:0] : 
	ss_addr[7:0] == 12 ? ppua12_st[7:0] : 
	ss_addr[7:0] == 13 ? ex_regs[0][7:0] : 
	ss_addr[7:0] == 14 ? ex_regs[1][7:0] :
	ss_addr[7:0] == 15 ? ex_regs[2][7:0] :
	ss_addr[7:0] == 16 ? ex_regs[3][7:0] :
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************

	assign ram_we = (!cpu_rw & ram_ce) | ram_allow;			//6 bit
	assign ram_ce = ram_on & cpu_addr[14:13] == 2'b11 & cpu_ce & m2; 		//7 bit
	assign rom_ce = !cpu_ce;
	assign chr_ce = ciram_ce;
	assign chr_we = !ppu_we & ciram_ce;//if cfg_chr_ram == 1 means that we don't have CHR rom, only CHR ram
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = 
	mirror == 0 ? ppu_addr[10] : 
	mirror == 1 ? ppu_addr[11] :
	mirror == 2 ? 0 : 1;
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[12:0] = cpu_addr[12:0];
	assign prg_addr[18:13] = cpu_ce ? 0 : 
	cpu_addr[14:13] == 2 ? ex_regs[0][5:0]	:
	cpu_addr[14:13] == 3 ? ex_regs[1][5:0]	: prg_mmc3[5:0];
	
	wire [5:0]prg_mmc3 = !prg_inver ? prg_bank1[5:0] : prg_bank2[5:0];
	wire [5:0]prg_bank1 = 
	cpu_addr[14:13] == 2'b00 ? prg0[5:0] :
	cpu_addr[14:13] == 2'b01 ? prg1[5:0] : {5'b11111, cpu_addr[13]};
	wire [5:0]prg_bank2 = 
	cpu_addr[14:13] == 2'b01 ? prg1[5:0] : 
	cpu_addr[14:13] == 2'b10 ? prg0[5:0] : {5'b11111, cpu_addr[13]};		
	
	
	assign chr_addr[9:0] = ppu_addr[9:0];
	assign chr_addr[17:10] = 
	ppu_addr[12:10] == 0 ? chr0[7:0] :
	ppu_addr[12:10] == 1 ? ex_regs[2][7:0] :
	ppu_addr[12:10] == 2 ? chr1[7:0] :
	ppu_addr[12:10] == 3 ? ex_regs[3][7:0] : chr_mmc3[7:0];
	
	wire [7:0]chr_mmc3 = !chr_inver ? chr_bank1 : chr_bank2;
	wire [7:0]chr_bank1 = 
	ppu_addr[12:11] == 2'b00 ? {chr0[7:1], ppu_addr[10]} :
	ppu_addr[12:11] == 2'b01 ? {chr1[7:1], ppu_addr[10]} :
	ppu_addr[12:10] == 3'b100 ? chr2[7:0] :
	ppu_addr[12:10] == 3'b101 ? chr3[7:0] :
	ppu_addr[12:10] == 3'b110 ? chr4[7:0] : chr5[7:0];
	wire [7:0]chr_bank2 = 
	ppu_addr[12:10] == 3'b000 ? chr2[7:0] :
	ppu_addr[12:10] == 3'b001 ? chr3[7:0] :
	ppu_addr[12:10] == 3'b010 ? chr4[7:0] :
	ppu_addr[12:10] == 3'b011 ? chr5[7:0] :
	ppu_addr[12:11] == 2'b10 ? {chr0[7:1], ppu_addr[10]} : {chr1[7:1], ppu_addr[10]};
	
	
	reg [1:0]mirror;
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
	
	reg [7:0]ex_regs[4];
	reg exreg_enable;
	
	always @ (negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 0) chr0[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 1) chr1[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 2) chr2[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 3) chr3[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 4) chr4[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 5) chr5[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 6) prg0[5:0] <= cpu_dat[5:0];
		if(ss_we & ss_addr[7:0] == 7) prg1[5:0] <= cpu_dat[5:0];
		if(ss_we & ss_addr[7:0] == 8) {mirror[1:0], prg_inver, chr_inver, select[2:0], ram_on} <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 9) 
		{ram_allow, irq_reload[1:0], irq_enable, irq_reg[1:0], exreg_enable} <= cpu_dat[6:0];
		if(ss_we & ss_addr[7:0] == 10) irq_counter[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 11) irq_latch[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 12) ppua12_st[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 13) ex_regs[0][7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 14) ex_regs[1][7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 15) ex_regs[2][7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 16) ex_regs[3][7:0] <= cpu_dat[7:0];
	end
	else
	begin
		if(map_rst) begin
			irq_enable <= 0;
			ex_regs[0] <= 8'hFE;
			ex_regs[1] <= 8'hFF;
			ex_regs[2] <= 8'h01;
			ex_regs[3] <= 8'h03;
		end
		
		if(!cpu_rw)
		case({cpu_addr[15:13], 12'd0, cpu_addr[0]})
		
			16'h8000: begin
				select[2:0] <= cpu_dat[2:0];
				exreg_enable <= cpu_dat[3];
				prg_inver <= cpu_dat[6];
				chr_inver <= cpu_dat[7];
			end
			
			16'h8001: begin
				if(exreg_enable) begin
					ex_regs[select[1:0]][7:0] <= cpu_dat[7:0];
				end
					else
				case(select)
					0: chr0[7:0] <= cpu_dat[7:0];
					1: chr1[7:0] <= cpu_dat[7:0];
					
					2: chr2[7:0] <= cpu_dat[7:0];
					3: chr3[7:0] <= cpu_dat[7:0];
					4: chr4[7:0] <= cpu_dat[7:0];
					5: chr5[7:0] <= cpu_dat[7:0];
					
					6: prg0[5:0] <= cpu_dat[5:0];
					7: prg1[5:0] <= cpu_dat[5:0];
				endcase
			end
			
			16'hA000: mirror[1:0] <= cpu_dat[1:0];
			16'hA001: begin
				ram_on <= cpu_dat[7];
				ram_allow <= cpu_dat[6];
			end
			
			16'hC000: irq_latch[7:0] <= cpu_dat[7:0];
			16'hC001: irq_reload[1] <= !irq_reload[0];
			16'hE000: begin 
				irq_enable <= 0;  
				irq_reg[0] <= irq_reg[1];
			end
			16'hE001: irq_enable <= 1;
		
		endcase	
		
		ppua12_st[7:0] <= {ppua12_st[6:0], ppu_addr[12]};
		
		if(ppua12_st[4:0] == 5'b00001) begin
			
			if(irq_counter == 0 | irq_reloaded ) begin
				irq_counter[7:0] <= irq_latch[7:0];
				irq_reload[0] <= irq_reload[1];
			end 
			else irq_counter <= irq_counter - 1;
			
			if((irq_counter == 1 & irq_enable & !irq_reloaded) | (irq_enable & irq_reloaded & irq_latch == 0) | (map_cfg[4] & irq_counter == 0)) irq_reg[1] <= !irq_reg[0];
		end
	end
	
endmodule


	
	
	
	
	
	





