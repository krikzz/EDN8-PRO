
`include "../base/defs.v"

module map_018
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
	ss_addr[7:3] == 0 ? chr[ss_addr[2:0]] : 
	ss_addr[7:0] == 8 ? prg[0] : 
	ss_addr[7:0] == 9 ? prg[1] : 
	ss_addr[7:0] == 10 ? prg[2] : 
	ss_addr[7:0] == 11 ? irq_ctr[15:8] : 
	ss_addr[7:0] == 12 ? irq_ctr[7:0] : 
	ss_addr[7:0] == 13 ? irq_reload[15:8] : 
	ss_addr[7:0] == 14 ? irq_reload[7:0] : 
	ss_addr[7:0] == 15 ? {irq_pend, irq_on, mirror_mode[1:0], irq_cfg[2:0]} : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = {cpu_addr[15:13], 13'd0} == 16'h6000;
	assign ram_we = !cpu_rw & ram_ce;
	assign rom_ce = cpu_addr[15];
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = 
	mirror_mode == 1 ? ppu_addr[10] : 
	mirror_mode == 0 ? ppu_addr[11] : mirror_mode[0];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[12:0] = cpu_addr[12:0];
	assign prg_addr[18:13] = 
	cpu_ce ? 0 : 
	cpu_addr[14:13] == 0 ? prg[0][5:0] : 
	cpu_addr[14:13] == 1 ? prg[1][5:0] : 
	cpu_addr[14:13] == 2 ? prg[2][5:0] : 6'b111111;
	
	assign chr_addr[9:0] = ppu_addr[9:0];
	assign chr_addr[17:10] = chr[ppu_addr[12:10]][7:0];

	assign irq = irq_pend;
	
	wire [3:0]reg_addr = {cpu_addr[14:12], cpu_addr[1]};
	
	wire [15:0]irq_ctr_val = 
	irq_cfg[2] ? {12'd0, irq_ctr[3:0]} : 
	irq_cfg[1] ? {8'd0, irq_ctr[7:0]} : 
	irq_cfg[0] ? {4'd0, irq_ctr[11:0]} : irq_ctr[15:0];
	
	
	reg [7:0]chr[8];
	reg [7:0]prg[3];

	
	
	reg [15:0]irq_ctr;
	reg [15:0]irq_reload;
	
	reg [2:0]irq_cfg;
	reg [1:0]mirror_mode;
	reg irq_on;
	reg irq_pend;
	
	
	
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:3] == 0)chr[ss_addr[2:0]] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 8)prg[0] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 9)prg[1] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 10)prg[2] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 11)irq_ctr[15:8] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 12)irq_ctr[7:0] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 13)irq_reload[15:8] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 14)irq_reload[7:0] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 15){irq_pend, irq_on, mirror_mode[1:0], irq_cfg[2:0]} <= cpu_dat;
	end
		else
	begin
	
		if(irq_on)
		begin
			irq_ctr <= irq_ctr - 1;
			if(irq_ctr_val == 1)begin
				irq_pend <= 1;
				irq_on <= 0;
			end
		end
	
		if(!cpu_rw & !cpu_ce)
		case(reg_addr)
			0:begin
				if(!cpu_addr[0])prg[0][3:0] <= cpu_dat[3:0]; else prg[0][7:4] <= cpu_dat[3:0];
			end
			1:begin
				if(!cpu_addr[0])prg[1][3:0] <= cpu_dat[3:0]; else prg[1][7:4] <= cpu_dat[3:0];
			end
			2:begin
				if(!cpu_addr[0])prg[2][3:0] <= cpu_dat[3:0]; else prg[2][7:4] <= cpu_dat[3:0];
			end
			4:begin
				if(!cpu_addr[0])chr[0][3:0] <= cpu_dat[3:0]; else chr[0][7:4] <= cpu_dat[3:0];
			end
			5:begin
				if(!cpu_addr[0])chr[1][3:0] <= cpu_dat[3:0]; else chr[1][7:4] <= cpu_dat[3:0];
			end
			6:begin
				if(!cpu_addr[0])chr[2][3:0] <= cpu_dat[3:0]; else chr[2][7:4] <= cpu_dat[3:0];
			end
			7:begin
				if(!cpu_addr[0])chr[3][3:0] <= cpu_dat[3:0]; else chr[3][7:4] <= cpu_dat[3:0];
			end
			8:begin
				if(!cpu_addr[0])chr[4][3:0] <= cpu_dat[3:0]; else chr[4][7:4] <= cpu_dat[3:0];
			end
			9:begin
				if(!cpu_addr[0])chr[5][3:0] <= cpu_dat[3:0]; else chr[5][7:4] <= cpu_dat[3:0];
			end
			10:begin
				if(!cpu_addr[0])chr[6][3:0] <= cpu_dat[3:0]; else chr[6][7:4] <= cpu_dat[3:0];
			end
			11:begin
				if(!cpu_addr[0])chr[7][3:0] <= cpu_dat[3:0]; else chr[7][7:4] <= cpu_dat[3:0];
			end
			12:begin
				if(!cpu_addr[0])irq_reload[3:0] <= cpu_dat[3:0]; else irq_reload[7:4] <= cpu_dat[3:0];
			end
			13:begin
				if(!cpu_addr[0])irq_reload[11:8] <= cpu_dat[3:0]; else irq_reload[15:12] <= cpu_dat[3:0];
			end
			14:begin
				irq_pend <= 0;
				if(!cpu_addr[0])irq_ctr <= irq_reload;
					else
				begin
					irq_on <= cpu_dat[0];
					irq_cfg[2:0] <= cpu_dat[3:1];
				end
			end
			15:begin
				if(!cpu_addr[0])mirror_mode[1:0] <= cpu_dat[1:0];
			end
			
		endcase
	
	end
	
	
endmodule
