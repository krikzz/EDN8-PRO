	
	
	input [`BW_SS_CTRL-1:0]ss_ctrl;
	
	//save state controls
	wire [12:0]ss_addr = ss_ctrl[10:0]; //8k reserved for ss memory, but for now only 2K used
	wire ss_wr_req = ss_ctrl[11];
	wire ss_act = ss_ctrl[12];
	
	wire ss_reg_ce = ss_addr[12:7] == 0;
	wire ss_we = ss_reg_ce & ss_wr_req;//regs we
	
	
	wire ss_snif_ce_ppu = ss_addr[12:7] == 1;
	wire ss_snif_ce_oam = ss_addr[12:8] == 1;
	wire ss_snif_ce = ss_snif_ce_ppu | ss_snif_ce_oam;
	
	
	wire ss_mem_ce = !ss_reg_ce & !ss_snif_ce;
	wire ss_mem_we = ss_mem_ce & ss_wr_req;
	
	
	wire [4:0]ss_bank256 = ss_addr[12:8];
	wire [3:0]ss_bank512 = ss_addr[12:9];
	wire [2:0]ss_bank1KB = ss_addr[12:10];
	
	//remove hardcoded ss_act from top