
`include "../base/defs.v"

module map_dma
(
	mao,
	map_out, bus,   
	pi_bus, pi_di, dma_req
	
);
	
	
	output MapOut mao;
	
	
	MemCtrl prg;
	MemCtrl chr;
	MemCtrl srm;
	assign mao.prg = prg;
	assign mao.chr = chr;
	assign mao.srm = srm;
	
	output [`BW_MAP_OUT-1:0]map_out;
	output [7:0]pi_di;
	output dma_req;
	
	`include "../base/bus_in.v"
	`include "../base/map_out.v"
	`include "../base/pi_bus.v"
	
	
	assign srm_mask_off = 1;
	assign chr_mask_off = 1;
	assign prg_mask_off = 1;
	assign sync_m2 = 0;
	assign mir_4sc = 0;
	assign srm_addr[17:0] = prg.addr[17:0];
	wire [9:0]prg_msk;
	wire [9:0]chr_msk;
	wire [10:0]srm_msk;
	wire cfg_prg_ram_off = 0;
	wire srm_mask_max;
	wire cfg_chr_ram = 0;
	//*************************************************************


	assign ram_ce = pi_ce_srm;
	assign ram_we = pi_we;
	
	assign rom_ce = pi_ce_prg;
	assign rom_we = pi_we;
	
	assign chr_ce = pi_ce_chr;
	assign chr_we = pi_we;
	
	assign prg_oe = pi_oe;
	assign chr_oe = pi_oe;
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = 0;
	assign ciram_ce = 1;
	
	assign prg.addr[22:0] = pi_addr[22:0];
	assign chr.addr[22:0] = pi_addr[22:0];
	
	assign map_cpu_oe = pi_we;
	assign map_ppu_oe = pi_we;
	
	
	assign map_cpu_dout[7:0] = pi_do[7:0];
	assign map_ppu_dout[7:0] = pi_do[7:0];
	
	assign dma_req = pi_dma_req;

	assign pi_di[7:0] = pi_ce_chr ? chr_dat[7:0] : prg_dat[7:0];
	
	assign mem_dma = 1;
	
endmodule




