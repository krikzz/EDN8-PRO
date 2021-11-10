
`include "../base/defs.v"

module map_091
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
	ss_addr[7:2] == 0 ? chr[ss_addr[1:0]] : 
	ss_addr[7:0] == 4 ? prg[0] : 
	ss_addr[7:0] == 5 ? prg[1] : 
	ss_addr[7:0] == 6 ? {irq_pend, irq_on, irq_ctr[3:0]} : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************

	assign ram_we = !cpu_rw & ram_ce;
	assign ram_ce = 0;//cpu_addr[14:13] == 2'b11 & cpu_ce & m2;
	assign rom_ce = !cpu_ce;
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = cfg_mir_v ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[12:0] = cpu_addr[12:0];
	assign prg_addr[16:13] = 
	cpu_addr[14:13] == 0 ? prg[0] : 
	cpu_addr[14:13] == 1 ? prg[1] : 
	cpu_addr[14:13] == 2 ? 4'b1110 : 4'b1111;
	
	assign chr_addr[10:0] = ppu_addr[10:0];
	assign chr_addr[18:11] = chr[ppu_addr[12:11]];

	
	reg [3:0]prg[2];
	reg [7:0]chr[4];
	reg irq_pend;
	reg irq_on;
	reg [3:0]irq_ctr;
	
	wire [2:0]reg_addr = {cpu_addr[12], cpu_addr[1:0]};
	reg [7:0]a12_filter;
	
	assign irq = irq_pend;
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:2] == 0)chr[ss_addr[1:0]] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 4)prg[0] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 5)prg[1] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 6){irq_pend, irq_on, irq_ctr[3:0]} <= cpu_dat;
	end
		else
	begin
	
		a12_filter[7:0] <= {a12_filter[6:0], ppu_addr[12]};
		
		
		if(a12_filter[4:0] == 5'b00001)
		begin
			if(irq_on)irq_ctr <= irq_ctr + 1;
			if(irq_ctr == 7)irq_pend <= 1;
		end
		
		if(cpu_ce & !cpu_rw & cpu_addr[14:13] == 2'b11)
		case(reg_addr)
			0:begin
				chr[0][7:0] <= cpu_dat[7:0];
			end
			1:begin
				chr[1][7:0] <= cpu_dat[7:0];
			end
			2:begin
				chr[2][7:0] <= cpu_dat[7:0];
			end
			3:begin
				chr[3][7:0] <= cpu_dat[7:0];
			end
			4:begin
				prg[0][3:0] <= cpu_dat[3:0];
			end
			5:begin
				prg[1][3:0] <= cpu_dat[3:0];
			end
			6:begin
				irq_on <= 0;
				irq_pend <= 0;
			end
			7:begin
				irq_on <= 1;
				irq_ctr <= 0;
			end
		endcase
		
	end
	
endmodule
