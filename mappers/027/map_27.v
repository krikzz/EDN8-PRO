
`include "../base/defs.v"

module map_027
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
	ss_addr[7:3] == 0 ? chr_bank[ss_addr[2:0]][7:0] : 
	ss_addr[7:3] == 1 ? chr_bank[ss_addr[2:0]][8] : 
	ss_addr[7:0] == 16 ? prg_bank[0] : 
	ss_addr[7:0] == 17 ? prg_bank[1] : 
	ss_addr[7:0] == 18 ? prg_bank[2]: 
	ss_addr[7:0] == 24 ? irq_latch[7:0] : 
	ss_addr[7:0] == 25 ? {mirror[1:0], irq_enable, irq_enable_after, irq_cycle, prg_mode, irq_reg[1:0]} : 
	ss_addr[7:0] == 26 ? irq_counter[7:0] :
	ss_addr[7:0] == 27 ? irq_prescaler_counter[7:0] :
	ss_addr[7:0] == 28 ? {7'b0000000, irq_prescaler_counter[8]} :
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = {cpu_addr[15:13], 13'd0} == 16'h6000;
	assign ram_we = !cpu_rw & ram_ce;
	assign rom_ce = !cpu_ce;
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;//if cfg_chr_ram == 1 means that we don't have CHR rom, only CHR ram
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = 
	mirror == 0 ? ppu_addr[10] : 
	mirror == 1 ? ppu_addr[11] :
	mirror == 2 ? 0 : 1;
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[12:0] = cpu_addr[12:0];
	assign prg_addr[18:13] = cpu_ce ? 0 : prg;
	
	wire [5:0]prg = 
	cpu_addr[14:13] == 0 ? (prg_mode ? 6'h3e : prg_bank[0]) :
	cpu_addr[14:13] == 1 ? prg_bank[1] :
	cpu_addr[14:13] == 2 ? (!prg_mode ? 6'h3e : prg_bank[2]) : 6'h3f;
	
	assign chr_addr[9:0] = ppu_addr[9:0];
	assign chr_addr[18:10] = chr_bank[ppu_addr[12:10]];
	
	reg prg_mode;
	reg [5:0]prg_bank[3];
	reg [8:0]chr_bank[8];
	reg [1:0]mirror;
	
	reg [7:0]irq_latch;
	reg irq_enable;
	reg irq_enable_after;
	reg irq_cycle;
	reg [7:0]irq_counter;
	reg [1:0]irq_reg;
	reg [8:0]irq_prescaler_counter;
	
	assign irq = irq_reg[1] != irq_reg[0];
	
	always @ (negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:3] == 0) chr_bank[ss_addr[2:0]][7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:3] == 1) chr_bank[ss_addr[2:0]][8] <= cpu_dat[0];
		if(ss_we & ss_addr[7:0] == 16) prg_bank[0] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 17) prg_bank[1] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 18) prg_bank[2] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 24) irq_latch[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 25){mirror[1:0], irq_enable, irq_enable_after, irq_cycle, prg_mode, irq_reg[1:0]} <= cpu_dat;

		if(ss_we & ss_addr[7:0] == 26) irq_counter[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 27) irq_prescaler_counter[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 28) irq_prescaler_counter[8] <= cpu_dat[0];
	end
		else
	begin

		if(!cpu_rw)
		case({!cpu_ce, cpu_addr[14:0]})
			
			16'h8000: begin
				if(!prg_mode) prg_bank[0][5:0] <= cpu_dat[5:0];
				else prg_bank[2][5:0] <= cpu_dat[5:0];
			end
			16'hA000: prg_bank[1][5:0] <= cpu_dat[5:0];
			
			16'h9000: mirror[1:0] <= cpu_dat[1:0];
			16'h9002: prg_mode <= cpu_dat[1];
			16'h9080: prg_mode <= cpu_dat[1];
			
			16'hB000: chr_bank[0][3:0] <= cpu_dat[3:0];
			16'hB001: chr_bank[0][8:4] <= cpu_dat[4:0];
			16'hB002: chr_bank[1][3:0] <= cpu_dat[3:0];
			16'hB003: chr_bank[1][8:4] <= cpu_dat[4:0];
			16'hC000: chr_bank[2][3:0] <= cpu_dat[3:0];
			16'hC001: chr_bank[2][8:4] <= cpu_dat[4:0];
			16'hC002: chr_bank[3][3:0] <= cpu_dat[3:0];
			16'hC003: chr_bank[3][8:4] <= cpu_dat[4:0];
			16'hD000: chr_bank[4][3:0] <= cpu_dat[3:0];
			16'hD001: chr_bank[4][8:4] <= cpu_dat[4:0];
			16'hD002: chr_bank[5][3:0] <= cpu_dat[3:0];
			16'hD003: chr_bank[5][8:4] <= cpu_dat[4:0];
			16'hE000: chr_bank[6][3:0] <= cpu_dat[3:0];
			16'hE001: chr_bank[6][8:4] <= cpu_dat[4:0];
			16'hE002: chr_bank[7][3:0] <= cpu_dat[3:0];
			16'hE003: chr_bank[7][8:4] <= cpu_dat[4:0];
			
			16'hF000: begin
				irq_latch[3:0] <= cpu_dat[3:0];
				//irq_reg[1] <= irq_reg[0];
			end
			16'hF001: begin
				irq_latch[7:4] <= cpu_dat[3:0];
				//irq_reg[1] <= irq_reg[0];
			end
			16'hF002: begin
				irq_enable_after <= cpu_dat[0];
				irq_enable <= cpu_dat[1];
				irq_cycle <= cpu_dat[2];
				if(cpu_dat[1]) begin 
					irq_counter <= irq_latch;
					irq_prescaler_counter <= 341;
				end
				irq_reg[1] <= irq_reg[0];
			end
			16'hF003: begin
				irq_enable <= irq_enable_after;
				irq_reg[1] <= irq_reg[0];
			end
			
		endcase
		
		//ppua12_st[7:0] <= {ppua12_st[6:0], ppu_addr[12]};
		
		if(irq_enable) begin
			irq_prescaler_counter <= irq_prescaler_counter - 3;
		
			if((/*ppua12_st[3:0] == 4'b0001*/irq_prescaler_counter == 2 & !irq_cycle) | irq_cycle) begin
		
				if(irq_counter == 8'hff) begin
					irq_counter <= irq_latch;
					irq_reg[0] <= !irq_reg[1];
				end
				else irq_counter <= irq_counter + 1;
				
				irq_prescaler_counter <= 341;
			end
		end
		
	end
	
	//reg [7:0]ppua12_st;

endmodule
