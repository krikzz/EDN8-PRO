
`include "../base/defs.v"

module map_064
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
	ss_addr[7:0] == 11 ? bank_sel :
	ss_addr[7:0] == 12 ? ctr_reload :
	ss_addr[7:0] == 13 ? irq_ctr :
	ss_addr[7:0] == 14 ? ctr_scal :
	ss_addr[7:0] == 15 ? {irq_reload_req, irq_on, mirror_mode, irq_mode, irq_pend} :
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************

	assign ram_we = 0;
	assign chr_we = 0;
	assign ram_ce = 0;
	assign rom_ce = !cpu_ce;
	assign chr_ce = ciram_ce;
	 
	assign ciram_a10 = !mirror_mode ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	 
	assign prg_addr[12:0] = cpu_addr[12:0];
	assign prg_addr[17:13] = prg_bank[4:0];
	
	assign chr_addr[9:0] = ppu_addr[9:0];
	assign chr_addr[17:10] = chr_bank[7:0];

	wire a12sw = !a12_mode ? ppu_addr[12] : !ppu_addr[12];
	wire chr_mode = bank_sel[5];
	wire prg_mode = bank_sel[6];
	wire a12_mode = bank_sel[7];
	
	

	wire a14sw = !prg_mode ? cpu_addr[14] : !cpu_addr[14];
	
	wire [4:0]prg_bank = 
	cpu_ce ? 0 :
	cpu_addr[14:13] == 2'b11 ? 5'b11111 : 
	a14sw ? prg[2][4:0] : 
	!cpu_addr[13] ? prg[0][4:0] : prg[1][4:0];
	
	wire [2:0]chr_sw = {a12sw, ppu_addr[11:10]};
	
	
	wire [7:0]chr_bank = !chr_mode ? chr2k : chr1k;
	
	
	wire [7:0]chr2k = 
	//!a12sw ? (chr_addr[11] == 0 ? {chr0[7:1], ppu_addr[10]} : {chr1[7:1], ppu_addr[10]}) :
	chr_sw[2:1] == 0 ? {chr[0][7:1], ppu_addr[10]} :
	chr_sw[2:1] == 1 ? {chr[1][7:1], ppu_addr[10]} :
	chr_sw == 4 ? chr[2] :
	chr_sw == 5 ? chr[3] :
	chr_sw == 6 ? chr[4] :
	chr[5];
	
	wire [7:0]chr1k = 
	chr_sw == 0 ? chr[0] :
	chr_sw == 1 ? chr[6] :
	chr_sw == 2 ? chr[1] :
	chr_sw == 3 ? chr[7] :
	chr_sw == 4 ? chr[2] :
	chr_sw == 5 ? chr[3] :
	chr_sw == 6 ? chr[4] :
	chr[5];
	
	
	wire [2:0]reg_addr = {cpu_addr[14:13], cpu_addr[0]};
	
	assign irq = irq_pend;
	
	reg [7:0]chr[8];
	reg [4:0]prg[3];
	reg [7:0]bank_sel;

	reg [7:0]ctr_reload;
	reg [7:0]irq_ctr;
	reg [1:0]ctr_scal;
	
	reg irq_pend;
	reg irq_mode;
	reg mirror_mode;
	reg irq_on;
	reg irq_reload_req;
	
	reg [7:0]a12_filter;
	
	wire irq_tick = irq_mode ? ctr_scal == 0 : a12_filter[3:0] == 4'b0001;
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:3] == 0)chr[ss_addr[2:0]] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 8)prg[0] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 9)prg[1] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 10)prg[2] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 11)bank_sel <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 12)ctr_reload <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 13)irq_ctr <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 14)ctr_scal <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 15){irq_reload_req, irq_on, mirror_mode, irq_mode, irq_pend} <= cpu_dat;
	end
		else
	begin
	
		ctr_scal <= ctr_scal + 1;
		a12_filter[7:0] <= {a12_filter[6:0], ppu_addr[12]};
		

		if(irq_tick)
		begin
			if(irq_reload_req)
			begin
				irq_reload_req <= 0;
				irq_ctr <= ctr_reload + 1;
			end
				else
			if(irq_ctr == 0)
			begin
				irq_ctr <= ctr_reload;
			end
				else
			begin
				irq_ctr <= irq_ctr - 1;
				if(irq_on & irq_ctr == 1)irq_pend <= 1;
			end

		end
	
		
		if(!cpu_ce & !cpu_rw)
		begin
		
			if(reg_addr[2:0] == 1)
			begin
				case(bank_sel[3:0])
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
						chr[4][7:0] <= cpu_dat[7:0];
					end
					5:begin
						chr[5][7:0] <= cpu_dat[7:0];
					end
					6:begin
						prg[0][4:0] <= cpu_dat[4:0];
					end
					7:begin
						prg[1][4:0] <= cpu_dat[4:0];
					end
					8:begin
						chr[6][7:0] <= cpu_dat[7:0];
					end
					9:begin
						chr[7][7:0] <= cpu_dat[7:0];
					end
					15:begin
						prg[2][4:0] <= cpu_dat[4:0];
					end
				endcase
			end
		
			case(reg_addr[2:0])
			
				0:begin//0x8000
					bank_sel[7:0] <= cpu_dat[7:0];
				end
				
				1:begin//0x8001
				end
				
				2:begin//0xa000
					mirror_mode <= cpu_dat[0];
				end
				
				4:begin//0xc000
					ctr_reload[7:0] <= cpu_dat[7:0];
				end
				
				5:begin//0xc001
					irq_mode <= cpu_dat[0];
					irq_reload_req <= 1;
				end
				
				6:begin//0xe000
					irq_pend <= 0;
					irq_on <= 0;
				end
				
				7:begin//0xe001
					irq_on <= 1;
				end
			
			endcase
		
		end
		
	end
	

endmodule
