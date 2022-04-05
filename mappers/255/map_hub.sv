`include "../base/defs.v"


module map_hub(
	
	input [`BW_SYS_CFG-1:0]sys_cfg,
	input [`BW_SYS_BUS-1:0]bus,
	output [`BW_MAP_OUT-1:0]map_out,
	input [`BW_SS_CTRL-1:0]ss_ctrl,
	
	input MapIn mai
	
);

	
	`include "../base/sys_cfg_in.v"
	
	
	
	
	assign map_out = map_out_nom;
	
	
	wire [`BW_MAP_OUT-1:0]map_out_nom;
	map_nom mnom(map_out_nom, bus, sys_cfg, ss_ctrl);
	
endmodule
