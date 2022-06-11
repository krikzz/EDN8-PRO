
module eep_24cXX_sync(

	input  clk,
	input  rst,
	input  [3:0]bram_type,
	
	input  scl,
	input  sda_in,
	output sda_out,
	
	input  [7:0]ram_do,
	output [7:0]ram_di,
	output [15:0]ram_addr,
	output ram_oe, ram_we,
	output led
);
	
	reg scl_sync, sda_in_sync, rst_sync;
	
	always @(posedge clk)
	begin
		{scl_sync, sda_in_sync, rst_sync} <= {scl, sda_in, rst} ;
	end
	
	eep_24cXX eep_inst(

		.clk(clk),
		.rst(rst_sync),
		.bram_type(bram_type),
		
		.scl(scl_sync),
		.sda_in(sda_in_sync),
		.sda_out(sda_out),

		.ram_do(ram_do),
		.ram_di(ram_di),
		.ram_addr(ram_addr),
		.ram_oe(ram_oe), 
		.ram_we(ram_we),
		.led(led)
	);

endmodule

module eep_24cXX(

	input clk,
	input rst,
	input [3:0]bram_type,
	
	input  scl,
	input  sda_in,
	output sda_out,
	
	input  [7:0]ram_do,
	output [7:0]ram_di,
	output [15:0]ram_addr,
	output reg ram_oe, ram_we,
	output led
);

	parameter BRAM_24X01    = 4'h3;
	parameter BRAM_24C01    = 4'h4;
	parameter BRAM_24C02    = 4'h5;
	parameter BRAM_24C08    = 4'h6;
	parameter BRAM_24C16    = 4'h7;
	parameter BRAM_24C64    = 4'h8;
	
	assign led 					= state != 0;
		
	assign sda_out 			= !sda_in ? 0 : sda_int;
	
	assign ram_di[7:0] 		= buff[7:0];
	
	assign ram_addr[15:0] 	= 
	bram_type == BRAM_24X01 ? ram_addr_int[6:0] : 
	bram_type == BRAM_24C01 ? ram_addr_int[6:0] : 
	bram_type == BRAM_24C02 ? ram_addr_int[7:0] : 
	bram_type == BRAM_24C08 ? ram_addr_int[9:0] : 
	bram_type == BRAM_24C16 ? ram_addr_int[10:0] : 
	bram_type == BRAM_24C64 ? ram_addr_int[12:0] : 0;
	
	wire start 		= scl & scl_st & sda_e & sda_in == 0;//may be use scl_st 
	wire stop 		= scl & scl_st & sda_e & sda_in == 1;//may be use scl_st 
	wire sda_e 		= sda_in != sda_in_st;
	wire scl_e_hi 	= scl == 1 & scl_st == 0;
	wire scl_e_lo 	= scl == 0 & scl_st == 1;
	
	reg [15:0]ram_addr_int;
	reg [3:0]state;
	reg [3:0]bit_ctr;
	reg [2:0]delay;
	reg [7:0]buff;
	reg [7:0]ram_buf;
	reg sda_in_st, scl_st;
	reg sda_int;
	
	
	always @(posedge clk)
	begin
		sda_in_st 	<= sda_in;
		scl_st 		<= scl;
	end
	
	always @(posedge clk)
	if(rst)
	begin
		state 	<= 0;
		ram_oe 	<= 0;
		ram_we 	<= 0;
		sda_int 	<= 1;
	end
		else
	begin
		

		if(delay)delay <= delay - 1;
		if(delay == 0 & ram_oe)ram_buf[7:0] <= ram_do[7:0];
		if(delay == 0 & ram_oe)ram_oe <= 0;
		if(delay == 0 & ram_we)ram_we <= 0;
		
		if(scl_e_hi & bit_ctr[3] == 0)buff[7 - bit_ctr[2:0]] <= sda_in;
		if(scl_e_hi)bit_ctr <= bit_ctr == 8 ? 0 : bit_ctr + 1;
		
		
		if(stop)state <= 0;
			else
		if(start)
		begin
			sda_int <= 1;
			bit_ctr <= 0;
			if(bram_type == BRAM_24X01)state <= 1;
			if(bram_type == BRAM_24C01)state <= 2;
			if(bram_type == BRAM_24C02)state <= 2;
			if(bram_type == BRAM_24C08)state <= 2;
			if(bram_type == BRAM_24C16)state <= 2;
			if(bram_type == BRAM_24C64)state <= 4;
		end
			else
		case(state)
			0:begin//idle
				sda_int <= 1;
			end
