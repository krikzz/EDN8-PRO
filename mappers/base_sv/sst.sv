
module sst_controller(
	
	
	input  clk,
	input  PiBus pi,
	input  CpuBus cpu,
	input  SysCfg cfg,
	input  map_rst,
	input  sys_rst,
	input  fds_sw,
	input [7:0]sst_di,//data from mapper regs
		
	output SSTBus sst,
	output [7:0]sst_do,//data for pi or cpu via sst registers
	output sst_ce_cpu
);
	
	//map regs	128
	//apu regs 	32
	//ppu pal	32
	//ppu regs	4
	//OAM 		256
	//map mem	1.5K
	parameter REG_SST_ADDR	= 16'h40F2;
	parameter REG_SST_DATA	= 16'h40F3;
	
	
	assign sst.dato[7:0] 	= cpu.data[7:0];//data to mapper regs
	assign sst.addr[12:0]	= pi.map.ce_sst ? pi.addr[12:0] : sst_addr_cpu[12:0];
	assign sst.we				= sst_data_ce & cpu.rw == 0 & sst.act;//do not use m2 here
	assign sst.we_reg			= sst.we & ce_reg;
	assign sst.we_mem			= sst.we & ce_mem;
	
	assign sst_do[7:0] 		= ce_snif ? snif_do[7:0] : sst_di[7:0];
	assign sst_ce_cpu			= sst_data_ce;// & cpu.rw == 1;
	
	wire sst_addr_ce 			= cpu.addr[15:0] == REG_SST_ADDR;
	wire sst_data_ce 			= cpu.addr[15:0] == REG_SST_DATA;
	
	wire ce_reg					= sst.addr[12:7] == 0;//128B mapper regs
	wire ce_snif_ppu			= sst.addr[12:7] == 1;//128B ppu/apu regs
	wire ce_snif_oam 			= sst.addr[12:8] == 1;//256B oam
	wire ce_snif 				= ce_snif_ppu | ce_snif_oam;
	wire ce_mem					= !ce_reg & !ce_snif;
	
	reg [12:0]sst_addr_cpu;
	reg sst_addr_inc;
	
	always @(negedge cpu.m2)
	begin
	
		if(sst_addr_ce & cpu.rw == 0)
		begin
			sst_addr_cpu[12:0] <= {sst_addr_cpu[4:0], cpu.data[7:0]};
		end
		
		
		if(sst_data_ce)
		begin
			sst_addr_inc	<= 1;
		end
			else
		if(sst_addr_inc)
		begin
			sst_addr_inc	<= 0;
			sst_addr_cpu 	<= sst_addr_cpu + 1;
		end
		
	end
	
	
	always @(posedge clk)
	begin
		sst.act_mc	<= sst.act;
	end
	
	sst_sw sst_sw_inst(
	
		.cpu(cpu),
		.cfg(cfg),
		.map_rst(map_rst),
		.sys_rst(sys_rst),
		.fds_sw(fds_sw),
		.sst_ce(sst_data_ce),
		.ss_act(sst.act),
		.ss_src(ss_src),
		.sniff_off(sniff_off)
	);

		//wire ss_we;
	wire [7:0]snif_do;
	wire [7:0]ss_src;
	wire sniff_off;
	
	sst_sniffer sniffer_inst(
		
		.clk(clk),
		.cpu(cpu),
		.rd_addr(sst.addr[8:0]),
		.sniff_off(sniff_off),
		.ss_src(ss_src),
		
		.dout(snif_do)
	);

endmodule



