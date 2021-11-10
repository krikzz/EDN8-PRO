
`include "../base/defs.v"


module map_hub
(sys_cfg, bus, map_out, ss_ctrl);

	
	`include "../base/sys_cfg_in.v"
	
	input [`BW_SYS_CFG-1:0]sys_cfg;
	input [`BW_SYS_BUS-1:0]bus;
	output [`BW_MAP_OUT-1:0]map_out;
	input [`BW_SS_CTRL-1:0]ss_ctrl;
	
	assign map_out = 
	map_idx == 21 ? map_out_021 : 
	map_idx == 22 ? map_out_021 : 
	map_idx == 23 ? map_out_021 : 
	map_idx == 24 ? map_out_024 : 
	map_idx == 25 ? map_out_021 : 
	map_idx == 26 ? map_out_024 : 
	map_idx == 73 ? map_out_073 : 
	map_idx == 75 ? map_out_075 : 
	map_idx == 151 ? map_out_075 : //vs mapper
	map_out_nom;
	
	
	wire [`BW_MAP_OUT-1:0]map_out_nom;
	map_nom mnom(map_out_nom, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_021;//vrc4+vrc2
	map_021 m021(map_out_021, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_024;//vrc6
	map_024 m024(map_out_024, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_073;//vrc3
	map_073 m073(map_out_073, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_075;//vrc1
	map_075 m075(map_out_075, bus, sys_cfg, ss_ctrl);
	
endmodule