//************************************************************************************* rx addr 24x01
			1:begin
				if(scl_e_lo & bit_ctr == 8)sda_int <= 0;
				if(scl_e_hi & bit_ctr == 8)
				begin
					ram_addr_int[6:0] <= buff[7:1];
					state <= buff[0] == 1 ? 11 : 10;
				end
			end
//************************************************************************************* rx addr 24c01 - 24c16
			2:begin
				if(scl_e_lo & bit_ctr == 8 & buff[7:4] == 4'b1010)sda_int <= 0;
				if(scl_e_hi & bit_ctr == 8 & buff[7:4] != 4'b1010)state <= 0;
				if(scl_e_hi & bit_ctr == 8 & buff[7:4] == 4'b1010)
				begin
					ram_addr_int[10:8] <= buff[3:1];
					state <= buff[0] == 1 ? 11 : state + 1;
				end
			end
			3:begin
			
				if(scl_e_lo & bit_ctr != 8)sda_int <= 1;//release ack
				if(scl_e_lo & bit_ctr == 8)sda_int <= 0;
				
				if(scl_e_hi & bit_ctr == 8)
				begin
					ram_addr_int[7:0] <= buff[7:0];
					state <= 10;
				end
			end
//************************************************************************************* rx addr 24c64
			4:begin
				if(scl_e_lo & bit_ctr == 8 & buff[7:4] == 4'b1010)sda_int <= 0;
				if(scl_e_hi & bit_ctr == 8 & buff[7:4] != 4'b1010)state <= 0;
				if(scl_e_hi & bit_ctr == 8 & buff[7:4] == 4'b1010)
				begin
					state <= buff[0] == 1 ? 11 : state + 1;
				end
			end
			5:begin
			
				if(scl_e_lo & bit_ctr != 8)sda_int <= 1;//release ack
				if(scl_e_lo & bit_ctr == 8)sda_int <= 0;
				
				if(scl_e_hi & bit_ctr == 8)
				begin
					ram_addr_int[15:8] <= buff[7:0];
					state <= state + 1;
				end
			end
			6:begin
			
				if(scl_e_lo & bit_ctr != 8)sda_int <= 1;//release ack
				if(scl_e_lo & bit_ctr == 8)sda_int <= 0;
				
				if(scl_e_hi & bit_ctr == 8)
				begin
					ram_addr_int[7:0] <= buff[7:0];
					state <= 10;
				end
			end
//************************************************************************************* wr op		
			10:begin
			
				if(scl_e_lo & bit_ctr != 8)sda_int <= 1;//release ack
				if(scl_e_lo & bit_ctr == 8)sda_int <= 0;
			
				if(scl_e_hi & bit_ctr == 7)
				begin
					ram_we <= 1;
					delay  <= 3;//80ns
				end
				
				if(scl_e_hi & bit_ctr == 8)
				begin
					if(bram_type == BRAM_24X01)ram_addr_int[1:0] <= ram_addr_int[1:0] + 1;
					if(bram_type == BRAM_24C01)ram_addr_int[2:0] <= ram_addr_int[2:0] + 1;
					if(bram_type == BRAM_24C02)ram_addr_int[2:0] <= ram_addr_int[2:0] + 1;
					if(bram_type == BRAM_24C08)ram_addr_int[3:0] <= ram_addr_int[3:0] + 1;
					if(bram_type == BRAM_24C16)ram_addr_int[3:0] <= ram_addr_int[3:0] + 1;
					if(bram_type == BRAM_24C64)ram_addr_int[4:0] <= ram_addr_int[4:0] + 1;
				end
				
			end
//************************************************************************************* rd op			
			11:begin
				ram_oe <= 1;
				delay <= 3;
				state <= state + 1;
			end
			12:begin
			
				if(scl_e_lo & bit_ctr != 8)sda_int <= ram_buf[7 - bit_ctr[2:0]];
				if(scl_e_lo & bit_ctr == 8)sda_int <= 1;//release bus for ack receive
				
				
				if(scl_e_hi & bit_ctr == 7)//read next byte from ram
				begin
					ram_addr_int <= ram_addr_int + 1;
					ram_oe <= 1;
					delay <= 3;//80ns
				end

				if(scl_e_hi & bit_ctr == 8 & sda_in == 1)state <= 0;//end rd if no ack
				
			end
			
		endcase
		
	end

endmodule
