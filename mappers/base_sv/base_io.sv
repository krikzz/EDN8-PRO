
/*
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
*/

module base_io(

	input  clk,
	input  PiBus pi,
	input  CpuBus cpu,
	input  SysCfg cfg,
	input  os_act,
	input  sys_rst,
	input  mcu_busy,
	
	output [7:0]pi_di,
	output [7:0]dato,
	output io_oe,
	output pi_fifo_rxf
);

	parameter REG_FIFO_DATA		= 8'hf0;
	parameter REG_FIFO_STAT		= 8'hf1;
	parameter REG_STATUS			= 8'hff;
	
	assign dato[7:0] = 
	fifo_data_ce 	? fifo_do_a[7:0] : 
	fifo_stat_ce 	? fifo_status[7:0] : 
	stat_oe 			? stat_do[7:0] :
	8'hff;
	
	assign io_oe 			= cpu.rw & (fifo_stat_ce | fifo_data_ce | stat_oe);
	
	wire [7:0]reg_addr	= cpu.addr[7:0];
	
	wire io_ce 				= {cpu.addr[15:8], 8'h00}  == 16'h4000 & !sys_rst;
	wire fifo_data_ce 	= io_ce & reg_addr[7:0] == REG_FIFO_DATA;
	wire fifo_stat_ce 	= io_ce & reg_addr[7:0] == REG_FIFO_STAT;
	wire stat_ce 			= io_ce & reg_addr[7:0] == REG_STATUS;
	
//****************************************************************************************************************** status
	wire [7:0]stat_do;
	wire stat_oe = stat_ce & cpu.rw == 1;
	wire stat_we = stat_ce & cpu.rw == 0;
	
	assign stat_do[7:0] = {4'hA, strobe, fpg_cfg_pend, mcu_cmd_pend, cfg.ctrl_unlock};
	
	
	wire ce = cpu.addr[15:0] == 16'h40ff;
	wire oe = ce & cpu.rw == 1;
	wire we = ce & cpu.rw == 0;
	wire mcu_cmd_end = mcu_busy_st[1:0] == 2'b10;
	
	reg [1:0]mcu_busy_st;
	reg mcu_cmd_pend, fpg_cfg_pend, strobe;
	
	always @(negedge cpu.m2)
	begin
	
		if(stat_oe)strobe <= !strobe;
		
		if(stat_we){fpg_cfg_pend, mcu_cmd_pend} <= cpu.data[2:1];
			else
		if(mcu_cmd_end)mcu_cmd_pend <= 0;
		
		mcu_busy_st[1:0] <= {mcu_busy_st[0], mcu_busy};

	end
//****************************************************************************************************************** fifo	
	wire reg_area 		= {cpu.addr[15:7], 7'h00}  == 16'h4080;
	wire regs_ce 		= reg_area & os_act & !sys_rst;
	
	wire [7:0]fifo_status = {fifo_rxf, pi_fifo_rxf, 6'd1};
	
	//wire pi_fifo_rxf;
	wire pi_fifo_we 	= pi.map.ce_fifo & pi.we;
	wire pi_fifo_oe 	= pi.map.ce_fifo & pi.oe;
	
	wire fifo_rxf;
	wire fifo_oe 		= fifo_data_ce & cpu.rw == 1 & cpu.m2;
	wire fifo_we 		= fifo_data_ce & cpu.rw == 0 & cpu.m2;
	
	
	wire [7:0]fifo_do_a;
	fifo fifo_a(
	
		.clk(clk),
		.oe(fifo_oe), 
		.we(pi_fifo_we),
		.dati(pi.dato),
		
		.dato(fifo_do_a),
		.fifo_empty(fifo_rxf)
	);
	
	
	wire [7:0]fifo_do_b;
	fifo fifo_b(
	
		.clk(clk),
		.oe(pi_fifo_oe),
		.we(fifo_we),
		.dati(cpu_dat),
		
		.dato(fifo_do_b),
		.fifo_empty(pi_fifo_rxf)
	);
	
	/*
	wire [7:0]fifo_do_a;
	fifo fifo_a(pi_do, fifo_do_a, fifo_oe, pi_fifo_we, fifo_rxf, clk);//arm to mos
	
	wire [7:0]fifo_do_b;
	fifo fifo_b(cpu_dat, fifo_do_b, pi_fifo_oe, fifo_we, pi_fifo_rxf, clk);//mos to arm
	*/

endmodule


//********************************************************************************* fifo
//(di, do, oe, we, fifo_empty, clk);
module fifo(
	
	input clk,
	input oe, we,
	input [7:0]dati,
	
	output [7:0]dato,
	output fifo_empty
);


	assign fifo_empty = we_addr == oe_addr;
	
	reg [10:0]we_addr;
	reg [10:0]oe_addr;
	reg [1:0]oe_st, we_st;	
	
	wire oe_sync = oe_st[1:0] == 2'b10;
	wire we_sync = we_st[1:0] == 2'b10;	
	
	always @(posedge clk)
	begin
	
		oe_st[1:0] <= {oe_st[0], (oe & !fifo_empty)};
		we_st[1:0] <= {we_st[0], we};
		
		if(oe_sync)oe_addr <= oe_addr + 1;
		if(we_sync)we_addr <= we_addr + 1;
	end
	
	
	ram_dp_sv fifo_ram(
	
		.clk_a(clk),
		.dati_a(dati),
		.addr_a(we_addr),
		.we_a(we),
		
		.clk_b(clk),
		.addr_b(oe_addr),
		.dato_b(dato)
		
	);

	
endmodule

//********************************************************************************* ram dual port

module ram_dp_sv(

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
