	

//********************************************************************************* pi map
module pi_io_map(

	input  PiBus pi,
	output PiMap map
);

	wire pi_exec				= pi.oe | pi.we;
	wire [1:0]pi_dst 			= pi.addr[24:23];
	assign map.ce_prg 		= pi_dst == 0 & pi_exec;//8M area
	assign map.ce_chr 		= pi_dst == 1 & pi_exec;//8M area
	assign map.ce_srm 		= pi_dst == 2 & pi_exec;//8M area
	assign map.ce_sys 		= pi_dst == 3 & pi_exec;//8M area
	
	//assign map.ce_prg 	= pi.act & map.dst_prg;
	//assign map.ce_chr 	= pi.act & map.dst_chr;//8M area
	//assign map.ce_srm 	= pi.act & map.dst_srm;//8M area
	//assign map.ce_sys 	= pi.act & map.dst_sys;//8M area
	
//******** 64K for system registers
	wire pi_ce_regs			= map.ce_sys  & pi.addr[21:16] == 0;
	
	assign map.ce_cfg 	 	= pi_ce_regs & pi.addr[15:8] == 0;//256B
	assign map.ce_cfg_ggc 	= map.ce_cfg & pi.addr[7:5] == 0;//32B cheat codes
	assign map.ce_cfg_reg 	= map.ce_cfg & pi.addr[7:5] == 1 & pi.addr[4] == 0;//16B mapper configuration
	
	assign map.ce_ss 		 	= pi_ce_regs & pi.addr[15:13] == 1;//8K
	
//******** 64K for fifo	
	
	assign map.ce_fifo 	 	= map.ce_sys & pi.addr[21:16] == 1;
	
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
	assign pi.clk = spi_clk;//remove me

	parameter CMD_MEM_WR	= 8'hA0;
	parameter CMD_MEM_RD	= 8'hA1;
	
	
	assign spi_miso 		= !spi_ss ? sout[7] : 1'bz;
	assign pi.oe 			= cmd[7:0] == CMD_MEM_RD & exec;
	assign pi.we 			= cmd[7:0] == CMD_MEM_WR & exec;

	
	reg [7:0]sin;
	reg [7:0]sout;
	reg [2:0]bit_ctr;
	reg [7:0]cmd;
	reg [3:0]byte_ctr;
	reg [7:0]rd_buff;
	reg wr_ok;
	reg exec;

	
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
			if(bit_ctr == 5)pi.act 			<= 0;//should not release on last cycle. otherwise spi clocked thing may not work properly
			if(bit_ctr == 6)pi.addr 		<= pi.addr + 1;
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
