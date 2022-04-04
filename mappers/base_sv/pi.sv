	

//********************************************************************************* pi map
module pi_io_map(

	input  PiBus pi,
	output PiMap map
);


	wire [1:0]pi_dst 			= pi.addr[24:23];
	assign map.dst_prg 	= pi_dst == 0;//8M area
	assign map.dst_chr 	= pi_dst == 1;//8M area
	assign map.dst_srm 	= pi_dst == 2;//8M area
	assign map.dst_sys 	= pi_dst == 3;//8M area
	
	assign map.ce_prg 	= pi.act & map.dst_prg;
	assign map.ce_chr 	= pi.act & map.dst_chr;//8M area
	assign map.ce_srm 	= pi.act & map.dst_srm;//8M area
	assign map.ce_sys 	= pi.act & map.dst_sys;//8M area
	
//******** 64K for system registers
	wire pi_ce_regs 	 		 = map.ce_sys  & pi.addr[21:16] == 0;
	
	assign map.ce_cfg 	 = pi_ce_regs & pi.addr[15:8] == 0;//256B
	assign map.ce_cfg_ggc = map.ce_cfg & pi.addr[7:5] == 0;//32B cheat codes
	assign map.ce_cfg_reg = map.ce_cfg & pi.addr[7:5] == 1 & pi.addr[4] == 0;//16B mapper configuration
	
	assign map.ce_ss 		 = pi_ce_regs & pi.addr[15:13] == 1;//8K
	
//******** 64K for fifo	
	
	assign map.ce_fifo 	 = map.ce_sys & pi.addr[21:16] == 1;
	
endmodule

//********************************************************************************* pi io
module pi_io(
	
	input clk,
	
	input  spi_clk,
	input  spi_ss,
	input  spi_mosi,
	output spi_miso,
	
	input  [7:0]dati,
	output PiBus pi
	
);


	parameter CMD_MEM_WR	= 8'hA0;
	parameter CMD_MEM_RD	= 8'hA1;
	
	
	assign spi_miso 		= !spi_ss ? sout[7] : 1'bz;
	assign pi.oe 			= cmd[7:0] == CMD_MEM_RD & exec;
	assign pi.we 			= cmd[7:0] == CMD_MEM_WR & exec;
	assign pi.act_sync	= act_st[2:0] == 3'b001;
	
	reg [7:0]sin;
	reg [7:0]sout;
	reg [2:0]bit_ctr;
	reg [7:0]cmd;
	reg [3:0]byte_ctr;
	reg [7:0]rd_buff;
	reg wr_ok;
	reg exec;
	reg [2:0]act_st;
	
	always @(posedge clk)
	begin
		act_st[2:0] <= {act_st[1:0], pi.act};
	end
	
	always @(posedge spi_clk)
	begin
		sin[7:0] <= {sin[6:0], spi_mosi};
	end
	
	
	always @(negedge spi_clk)
	if(spi_ss)
	begin
		cmd[7:0] 		<= 8'h00;
		sout[7:0] 		<= 8'hff;
		bit_ctr[2:0] 	<= 3'd0;
		byte_ctr[3:0] 	<= 4'd0;
		pi.act 			<= 0;
		wr_ok 			<= 0;
		exec 				<= 0;
	end
		else
	begin
		
		
		bit_ctr <= bit_ctr + 1;
				
		
		if(bit_ctr == 7 & !exec)
		begin
			if(byte_ctr[3:0] == 4'd0)cmd[7:0] 			<= sin[7:0];
			if(byte_ctr[3:0] == 4'd1)pi.addr[7:0] 		<= sin[7:0];
			if(byte_ctr[3:0] == 4'd2)pi.addr[15:8] 	<= sin[7:0];
			if(byte_ctr[3:0] == 4'd3)pi.addr[23:16] 	<= sin[7:0];
			if(byte_ctr[3:0] == 4'd4)pi.addr[31:24] 	<= sin[7:0];
			if(byte_ctr[3:0] == 4'd4)exec 				<= 1;
			byte_ctr 											<= byte_ctr + 1;
		end
		
		
		
		if(cmd[7:0] == CMD_MEM_WR & exec)
		begin
			if(bit_ctr == 7)pi.dato[7:0] 		<= sin[7:0];
			if(bit_ctr == 7)wr_ok 				<= 1;
			if(bit_ctr == 0 & wr_ok)pi.act 	<= 1;
			if(bit_ctr == 5 & wr_ok)pi.act 	<= 0;
			if(bit_ctr == 6 & wr_ok)pi.addr 	<= pi.addr + 1;
		end

		
		if(cmd[7:0] == CMD_MEM_RD & exec)
		begin
			if(bit_ctr == 1)pi.act 			<= 1;
			if(bit_ctr == 5)rd_buff[7:0] 	<= dati[7:0];
			if(bit_ctr == 5)pi.addr 		<= pi.addr + 1;
			if(bit_ctr == 5)pi.act 			<= 0;//should not release on last cycle. otherwise spi clocked thing may not work properly
			if(bit_ctr == 7)sout[7:0] 		<= rd_buff[7:0];
			
			if(bit_ctr != 7)sout[7:0] 		<= {sout[6:0], 1'b1};
		end
		
	end
	
	
	
//********************************************************************************* pi map	
	
	
	pi_io_map pi_io_map_inst(

		.pi(pi),
		.map(pi.map)
	);
	
	
endmodule
	
/*
module pi_io(
);	
	

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
	wire pi_ce_regs 	 = pi_ce_sys  & pi_addr[21:16] == 0;
	
	wire pi_ce_cfg 	 = pi_ce_regs & pi_addr[15:8] == 0;//256B
	wire pi_ce_cfg_ggc = pi_ce_cfg  & pi_addr[7:5] == 0;//32B cheat codes
	wire pi_ce_cfg_reg = pi_ce_cfg  & pi_addr[7:5] == 1 & pi_addr[4] == 0;//16B mapper configuration
	
	wire pi_ce_ss 		 = pi_ce_regs & pi_addr[15:13] == 1;//8K
	

//**************************************************************************64K for fifo
//next 64k should not be used. last byte of read operations out of this area to prevent false fifo increment
	wire pi_ce_fifo = pi_ce_sys & pi_addr[21:16] == 1;
	
endmodule
*/