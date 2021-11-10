
`include "../base/defs.v"

module map_040
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
	ss_addr[7:0] == 0 ? prg : 
	ss_addr[7:0] == 1 ? {irq_pend, irq_on} : 
	ss_addr[7:0] == 2 ? irq_ctr[7:0] : 
	ss_addr[7:0] == 3 ? irq_ctr[12:8] : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************

	assign ram_we = 0;//!cpu_rw & ram_ce;
	assign ram_ce = 0;//cpu_addr[14:13] == 2'b11 & cpu_ce & m2;
	assign rom_ce = !cpu_ce | (cpu_ce & cpu_addr[14:13] == 2'b11);
	assign chr_ce = ciram_ce;
	assign chr_we = 0;//cfg_chr_ram ? !ppu_we & ciram_ce : 0;
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = cfg_mir_v ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[12:0] = cpu_addr[12:0];
	assign prg_addr[15:13] = 
	cpu_ce ? 3'd6 : 
	cpu_addr[14:13] == 0 ? 3'd4 :
	cpu_addr[14:13] == 1 ? 3'd5 :
	cpu_addr[14:13] == 2 ? prg[2:0] : 3'd7;
	
	assign chr_addr[12:0] = ppu_addr[12:0];
	
	
	reg [2:0]prg;
	reg irq_on;	
	reg irq_pend;
	reg [12:0]irq_ctr;
	
	assign irq = irq_pend;
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 0)prg <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 1){irq_pend, irq_on} <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 2)irq_ctr[7:0] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 3)irq_ctr[12:8] <= cpu_dat;
	end
		else
	begin
		
		if(map_rst)prg <= 0;
			else
		if(!cpu_ce & !cpu_rw)
		case(cpu_addr[14:13])
			0:begin
				irq_on <= 0;
				irq_ctr <= 0;
				irq_pend <= 0;
			end
			1:begin
				irq_on <= 1;
			end
			3:begin
				prg[2:0] <= cpu_dat[2:0];
			end
		endcase
		

		if(irq_on)
		begin
		
			if(irq_ctr[12] == 0)irq_ctr <= irq_ctr + 1;
				else
			begin
				irq_on <= 0;
				irq_pend <= 1;
			end
		end
		
		
	end
	
endmodule
