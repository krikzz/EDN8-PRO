
`include "../base/defs.v"

module map_157
(map_out, bus, sys_cfg, ss_ctrl);

	`include "../base/bus_in.v"
	`include "../base/map_out.v"
	`include "../base/sys_cfg_in.v"
	`include "../base/ss_ctrl_in.v"
	
	output [`BW_MAP_OUT-1:0]map_out;
	input [`BW_SYS_CFG-1:0]sys_cfg;
	
	
	
	assign sync_m2 = 1;
	assign mir_4sc = 0;//enable support for 4-screen mirroring. for activation should be ensabled in sys_cfg also

	assign prg_oe = cpu_rw;
	assign chr_oe = !ppu_oe;
	//*************************************************************  save state setup
	assign ss_rdat[7:0] = 
	ss_addr[7:3] == 0 ? chr[ss_addr[2:0]] :
	ss_addr[7:0] == 8 ? prg : 
	ss_addr[7:0] == 9 ? irq_ctr[15:8] : 
	ss_addr[7:0] == 10 ? irq_ctr[7:0] : 
	ss_addr[7:0] == 11 ? irq_latch[15:8] : 
	ss_addr[7:0] == 12 ? irq_latch[7:0] : 
	ss_addr[7:0] == 13 ? {irq_on, irq_pend, mirror_mode[1:0]} : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = 0;
	assign ram_we = 0;
	assign rom_ce = cpu_addr[15];
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = 
	mirror_mode == 0 ? ppu_addr[10] : 
	mirror_mode == 1 ? ppu_addr[11] : mirror_mode[0];
	
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[13:0] = cpu_addr[13:0];
	assign prg_addr[17:14] = !cpu_addr[14] ? prg[3:0] : 4'b1111;

	
	assign chr_addr[12:0] = ppu_addr[12:0];
	
	wire regs_ce = (cpu_addr[15:0] & 16'h8000) == 16'h8000;

	
	reg [7:0]chr[8];
	reg [4:0]prg;
	
	reg [15:0]irq_ctr;
	reg [15:0]irq_latch;
	
	reg [1:0]mirror_mode;
	reg irq_pend;
	reg irq_on;
	
	assign irq = irq_pend;
	
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:3] == 0)chr[ss_addr[2:0]] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 8)prg <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 9)irq_ctr[15:8] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 10)irq_ctr[7:0] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 11)irq_latch[15:8] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 12)irq_latch[7:0] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 13){irq_on, irq_pend, mirror_mode[1:0]} <= cpu_dat;
	end
		else
	if(map_rst)
	begin
		irq_on <= 0;
		irq_pend <= 0;
		prg <= 0;
	end
		else
	begin
			
		if(!cpu_rw & regs_ce & cpu_addr[3:0] == 4'hA)
		begin
			irq_ctr <= irq_latch;
		end
			else
		if(irq_on)
		begin
			irq_ctr <= irq_ctr - 1;
			if(irq_ctr == 0 & irq_pend == 0)irq_pend <= 1;
		end
			
			
				
		if(!cpu_rw & regs_ce & cpu_addr[3] == 0)
		begin
			chr[cpu_addr[2:0]][7:0] <= cpu_dat[7:0];
		end
		
		
		if(!cpu_rw & regs_ce)
		case(cpu_addr[3:0])
			4'h8:begin
				prg[4:0] <= cpu_dat[4:0];
			end
			4'h9:begin
				mirror_mode[1:0] <= cpu_dat[1:0];
			end
			4'hA:begin
				irq_on <= cpu_dat[0];
				irq_pend <= 0;
			end
			4'hB:begin
				irq_latch[7:0] <= cpu_dat[7:0];
			end
			4'hC:begin
				irq_latch[15:8] <= cpu_dat[7:0];
			end
		endcase
	
	end


//************************************************************* eeprom section
	parameter BRAM_OFF    	= 4'h0;
	parameter BRAM_24X01    = 4'h3;
	parameter BRAM_24C01    = 4'h4;
	parameter BRAM_24C02    = 4'h5;
		
	assign eep_on = 1;
	assign map_cpu_oe = cpu_rw & {cpu_addr[15:13], 13'd0} == 16'h6000;
	assign map_cpu_dout[7:0] = {cpu_addr[15:13], (eep_do[0] & eep_do[1]), 1'b0, cpu_addr[10:8]};
	assign map_led = led_eep;
	

	assign eep_we = ram_we_eep[0] | ram_we_eep[1];
	assign eep_oe = ram_oe_eep[0] | ram_oe_eep[1];
	
	assign eep_ram_di = ram_we_eep[1] ? eep_mem_di[1] : eep_mem_di[0];
	assign srm_addr[8:0] =  ram_we_eep[1] | ram_oe_eep[1] ? {1'b1, eep_addr[1][7:0]} :  {1'b0, eep_addr[0][7:0]};
	
	wire [7:0]eep_mem_di[2];
	wire [7:0]eep_addr[2];
	wire [1:0]ram_oe_eep, ram_we_eep, led_eep, eep_do;
	
	eep_24cXX_sync eep_int(

		.clk(clk),
		.rst(map_rst | sys_rst),
		.bram_type(BRAM_24C02),
		
		.scl(eep_scl),
		.sda_in(eep_di),
		.sda_out(eep_do[0]),

		.ram_do(prg_dat),
		.ram_di(eep_mem_di[0]),
		.ram_addr(eep_addr[0]),
		.ram_oe(ram_oe_eep[0]), 
		.ram_we(ram_we_eep[0]),
		.led(led_eep[0])
	);
	
	
	
	reg eep_dir, eep_di, eep_scl;
	
	always @(negedge m2)
	if(map_rst)
	begin
		eep_dir <= 1;
		eep_di <= 1;
		eep_scl <= 1;
	end
		else
	if(!cpu_rw)
	begin
		if((cpu_addr[15:0] & 16'h800F) == 16'h800D){eep_dir, eep_di, eep_scl} <= cpu_dat[7:5];
	end
	
	
	
	wire [17:10]chr_a = chr[ppu_addr[11:10]];
	
	
	eep_24cXX_sync eep_ext(

		.clk(clk),
		.rst(map_rst | sys_rst),
		.bram_type(BRAM_24X01),
		
		.scl(chr_a[13]),
		.sda_in(eep_di),
		.sda_out(eep_do[1]),

		.ram_do(prg_dat),
		.ram_di(eep_mem_di[1]),
		.ram_addr(eep_addr[1]),
		.ram_oe(ram_oe_eep[1]), 
		.ram_we(ram_we_eep[1]),
		.led(led_eep[1])
	);
	
endmodule


