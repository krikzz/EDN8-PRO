
`include "defs.sv"

module top(

	inout  [7:0]cpu_dat,
	input  [14:0]cpu_addr,
	input  cpu_ce, cpu_rw, m2,
	output cpu_irq,
	output cpu_dir, cpu_ex,
	
	inout  [7:0]ppu_dat,
	input  [13:0]ppu_addr,
	input  ppu_oe, ppu_we, ppu_a13n,
	output ppu_ciram_ce, ppu_ciram_a10,
	output ppu_dir, ppu_ex,
	
	inout  [7:0]prg_dat,
	output [21:0]prg_addr,
	output prg_ce, prg_oe, prg_we, prg_ub, prg_lb,
	
	inout  [7:0]chr_dat,
	output [21:0]chr_addr,
	output chr_ce, chr_oe, chr_we, chr_ub, chr_lb,

	output srm_ce, srm_oe, srm_we,
	
	output spi_miso,
	input  spi_mosi, spi_clk, spi_ss,
	
	input  mcu_busy,
	output fifo_rxf,
	
	input  clk, fds_sw,
	output led, pwm, boot_on,
	inout  [3:0]gpio,
	inout  [9:0]exp_io,
	output [2:0]xio,
	input  rx,
	output tx
);

	
	
	assign exp_io[0] 		= 1'bz;
	assign exp_io[9:1] 	= 9'hzz;
	assign xio[2:0] 		= 3'bzzz;
	assign boot_on 		= 0;
	
	SysCfg cfg;
	DmaBus dma;
//**************************************************************************************** map in
	MapIn mai;
	CpuBus cpu;
	PpuBus ppu;
	
	assign cpu.data[7:0]		= cpu_dat[7:0];
	assign cpu.addr[15:0]	= {!cpu_ce, cpu_addr[14:0]};
	assign cpu.rw				= cpu_rw;
	assign cpu.m2				= m2;
	
	assign ppu.data[7:0]		= ppu_dat[7:0];
	assign ppu.addr[13:0]	= ppu_addr[13:0];
	assign ppu.oe				= ppu_oe;
	assign ppu.we				= ppu_we;
	
	assign mai.clk 			= clk;
	assign mai.fds_sw 		= !fds_sw;
	//assign mai.sys_rst 		= sys_rst;
	assign mai.map_rst 		= cfg.map_idx == 255 | !cfg.ct_unlock | map_rst_req;
	assign mai.os_act 		= mai.map_rst | ss_act;
	assign mai.prg_do			= prg_dat;
	assign mai.chr_do			= chr_dat;
	assign mai.srm_do			= prg_dat;
	assign mai.cpu				= cpu;
	assign mai.ppu				= ppu;
//**************************************************************************************** map out	
	MapOut map_out;
	MemCtrl prg;
	MemCtrl chr;
	MemCtrl srm;
	
	
	
	assign prg_lb = prg.addr[22];
	assign prg_ub = !prg.addr[22];
	assign chr_lb = chr.addr[22];
	assign chr_ub = !chr.addr[22];
	
	assign prg = dma.req_prg ? dma.mem : map_out.prg;
	assign chr = dma.req_chr ? dma.mem : map_out.chr;
	assign srm = dma.req_srm ? dma.mem : map_out.srm;
	
	assign prg_addr[21:0] 	= srm.ce ? srm.addr : prg.addr;
	assign prg_ce 				= !(prg.ce & !dma.req_srm & (cpu.m2 | prg.async_io));
	assign prg_oe 				= !(prg.oe | bus_conf_act);//make it better
	assign prg_we 				= !prg.we;
	
	assign chr_addr[21:0] 	= chr.addr;
	assign chr_ce 				= !chr.ce;
	assign chr_oe 				= !chr.oe;
	assign chr_we 				= !chr.we;
	
	assign srm_ce 				= srm.ce & !dma.req_prg & (cpu.m2 | srm.async_io);
	assign srm_oe 				= !srm.oe;
	assign srm_we 				= !srm.we;
	
	assign int_ciram_ce 		= map_out.ciram_ce;
	assign int_ciram_a10 	= map_out.ciram_a10;
	assign cpu_irq				= !map_out.irq;
	assign mir_4sc				= map_out.mir_4sc;
	assign bus_conflicts		= map_out.bus_conflicts;
	
	assign map_cpu_oe			= map_out.map_cpu_oe;
	assign map_ppu_oe			= map_out.map_ppu_oe;
	assign map_cpu_dout		= map_out.map_cpu_do;
	assign map_ppu_dout		= map_out.map_ppu_do;
	
	
	assign led 					= map_out.led | (mai.sys_rst & mai.map_rst & cfg.map_idx != 255);//ss_act
	
	
//**************************************************************************************** bus ctrl		
	wire eep_on, bus_conflicts, map_led, mem_dma, mir_4sc, map_ppu_oe, map_cpu_oe, prg_mem_oe, int_ciram_ce, int_ciram_a10;
	wire [7:0]map_cpu_dout, map_ppu_dout, eep_ram_di;
	
	
	wire [7:0]cpu_dat_int = bus_conf_act ? (cpu_dat[7:0] & prg_dat[7:0]) : cpu_dat[7:0];
	wire bus_conf_act = bus_conflicts & !prg_ce & !cpu_rw;
	
	wire m3 = m[8] & m2;//m2 with delayed rising edge. required for mem async write operations and some other stuff
	reg [8:0]m;	
	always @(posedge clk)m[8:0] <= {m[7:0], m2};
//**************************************************************************************** data bus driver
	wire apu_area 		= {!cpu_ce, cpu_addr[14:5], 5'd0} == 16'h4000;
	wire cart_space 	= (!cpu_ce | cpu_addr[14]) & !apu_area;
	
	//cpu
	assign cpu_dat[7:0] = 
	cpu_dir == 0 	? 8'hzz : 
	io_oe_cp 		? io_dout_cp[7:0] : 
	ss_oe_cpu 		? ss_do[7:0] :
	map_cpu_oe 		? map_cpu_dout[7:0] : 
	gg_oe 			? gg_do[7:0] : 
	(!prg_ce | srm_ce) & !prg_oe ? prg_dat[7:0] : 
	{!cpu_ce, cpu_addr[14:8]};//open bus
	
	//assign cpu_dir = cart_space & cpu_rw & m3 ? 1 : 0;// cpu_bus_oe;
	assign cpu_dir = cart_space & cpu_rw & cpu.m2 ? 1 : 0;// cpu_bus_oe;
	assign cpu_ex  = 0;//mem_dma ? 1 : 0;
	
	
	//ppu
	assign ppu_dat[7:0] = 
	ppu_dir == 0 		? 8'hzz : 
	dma.req_chr			? 8'h00 : 
	map_ppu_oe 			? map_ppu_dout[7:0] :
	ppu_iram_oe 		? ppu_ram_do[7:0] : 
	!chr_ce & !chr_oe ? chr_dat[7:0] : 
	8'hff;
	
	assign ppu_dir = !ppu_oe & ppu_ciram_ce ? 1 : 0;
	assign ppu_ex = 0;//mem_dma ? 1 : 0;
//**************************************************************************************** memory driver

	assign prg_dat[7:0] = 
	(!prg_oe & !prg_ce) | (!srm_oe & srm_ce) ? 8'hzz ://make me better
	dma.req_prg ? prg.dati : //make me better
	dma.req_srm ? srm.dati : //make me better
	eep_on  ? eep_ram_di[7:0] : 
	map_cpu_oe ? map_cpu_dout[7:0] : cpu_dat[7:0];
	
	assign chr_dat[7:0] = 
	!chr_oe ? 8'hzz :
	dma.req_chr ? chr.dati : //make me better
	map_ppu_oe ? map_ppu_dout[7:0] : ppu_dat[7:0];

	
	//assign prg_oe = prg_mem_oe & !bus_conf_act;
	//assign srm_oe = prg_mem_oe;
//**************************************************************************************** vram driver
	assign ppu_ciram_a10 = !mir_4sc_act ? int_ciram_a10 : ppu_addr[10];
	assign ppu_ciram_ce =  !mir_4sc_act ? int_ciram_ce  : !(!int_ciram_ce & ppu_addr[11] == 0);
	wire mir_4sc_act = cfg.mc_mir_4 & mir_4sc;
	wire ppu_iram_ce = mir_4sc_act & !int_ciram_ce & ppu_addr[11] == 1;
	wire ppu_iram_oe = ppu_iram_ce & !ppu_oe;
	wire [7:0]ppu_ram_do;
	
	ppu_ram ppu_ram_inst(

		.clk(mai.clk),
		.din(ppu_dat),
		.addr(ppu_addr[10:0]),
		.ce(ppu_iram_ce),
		.oe(!ppu_oe),
		.we(!ppu_we),
		.dout(ppu_ram_do)
	);
//**************************************************************************************** system mappers
	
	
	assign map_out = 
	map_out_255;
	
	MapOut map_out_255;
	map_255 m255(mai, map_out_255);
	
	/*
	wire [`BW_MAP_OUT-1:0]map_out_ = 
	os_act 	? map_out_255_ : 
	map_out_hub;	
	
	
	
	wire [`BW_MAP_OUT-1:0]map_out_255_;
	
	

	wire [`BW_MAP_OUT-1:0]map_out_hub;
	map_hub hub_inst(
	
		.mai(mai),
		.sys_cfg(sys_cfg),
		.bus(bus),
		.map_out(map_out_hub),
		.ss_ctrl(ss_ctrl)
	);*/

