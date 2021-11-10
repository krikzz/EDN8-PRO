
`include "../base/defs.v"

module map_254
(map_out, bus, sys_cfg, ss_ctrl);

	`include "../base/bus_in.v"
	`include "../base/map_out.v"
	`include "../base/sys_cfg_in.v"
	`include "../base/ss_ctrl_in.v"

	output [`BW_MAP_OUT-1:0]map_out;
	input [`BW_SYS_CFG-1:0]sys_cfg;
	
	
	assign srm_mask_off = 1;
	assign chr_mask_off = 1;
	assign prg_mask_off = 1;
	assign sync_m2 = 1;
	assign mir_4sc = 0;//enable support for 4-screen mirroring. for activation should be ensabled in sys_cfg also
	assign srm_addr[15:0] = disk_addr[15:0];
	assign srm_addr[17:16] = disk_addr[17:16] & fds_msk[1:0];
	assign prg_oe = cpu_rw;
	assign chr_oe = !ppu_oe;
	wire cfg_fds_asw = map_sub[0];//fds disk auto swap
	wire cfg_fds_ebi = map_sub[1];
	//*************************************************************  save state setup
`ifndef SS_OFF
	assign ss_rdat[7:0] = 
	ss_addr[7:0] == 0 ? disk_addr[15:8] :
	ss_addr[7:0] == 1 ? disk_addr[7:0] :
	ss_addr[7:0] == 2 ? disk_side[1:0] :
	ss_addr[7:0] == 3 ? reg25[7:0] :
	ss_addr[7:0] == 4 ? reg30[7:0] :
	ss_addr[7:0] == 5 ? irq_reload[15:8] :
	ss_addr[7:0] == 6 ? irq_reload[7:0] :
	ss_addr[7:0] == 7 ? irq_ctr[15:8] :
	ss_addr[7:0] == 8 ? irq_ctr[7:0] :
	ss_addr[7:0] == 9 ? delay[7:0] :
	ss_addr[7:0] == 10 ? {4'h0, irq_re, irq_on, disk_end, inc_disk_addr} :
	ss_addr[7:0] == 127 ? map_idx : ss_rdat_snd[7:0];
`endif
	//*************************************************************
	assign ram_we =  disk_we;
	assign ram_ce =  disk_ce;
	assign rom_we = (wram_ce & !cpu_rw);
	assign rom_ce = wram_ce | (bios_ce & cfg_fds_ebi);
	assign chr_ce = ciram_ce;
	assign chr_we = !ppu_we & ciram_ce;
	assign chr_xram = chr_ce;
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = !reg25[3] ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[22:0] = 
	(bios_ce & cfg_fds_ebi) ? bios_addr[22:0] : wram_addr[22:0];
	//wram_ce ? wram_addr[22:0] : disk_addr[18:0];

	
	assign chr_addr[12:0] = ppu_addr[12:0];
	
	
	assign map_cpu_oe = !m2 ? 0 : (regs_oe & !disk_ce) | snd_oe | (bios_ce & cpu_rw & !cfg_fds_ebi);
	assign map_cpu_dout[7:0] = 
	cpu_addr[15:0] == 16'h4030 ? reg30[7:0] :
	cpu_addr[15:0] == 16'h4032 ? reg32[7:0] :
	cpu_addr[15:0] == 16'h4033 ? 8'hff :
	snd_oe ? snd_dout[7:0] : 
	bios_do[7:0];
	
	assign irq = reg30[0] | (reg30[1] & reg25[7]);
	
	
	wire regs_we = {cpu_addr[15:4], 4'd0} == 16'h4020 & cpu_rw == 0;
	wire regs_oe = {cpu_addr[15:4], 4'd0} == 16'h4030 & cpu_rw == 1;
	
	wire disk_we = disk_wr_ce & cpu_rw == 0 & disk_we_on;
	wire disk_oe = disk_rd_ce & cpu_rw == 1;
	wire disk_wr_ce = cpu_addr[15:0] == 16'h4024;
	wire disk_rd_ce = cpu_addr[15:0] == 16'h4031;
	wire disk_ce = disk_wr_ce | disk_rd_ce;
	
	wire bios_ce = {cpu_addr[15:13], 13'd0} == 16'hE000;
	wire wram_ce = 
	{cpu_addr[15:13], 13'd0} == 16'h6000 |
	{cpu_addr[15:13], 13'd0} == 16'h8000 | 
	{cpu_addr[15:13], 13'd0} == 16'hA000 |
	{cpu_addr[15:13], 13'd0} == 16'hC000;
	
	
	//{6'h3F, 4'h3, cpu_addr[12:0]};//bios rom locatd in OS binary. 0x6000. BANK3
	wire [22:0]bios_addr = {8'h01, 2'h0, cpu_addr[12:0]};
	wire [22:0]wram_addr = {8'h00, cpu_addr[14:0]};//work ram located at 0x000000
	
	wire disk_txf = reg25[0] & !reg25[1];
	wire disk_back = reg25[0] & reg25[1];
	wire read_mode = reg25[2];
	wire transfer_irq = delay == 0 & disk_txf & !disk_end & reg25[7];
	wire disk_we_on = !read_mode & disk_txf & !disk_end;
	
	wire disk_eject;
	wire [7:0]reg32;
	assign reg32[0] = disk_eject;
	assign reg32[1] = reg25[1] | disk_end;
	assign reg32[2] = disk_eject;
	assign reg32[7:3] = 5'b11111;
	
	reg [7:0]reg25;
	reg [7:0]reg30;
	reg [15:0]irq_reload;
	reg [15:0]irq_ctr;
	reg [18:0]disk_addr;
	reg [7:0]delay;
	reg irq_re, irq_on;
	reg disk_end;
	reg inc_disk_addr;
	
	assign map_led = disk_txf | disk_eject;
	
	
	always @(negedge m2)
`ifndef SS_OFF
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 0)disk_addr[15:8] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 1)disk_addr[7:0] <= cpu_dat[7:0];
		//if(ss_we & ss_addr[7:0] == 2)disk_side[1:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 3)reg25[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 4)reg30[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 5)irq_reload[15:8] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 6)irq_reload[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 7)irq_ctr[15:8] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 8)irq_ctr[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 9)delay[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 10){irq_re, irq_on, disk_end, inc_disk_addr} <= cpu_dat[3:0];
	end
		else
