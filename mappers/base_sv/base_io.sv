
`include "../base/defs.v"

module base_io(

	input clk,
	input PiBus pi,
	input CpuBus cpu,
	input sys_rst,
	input mcu_busy,
	input ct_unlock,
	
	output [7:0]dout_pi,
	output [7:0]dout_cp,
	output oe_cp, 
	output fifo_rxf_pi
);
	
//**************************************************************************64K for fifo


	parameter REG_FIFO_DATA		= 8'hf0;
	parameter REG_FIFO_STAT		= 8'hf1;
	parameter REG_STATUS			= 8'hff;
	
	assign dout_pi[7:0] = fifo_do_b[7:0];
	
	assign dout_cp[7:0] = 
	fifo_data_ce ? fifo_do_a[7:0] : 
	fifo_stat_ce ? fifo_status[7:0] : 
	baio_stat_ce ? baio_status[7:0] :
	8'hff;
	
	assign oe_cp 			= cpu.rw & (fifo_stat_ce | fifo_data_ce | baio_stat_ce);
	
	wire [7:0]reg_addr	= cpu.addr[7:0];
	
	
	wire io_ce_cp			= {cpu.addr[15:8], 8'h00}  == 16'h4000 & !sys_rst;
	wire fifo_data_ce 	= io_ce_cp & reg_addr[7:0] == REG_FIFO_DATA;
	wire fifo_stat_ce 	= io_ce_cp & reg_addr[7:0] == REG_FIFO_STAT;
	wire baio_stat_ce 	= io_ce_cp & reg_addr[7:0] == REG_STATUS;
	
//****************************************************************************************************************** base io status
	wire [7:0]baio_status;
	wire stat_oe = baio_stat_ce & cpu.rw == 1;
	wire stat_we = baio_stat_ce & cpu.rw == 0;
	
	assign baio_status[7:0] = {4'hA, strobe, fpg_cfg_pend, mcu_cmd_pend, unlock_st};
	
	
	wire ce = cpu.addr[15:0] == 16'h40ff;
	wire oe = ce & cpu.rw == 1;
	wire we = ce & cpu.rw == 0;
	wire mcu_cmd_end = mcu_busy_st[1:0] == 2'b10;
	
	reg [1:0]mcu_busy_st;
	reg mcu_cmd_pend, fpg_cfg_pend, strobe;
	reg unlock_st;
	
	always @(negedge cpu.m2)
	begin
	
		if(stat_oe)
		begin
			strobe 			<= !strobe;
		end
		
		if(stat_we)
		begin
			{fpg_cfg_pend, mcu_cmd_pend} <= cpu.data[2:1];
		end
			else
		if(mcu_cmd_end)
		begin
			mcu_cmd_pend 	<= 0;
		end
		
		mcu_busy_st[1:0] 	<= {mcu_busy_st[0], mcu_busy};
		unlock_st			<= ct_unlock;
		
	end
//****************************************************************************************************************** fifo	
	
	reg [7:0]fifo_status;
	always @(negedge cpu.m2)
	begin
		fifo_status <= {fifo_rxf_cp, fifo_rxf_pi, 6'd1};
	end
	
	wire fifo_oe_pi = pi.map.ce_fifo & pi.oe & pi.act;
	wire fifo_we_pi = pi.map.ce_fifo & pi.we & pi.act;
	
	wire fifo_rxf_cp;
	wire fifo_oe_cp = fifo_data_ce & cpu.rw == 1 & cpu.m2;
	wire fifo_we_cp = fifo_data_ce & cpu.rw == 0 & cpu.m2;
	
	//arm to mos
	wire [7:0]fifo_do_a;
	fifo fifo_a(

		.clk(clk),
		.di(pi.dato),
		.oe(fifo_oe_cp),
		.we(fifo_we_pi),
		.dato(fifo_do_a),
		.fifo_empty(fifo_rxf_cp)
	);
	
	//mos to arm
	wire [7:0]fifo_do_b;
	fifo fifo_b(

		.clk(clk),
		.di(cpu.data),
		.oe(fifo_oe_pi),
		.we(fifo_we_cp),
		.dato(fifo_do_b),
		.fifo_empty(fifo_rxf_pi)
	);
	

endmodule



//********************************************************************************* fifo

module fifo(

	input clk, 
	input [7:0]di,
	input oe, we,
	
	output [7:0]dato,
	output fifo_empty
);

	
	assign fifo_empty = we_addr == oe_addr;
	
	reg [10:0]we_addr;
	reg [10:0]oe_addr;
	reg [1:0]oe_st, we_st;	
	
	wire oe_end = oe_st[1:0] == 2'b10;
	wire we_end = we_st[1:0] == 2'b10;	
	
	always @(posedge clk)
	begin
	
		oe_st[1:0] <= {oe_st[0], (oe & !fifo_empty)};
		we_st[1:0] <= {we_st[0], we};
		
		if(oe_end)oe_addr <= oe_addr + 1;
		if(we_end)we_addr <= we_addr + 1;
		
	end
	
	
	
	ram_dp fifo_ram(
	
		.clk_a(clk),
		.dati_a(di), 
		.addr_a(we_addr), 
		.we_a(we), 
		
		.clk_b(clk),
		.addr_b(oe_addr), 
		.dato_b(dato)
	);

	
endmodule

//********************************************************************************* ram dual port

module ram_dp(

	input clk_a,
	input [7:0]dati_a,
	input [15:0]addr_a,
	input we_a,
	output reg [7:0]dato_a,
	
	input clk_b,
	input [7:0]dati_b,
	input [15:0]addr_b,
	input we_b,
	output reg [7:0]dato_b
);

	
	reg [7:0]ram[65536];
	
	always @(posedge clk_a)
	begin
	
		dato_a 			<= we_a ? dati_a : ram[addr_a];
		
		if(we_a)
		begin
			ram[addr_a] <= dati_a;
		end
	end
	
	always @(posedge clk_b)
	begin
	
		dato_b 			<= we_b ? dati_b : ram[addr_b];
		
		if(we_b)
		begin
			ram[addr_b] <= dati_b;
		end
	end
	
endmodule
