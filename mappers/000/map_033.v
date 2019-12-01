
`include "../base/defs.v"

//33,48
module map_033
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
	ss_addr[7:0] == 0 ? chr[0] : 
	ss_addr[7:0] == 1 ? chr[1] :
	ss_addr[7:0] == 2 ? chr[2] :
	ss_addr[7:0] == 3 ? chr[3] :
	ss_addr[7:0] == 4 ? chr[4] :
	ss_addr[7:0] == 5 ? chr[5] :
	ss_addr[7:0] == 6 ? prg[0] :
	ss_addr[7:0] == 7 ? prg[1] :
	ss_addr[7:0] == 8 ? ctr_reload :
	ss_addr[7:0] == 9 ? irq_ctr :
	ss_addr[7:0] == 10 ? {map_48_mode, irq_pend, irq_reload_req, irq_on, mirror_mode} :
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
   //*************************************************************
	assign ram_ce = 0;
   assign ram_we = 0;
   assign chr_we = 0;
   assign rom_ce = cpu_addr[15];
   assign chr_ce = ciram_ce;
    
   assign ciram_a10 = !mirror_mode ? ppu_addr[10] : ppu_addr[11];
   assign ciram_ce = !ppu_addr[13];
    
   assign prg_addr[12:0] = cpu_addr[12:0];
	assign prg_addr[18:13] = cpu_addr[14] ? {5'b11111, cpu_addr[13]} : !cpu_addr[13] ? prg[0][5:0] : prg[1][5:0];
	
   assign chr_addr[9:0] = ppu_addr[9:0];
	assign chr_addr[18:10] = !ppu_addr[12] ? {chr_reg[7:0], ppu_addr[10]} : {1'b0, chr_reg[7:0]};
	 //assign chr_addr[20:]
	 
	

	wire [7:0]chr_reg = 
	ppu_addr[12:11] == 0 ? chr[0][7:0] : 
	ppu_addr[12:11] == 1 ? chr[1][7:0] : 
	ppu_addr[12:10] == 4 ? chr[2][7:0] : 
	ppu_addr[12:10] == 5 ? chr[3][7:0] : 
	ppu_addr[12:10] == 6 ? chr[4][7:0] : chr[5][7:0];
	
	 reg [5:0]prg[2];
	reg [7:0]chr[6];
	
	reg [7:0]ctr_reload;
	reg [7:0]irq_ctr;
	reg mirror_mode;
	reg irq_on;
	reg irq_reload_req;
	reg irq_pend;
	reg map_48_mode;
	
	
	reg [10:0]a12_filter;
	wire mmc3b_mode = 0;
	wire next_ctr_zero = (irq_ctr == 1 & !irq_reload_req) | (irq_reload_req & ctr_reload == 0) | (irq_ctr == 0 & ctr_reload == 0 & mmc3b_mode);
	assign irq = irq_pend;// may be irq should be delayed on 7 cycles
	
	 
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 0)chr[0] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 1)chr[1] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 2)chr[2] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 3)chr[3] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 4)chr[4] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 5)chr[5] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 6)prg[0] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 7)prg[1] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 8)ctr_reload <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 9)irq_ctr <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 10){map_48_mode, irq_pend, irq_reload_req, irq_on, mirror_mode} <= cpu_dat;
	end
		else
	begin
	
		if(map_rst)map_48_mode <= 0;
			else
		if(map_idx == 48)map_48_mode <= 1;
			else
		if(cpu_addr[14] == 1 & !cpu_ce & !cpu_rw)map_48_mode <= 1;
	 
		a12_filter[10:0] <= {a12_filter[9:0], ppu_addr[12]};
	 
		if(a12_filter[7:4] == 4'b0001)
		begin
			if(irq_on & next_ctr_zero)irq_pend <= 1;
			irq_ctr <= irq_ctr == 0 | irq_reload_req ? ctr_reload : irq_ctr - 1;
			if(irq_reload_req)irq_reload_req <= 0;
		end
		
		if(cpu_addr[14:13] == 2'b00 & !cpu_ce & !cpu_rw)
		case(cpu_addr[1:0])
			0:begin
				prg[0][5:0] <= cpu_dat[5:0];
				if(!map_48_mode)mirror_mode <= cpu_dat[6];
			end
			1:prg[1][5:0] <= cpu_dat[5:0];
			2:chr[0][7:0] <= cpu_dat[7:0];
			3:chr[1][7:0] <= cpu_dat[7:0];
		endcase
		
		if(cpu_addr[14:13] == 2'b01 & !cpu_ce & !cpu_rw)
		case(cpu_addr[1:0])
			0:chr[2][7:0] <= cpu_dat[7:0];
			1:chr[3][7:0] <= cpu_dat[7:0];
			2:chr[4][7:0] <= cpu_dat[7:0];
			3:chr[5][7:0] <= cpu_dat[7:0];
		endcase
		
		
		if(cpu_addr[14:13] == 2'b10 & !cpu_ce & !cpu_rw)
		case(cpu_addr[1:0])
			0:begin
				ctr_reload[7:0] <= cpu_dat[7:0] ^ 8'hff;
			end
			1:begin
				irq_reload_req  <= 1;
			end
			2:begin
				irq_on <= 1;
			end
			3:begin
				irq_on <= 0;
				irq_pend <= 0;
			end
		endcase
		
		if(cpu_addr[14:13] == 2'b11 & !cpu_ce & !cpu_rw)
		begin
			if(cpu_addr[1:0] == 0)mirror_mode <= cpu_dat[6];
		end
		
	end
    
endmodule
