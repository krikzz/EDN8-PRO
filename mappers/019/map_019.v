
`include "../base/defs.v"

module map_019
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
	ss_addr[7:3] == 0		? chr[ss_addr[2:0]] :
	ss_addr[7:2] == 2		? mirror_reg[ss_addr[1:0]] :
	ss_addr[7:0] == 12	? prg[0] :
	ss_addr[7:0] == 13 	? prg[1] :
	ss_addr[7:0] == 14 	? prg[2] :
	ss_addr[7:0] == 15 	? we_protect :
	ss_addr[7:0] == 16 	? irq_ctr[14:8] :
	ss_addr[7:0] == 17 	? irq_ctr[7:0] :
	ss_addr[7:0] == 18 	? {irq_pend, irq_on, chr_lo_off, chr_hi_off, mirr_cnt, chr_hilo[1:0]} :
	ss_addr[7:0] == 127 	? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = {cpu_addr[15:13], 13'd0} == 16'h6000;
	assign ram_we = !cpu_rw & ram_ce;	
	assign rom_ce = cpu_addr[15];
	assign chr_ce = ciram_ce;
	assign chr_we = !ppu_we & !ppu_addr[13] & chr_ram_ce;// : 0;
	
	
	//A10-Vmir, A11-Hmir
	wire [7:0]mirror = mirror_reg[ppu_addr[11:10]];
	
	assign ciram_a10 = mirr_cnt ? mirror[0] : cfg_mir_v ? ppu_addr[10] : ppu_addr[11];
		
	
	assign ciram_ce = !mirr_cnt ? !ppu_addr[13] :
	ppu_addr[13:12] == 2'b11 ? 0 :
	mirror[7:5] == 3'b111 & ppu_addr[13:12] == 2'b10 ? 0 : 1;
	
	
	assign prg_addr[12:0] = cpu_addr[12:0];
	assign prg_addr[18:13] = cpu_ce ? 0 : cpu_addr[14:13] == 3 ? 6'b111111 : prg[cpu_addr[14:13]][5:0];

	
	assign chr_addr[9:0] = ppu_addr[9:0];
	assign chr_addr[17:10] = ppu_addr[13:12] == 2'b10 ? mirror[7:0] : chr_page[7:0];
	
	
	wire lo_ram_ce = ppu_addr[12] == 0 & !chr_lo_off;
	wire hi_ram_ce = ppu_addr[12] == 1 & !chr_hi_off;
	assign chr_ram_ce = chr_page[7:5] != 3'b111 ? 0 : lo_ram_ce | hi_ram_ce;
	
	assign map_cpu_oe = !cpu_rw ? 0 : reg_addr == 8'h48 | reg_addr == 8'h50 | reg_addr == 8'h58 ? 1 : 0;
	assign map_cpu_dout = reg_addr == 8'h50 ? irq_ctr[7:0] : reg_addr == 8'h58 ? {irq_on, irq_ctr[14:8]} : sound_dout;
	assign irq = irq_pend;
	
	//wire write_on = we_protect[7:4] != 4'b0100 ? 0 :  we_protect[cpu_addr[12:11]];
	//wire prg_ram_on = mirror_reg[0][0];
	wire [7:0]chr_page = chr[ppu_addr[12:10]];
	wire [7:0]reg_addr = {!cpu_ce, cpu_addr[14:11], 3'b000};
	

	reg [7:0]chr[8];
	reg [7:0]mirror_reg[4];
	reg [5:0]prg[3];
	reg [7:0]we_protect;
	reg [14:0]irq_ctr;
	
	reg irq_pend;
	reg irq_on;
	reg chr_lo_off;
	reg chr_hi_off;
	reg mirr_cnt;
	reg [1:0]chr_hilo;
	
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:3] == 0)chr[ss_addr[2:0]] <= cpu_dat;
		if(ss_we & ss_addr[7:2] == 2)mirror_reg[ss_addr[1:0]] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 12)prg[0] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 13)prg[1] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 14)prg[2] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 15)we_protect <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 16)irq_ctr[14:8] <= cpu_dat; 
		if(ss_we & ss_addr[7:0] == 17)irq_ctr[7:0] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 18){irq_pend, irq_on, chr_lo_off, chr_hi_off, mirr_cnt, chr_hilo[1:0]} <= cpu_dat;
	end
		else
	if(map_rst)
	begin
		prg[0] <= 0;
		prg[1] <= 1;
		prg[2] <= 2;
		irq_on <= 0;
		irq_pend <= 0;
		mirr_cnt <= 0;
	end
		else
	begin
		
		if(reg_addr == 8'h50 | reg_addr == 8'h58)irq_pend <= 0;

		if(irq_on)
		begin
			if(irq_ctr != 15'h7FFF)irq_ctr <= irq_ctr + 1;			
			if(irq_ctr == 15'h7FFE)irq_pend <= 1;
		end
		
		
		
		if(!cpu_rw)
		case(reg_addr)
			8'h48:begin
			end
			8'h50:begin
				irq_ctr[7:0] <= cpu_dat[7:0];
				//irq_pend <= 0;
			end
			8'h58:begin
				irq_ctr[14:8] <= cpu_dat[6:0];
				irq_on <= cpu_dat[7];
				//irq_pend <= 0;
			end
			8'h80:begin
				chr[0][7:0] <= cpu_dat[7:0];
			end
			8'h88:begin
				chr[1][7:0] <= cpu_dat[7:0];
			end
			8'h90:begin
				chr[2][7:0] <= cpu_dat[7:0];
			end
			8'h98:begin
				chr[3][7:0] <= cpu_dat[7:0];
			end
			8'hA0:begin
				chr[4][7:0] <= cpu_dat[7:0];
			end
			8'hA8:begin
				chr[5][7:0] <= cpu_dat[7:0];
			end
			8'hB0:begin
				chr[6][7:0] <= cpu_dat[7:0];
			end
			8'hB8:begin
				chr[7][7:0] <= cpu_dat[7:0];
			end
			8'hC0:begin
				mirror_reg[0][7:0] <= cpu_dat[7:0];
			end
			8'hC8:begin
				mirror_reg[1][7:0] <= cpu_dat[7:0];
				mirr_cnt <= 1;
			end
			8'hD0:begin
				mirror_reg[2][7:0] <= cpu_dat[7:0];
			end
			8'hD8:begin
				mirror_reg[3][7:0] <= cpu_dat[7:0];
			end
			8'hE0:begin
				prg[0][5:0] <= cpu_dat[5:0];
			end
			8'hE8:begin
				prg[1][5:0] <= cpu_dat[5:0];
				chr_hilo[1:0] <= cpu_dat[7:6];
				chr_lo_off <= cpu_dat[6];
				chr_hi_off <= cpu_dat[7];
			end
			8'hF0:begin
				prg[2][5:0] <= cpu_dat[5:0];
			end
			8'hF8:begin
				we_protect[7:0] <= cpu_dat[7:0];
			end
			
		endcase
		
	end
	
	
	wire [7:0]sound_dout;
	wire [7:0]snd_vol;
	
	snd_n163 snd_inst(
		.bus(bus),
		.vol(snd_vol), 
		.dout(sound_dout)
	);
	
	dac_ds dac_inst(clk, m2, {snd_vol[7:0], 3'b0}, master_vol, pwm);

	
endmodule


module dac_ds
(clk, m2, vol, master_vol, snd);
	
	parameter DEPTH = 11;
	
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

	
	always @(negedge m2)
	begin
		vol_st[DEPTH-1:0] <= (vol[DEPTH-1:0] * master_vol) / 128;
	end
	
	
	always @(negedge clk) 
	begin
		sigma_st[DEPTH+1:0] <= sigma[DEPTH+1:0];
		snd <= sigma_st[DEPTH+1];
	end
	
endmodule  
