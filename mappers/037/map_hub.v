
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
	map_idx == 35  ? map_out_035 : //+ ?
	map_idx == 37  ? map_out_037 : //+
	map_idx == 44  ? map_out_044 : //+
	map_idx == 45  ? map_out_045 : //+
	map_idx == 49  ? map_out_049 : //+
	map_idx == 51  ? map_out_051 : //+
	map_idx == 52  ? map_out_052 : //+
	map_idx == 60  ? map_out_060 : //+ bad switch (map_rst??)
	map_idx == 105 ? map_out_105 : //+
	map_idx == 144 ? map_out_144 : //+ already implemented in map pack 001 ? 
	map_idx == 177 ? map_out_177 : //+
	map_idx == 197 ? map_out_197 : //+
	map_idx == 214 ? map_out_214 : //+
	map_idx == 229 ? map_out_229 : //+
	map_idx == 238 ? map_out_238 : //+ ?
	map_idx == 244 ? map_out_244 : //+
	map_idx == 248 ? map_out_248 : //+
	map_idx == 249 ? map_out_249 : //+
	map_idx == 250 ? map_out_250 : //+
	map_out_nom;
	
	
	wire [`BW_MAP_OUT-1:0]map_out_nom;
	map_nom mnom(map_out_nom, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_035;
	map_035 m035(map_out_035, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_037;
	map_037 m037(map_out_037, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_044;
	map_044 m044(map_out_044, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_045;
	map_045 m045(map_out_045, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_049;
	map_049 m049(map_out_049, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_051;
	map_051 m051(map_out_051, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_052;
	map_052 m052(map_out_052, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_060;
	map_060 m060(map_out_060, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_105;
	map_105 m105(map_out_105, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_144; 
	map_144 m144(map_out_144, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_177;
	map_177 m177(map_out_177, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_197;
	map_197 m197(map_out_197, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_214;
	map_214 m214(map_out_214, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_229;
	map_229 m229(map_out_229, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_238;
	map_238 m238(map_out_238, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_244;
	map_244 m244(map_out_244, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_248;
	map_248 m248(map_out_248, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_249;
	map_249 m249(map_out_249, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_250;
	map_250 m250(map_out_250, bus, sys_cfg, ss_ctrl);
	
endmodule
