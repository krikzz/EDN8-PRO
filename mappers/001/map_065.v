
`include "../base/defs.v"

module map_065
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
	ss_addr[7:3] == 0 ? chr_reg[ss_addr[2:0]] : 
	ss_addr[7:0] == 8 ? prg0  : 
	ss_addr[7:0] == 9 ? prg1  : 
	ss_addr[7:0] == 10 ? prg2 : 
	ss_addr[7:0] == 11 ? irq_ctr[7:0] : 
	ss_addr[7:0] == 12 ? irq_ctr[15:8]  : 
	ss_addr[7:0] == 13 ? irq_reload[7:0] : 
	ss_addr[7:0] == 14 ? irq_reload[15:8] : 
	ss_addr[7:0] == 15 ? {mirror_mode, irq_reload_req, irq_pend, irq_on} : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = 0;
	assign ram_we = !cpu_rw & ram_ce;
    assign rom_ce = !cpu_ce;
    assign chr_ce = ciram_ce;
    assign chr_we = 0;//cfg_chr_ram ? !ppu_we & ciram_ce : 0;
    
    //A10-Vmir, A11-Hmir
    assign ciram_a10 = !mirror_mode ? ppu_addr[10] : ppu_addr[11];
    assign ciram_ce = !ppu_addr[13];
    
    assign prg_addr[12:0] = cpu_addr[12:0];
    //assign prg_addr[14:13] = cpu_ce ? 0 : cpu_addr[14:13];
    assign prg_addr[17:13] = 
    cpu_addr[14:13] == 0 ? prg0[4:0] : 
    cpu_addr[14:13] == 1 ? prg1[4:0] : 
    cpu_addr[14:13] == 2 ? prg2[4:0] : 
    5'b11111;
    
    assign chr_addr[9:0] = ppu_addr[9:0];
    assign chr_addr[17:10] = chr_reg[ppu_addr[12:10]];
    
	 assign irq = irq_pend;
    
	 reg [7:0]chr_reg[8];
    reg [4:0]prg0;
    reg [4:0]prg1;
    reg [4:0]prg2;
    reg [15:0]irq_ctr;
    reg [15:0]irq_reload;
    reg irq_on;
    reg irq_pend;
    reg irq_reload_req;
	 reg mirror_mode;
    
    
    always @(negedge m2)
    begin
        
		if(ss_act)
		begin
			if(ss_we & ss_addr[7:3] == 0)chr_reg[ss_addr[2:0]] <= cpu_dat;
			if(ss_we & ss_addr[7:0] == 8)prg0 <= cpu_dat;
			if(ss_we & ss_addr[7:0] == 9)prg1 <= cpu_dat;
			if(ss_we & ss_addr[7:0] == 10)prg2 <= cpu_dat;
			if(ss_we & ss_addr[7:0] == 11)irq_ctr[7:0] <= cpu_dat;
			if(ss_we & ss_addr[7:0] == 12)irq_ctr[15:8] <= cpu_dat;
			if(ss_we & ss_addr[7:0] == 13)irq_reload[7:0] <= cpu_dat;
			if(ss_we & ss_addr[7:0] == 14)irq_reload[15:8] <= cpu_dat;
			if(ss_we & ss_addr[7:0] == 15){mirror_mode, irq_reload_req, irq_pend, irq_on} <= cpu_dat[3:0];
		end
			else
	  if(map_rst)
	  begin
			prg0 <= 5'h00;
			prg1 <= 5'h01;
			prg2 <= 5'h1E;
			irq_on <= 0;
			irq_pend <= 0;
	  end
			else
	  begin
	  
			if(irq_reload_req)
			begin
				 irq_reload_req <= 0;
				 irq_pend <= 0;
				 irq_ctr[15:0] <= irq_reload[15:0];
			end
				 else
			if(irq_on)
			begin
				 if(irq_ctr != 0)irq_ctr <= irq_ctr - 1;
				 if(irq_ctr == 1)irq_pend <= 1;
			end
	  
			if(!cpu_ce & !cpu_rw)
			case(cpu_addr[14:12])
				 0:begin
					  prg0[4:0] <= cpu_dat[4:0];
				 end
				 1:begin
					  if(cpu_addr[2:0] == 1)mirror_mode <= cpu_dat[7];
							else
					  if(cpu_addr[2:0] == 3)
					  begin
							irq_pend <= 0;
							irq_on <= cpu_dat[7];
					  end
							else
					  if(cpu_addr[2:0] == 4)irq_reload_req <= 1;
							else
					  if(cpu_addr[2:0] == 5)irq_reload[15:8] <= cpu_dat[7:0];
							else
					  if(cpu_addr[2:0] == 6)irq_reload[7:0] <= cpu_dat[7:0];
				 end
				 2:begin
					  prg1[4:0] <= cpu_dat[4:0];
				 end
				 3:begin
					  chr_reg[cpu_addr[2:0]] <= cpu_dat[7:0];
				 end
				 4:begin
					  prg2[4:0] <= cpu_dat[4:0];
				 end
			endcase
			
        end
    end
    
    
endmodule

