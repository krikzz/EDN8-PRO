
`include "../base/defs.v"

module base_io
(bus, pi_bus, sys_cfg, dout_pi, dout_cpu, io_oe_pi, io_oe_cpu, pi_fifo_rxf, mcu_busy);

	`include "pi_bus.v"
	`include "bus_in.v"
	`include "sys_cfg_in.v"
	
	output [`BW_SYS_CFG:0]sys_cfg;
	output [7:0]dout_pi;
	output [7:0]dout_cpu;
	output io_oe_cpu, io_oe_pi, pi_fifo_rxf; 
	input mcu_busy;

	parameter REG_FIFO_DATA		= 8'hf0;
	parameter REG_FIFO_STAT		= 8'hf1;
	parameter REG_STATUS			= 8'hff;
	

	assign dout_cpu[7:0] = 
	fifo_data_ce ? fifo_do_a[7:0] : 
	fifo_stat_ce ? fifo_status[7:0] : 
	stat_oe ? stat_do[7:0] :
	8'hff;
	
	
	assign io_oe_cpu = cpu_rw & (fifo_stat_ce | fifo_data_ce | stat_oe);
	assign io_oe_pi = pi_ce_cfg_reg | pi_ce_fifo;
	
	wire [7:0]reg_addr = cpu_addr[7:0];
	
	
	wire io_ce = {cpu_addr[15:8], 8'h00}  == 16'h4000 & !sys_rst;
	wire fifo_data_ce = io_ce & reg_addr[7:0] == REG_FIFO_DATA;
	wire fifo_stat_ce = io_ce & reg_addr[7:0] == REG_FIFO_STAT;
	wire stat_ce 		= io_ce & reg_addr[7:0] == REG_STATUS;
	
	
	
//****************************************************************************************************************** status
	wire [7:0]stat_do;
	wire stat_oe = stat_ce & cpu_rw == 1;
	wire stat_we = stat_ce & cpu_rw == 0;
	
	assign stat_do[7:0] = {4'hA, strobe, fpg_cfg_pend, mcu_cmd_pend, ctrl_unlock};
	
	
	wire ce = cpu_addr[15:0] == 16'h40ff;
	wire oe = ce & cpu_rw == 1;
	wire we = ce & cpu_rw == 0;
	wire mcu_cmd_end = mcu_busy_st[1:0] == 2'b10;
	
	reg [1:0]mcu_busy_st;
	reg mcu_cmd_pend, fpg_cfg_pend, strobe;
	
	always @(negedge m2)
	begin
	
		if(stat_oe)strobe <= !strobe;
		
		if(stat_we){fpg_cfg_pend, mcu_cmd_pend} <= cpu_dat[2:1];
			else
		if(mcu_cmd_end)mcu_cmd_pend <= 0;
		
		mcu_busy_st[1:0] <= {mcu_busy_st[0], mcu_busy};
		
		
		
	end
//****************************************************************************************************************** fifo	
	wire reg_area = {cpu_addr[15:7], 7'h00}  == 16'h4080;
	wire regs_ce = reg_area & os_act & !sys_rst;
	
	wire [7:0]fifo_status = {fifo_rxf, pi_fifo_rxf, 6'd1};
	
	//wire pi_fifo_rxf;
	wire pi_fifo_we = pi_ce_fifo & pi_we;
	wire pi_fifo_oe = pi_ce_fifo & pi_oe;
	
	wire fifo_rxf;
	wire fifo_oe = fifo_data_ce & cpu_rw == 1 & m2;
	wire fifo_we = fifo_data_ce & cpu_rw == 0 & m2;
	
	wire [7:0]fifo_do_a;
	fifo fifo_a(pi_do, fifo_do_a, fifo_oe, pi_fifo_we, fifo_rxf, clk);//arm to mos
	
	wire [7:0]fifo_do_b;
	fifo fifo_b(cpu_dat, fifo_do_b, pi_fifo_oe, fifo_we, pi_fifo_rxf, clk);//mos to arm
	
//****************************************************************************************************************** peripheral interface	
	assign dout_pi[7:0] = 
	pi_ce_cfg_reg ? scfg[pi_addr[3:0]][7:0] :
	pi_ce_fifo ? fifo_do_b[7:0] : 
	8'hff;

	
	//pi to internal registers
	reg [7:0]scfg[16];
	assign sys_cfg[`BW_SYS_CFG-1:0] = {scfg[8], scfg[7],scfg[6],scfg[5],scfg[4],scfg[3],scfg[2],scfg[1],scfg[0]};
	
	always @(negedge pi_clk)
	begin
		if(pi_ce_cfg_reg & pi_we)scfg[pi_addr[3:0]][7:0] <= pi_do[7:0];
	end
	

	
endmodule



//********************************************************************************* fifo

