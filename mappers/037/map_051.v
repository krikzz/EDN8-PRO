
`include "../base/defs.v"

module map_051
(map_out, bus, sys_cfg, ss_ctrl); 

	`include "../base/bus_in.v"
	`include "../base/map_out.v"
	`include "../base/sys_cfg_in.v"
	`include "../base/ss_ctrl_in.v"
	
	output [`BW_MAP_OUT-1:0]map_out;
	input [`BW_SYS_CFG-1:0]sys_cfg;
	
	
	assign sync_m2 = 1;
	assign mir_4sc = 0;//enable support for 4-screen mirroring. for activation should be ensabled in sys_cfg also
	assign srm_addr[12:0] = cpu_addr[12:0];
	assign prg_oe = cpu_rw;
	assign chr_oe = !ppu_oe;
	//*************************************************************  save state setup
	assign ss_rdat[7:0] = 
	ss_addr[7:0] == 0 ? {4'h0, bank[3:0]}:
	ss_addr[7:0] == 1 ? {6'h00, mode[1:0]}:
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************

	assign ram_we = !cpu_rw & ram_ce;
	assign ram_ce = 0; //cpu_addr[14:13] == 2'b11 & cpu_ce & m2;
	assign rom_ce = !cpu_ce | (cpu_addr[14:13] == 2'b11 & cpu_ce);
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;//if cfg_chr_ram == 1 means that we don't have CHR rom, only CHR ram
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = mode == 3 ? ppu_addr[11] : ppu_addr[10];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[12:0] = cpu_addr[12:0];
	assign prg_addr[18:13] =  cpu_ce ?  prg_bank0 : prg_bank[5:0];//
	
	assign chr_addr[12:0] = ppu_addr[12:0];
	
	wire [5:0] prg_bank0 =
	mode[0] ? {1'b1, bank[2:0], 2'b11} : {1'b1, bank[2], 4'hf};

	wire [5:0] prg_bank = 
	mode[1:0] == 0 ? prg_mode0 :
	//mode[1:0] == 1 ? prg_mode1 :
	mode[1:0] == 2 ? prg_mode2 : prg_mode1;
	
	wire [5:0] prg_mode0 =
	{!cpu_ce, cpu_addr[14:13]} == 3'b011 ? {1'b1, bank[2], 4'hF} :
	{!cpu_ce, cpu_addr[14:13]} == 3'b100 ? {bank, 2'b00} :
	{!cpu_ce, cpu_addr[14:13]} == 3'b101 ? {bank, 2'b01} :
	{!cpu_ce, cpu_addr[14:13]} == 3'b110 ? {bank[3:2],4'hE} : {bank[3:2],4'hF};
	
	wire [5:0] prg_mode1 =
	{!cpu_ce, cpu_addr[14:13]} == 3'b011 ? {1'b1, bank[3:1], 2'b11} :
	{!cpu_ce, cpu_addr[14:13]} == 3'b100 ? {bank, 2'b00} :
	{!cpu_ce, cpu_addr[14:13]} == 3'b101 ? {bank, 2'b01} :
	{!cpu_ce, cpu_addr[14:13]} == 3'b110 ? {bank, 2'b10} : {bank, 2'b11};
	
	wire [5:0] prg_mode2 =
	{!cpu_ce, cpu_addr[14:13]} == 3'b011 ? {1'b1, bank[2], 4'hF} :
	{!cpu_ce, cpu_addr[14:13]} == 3'b100 ? {bank, 2'b10} :
	{!cpu_ce, cpu_addr[14:13]} == 3'b101 ? {bank, 2'b11} :
	{!cpu_ce, cpu_addr[14:13]} == 3'b110 ? {bank[3:2], 4'hE} : {bank[3:2], 4'hF};
	/*
	wire [5:0] prg_bank = 
	mode[0] ? prg_mode0 : prg_mode1;
	
	wire [5:0] prg_mode0 =  
	{!cpu_ce, cpu_addr[14:13]} == 3'b011 ? {1'b1, bank[2:0], 2'b11} :
	{!cpu_ce, cpu_addr[14]} == 2'b10 ?  {bank[3:0], 1'b0, cpu_addr[13]} : {bank[3:0], 1'b1, cpu_addr[13]};
	
	wire [5:0] prg_mode1 =  
	{!cpu_ce, cpu_addr[14:13]} == 3'b011 ? {1'b1, bank[2], 4'hf} :
	{!cpu_ce, cpu_addr[14]} == 2'b10 ? {bank[3:0], mode[1], cpu_addr[13]} : {bank[3:2], 3'b111, cpu_addr[13]};
	
	initial 
	begin
			bank <= 0;
			mode <= 2'b01;
	end
*/
	reg [3:0]bank;
	reg [1:0]mode;
	
	always @ (negedge m2)begin
			if(ss_act)
	begin
		if(ss_we)begin
			case(ss_addr[7:0])
				0: bank <= cpu_dat[3:0];
				1: mode <= cpu_dat[1:0];
			endcase
		end
	end
		else
		 begin
			if(map_rst)begin
				bank <= 0;
				mode <= 2'b01;
			end
			
			if(cpu_ce & cpu_addr[14:13] == 2'b11 & !cpu_rw) mode[1:0] <= {cpu_dat[4], cpu_dat[1]};
		
			else if(!cpu_ce & !cpu_rw) begin
				bank[3:0] <= cpu_dat[3:0];
				if(cpu_addr[14:13] == 2'b10) mode[1:0] <= {cpu_dat[4], mode[0]};
			end
		end
	end
endmodule