//**************************************************************************************** peripheral interface	
	PiBus pi;
	
	wire [7:0]pi_di = 
	dma.mem_req ? dma.pi_di : 
	ss_oe_pi 	? ss_do : 
	io_oe_pi 	? io_dout_pi :
	8'hff;
	
	pi_io pi_io_inst(
	
		.clk(mai.clk),
		.spi_clk(spi_clk),
		.spi_ss(spi_ss),
		.spi_mosi(spi_mosi),
		.spi_miso(spi_miso),
		.dati(pi_di),
		.pi(pi)
	);
//**************************************************************************************** base io
	wire io_oe_cp, io_oe_pi;
	wire [7:0]io_dout_cp;
	wire [7:0]io_dout_pi;	
	
	base_io io_inst(
	
		.clk(mai.clk),
		.pi(pi),
		.cpu(cpu),
		.sys_rst(mai.sys_rst),
		.os_act(mai.os_act),
		.mcu_busy(mcu_busy),

		.cfg(cfg),
		.dout_pi(io_dout_pi),
		.dout_cp(io_dout_cp),
		.io_oe_pi(io_oe_pi),
		.io_oe_cp(io_oe_cp),
		.fifo_rxf_pi(fifo_rxf)
		
	);
//**************************************************************************************** dma controller
	
	wire [7:0]pi_dat_dma = dma.pi_di;
	wire dma_req = dma.mem_req;
	
	dma_io dma_io_inst(
			
		.pi(pi),
		.prg_do(prg_dat),
		.chr_do(chr_dat),
		.srm_do(prg_dat),
		.dma(dma)
	);
