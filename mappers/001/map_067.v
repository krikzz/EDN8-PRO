
`include "../base/defs.v"

module map_067 //Sunsoft-3 
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
	ss_addr[7:0] == 4 ? prg : 
	ss_addr[7:0] == 5 ? irq_ctr[15:8] : 
	ss_addr[7:0] == 6 ? irq_ctr[7:0] : 
	ss_addr[7:0] == 7 ? {irq_pend, irq_on, mirror_mode[1:0]} : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = 0;
	assign ram_we = 0;
	assign rom_ce = cpu_addr[15];
	assign chr_ce = ciram_ce;
	assign chr_we = 0;
	
	assign ciram_a10 = mirror_mode[1] ? mirror_mode[0] : !mirror_mode[0] ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[13:0] = cpu_addr[13:0];
	assign prg_addr[16:14] = cpu_addr[14] ? 3'b111 : prg[2:0];
	
	assign chr_addr[10:0] = ppu_addr[10:0];
	assign chr_addr[16:11] = chr_bank[5:0];
	
	wire [5:0]chr_bank = chr[ppu_addr[12:11]];
	
	assign irq = irq_pend;
	
	reg [5:0]chr[4];
	reg [2:0]prg;
	reg [15:0]irq_ctr;
	reg [1:0]mirror_mode;
	reg irq_on;
	reg irq_pend;
	
	
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:2] == 0)chr[ss_addr[1:0]] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 4)prg <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 5)irq_ctr[15:8] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 6)irq_ctr[7:0] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 7){irq_pend, irq_on, mirror_mode[1:0]} <= cpu_dat;
	end
		else
	begin
		
		if(irq_on)
		begin
			irq_ctr <= irq_ctr - 1;
			if(irq_ctr == 0){irq_on, irq_pend} <= 2'b01;
		end
		
		if(!cpu_ce & !cpu_rw)
		begin
			if(cpu_addr[14] == 0)chr[cpu_addr[13:12]] <= cpu_dat;
			if(cpu_addr[14:12] == 4)irq_ctr[15:0] <= {irq_ctr[7:0], cpu_dat[7:0]};
			if(cpu_addr[14:12] == 5){irq_pend, irq_on} <= {1'b0, cpu_dat[4]};
			if(cpu_addr[14:12] == 6)mirror_mode[1:0] <= cpu_dat[1:0];
			if(cpu_addr[14:12] == 7)prg[2:0] <= cpu_dat[2:0];
		end
		
	
	end
	
	
	
endmodule