`endif
	begin
	
	
		disk_addr[17:16] <= disk_side[1:0];
	
		if(disk_addr[15:0] == 65500)disk_end <= 1;
			else
		if(disk_addr[15:0] == 0)disk_end <= 0;
		
		
		if(inc_disk_addr)inc_disk_addr <= 0;
		if(inc_disk_addr & !disk_back)disk_addr[15:0] <= disk_addr[15:0] + 1;
		
		if(disk_back)
		begin
			if(disk_addr[15:0] != 0)disk_addr[15:0] <= 0;
		end
			else
		if(transfer_irq)
		begin
			if(reg30[1] == 0)reg30[1] <= 1;
		end
		
		if(irq_on & irq_ctr == 1)
		begin
			reg30[0] <= 1;
		end
		
		if(irq_on)irq_ctr <= irq_ctr - 1;
		
		//delay <= !disk_transfer | delay == 0 | disk_end | !reg25[7] ? 140 : delay - 1;
		if(!disk_txf | delay == 0 | disk_end | !reg25[7])delay <= 140;
			//else
		//if(cpu_addr[15:0] == 16'h402C & !cpu_rw)delay <= 0;
			else
		delay <= delay - 1;
		
		
		if(regs_oe)//0x403x
		case(cpu_addr[3:0])
			0:reg30[1:0] <= 2'b00;
			1:begin
				if(disk_txf & !disk_end)inc_disk_addr <= 1;
				reg30[1] <= 0;
			end
		endcase
		
		
		if(regs_we)//0x402x
		case(cpu_addr[3:0])
			0:irq_reload[7:0]  <= cpu_dat[7:0];
			1:irq_reload[15:8] <= cpu_dat[7:0];
			2:begin
				irq_re <= cpu_dat[0];
				irq_on <= cpu_dat[1];
				irq_ctr <= irq_reload;
			end
			4:reg30[1] <= 0;
			5:reg25[7:0] <= cpu_dat[7:0];
		endcase
		

		
	end


	wire eject_req = (!fds_sw & !ctrl_ss_btn) | auto_swp_req | sw_swap_req;
	wire [1:0]disk_side;
	disk_swap swap_inst(bus, eject_req, disk_eject, disk_side, ss_ctrl);
	
	wire auto_swp_off = !cfg_fds_asw | disk_eject; 
	wire auto_swp_req;
	swap_auto swp_inst_au(bus, auto_swp_off, auto_swp_req);
	
	wire sw_swap_req;
	swap_sw swp_inst_sw(bus, sw_swap_req, ss_act);

	
	wire [7:0]ss_rdat_snd;
	wire [11:0]snd_vol;
	wire [7:0]snd_dout;
	wire snd_oe;
`ifndef SND_OFF	
	fds_snd snd_inst(bus, snd_vol, snd_oe, snd_dout, ss_ctrl, ss_rdat_snd);
