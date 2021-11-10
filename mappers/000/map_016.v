
`include "../base/defs.v"

module map_016
(map_out, bus, sys_cfg, ss_ctrl);

	`include "../base/bus_in.v"
	`include "../base/map_out.v"
	`include "../base/sys_cfg_in.v"
	`include "../base/ss_ctrl_in.v"
	
	output [`BW_MAP_OUT-1:0]map_out;
	input [`BW_SYS_CFG-1:0]sys_cfg;
	
	
	
	assign sync_m2 = 1;
	assign mir_4sc = 0;//enable support for 4-screen mirroring. for activation should be ensabled in sys_cfg also
	assign srm_addr[7:0] = eep_addr[7:0];
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
	assign prg_addr[21:14] = !cpu_addr[14] ? prg[7:0] : 8'hff;

	
	assign chr_addr[9:0] = ppu_addr[9:0];
	assign chr_addr[17:10] = chr[ppu_addr[12:10]];

	
	wire regs_ce_s4 = (cpu_addr[15:0] & 16'hE000) == 16'h6000;
	wire regs_ce_s5 = (cpu_addr[15:0] & 16'h8000) == 16'h8000;
	wire regs_ce = 
	map_idx == 16 & map_sub == 4 ? regs_ce_s4 : 
	map_idx == 16 & map_sub == 5 ? regs_ce_s5 : 
	map_idx == 159 ? regs_ce_s5 : 
	regs_ce_s4 | regs_ce_s5;
	
	reg [7:0]chr[8];
	reg [7:0]prg;
	
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

	
		if(!cpu_rw & regs_ce_s5 & cpu_addr[3:0] == 4'hA)
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
				prg[7:0] <= cpu_dat[7:0];
			end
			4'h9:begin
				mirror_mode[1:0] <= cpu_dat[1:0];
			end
			4'hA:begin
				irq_on <= cpu_dat[0];
				irq_pend <= 0;
			end
			4'hB:begin
				if(regs_ce_s4)irq_ctr[7:0] <= cpu_dat[7:0];
				if(regs_ce_s5)irq_latch[7:0] <= cpu_dat[7:0];
			end
			4'hC:begin
				if(regs_ce_s4)irq_ctr[15:8] <= cpu_dat[7:0];
				if(regs_ce_s5)irq_latch[15:8] <= cpu_dat[7:0];
			end
		endcase
	
	end


//************************************************************* eeprom section
	parameter BRAM_OFF    	= 4'h0;
	parameter BRAM_24X01    = 4'h3;
	parameter BRAM_24C01    = 4'h4;
	parameter BRAM_24C02    = 4'h5;
		
	wire [3:0]bram_type = 
	srm_size == 128 ? BRAM_24X01 :
	srm_size == 256 ? BRAM_24C02 :
	map_idx  == 159 ? BRAM_24X01 :
	map_idx  == 16  & map_sub != 4 ? BRAM_24C02 :
	BRAM_OFF;

	
	assign map_cpu_oe = eep_on & cpu_rw & {cpu_addr[15:13], 13'd0} == 16'h6000;
	assign map_cpu_dout[7:0] = {cpu_addr[15:13], eep_do, cpu_addr[11:8]};
	assign map_led = eep_on & led_eep;
	
	
	assign eep_on = bram_type != BRAM_OFF;
	assign eep_we = eep_on & ram_we_eep;
	assign eep_oe = eep_on & ram_oe_eep;

	wire [7:0]eep_addr;
	wire ram_oe_eep, ram_we_eep, led_eep, eep_do;
	
	eep_24cXX_sync eep_inst(

		.clk(clk),
		.rst(map_rst | sys_rst | !eep_on),
		.bram_type(bram_type),
		
		.scl(eep_scl),
		.sda_in(eep_di),
		.sda_out(eep_do),

		.ram_do(prg_dat),
		.ram_di(eep_ram_di),
		.ram_addr(eep_addr),
		.ram_oe(ram_oe_eep), 
		.ram_we(ram_we_eep),
		.led(led_eep)
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
	
	
	
endmodule


