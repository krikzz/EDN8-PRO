


//chead codes
module ggc(
	
	input  clk,
	input  PiBus pi,
	input  CpuBus cpu,
	input  cheats_on,
	input  [7:0]prg_do,
	
	output [7:0]ggc_do,
	output ggc_ce_cpu
	
);
	
	
	//assign ggc_ce = slot_act != 0 & !pi_dma_req & ctrl_gg_on & !os_act;
	assign ggc_ce_cpu = slot_act != 0 & cheats_on;
	
	assign ggc_do[7:0] =  
	slot_act[0] ? cpu_do[0][7:0] : 
	slot_act[1] ? cpu_do[1][7:0] : 
	slot_act[2] ? cpu_do[2][7:0] : 
	slot_act[3] ? cpu_do[3][7:0] : 
	slot_act[4] ? cpu_do[4][7:0] : 
	slot_act[5] ? cpu_do[5][7:0] : 
	slot_act[6] ? cpu_do[6][7:0] : 
	slot_act[7] ? cpu_do[7][7:0] : 8'h00;
	
	
	wire [7:0]cpu_do[8];
	wire [7:0]slot_act;
	
	
	gg_slot gg0(.slot(6'h00), .clk(clk), .cpu(cpu), .prg_do(prg_do), .pi(pi), .slot_act(slot_act[0]), .cpu_do(cpu_do[0]));
	gg_slot gg1(.slot(6'h01), .clk(clk), .cpu(cpu), .prg_do(prg_do), .pi(pi), .slot_act(slot_act[1]), .cpu_do(cpu_do[1]));
	gg_slot gg2(.slot(6'h02), .clk(clk), .cpu(cpu), .prg_do(prg_do), .pi(pi), .slot_act(slot_act[2]), .cpu_do(cpu_do[2]));
	gg_slot gg3(.slot(6'h03), .clk(clk), .cpu(cpu), .prg_do(prg_do), .pi(pi), .slot_act(slot_act[3]), .cpu_do(cpu_do[3]));
	gg_slot gg4(.slot(6'h04), .clk(clk), .cpu(cpu), .prg_do(prg_do), .pi(pi), .slot_act(slot_act[4]), .cpu_do(cpu_do[4]));
	gg_slot gg5(.slot(6'h05), .clk(clk), .cpu(cpu), .prg_do(prg_do), .pi(pi), .slot_act(slot_act[5]), .cpu_do(cpu_do[5]));
	gg_slot gg6(.slot(6'h06), .clk(clk), .cpu(cpu), .prg_do(prg_do), .pi(pi), .slot_act(slot_act[6]), .cpu_do(cpu_do[6]));
	gg_slot gg7(.slot(6'h07), .clk(clk), .cpu(cpu), .prg_do(prg_do), .pi(pi), .slot_act(slot_act[7]), .cpu_do(cpu_do[7]));
	

endmodule


module gg_slot(
	
	input  clk,
	input  PiBus pi,
	input  CpuBus cpu,
	input  [5:0]slot,
	input  [7:0]prg_do,
	
	output slot_act,
	output [7:0]cpu_do
);

	assign cpu_do[7:0] 	= slot_act ? code[3][7:0] : 8'h00;
	
	assign slot_act		= cpu.m2 & cpu.rw & rd_ok & code_eq;
	
	wire gg_ce 				= pi.map.ce_ggc & pi.addr[7:2] == slot[5:0];
	wire gg_we 				= gg_ce & pi.we & pi.act;
	wire code_eq 			=  addr_eq & (data_eq | data_cmp_off);
	wire addr_eq 			= {1'b1, cpu.addr[14:0]} == {code[1][7:0], code[0][7:0]};//0x8000-0xffff area. upper bit turn on/off slot
	wire data_eq 			= prg_do[7:0]  == code[2][7:0];
	wire data_cmp_off 	= code[3][7:0] == code[2][7:0];
	
	reg [7:0]code[4];
	
	always @(posedge clk)
	if(gg_we)
	begin
		code[pi.addr[1:0]][7:0] <= pi.dato[7:0];		
	end
	
	
	//wire rd_le = rd_delay == 6;
	wire rd_ok = rd_delay == 4;//+1 at rd_st latch delay
	
	reg [3:0]rd_delay;
	reg rd_st;
	
	always @(posedge clk)
	begin
		
		rd_st <= cpu.m2 | cpu.rw;
		
		if(!rd_st)rd_delay <= 0;
			else
		if(!rd_ok)rd_delay <= rd_delay + 1;
		
	end
	
endmodule
	