module fifo
(di, do, oe, we, fifo_empty, clk);

	input [7:0]di;
	output [7:0]do;
	input oe, we, clk;
	output fifo_empty;
	
	
	assign fifo_empty = we_addr == oe_addr;
	
	reg [10:0]we_addr;
	reg [10:0]oe_addr;
	reg [1:0]oe_st, we_st;	
	
	wire oe_sync = oe_st[1:0] == 2'b10;
	wire we_sync = we_st[1:0] == 2'b10;	
	
	always @(negedge clk)
	begin
	
	
		oe_st[1:0] <= {oe_st[0], (oe & !fifo_empty)};
		we_st[1:0] <= {we_st[0], we};
		
		if(oe_sync)oe_addr <= oe_addr + 1;
		if(we_sync)we_addr <= we_addr + 1;
	end
	
	
	
	ram_dp fifo_ram(
		.din_a(di), 
		.addr_a(we_addr), 
		.we_a(we), 
		.clk_a(clk), 
		.addr_b(oe_addr), 
		.dout_b(do), 
		.clk_b(clk)
	);

	
endmodule


//********************************************************************************* spi

module pi_interface
(miso, mosi, ss, clk, din, pi_bus);

	output miso;
	input mosi, ss, clk;
	
	input [7:0]din;
	output [43:0]pi_bus;
	
	assign pi_bus[43:0] = {clk, pi_act, pi_we, pi_oe, dout[7:0], aout[31:0]};
	
	reg[7:0]dout;
	reg[31:0]aout;
	wire pi_we, pi_oe;
	reg pi_act;
	
	
	parameter CMD_MEM_WR	= 8'hA0;
	parameter CMD_MEM_RD	= 8'hA1;
	
	assign miso = !ss ? sout[7] : 1'bz;
	assign pi_oe = cmd[7:0] == CMD_MEM_RD & exec;
	assign pi_we = cmd[7:0] == CMD_MEM_WR & exec;
	
	reg [7:0]sin;
	reg [7:0]sout;
	reg [2:0]bit_ctr;
	reg [7:0]cmd;
	reg [3:0]byte_ctr;
	reg [7:0]rd_buff;
	reg wr_ok;
	reg exec;

	
	always @(posedge clk)
	begin
		sin[7:0] <= {sin[6:0], mosi};
	end
	
	
	always @(negedge clk)
	if(ss)
	begin
		cmd[7:0] <= 8'h00;
		sout[7:0] <= 8'hff;
		bit_ctr[2:0] <= 3'd0;
		byte_ctr[3:0] <= 4'd0;
		pi_act <= 0;
		wr_ok <= 0;
		exec <= 0;
	end
		else
	begin
		
		
		bit_ctr <= bit_ctr + 1;
				
		
		if(bit_ctr == 7 & !exec)
		begin
			if(byte_ctr[3:0] == 4'd0)cmd[7:0] <= sin[7:0];
			if(byte_ctr[3:0] == 4'd1)aout[7:0] <= sin[7:0];
			if(byte_ctr[3:0] == 4'd2)aout[15:8] <= sin[7:0];
			if(byte_ctr[3:0] == 4'd3)aout[23:16] <= sin[7:0];
			if(byte_ctr[3:0] == 4'd4)aout[31:24] <= sin[7:0];
			if(byte_ctr[3:0] == 4'd4)exec <= 1;
			byte_ctr <= byte_ctr + 1;
		end
		
		
		
		if(cmd[7:0] == CMD_MEM_WR & exec)
		begin
			if(bit_ctr == 7)dout[7:0] <= sin[7:0];
			if(bit_ctr == 7)wr_ok <= 1;
			if(bit_ctr == 0 & wr_ok)pi_act <= 1;
			if(bit_ctr == 5 & wr_ok)pi_act <= 0;
			if(bit_ctr == 6 & wr_ok)aout <= aout + 1;
		end

		
		if(cmd[7:0] == CMD_MEM_RD & exec)
		begin
			if(bit_ctr == 1)pi_act <= 1;
			if(bit_ctr == 5)rd_buff[7:0] <= din[7:0];
			if(bit_ctr == 5)aout <= aout + 1;
			if(bit_ctr == 5)pi_act <= 0;//should not release on last cycle. otherwise spi clocked thing may not work properly
			if(bit_ctr == 7)sout[7:0] <= rd_buff[7:0];
			
			if(bit_ctr != 7)sout[7:0] <= {sout[6:0], 1'b1};
		end
		
	end

endmodule


//********************************************************************************* ram dual port

module ram_dp
(din_a, addr_a, we_a, dout_a, clk_a, din_b, addr_b, we_b, dout_b, clk_b);

	input [7:0]din_a, din_b;
	input [14:0]addr_a, addr_b;
	input we_a, we_b, clk_a, clk_b;
	output reg [7:0]dout_a, dout_b;

	
	reg [7:0]ram[32768];
	
	always @(negedge clk_a)
	begin
		dout_a <= we_a ? din_a : ram[addr_a];
		if(we_a)ram[addr_a] <= din_a;
	end
	
	always @(negedge clk_b)
	begin
		dout_b <= we_b ? din_b : ram[addr_b];
		if(we_b)ram[addr_b] <= din_b;
	end
	
endmodule

/*
	ram_dp(
		.din_a(), 
		.addr_a(), 
		.we_a(), 
		.dout_a(), 
		.clk_a(), 
		.din_b(), 
		.addr_b(), 
		.we_b(), 
		.dout_b(), 
		.clk_b()
	);

*/