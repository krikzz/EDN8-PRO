
`include "../base/defs.v"

module map_hub
(sys_cfg, bus, map_out, ss_ctrl);

	
	`include "../base/sys_cfg_in.v"
	
	input [`BW_SYS_CFG-1:0]sys_cfg;
	input [`BW_SYS_BUS-1:0]bus;
	output [`BW_MAP_OUT-1:0]map_out;
	input [`BW_SS_CTRL-1:0]ss_ctrl;
	
	
	
	assign map_out = 
	map_idx == 1   ? map_out_001 : 
	map_idx == 4   & map_sub == 1 ? map_out_004_s1 : 
	map_idx == 4   & map_sub == 3 ? map_out_004_s3 :
	map_idx == 4   ? map_out_004 : 
	map_idx == 9   ? map_out_009 : 
	map_idx == 10  ? map_out_009 : 
	map_idx == 155 ? map_out_001 :
	map_out_nom;
	
	
	wire [`BW_MAP_OUT-1:0]map_out_nom;
	map_nom mnom(map_out_nom, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_001;
	map_001 m001(map_out_001, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_004;
	map_004 m004(map_out_004, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_009;
	map_009 m009(map_out_009, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_004_s1;
	map_004_s1 m004_s1(map_out_004_s1, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_004_s3;
	map_004_s3 m004_s3(map_out_004_s3, bus, sys_cfg, ss_ctrl);
	
endmodule
