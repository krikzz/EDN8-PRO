
`include "../base/defs.v"

module gg
(bus, sys_cfg, pi_bus, gg_do, gg_oe);

	`include "bus_in.v"
	`include "pi_bus.v"
	`include "sys_cfg_in.v"
	
	input [`BW_SYS_CFG-1:0]sys_cfg;
	output [7:0]gg_do;
	output gg_oe;
	
	
	assign gg_oe = slot_act != 0 & !pi_dma_req & ctrl_gg_on & !os_act;
	
	assign gg_do[7:0] =  
	slot_act[0] ? cpu_do_ar[0][7:0] : 
	slot_act[1] ? cpu_do_ar[1][7:0] : 
	slot_act[2] ? cpu_do_ar[2][7:0] : 
	slot_act[3] ? cpu_do_ar[3][7:0] : 
	slot_act[4] ? cpu_do_ar[4][7:0] : 
	slot_act[5] ? cpu_do_ar[5][7:0] : 
	slot_act[6] ? cpu_do_ar[6][7:0] : 
	slot_act[7] ? cpu_do_ar[7][7:0] : 8'h00;
	
	
	wire [7:0]cpu_do_ar[8];
	wire [7:0]slot_act;
	
	gg_slot gg0(6'h00, bus, pi_bus, slot_act[0], cpu_do_ar[0]);
	gg_slot gg1(6'h01, bus, pi_bus, slot_act[1], cpu_do_ar[1]);
	gg_slot gg2(6'h02, bus, pi_bus, slot_act[2], cpu_do_ar[2]);
	gg_slot gg3(6'h03, bus, pi_bus, slot_act[3], cpu_do_ar[3]);
	gg_slot gg4(6'h04, bus, pi_bus, slot_act[4], cpu_do_ar[4]);
	gg_slot gg5(6'h05, bus, pi_bus, slot_act[5], cpu_do_ar[5]);
	gg_slot gg6(6'h06, bus, pi_bus, slot_act[6], cpu_do_ar[6]);
	gg_slot gg7(6'h07, bus, pi_bus, slot_act[7], cpu_do_ar[7]);

	

endmodule


module gg_slot
(slot, bus, pi_bus, slot_act, cpu_do);

	`include "bus_in.v"
	`include "pi_bus.v"
	
	input [5:0]slot;
	output slot_act;
	output [7:0]cpu_do;
	
	assign cpu_do[7:0] = slot_act ? code[3][7:0] : 8'h00;
	
	
	assign slot_act = m2 & cpu_rw & rd_ok & code_eq;
	
	wire gg_ce = pi_ce_cfg_ggc & pi_addr[7:2] == slot[5:0];
	wire gg_we = gg_ce & pi_we;
	wire code_eq =  addr_eq & (data_eq | data_cmp_off);
	wire addr_eq = {1'b1, cpu_addr[14:0]} == {code[1][7:0], code[0][7:0]};//0x8000-0xffff area. upper bit turn on/off slot
	wire data_eq = prg_dat[7:0] == code[2][7:0];
	wire data_cmp_off = code[3][7:0] == code[2][7:0];
	
	reg [7:0]code[4];
	
	always @(negedge pi_clk)
	begin
		if(gg_we)code[pi_addr[1:0]][7:0] <= pi_do[7:0];		
	end
	
	
	//wire rd_le = rd_delay == 6;
	wire rd_ok = rd_delay == 4;//+1 at rd_st latch delay
	
	reg [3:0]rd_delay;
	reg rd_st;
	
	always @(negedge clk)
	begin
		
		rd_st <= m2 | cpu_rw;
		
		if(!rd_st)rd_delay <= 0;
			else
		if(!rd_ok)rd_delay <= rd_delay + 1;
		/*
		if(!m2 | !cpu_rw)slot_act <= 0;
			else
		if(rd_le)slot_act <= code_eq;*/
		
	end
	
endmodule
