
	
	`include "../base/defs.v"
	
	
	//mapper outputs
	wire [22:0]prg_addr, chr_addr;
	wire [7:0]map_cpu_dout, map_ppu_dout, ss_rdat;
	wire ciram_a10, ciram_ce, ram_we, chr_we, irq, chr_oe, prg_oe, chr_ce, ram_ce, rom_ce, pwm, map_cpu_oe, rom_we, map_ppu_oe, mir_4sc, mem_dma, map_led, bus_conflicts;
	
	
	assign map_out[`BW_MAP_OUT-1:0] = 
	{
		 bus_conflicts, map_led, mem_dma, mir_4sc, map_ppu_oe, map_cpu_oe, !pwm, 
		 !irq, !chr_oe, !prg_oe_o, !chr_ce_o, ram_ce_o, !rom_ce_o, !chr_we_o, 
		 !ram_we_o, !rom_we_o, ciram_ce, ciram_a10, chr_addr_out[22:0], 
		 prg_addr_out[22:0], map_ppu_dout[7:0], map_cpu_dout[7:0], ss_rdat[7:0]
	};

	
	
	
	wire sync_m2;
	wire prg_oe_o = sync_m2 ? (m2 & prg_oe & !sys_rst) : prg_oe;
	wire ram_we_o = sync_m2 ? (m2 & ram_we & !sys_rst & m3) : ram_we;
	wire ram_ce_o = sync_m2 ? (m2 & ram_ce & !sys_rst & !cfg_prg_ram_off) : ram_ce;//?
	wire rom_we_o = sync_m2 ? (m2 & rom_we & !sys_rst & m3) : rom_we;
	wire rom_ce_o = sync_m2 ? (m2 & rom_ce & !sys_rst) : rom_ce;		//ISSI PSRAM seems not allows to hold CE active for a long time, otherwise it stops doing refresh cycles and it results lost of data after all.
	wire chr_ce_o = sync_m2 ? (chr_oe | chr_we) & chr_ce : chr_ce;
	wire chr_we_o = sync_m2 ? (chr_we & !sys_rst) : chr_we;
	
	wire prg_mask_off, chr_mask_off, srm_mask_off;
	
	wire [17:0]srm_addr;
	wire [17:0]srm_addr_msk = srm_mask_off ? srm_addr[17:0] : {(srm_addr[17:10] & srm_msk[7:0]), srm_addr[9:0]};
	
	wire [22:0]prg_addr_out = prg_mask_off ? prg_addr_std[22:0] : prg_addr_msk[22:0];
	wire [22:0]chr_addr_out = chr_mask_off ? chr_addr_std[22:0] : chr_addr_msk[22:0];
	
	wire [22:0]prg_addr_std = rom_ce ? prg_addr[22:0] : srm_addr_msk[17:0];
	wire [22:0]chr_addr_std = chr_addr[22:0];
	
	wire [22:0]prg_addr_msk = rom_ce ? {prg_addr[22:21], (prg_addr[20:13] & prg_msk[7:0]), prg_addr[12:0]} : srm_addr_msk[17:0];
	wire [22:0]chr_addr_msk = {chr_addr[22:21], (chr_addr[20:13] & chr_msk[7:0]), chr_addr[12:0]};
	
	
	