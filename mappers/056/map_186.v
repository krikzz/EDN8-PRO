
`include "../base/defs.v"

module map_186
(map_out, bus, sys_cfg, ss_ctrl); //no mapper

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
	parameter MAP_NUM = 8'd27;
	assign ss_rdat[7:0] = 
	ss_addr[7:0] == 0 ? prg_bank[7:0] : 
	ss_addr[7:0] == 1 ? {1'b0, tape_ready_delay[6:0]} : 
	ss_addr[7:0] == 2 ? {4'd0, tape_ready, read_reg, ram_bank[1:0]} : 
	ss_addr[7:0] == 127 ? MAP_NUM : 8'hff;
	//*************************************************************
	
	wire ram_area = cpu_addr[14:13] == 2'b11 & cpu_ce;
	wire save_area = cpu_addr[15:12] == 4'h4 & cpu_addr[11:0] >= 12'h400;
	assign ram_we = !cpu_rw;
	assign ram_ce = (ram_area | save_area) & m2;
	assign rom_ce = !cpu_ce;
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;//if cfg_chr_ram == 1 means that we don't have CHR rom, only CHR ram
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = cfg_mir_v ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[12:0] = save_area ? {1'b0, cpu_addr[11:0] - 12'h400} : cpu_addr[12:0];
	assign prg_addr[18:13] = cpu_ce ? (save_area ? 0 : {4'd0, ram_bank[1:0]}) : 
	!cpu_addr[14] ? {prg_bank[4:0], cpu_addr[13]} : {5'd0, cpu_addr[13]};
	
	assign chr_addr[12:0] = ppu_addr[12:0];
	
	//****************************************************************** Read
	assign map_cpu_oe = cpu_ce & cpu_rw & m2 & cpu_addr[14:4] == 11'h420  & cpu_addr[3:2] == 2'b00;
	assign map_cpu_dout[7:0] = 
	cpu_addr[1:0] == 1 ? 8'h10 :
	cpu_addr[1:0] == 2 & tape_ready ? 8'h40 : 0;

	//*****************************************************
	
	reg [1:0]ram_bank;
	reg [7:0]prg_bank;
	reg tape_ready;
	reg [6:0]tape_ready_delay;
	reg read_reg;
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 0) prg_bank[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 1) tape_ready_delay[6:0] <= cpu_dat[6:0];
		if(ss_we & ss_addr[7:0] == 2) {tape_ready, read_reg, ram_bank[1:0]} <= cpu_dat[3:0];
	end
	else
	begin
		if(!cpu_rw & cpu_ce & cpu_addr[14:4] == 11'h420  & cpu_addr[3:2] == 2'b00)
		case(cpu_addr[1:0])
			
			0: ram_bank[1:0] <= cpu_dat[7:6];
			1: prg_bank[7:0] <= cpu_dat[7:0];
			2: begin
				read_reg <= cpu_dat[4];
				tape_ready_delay <= 100;
			end
			
		endcase
		
		if(tape_ready_delay > 0) begin
			tape_ready_delay <= tape_ready_delay - 1;
			if(tape_ready_delay - 1 == 0) tape_ready <= read_reg;
		end
	end

endmodule
