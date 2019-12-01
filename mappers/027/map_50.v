
`include "../base/defs.v"

module map_050
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
	ss_addr[7:0] == 0 ? {4'b0000, prg_bank[3:0]} : 
	ss_addr[7:0] == 1 ? irq_counter[7:0] :
	ss_addr[7:0] == 2 ? {irq_enable, irq_reg, 1'b0, irq_counter[12:8]} :
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************

	assign ram_we = !cpu_rw & ram_ce;
	assign ram_ce = 0;//cpu_addr[14:13] == 2'b11 & cpu_ce & m2;
	assign rom_ce = !cpu_ce | (cpu_addr[14:13] == 2'b11 & cpu_ce);
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;//if cfg_chr_ram == 1 means that we don't have CHR rom, only CHR ram
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = cfg_mir_v ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[12:0] = cpu_addr[12:0];
	assign prg_addr[16:13] = cpu_ce ? 4'hF : 
	cpu_addr[14:13] == 2'b00 ? 4'h8 :
	cpu_addr[14:13] == 2'b01 ? 4'h9 :
	cpu_addr[14:13] == 2'b10 ? prg_bank[3:0] : 4'hB;
	
	assign chr_addr[12:0] = ppu_addr[12:0];
	
	reg [3:0]prg_bank;
	reg irq_enable;
	reg [12:0]irq_counter;
	reg irq_reg;
	
	assign irq = irq_reg;
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 0) prg_bank[3:0] <= cpu_dat[3:0];
		if(ss_we & ss_addr[7:0] == 1) irq_counter[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 2) 
		begin
			irq_counter[12:8] <= cpu_dat[4:0];
			irq_enable <= cpu_dat[7];
			irq_reg <= cpu_dat[6];
		end
	end
	else
	begin
		
		if(cpu_ce & !cpu_rw & cpu_addr[14:13] == 2'b10 & cpu_addr[6:5] == 2'b01) 
		begin
			if(!cpu_addr[8]) prg_bank[3:0] <= {cpu_dat[3], cpu_dat[0], cpu_dat[2:1]};
			else
			begin
				irq_enable <= cpu_dat[0];
				if(!cpu_dat[0]) begin
					irq_counter <= 0;
					irq_reg <= 0;
				end
			end
		end
		
		if(irq_enable) begin
			if(irq_counter[12]) begin
				irq_reg <= 1;
				irq_enable <= 0;
			end 
			else irq_counter <= irq_counter + 1;
		end
		
	end
	
endmodule