module sst_sw(
	
	input  CpuBus cpu,
	input  SysCfg cfg,
	input  map_rst,
	input  sys_rst,
	input  fds_sw,
	input  sst_ce,
	
	output ss_act,
	output reg [7:0]ss_src,
	output sniff_off
);
	
	
	assign ss_act 		= ((game_out & cpu.m2) | ss_latch) & !(game_ret & cpu.m2);
	//assign ss_we 		= sst_ce & ss_act & !cpu.rw;
	assign sniff_off 	= ss_act & !ss_ack;
	
	wire game_out 		= (nmi & ss_ack == 0 & ss_req);
	wire game_ret 		= (nmi & ss_ack == 1);
	wire ss_req 		= ss_req_st[1:0] == 2'b10;
	
	wire nmi 			= cpu.rw & cpu.addr[15:0] == 16'hfffa;
	wire joy_hit_save = cfg.ss_key_save != 8'h00 & joy1 == cfg.ss_key_save;
	wire joy_hit_load = cfg.ss_key_load != 8'h00 & joy1 == cfg.ss_key_load;
	wire joy_hit_menu = cfg.ss_key_menu != 8'h00 & joy1 == cfg.ss_key_menu;
	wire joy_hit 		= joy_hit_save | joy_hit_load | joy_hit_menu;
	wire btn_hit 		= fds_sw & cfg.ct_ss_btn;
	
	
	reg ss_latch;
	reg ss_ack;
	reg [1:0]ss_req_st;
	reg nmi_on;
	
	
	always @(negedge cpu.m2)
	begin
				
		if(ss_req_st[1:0] == 2'b01)
		begin
			ss_src[7:0] 	<= joy1[7:0];
		end
	
		if(ss_latch)
		begin
			ss_req_st[1:0] <= 2'b00;
		end
			else
		if(!ss_req)
		begin
			ss_req_st[1:0] <= {ss_req_st[0], (cfg.ct_ss_on & (joy_hit | btn_hit) & !map_rst)};
		end
	
		if(cpu.addr[15:0] == 16'h2000 & !cpu.rw)
		begin
			nmi_on 			<= cpu.data[7];
		end
		
	end

	
	always @(negedge cpu.m2)
	if(map_rst)
	begin
		ss_latch <= 0;
		ss_ack 	<= 0;
	end
		else
	begin
		
		if(game_out)ss_latch <= 1;
		if(game_ret)ss_latch <= 0;
		
		
		if(game_ret | !ss_act)
		begin
			ss_ack <= 0;
		end
			else
		if(sst_ce & !cpu.rw)
		begin
			ss_ack <= 1;
		end
		
	end
	
	
	wire [7:0]joy1;
	
	joy_rdr joy_inst1(
	
		.cpu(cpu),
		.sys_rst(sys_rst),
		.port(0),
		.dout(joy1)
	);

endmodule


module joy_rdr(

	input  CpuBus cpu,
	input  sys_rst,
	input  port,
	output reg[7:0]dout
	
);
	
	wire [1:0]joy_ce;
	wire joy_cex 		= {cpu.addr[15:1], 1'b0} ==  16'h4016;
	assign joy_ce[0] 	= joy_cex & cpu.addr[0] == 0;
	assign joy_ce[1] 	= joy_cex & cpu.addr[0] == 1;
	
	reg load;
	reg [3:0]bctr;
	reg [7:0]buff[2];
	reg buff_sw;
	
	always @(negedge cpu.m2, posedge sys_rst)
	if(sys_rst)
	begin
		dout[7:0] 	<= 8'h00;
	end
		else
	begin
	
		if(joy_ce[0] & cpu.rw == 0)
		begin
			load 		<= cpu.data[0];
		end
		
		if(load)
		begin
			bctr <= 7;
		end
			else
		if(bctr[3])
		begin
			
			if(buff[0] == buff[1])//required for solve the problem with dmc collision glitch
			begin
				dout[7:0] <= buff[0];
			end
			
		end
			else
		if(joy_ce[port] & cpu.rw == 1)
		begin
		
			buff[buff_sw][bctr] <= cpu.data[0] | cpu.data[1];
			
			bctr <= bctr - 1;
			
			if(bctr == 0)
			begin
				buff_sw <= !buff_sw;
			end
			
		end
		
	
	end
	
endmodule


module sst_sniffer(
	
	input  clk,
	input  CpuBus cpu,
	input  [8:0]rd_addr,
	input  sniff_off,
	input  [7:0]ss_src,
	
	output [7:0]dout
	
);
	
	parameter PPU_CTRL = 3'd0;
	parameter PPU_MASK = 3'd1;
	parameter PPU_STAT = 3'd2;
	parameter PPU_OADR = 3'd3;
	parameter PPU_ODAT = 3'd4;
	parameter PPU_SCRL = 3'd5;
	parameter PPU_ADDR = 3'd6;
	parameter PPU_DATA = 3'd7;
	
	
	assign dout[7:0] = rd_addr[8] ? oam_do[7:0] : rd_addr[6] == 0 ? mem_do[7:0] : regs_do[7:0];

	wire ppu_reg_ce = {cpu.addr[15:12], 12'd0} 	== 16'h2000;
	wire apu_reg_ce = {cpu.addr[15:5], 5'd0} 		== 16'h4000;
	
	wire ppu_pal_ce = {ppu_rw_addr[13:8], 8'd0} 	== 14'h3f00 & ppu_reg_ce & cpu.addr[2:0] == PPU_DATA;
	wire ppu_dat_ce = ppu_reg_ce & cpu.addr[2:0] == PPU_DATA;
	
	wire ppu_reg_oe = ppu_reg_ce & cpu.rw;
	wire ppu_reg_we = ppu_reg_ce & !cpu.rw & !sniff_off;
	
	wire apu_reg_we = apu_reg_ce & !cpu.rw & !sniff_off;
	wire ppu_pal_we = ppu_pal_ce & !cpu.rw & !sniff_off;
	
	wire oam_we = ppu_reg_we & cpu.addr[2:0] == PPU_ODAT;
	
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
	
	
	always @(negedge cpu.m2)
	begin
			
		if(ppu_reg_oe & cpu.addr[2:0] == PPU_STAT)
		begin
			addr_latch <= 0;
		end
		
		if(ppu_reg_we & cpu.addr[2:0] == PPU_CTRL)
		begin
			ppu_ctrl[7:0] <= cpu.data[7:0];
		end
		
		if(ppu_reg_we & cpu.addr[2:0] == PPU_MASK)
		begin
			ppu_mask[7:0] <= cpu.data[7:0];
		end
		
		if(ppu_reg_we & cpu.addr[2:0] == PPU_SCRL)
		begin
			if(addr_latch == 0)ppu_scrl[15:8] <= cpu.data[7:0];
			if(addr_latch == 1)ppu_scrl[7:0] <= cpu.data[7:0];
			addr_latch <= !addr_latch;
		end
		
		if(ppu_reg_we & cpu.addr[2:0] == PPU_ADDR)
		begin
			if(addr_latch == 0)ppu_rw_addr[13:8] <= cpu.data[5:0];
			if(addr_latch == 1)ppu_rw_addr[7:0] <= cpu.data[7:0];
			addr_latch <= !addr_latch;
		end
		
		if(ppu_dat_ce & ppu_ctrl[2] == 0)
		begin
			ppu_rw_addr <= ppu_rw_addr + 1;
		end
		
		if(ppu_dat_ce & ppu_ctrl[2] == 1)
		begin
			ppu_rw_addr <= ppu_rw_addr + 32;
		end
		
		
		if(ppu_reg_we & cpu.addr[2:0] == PPU_OADR)
		begin
			oam_addr[7:0] <= cpu.data[7:0];
		end
		
		if(ppu_reg_we & cpu.addr[2:0] == PPU_ODAT)
		begin
			oam_addr[7:0] <= oam_addr[7:0] + 1;
		end
		
	end
	
	wire [7:0]mem_do;
	wire [5:0]mem_addr 	= apu_reg_ce ? {1'b0, cpu.addr[4:0]} : {1'b1, ppu_rw_addr[4:0]};
	wire mem_we 			= apu_reg_we | ppu_pal_we;
	
	//handle trasparent color mirroring
	wire [5:0]mem_addr_pm 	= mem_addr[5] & mem_addr[3:0] == 0 ? {mem_addr[5], 5'd0} : mem_addr[5:0];
	wire [5:0]rd_addr_pm 	= rd_addr[5] & rd_addr[3:0] == 0 ? {rd_addr[5], 5'd0} : rd_addr[5:0];
	
	
	ram_dp regs_mem(
	
		.clk_a(!cpu.m2),
		.dati_a(cpu.data), 
		.addr_a(mem_addr_pm),
		.we_a(mem_we),
		
		.clk_b(clk),
		.addr_b(rd_addr_pm[5:0]),
		.dato_b(mem_do)
	);
	
	
	wire [7:0]oam_do;
	
	ram_dp oam_mem(
		
		.clk_a(!cpu.m2), 
		.dati_a(cpu.data), 
		.addr_a(oam_addr), 
		.we_a(oam_we), 
		
		.clk_b(clk),
		.addr_b(rd_addr[7:0]), 
		.dato_b(oam_do)
	);

endmodule
