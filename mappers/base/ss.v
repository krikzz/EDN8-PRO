
`include "../base/defs.v"


module sst_controller
(bus, pi_bus, sys_cfg, ss_ctrl, ss_di, ss_do, ss_oe_cpu, ss_oe_pi, ss_act);

	`include "pi_bus.v"
	`include "bus_in.v"
	`include "../base/sys_cfg_in.v"
	output [`BW_SS_CTRL-1:0]ss_ctrl;
	input [`BW_SYS_CFG-1:0]sys_cfg;
	
	input [7:0]ss_di;
	output [7:0]ss_do;
	output ss_oe_cpu, ss_oe_pi, ss_act;
	
	//map regs	128
	//apu regs 	32
	//ppu pal	32
	//ppu regs	4
	//OAM 		256
	//map mem	1.5K
	parameter REG_SST_ADDR		= 16'h40F2;
	parameter REG_SST_DATA		= 16'h40F3;
	
	
	assign ss_ctrl[`BW_SS_CTRL-1:0] = {ss_act, ss_we, ss_addr[10:0]};
	assign ss_do[7:0] =  ss_snif_ce ? snif_do[7:0] : ss_di[7:0];
	
	assign ss_oe_cpu = sst_data_ce & cpu_rw == 1;
	assign ss_oe_pi = pi_ce_ss;
	
	wire sst_addr_ce = cpu_addr[15:0] == REG_SST_ADDR;
	wire sst_data_ce = cpu_addr[15:0] == REG_SST_DATA;
	
	
	reg [10:0]sst_addr_cpu;
	
	always @(negedge m2)
	begin
		if(sst_addr_ce & cpu_rw == 0)sst_addr_cpu[10:0] <= {sst_addr_cpu[2:0], cpu_dat[7:0]};
		if(sst_data_ce)sst_addr_cpu <= sst_addr_cpu + 1;
	end
	
	wire ss_snif_ce_ppu = ss_addr[10:7] == 1;
	wire ss_snif_ce_oam = ss_addr[10:8] == 1;
	wire ss_snif_ce = ss_snif_ce_ppu | ss_snif_ce_oam;
	
	wire [10:0]ss_addr = pi_ce_ss ? pi_addr[10:0] : sst_addr_cpu[10:0];
	wire ss_we;
	wire [7:0]snif_do;
	wire [7:0]ss_src;
	wire sniff_off;
	
	
	sniffer snif_inst(
	
		.bus(bus),
		.rd_addr(ss_addr[8:0]),
		.sniff_off(sniff_off),
		.dout(snif_do),
		.ss_src(ss_src)
	);
	
	ss_sw ss_sw_inst(
	
		.bus(bus),
		.sys_cfg(sys_cfg),
		.sst_ce(sst_data_ce),
		.ss_act(ss_act),
		.ss_we(ss_we),
		.ss_src(ss_src),
		.sniff_off(sniff_off)
	);


endmodule



module ss_sw
(bus, sys_cfg, sst_ce, ss_act, ss_we, ss_src, sniff_off);

	`include "sys_cfg_in.v"
	`include "bus_in.v"
	
	input [`BW_SYS_CFG-1:0]sys_cfg;
	input sst_ce;
	output ss_act, ss_we;
	output reg [7:0]ss_src;
	output sniff_off;
	
	assign ss_act = ((game_out & m2) | ss_latch) & !(game_ret & m2);
	assign ss_we = sst_ce & ss_act & !cpu_rw;
	assign sniff_off = ss_act & !ss_ack;
	
	wire game_out = (nmi & ss_ack == 0 & ss_req);
	wire game_ret = (nmi & ss_ack == 1);
	wire ss_req = ss_req_st[1:0] == 2'b10;
	
	wire nmi = cpu_rw & cpu_addr[15:0] == 16'hfffa;
	wire joy_hit = joy_hit_save | joy_hit_load | joy_hit_menu;
	wire joy_hit_save = joy1 == ss_key_save & ss_key_save != 8'h00;
	wire joy_hit_load = joy1 == ss_key_load & ss_key_load != 8'h00;
	wire joy_hit_menu = joy1 == ss_key_menu & ss_key_menu != 8'h00;
	wire btn_hit = !fds_sw & ctrl_ss_btn;
	
	
	reg ss_latch;
	reg ss_ack;
	reg [1:0]ss_req_st;
	reg nmi_on;
	
	
	always @(negedge m2)
	begin
				
		if(ss_req_st[1:0] == 2'b01)ss_src[7:0] <= joy1[7:0];
	
		if(ss_latch)ss_req_st[1:0] <= 2'b00;
			else
		if(!ss_req)ss_req_st[1:0] <= {ss_req_st[0], (ctrl_ss_on & (joy_hit | btn_hit) & !map_rst)};
	
		if(cpu_addr[15:0] == 16'h2000 & !cpu_rw)nmi_on <= cpu_dat[7];
		
	end

	
	always @(negedge m2)
	if(map_rst)
	begin
		ss_latch <= 0;
		ss_ack <= 0;
	end
		else
	begin
		
		if(game_out)ss_latch <= 1;
		if(game_ret)ss_latch <= 0;
		
		
		if(game_ret | !ss_act)ss_ack <= 0;
			else
		if(sst_ce & !cpu_rw)ss_ack <= 1;
		
	end
	
	
	wire [7:0]joy1;
	joy_rdr joy_inst1(bus, 0, joy1);

endmodule

module joy_rdr
(bus, port, dout);

	`include "bus_in.v"
	
	input port;
	output reg[7:0]dout;
	
	wire [1:0]joy_ce;
	wire joy_cex = {cpu_addr[15:1], 1'b0} ==  16'h4016;
	assign joy_ce[0] = joy_cex & cpu_addr[0] == 0;
	assign joy_ce[1] = joy_cex & cpu_addr[0] == 1;
	
	reg load;
	reg [8:0]buff;
	
	always @(negedge m2, posedge sys_rst)
	if(sys_rst)
	begin
		dout[7:0] <= 8'h00;
	end
		else
	begin
	
		if(joy_ce[0] & cpu_rw == 0)load <= cpu_dat[0];
		
		if(load)buff <= 1;
			else
		if(buff[8])dout[7:0] <= buff[7:0];
			else
		if(joy_ce[port] & cpu_rw == 1)buff[8:0] <= {buff[7:0], cpu_dat[0] | cpu_dat[1]};
	
	end
	
endmodule

module sniffer
(bus, rd_addr, sniff_off, dout, ss_src);

	`include "bus_in.v"
	
	input [8:0]rd_addr;
	input sniff_off;
	output [7:0]dout;
	input [7:0]ss_src;
	
	parameter PPU_CTRL = 3'd0;
	parameter PPU_MASK = 3'd1;
	parameter PPU_STAT = 3'd2;
	parameter PPU_OADR = 3'd3;
	parameter PPU_ODAT = 3'd4;
	parameter PPU_SCRL = 3'd5;
	parameter PPU_ADDR = 3'd6;
	parameter PPU_DATA = 3'd7;
	
	
	assign dout[7:0] = rd_addr[8] ? oam_do[7:0] : rd_addr[6] == 0 ? mem_do[7:0] : regs_do[7:0];

	wire ppu_reg_ce = {cpu_addr[15:12], 12'd0} == 16'h2000;
	wire apu_reg_ce = {cpu_addr[15:5], 5'd0} == 16'h4000;
	
	wire ppu_pal_ce = {ppu_rw_addr[13:8], 8'd0} == 14'h3f00 & ppu_reg_ce & cpu_addr[2:0] == PPU_DATA;
	wire ppu_dat_ce = ppu_reg_ce & cpu_addr[2:0] == PPU_DATA;
	
	wire ppu_reg_oe = ppu_reg_ce & cpu_rw;
	wire ppu_reg_we = ppu_reg_ce & !cpu_rw & !sniff_off;
	
	wire apu_reg_we = apu_reg_ce & !cpu_rw & !sniff_off;
	wire ppu_pal_we = ppu_pal_ce & !cpu_rw & !sniff_off;
	
	wire oam_we = ppu_reg_we & cpu_addr[2:0] == PPU_ODAT;
	
	wire [7:0]regs_do = 
	rd_addr[5:0] == 0 ? ppu_ctrl[7:0] : 
	rd_addr[5:0] == 1 ? ppu_mask[7:0] : 
	rd_addr[5:0] == 2 ? ppu_scrl[15:8] : 
	rd_addr[5:0] == 3 ? ppu_scrl[7:0] :
	rd_addr[5:0] == 15 ? 8'h53 : 
	rd_addr[5:0] == 63 ? ss_src[7:0] : 
	8'hff;
	
	
	//actually ppu use same register for address and scroll, but it should be accurate enough for save state
	reg [15:0]ppu_scrl;
	reg [13:0]ppu_rw_addr;
	reg [7:0]ppu_ctrl;
	reg [7:0]ppu_mask;
	reg addr_latch;
	reg [7:0]oam_addr;
	
	
	always @(negedge m2)
	begin
			
		if(ppu_reg_oe & cpu_addr[2:0] == PPU_STAT)addr_latch <= 0;
		
		if(ppu_reg_we & cpu_addr[2:0] == PPU_CTRL)ppu_ctrl[7:0] <= cpu_dat[7:0];
		if(ppu_reg_we & cpu_addr[2:0] == PPU_MASK)ppu_mask[7:0] <= cpu_dat[7:0];
		
		if(ppu_reg_we & cpu_addr[2:0] == PPU_SCRL)
		begin
			if(addr_latch == 0)ppu_scrl[15:8] <= cpu_dat[7:0];
			if(addr_latch == 1)ppu_scrl[7:0] <= cpu_dat[7:0];
			addr_latch <= !addr_latch;
		end
		
		if(ppu_reg_we & cpu_addr[2:0] == PPU_ADDR)
		begin
			if(addr_latch == 0)ppu_rw_addr[13:8] <= cpu_dat[5:0];
			if(addr_latch == 1)ppu_rw_addr[7:0] <= cpu_dat[7:0];
			addr_latch <= !addr_latch;
		end
		
		if(ppu_dat_ce & ppu_ctrl[2] == 0)ppu_rw_addr <= ppu_rw_addr + 1;
		if(ppu_dat_ce & ppu_ctrl[2] == 1)ppu_rw_addr <= ppu_rw_addr + 32;
		
		
		if(ppu_reg_we & cpu_addr[2:0] == PPU_OADR)oam_addr[7:0] <= cpu_dat[7:0];
		if(ppu_reg_we & cpu_addr[2:0] == PPU_ODAT)oam_addr[7:0] <= oam_addr[7:0] + 1;
		
	end
	
	wire [7:0]mem_do;
	wire [5:0]mem_addr = apu_reg_ce ? {1'b0, cpu_addr[4:0]} : {1'b1, ppu_rw_addr[4:0]};
	wire mem_we = apu_reg_we | ppu_pal_we;
	
	
	//ram_dp regs_mem(cpu_dat, mem_addr, mem_we, , m2, , rd_addr[5:0], 0, mem_do, clk);//write sync to m2, read sync to 50mhz
	
	//handle trasparent color mirroring
	wire [5:0]mem_addr_pm = mem_addr[5] & mem_addr[3:0] == 0 ? {mem_addr[5], 5'd0} : mem_addr[5:0];
	wire [5:0]rd_addr_pm = rd_addr[5] & rd_addr[3:0] == 0 ? {rd_addr[5], 5'd0} : rd_addr[5:0];
	
	ram_dp regs_mem(
		.din_a(cpu_dat), 
		.addr_a(mem_addr_pm), 
		.we_a(mem_we), 
		.clk_a(m2), 
		.addr_b(rd_addr_pm[5:0]),
		.dout_b(mem_do), 
		.clk_b(clk)
	);
	
	
	wire [7:0]oam_do;
	ram_dp oam_mem(
		.din_a(cpu_dat), 
		.addr_a(oam_addr), 
		.we_a(oam_we), 
		.clk_a(m2), 
		.addr_b(rd_addr[7:0]), 
		.dout_b(oam_do), 
		.clk_b(clk)
	);

endmodule
