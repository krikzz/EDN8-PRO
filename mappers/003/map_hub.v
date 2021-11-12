
`include "../base/defs.v"

module map_hub
(sys_cfg, bus, map_out, ss_ctrl);

	
	`include "../base/sys_cfg_in.v"
	
	input [`BW_SYS_CFG-1:0]sys_cfg;
	input [`BW_SYS_BUS-1:0]bus;
	output [`BW_MAP_OUT-1:0]map_out;
	input [`BW_SS_CTRL-1:0]ss_ctrl;
	
	
	//? means not tested
	assign map_out = 
	//map_idx == 79  ? map_out_079 ://ave/sachen/hes multi
	map_idx == 90  ? map_out_090 : 
	/*
	map_idx == 113 ? map_out_079 ://ave/sachen/hes multi
	map_idx == 133 ? map_out_133 ://sachen
	map_idx == 137 ? map_out_137 : 
	map_idx == 138 ? map_out_137 : 
	map_idx == 139 ? map_out_137 : 
	map_idx == 141 ? map_out_137 : 
	map_idx == 146 ? map_out_079 : //ave/sachen/hes multi
	map_idx == 147 ? map_out_147 : 
	map_idx == 148 ? map_out_148 : //sachen	
	map_idx == 150 ? map_out_243 : //sachen
	map_idx == 211 ? map_out_090 : 
	map_idx == 243 ? map_out_243 : //sachen
	*/
	map_out_nom;
	
	
	wire [`BW_MAP_OUT-1:0]map_out_nom;
	map_nom mnom(map_out_nom, bus, sys_cfg, ss_ctrl);
/*
	wire [`BW_MAP_OUT-1:0]map_out_079;
	map_079 m079(map_out_079, bus, sys_cfg, ss_ctrl);*/
	
	wire [`BW_MAP_OUT-1:0]map_out_090;
	map_090 m090(map_out_090, bus, sys_cfg, ss_ctrl);
	
	/*
	wire [`BW_MAP_OUT-1:0]map_out_133;
	map_133 m133(map_out_133, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_137;
	map_137 m137(map_out_137, bus, sys_cfg, ss_ctrl);
			
	wire [`BW_MAP_OUT-1:0]map_out_147;
	map_147 m147(map_out_147, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_148;
	map_148 m148(map_out_148, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_243;
	map_243 m243(map_out_243, bus, sys_cfg, ss_ctrl);*/
	
endmodule