`endif	

	//wire [7:0]master_vol = 8;
	dac_ds dac(clk, m2, snd_vol, master_vol, pwm);
	
	
	wire [7:0]bios_do;
	rom bios(cpu_addr[12:0], bios_do, clk);

endmodule


module dac_ds
(clk, m2, vol, master_vol, snd);
	
	parameter DEPTH = 12;
	
	input clk, m2;
	input [DEPTH-1:0]	vol;
	input [7:0]master_vol;
	output reg snd;
	

	
	wire [DEPTH+1:0]delta;
	wire [DEPTH+1:0]sigma;
	

	reg [DEPTH+1:0] sigma_st;	
	reg [DEPTH-1:0] vol_st;

	assign	delta[DEPTH+1:0] = {2'b0, vol_st[DEPTH-1:0]} + {sigma_st[DEPTH+1], sigma_st[DEPTH+1], {(DEPTH){1'b0}}};
	assign	sigma[DEPTH+1:0] = delta[DEPTH+1:0] + sigma_st[DEPTH+1:0];

	reg mclk;
	always @(negedge m2)mclk <= !mclk;
	
	always @(negedge mclk)
	begin
		vol_st[DEPTH-1:0] <= (vol[DEPTH-1:0] * master_vol) / 128;
	end
	
	
	always @(posedge clk) 
	begin
		sigma_st[DEPTH+1:0] <= sigma[DEPTH+1:0];
		//vol_st[DEPTH-1:0] <= master_vol == 0 ? 0 : ({vol[DEPTH-1:0], 4'd0} >> (7-master_vol));
		snd <= sigma_st[DEPTH+1];
	end
	
endmodule 

module swap_sw
(bus, swp_req, ss_act);

	`include "../base/bus_in.v"
	output reg swp_req;
	input ss_act;
	
	always @(negedge m2)
	begin
		
		if(cpu_addr[15:0] == 16'h402D & cpu_rw == 0 & ss_act == 1)swp_req <= 1;
		if(cpu_addr[15:0] == 16'h4032 & cpu_rw == 1 & ss_act == 0)swp_req <= 0;
		
	end

endmodule

module swap_auto
(bus, swp_off, swp_req);

	`include "../base/bus_in.v"
	
	input swp_off;
	output swp_req;
	
	assign swp_req = swp_req_ctr[8];
	
	reg [8:0]swp_req_ctr;
	reg [21:0]swp_lock_ctr;
	
	always @(negedge m2)
	if(swp_off)
	begin
		swp_req_ctr <= 0;
		swp_lock_ctr <= 0;
	end
		else
	if(swp_req)
	begin
		swp_req_ctr <= 0;
		swp_lock_ctr <= 1;
	end
		else
	if(swp_lock_ctr != 0)swp_lock_ctr <= swp_lock_ctr + 1;
		else
	begin
		if(cpu_addr[15:0] == 16'h4024 & cpu_rw == 0)swp_req_ctr <= 0;
		if(cpu_addr[15:0] == 16'h4031 & cpu_rw == 1)swp_req_ctr <= 0;
		if(cpu_addr[15:0] == 16'h4032 & cpu_rw == 1)swp_req_ctr <= swp_req_ctr + 1;
	end
	
endmodule

module disk_swap
(bus, eject_req, disk_eject, disk_side, ss_ctrl);
	
	`include "../base/bus_in.v"
	`include "../base/ss_ctrl_in.v"
	
	input eject_req;
	output disk_eject;
	output reg[1:0]disk_side;

	
	
	assign disk_eject = eject_req_st | eject_ctr != 0;
	
	reg [20:0]eject_ctr;
	reg eject_req_st;
	reg [1:0]eject_st;

	
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 2)disk_side[1:0] <= cpu_dat[1:0];
		if(ss_we)eject_ctr <= 0;
		if(ss_we)eject_st <= 0;
	end
		else
	begin
	
		//if(inc_mode == 0 & cpu_addr[15:0] == 16'h402E & !cpu_rw)disk_side[0] <= cpu_dat[0];
		
		//if(inc_mode == 0 & eject_st[1:0] == 2'b01)disk_side[1] <= !disk_side[1];
		//if(inc_mode == 1 & eject_st[1:0] == 2'b01)disk_side[1:0] <= disk_side[1:0] + 1;
		
		//if(cpu_addr[15:0] == 16'h402F & !cpu_rw & inc_mode == 0)disk_side[1] <= cpu_dat[0];
		//if(eject_st[1:0] == 2'b01 & inc_mode == 1)disk_side[1] <= !disk_side[1];
		//if(cpu_addr[15:0] == 16'h402F & !cpu_rw & inc_mode == 0)disk_side[1] <= cpu_dat[0];
		
	
		if(eject_st[1:0] == 2'b01)disk_side[1:0] <= disk_side[1:0] + 1;
	
		eject_req_st <= eject_req;
		
		if(eject_req_st)eject_ctr <= 1;
			else
		if(eject_ctr != 0)eject_ctr <= eject_ctr + 1;
		
		eject_st[1:0] <= {eject_st[0], disk_eject};
		
		//if(eject_st[1:0] == 2'b01)disk_side <= disk_side + 1;
		
	end

endmodule



module rom 
(addr, dout, clk);

	input [12:0]addr;
	output reg[7:0]dout;
	input clk;
   
	reg [7:0]rom[8192];
	
	initial
	begin
		$readmemh("disksys.rom.txt", rom);
	end
	
	always @(negedge clk)
	begin
		dout[7:0] <= rom[addr];
	end

endmodule

