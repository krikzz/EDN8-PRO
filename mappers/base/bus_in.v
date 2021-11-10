	


	input [`BW_SYS_BUS-1:0]bus;

	
	//cpu bus
	wire [7:0]cpu_dat;
	wire [15:0]cpu_addr;
	wire cpu_ce, cpu_rw, m2, m3;
	
	//ppu bus
	wire [7:0]ppu_dat;
	wire [13:0]ppu_addr;
	wire ppu_oe, ppu_we, clk, map_rst, sys_rst, fds_sw, os_act;
	
	//memory data bus
	wire [7:0]chr_dat, prg_dat;

	assign {
	chr_dat[7:0], prg_dat[7:0], m3, os_act, fds_sw, sys_rst, 
	map_rst, clk, ppu_we, ppu_oe, ppu_addr[13:0], ppu_dat[7:0], 
	m2, cpu_rw, cpu_addr[15:0], cpu_dat[7:0]} = bus[`BW_SYS_BUS-1:0];
	
	assign cpu_ce = !cpu_addr[15];