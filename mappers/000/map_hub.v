
`include "../base/defs.v"

module map_hub
(sys_cfg, bus, map_out, ss_ctrl);

	
	`include "../base/sys_cfg_in.v"
	
	input [`BW_SYS_CFG-1:0]sys_cfg;
	input [`BW_SYS_BUS-1:0]bus;
	output [`BW_MAP_OUT-1:0]map_out;
	input [`BW_SS_CTRL-1:0]ss_ctrl;
	
	
	assign map_out = 
	map_idx == 0   ? map_out_000 :
	map_idx == 2   ? map_out_002 :
	map_idx == 517 ? map_out_002 :
	map_idx == 3   ? map_out_003 :
	map_idx == 7   ? map_out_007 :
	map_idx == 16  ? map_out_016 :
	map_idx == 18  ? map_out_018 :
	map_idx == 32  ? map_out_032 :
	map_idx == 33  ? map_out_033 :
	map_idx == 38  ? map_out_066 :
	map_idx == 48  ? map_out_033 :
	map_idx == 66  ? map_out_066 :
	map_idx == 71  ? map_out_071 :
	map_idx == 87  ? map_out_087 :
	map_idx == 140 ? map_out_066 :
	map_idx == 153 ? map_out_153 :
	map_idx == 157 ? map_out_157 :
	map_idx == 159 ? map_out_016 :
	map_out_nom;
	
	
	wire [`BW_MAP_OUT-1:0]map_out_nom;
	map_nom mnom(map_out_nom, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_000;
	map_000 m000(map_out_000, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_002;
	map_002 m002(map_out_002, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_003;
	map_003 m003(map_out_003, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_007;
	map_007 m007(map_out_007, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_016;
	map_016 m016(map_out_016, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_018;
	map_018 m018(map_out_018, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_032;
	map_032 m032(map_out_032, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_033;
	map_033 m033(map_out_033, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_066;
	map_066 m066(map_out_066, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_071;
	map_071 m071(map_out_071, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_087;
	map_087 m087(map_out_087, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_153;
	map_153 m153(map_out_153, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_157;
	map_157 m157(map_out_157, bus, sys_cfg, ss_ctrl);
	
endmodule
