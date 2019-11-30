

	input [`BW_PI_BUS-1:0]pi_bus;
	//output [7:0]pi_di;
	
	wire [7:0]pi_do;
	wire [31:0]pi_addr;
	wire pi_we, pi_oe, pi_act, pi_clk;
	assign {pi_clk, pi_act, pi_we, pi_oe, pi_do[7:0], pi_addr[31:0]} = pi_bus[43:0];
	
	//wire pi_bus_req = (pi_we | pi_oe);
	wire pi_dma_req = (pi_we | pi_oe) & pi_dst != 3;
	
	
	wire [1:0]pi_dst = pi_addr[24:23];
	wire pi_dst_prg = pi_dst == 0;//8M area
	wire pi_dst_chr = pi_dst == 1;//8M area
	wire pi_dst_srm = pi_dst == 2;//8M area
	wire pi_dst_sys = pi_dst == 3;//8M area
	
	wire pi_ce_prg = pi_act & pi_dst_prg;
	wire pi_ce_chr = pi_act & pi_dst_chr;//8M area
	wire pi_ce_srm = pi_act & pi_dst_srm;//8M area
	wire pi_ce_sys = pi_act & pi_dst_sys;//8M area
	
//**************************************************************************64K for system registers	
	wire pi_ce_regs = pi_ce_sys & pi_addr[21:16] == 0;
	
	wire pi_ce_cfg = pi_ce_regs & pi_addr[15:8] == 0;//256B
	wire pi_ce_cfg_ggc = pi_ce_cfg & pi_addr[7:5] == 0;//32B cheat codes
	wire pi_ce_cfg_reg = pi_ce_cfg & pi_addr[7:5] == 1 & pi_addr[4:3] == 0;//8B mapper configuration
	
	wire pi_ce_ss = pi_ce_regs & pi_addr[15:13] == 1;//8K
	

//**************************************************************************64K for fifo
//next 64k should not be used. last byte of read operations out of this area to prevent false fifo increment
	wire pi_ce_fifo = pi_ce_sys & pi_addr[21:16] == 1;