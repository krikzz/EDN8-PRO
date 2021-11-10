`include "../base/defs.v"


module map_hub
(sys_cfg, bus, map_out, ss_ctrl);

	
	`include "../base/sys_cfg_in.v"
	
	input [`BW_SYS_CFG-1:0]sys_cfg;
	input [`BW_SYS_BUS-1:0]bus;
	output [`BW_MAP_OUT-1:0]map_out;
	input [`BW_SS_CTRL-1:0]ss_ctrl;
	
	
	assign map_out = 
	map_idx == 261 ? map_out_261 :
	map_idx == 262 ? map_out_262 :
	map_idx == 290 ? map_out_290 :
	map_idx == 389 ? map_out_389 :
	map_idx == 516 ? map_out_516 :
	map_out_nom;
	
	
	wire [`BW_MAP_OUT-1:0]map_out_nom;
	map_nom mnom(map_out_nom, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_261;
	map_261 m261(map_out_261, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_262;
	map_262 m262(map_out_262, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_290;
	map_290 m290(map_out_290, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_389;
	map_389 m389(map_out_389, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_516;
	map_516 m516(map_out_516, bus, sys_cfg, ss_ctrl);
	
endmodule
