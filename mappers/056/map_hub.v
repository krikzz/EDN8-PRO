
`include "../base/defs.v"

module map_hub
(sys_cfg, bus, map_out, ss_ctrl);

	
	`include "../base/sys_cfg_in.v"
	
	input [`BW_SYS_CFG-1:0]sys_cfg;
	input [`BW_SYS_BUS-1:0]bus;
	output [`BW_MAP_OUT-1:0]map_out;
	input [`BW_SS_CTRL-1:0]ss_ctrl;
	
	
	//? means not tested
	assign map_out = //2.8k
	map_idx == 56  ? map_out_056 :
	map_idx == 103 ? map_out_103 :
	map_idx == 132 ? map_out_132 :
	map_idx == 134 ? map_out_134 :
	map_idx == 136 ? map_out_136 :
	map_idx == 172 ? map_out_172 :
	map_idx == 173 ? map_out_173 :
	map_idx == 186 ? map_out_186 :
	map_idx == 187 ? map_out_187 :
	map_idx == 221 ? map_out_221 :
	map_idx == 254 ? map_out_254 ://?
	map_out_nom;
	
	
	wire [`BW_MAP_OUT-1:0]map_out_nom;
	map_nom mnom(map_out_nom, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_056 ;
	map_056 m056 (map_out_056 , bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_103;
	map_103 m103(map_out_103, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_132;
	map_132 m132(map_out_132, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_134;
	map_134 m134(map_out_134, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_136;
	map_136 m136(map_out_136, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_172;
	map_172 m172(map_out_172, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_173;
	map_173 m173(map_out_173, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_186;
	map_186 m186(map_out_186, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_187;
	map_187 m187(map_out_187, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_221;
	map_221 m221(map_out_221, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_254;
	map_254 m254(map_out_254, bus, sys_cfg, ss_ctrl);	

	
endmodule
