
	
module sys_cfg(
	
	input clk,
	input PiBus pi,
	
	output [7:0]pi_di,
	
	output SysCfg cfg
);
	
	
	wire [11:0]map_idx 		= {scfg[2][7:4], scfg[0][7:0]};
	wire [7:0]prg_mask		= scfg[1][7:0];
	wire [3:0]chr_mask		= scfg[2][3:0];
	wire [7:0]master_vol		= scfg[3][7:0];
	wire [7:0]map_cfg			= scfg[4][7:0];//mappers may use bits 7-4 for own custom conigs
	wire [7:0]ss_key_save	= scfg[5][7:0];
	wire [7:0]ss_key_load	= scfg[6][7:0];
	wire [7:0]ctrl				= scfg[7][7:0];
	wire [7:0]ss_key_menu	= scfg[8][7:0];
	
	
	
	assign cfg.map_idx[11:0]		= map_idx[11:0];
	assign cfg.prg_msk[9:0]  		= (1'b1 << prg_mask[3:0])-1;
	assign cfg.srm_msk[10:0] 		= (1'b1 << prg_mask[7:4])-1;
	assign cfg.chr_msk[9:0]  		= (1'b1 << chr_mask[3:0])-1;
	assign cfg.master_vol[7:0]		= master_vol[7:0];
	assign cfg.ss_key_save[7:0]	= ss_key_save[7:0];
	assign cfg.ss_key_load[7:0]	= ss_key_load[7:0];
	assign cfg.ss_key_menu[7:0]	= ss_key_menu[7:0];
	
	assign cfg.ct_rst_delay			= ctrl[0];//with this option quick reset will reset the game but will not return to menu
	assign cfg.ct_ss_on     		= ctrl[1];//vblank hook for in-game menu
	assign cfg.ct_gg_on     		= ctrl[2];//cheats engine
	assign cfg.ct_ss_btn    		= ctrl[3];//use external button for in-game menu
	assign cfg.ct_fami 	  			= ctrl[4];//cartridge form-factor (0-nes, 1-famicom)
	assign cfg.ct_unlock    		= ctrl[7];//used for mapper status check at 0x4080 during reboot. force map 255 till mapper is not configured
	
	
	assign cfg.mir_h 					= map_cfg[1:0] == 2'b00;
	assign cfg.mir_v 					= map_cfg[1:0] == 2'b01;
	assign cfg.mir_4 					= map_cfg[1:0] == 2'b10;
	assign cfg.mir_1 					= map_cfg[1:0] == 2'b11;
	assign cfg.chr_ram 				= map_cfg[2];
	assign cfg.prg_ram_off 			= map_cfg[3];//check if it handled
	assign cfg.map_sub[3:0]			= map_cfg[7:4];
	
	assign cfg.srm_size[18:0]		= (1'b1 << prg_mask[7:4]) << 7;//exact ram size detection. Used for some eeprom mappers and mmc5

	
//************************************************************* config r/w
	assign pi_di[7:0] = scfg[pi.addr[3:0]];
	
	reg [7:0]scfg[16];
	reg cfg_we;
	
	always @(posedge clk)
	begin
		
		cfg_we <= pi.act & pi.we & pi.map.ce_cfg;
		
		if(cfg_we)
		begin
			scfg[pi.addr[3:0]][7:0] <= pi.dato[7:0];
		end
		
	end
	


endmodule
