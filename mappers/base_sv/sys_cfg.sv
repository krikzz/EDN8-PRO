

module sys_cfg(
	
	input clk,
	input PiBus pi,
	output SysCfg cfg
);
	
	reg [7:0]scfg[16];
	
	always @(posedge clk)
	if(pi.act_sync & pi.we & pi.map.ce_cfg_reg)
	begin
		
		scfg[pi.addr[3:0]][7:0] <= pi.dato[7:0];
		
	end
	
	/*
	reg [7:0]ctrl;
	reg [7:0]map_cfg;
	reg [7:0]prg_mask;
	reg [3:0]chr_mask;
	
	always @(posedge clk)
	if(pi.act_sync & pi.we & pi.map.ce_cfg_reg)
	begin
		
		 case(pi.addr[3:0])
			'h0:cfg.map_idx[7:0]	<= pi.dato[7:0];
			'h1:prg_mask[7:0]		<= pi.dato[7:0];
			'h2:begin
				cfg.map_idx[11:8]	<= pi.dato[7:4];
				chr_mask[3:0]		<= pi.dato[3:0];
			end
			'h3:
			'h4:
			'h5:
			'h6:
			'h7:
		 endcase
		
	end
	
	reg [7:0]scfg[16];
	assign sys_cfg[`BW_SYS_CFG-1:0] = {scfg[8], scfg[7],scfg[6],scfg[5],scfg[4],scfg[3],scfg[2],scfg[1],scfg[0]};
	
	always @(negedge pi_clk)
	begin
		if(pi_ce_cfg_reg & pi_we)scfg[pi_addr[3:0]][7:0] <= pi_do[7:0];
	end*/

endmodule

/*
assign {
	ss_key_menu[7:0],
	ctrl[7:0], 
	ss_key_load[7:0], 
	ss_key_save[7:0], 
	map_cfg[7:0], 
	master_vol[7:0], 
	{map_idx[11:8], chr_msk_in[3:0]}, 
	prg_msk_in[7:0], 
	map_idx[7:0]}*/