//**************************************************************************************** reset controls			
	//cpu reset detection
	sys_rst_ctrl sys_rst_inst(
	
		.clk(mai.clk),
		.m2(cpu.m2),
		.rst(mai.sys_rst)
	);

	
	wire map_rst_req;

	//mapper reset control
	map_rst_ctrl map_rst_inst(

		.clk(mai.clk),
		.sys_rst(mai.sys_rst),
		.rst_ack(cfg.map_idx == 255),
		.rst_delay(cfg.ct_rst_delay),
		.rst_req(map_rst_req)
	);	
//**************************************************************************************** gg	
	wire [7:0]gg_do;
	wire gg_oe;
	
`ifndef GG_OFF	
	gg gg_inst
	(
		.bus(bus), 
		.sys_cfg(sys_cfg),
		.pi_bus(pi_bus), 
		.gg_do(gg_do), 
		.gg_oe(gg_oe)
	);
`endif	

//**************************************************************************************** save state controller	
	wire [`BW_SS_CTRL-1:0]ss_ctrl;
	wire ss_oe_cpu, ss_oe_pi, ss_act;
	wire [7:0]ss_do;
	wire [7:0]ss_rdat;// = map_out_hub[7:0]; fix me

`ifndef SS_OFF		
	sst_controller ss_inst(
	
		.bus(bus),
		.pi_bus(pi_bus),
		.sys_cfg(sys_cfg),
		.ss_ctrl(ss_ctrl),
		.ss_di(ss_rdat),
		.ss_do(ss_do),// mkae me better. use separate do for pi and cpu
		.ss_oe_cpu(ss_oe_cpu),
		.ss_oe_pi(ss_oe_pi),
		.ss_act(ss_act)
	);
`endif



endmodule


//*********************************************************************************
//*********************************************************************************
//*********************************************************************************
module sys_rst_ctrl(

	input  clk,
	input  m2,
	output rst
);
	
	assign rst = ctr[6];
	
	reg [1:0]m2_st;
	reg [6:0]ctr;
	
	always @(posedge clk)
	begin
		
		m2_st[1:0] <= {m2_st[0], m2};
		
		if(m2_st[0] != m2_st[1])
		begin
			ctr <= 0;
		end
			else
		if(!rst)
		begin
			ctr <= ctr + 1;
		end
	
	end
	
endmodule
//*********************************************************************************
module map_rst_ctrl(

	input clk,
	input sys_rst, 
	input rst_ack, 
	input rst_delay,
	
	output reg rst_req
);	
	parameter DELAY_SIZE = 25;
	
	reg rst_st;
	reg rst_ack_st;
	reg [DELAY_SIZE:0]delay;
	
	wire rst_act = rst_st & (delay[DELAY_SIZE:DELAY_SIZE-1] == 2'b11 | !rst_delay);
	
	always @(posedge clk)
	begin
	
		rst_ack_st 	<= rst_ack;
		rst_st 		<= sys_rst;
		
		if(rst_act)
		begin
			rst_req 	<= 1;
		end
			else
		if(rst_ack_st)
		begin
			rst_req 	<= 0;
		end
		
		
		if(rst_st == 0)
		begin
			delay 	<= 0;
		end
			else
		if(rst_st == 1 & !rst_act)
		begin
			delay 	<= delay + 1;
		end
		
	end
	
endmodule
//*********************************************************************************
module ppu_ram(

	input  clk,
	input  [7:0]din,
	input  [11:0]addr,
	input  ce, oe, we,

	output reg [7:0]dout
	
);
	
	reg [7:0]ram[4096];
	wire we_act = we & ce & !oe;
	
	
	always @(posedge clk)
	begin
		
		if(we_act)
		begin
			ram[addr][7:0] <= din[7:0];
		end
			else
		begin
			dout[7:0] 		<= ram[addr][7:0];
		end
		
	end

endmodule
