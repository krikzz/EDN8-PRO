
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
	map_idx == 27  ? map_out_027 : 
	map_idx == 50  ? map_out_050 : 
	map_idx == 106 ? map_out_106 : 
	map_idx == 108 ? map_out_108 : 
	map_idx == 117 ? map_out_117 :			
	map_idx == 142 ? map_out_142 : 
	map_idx == 143 ? map_out_143 : 		
	map_idx == 145 ? map_out_145 : 
	map_idx == 149 ? map_out_149 : 
	map_idx == 156 ? map_out_156 : 
	map_idx == 165 ? map_out_165 : 
	map_idx == 171 ? map_out_171 : 
	map_idx == 175 ? map_out_175 : 
	map_idx == 176 ? map_out_176 : 
	map_idx == 183 ? map_out_183 :		
	map_idx == 199 ? map_out_199 :	//*	
	map_idx == 213 ? map_out_213 : 
	map_idx == 216 ? map_out_216 : 
	map_idx == 222 ? map_out_222 : 
	map_idx == 252 ? map_out_252 : 
	map_out_nom;
	
	
	wire [`BW_MAP_OUT-1:0]map_out_nom;
	map_nom mnom(map_out_nom, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_027;
	map_027 m027(map_out_027, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_050;
	map_050 m050(map_out_050, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_106;
	map_106 m106(map_out_106, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_108;
	map_108 m108(map_out_108, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_117;
	map_117 m117(map_out_117, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_142;
	map_142 m142(map_out_142, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_143;
	map_143 m143(map_out_143, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_145;
	map_145 m145(map_out_145, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_149;
	map_149 m149(map_out_149, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_156;
	map_156 m156(map_out_156, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_165;
	map_165 m165(map_out_165, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_171;
	map_171 m171(map_out_171, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_175;
	map_175 m175(map_out_175, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_176;
	map_176 m176(map_out_176, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_183;
	map_183 m183(map_out_183, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_199;
	map_199 m199(map_out_199, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_213;
	map_213 m213(map_out_213, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_216;
	map_216 m216(map_out_216, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_222;
	map_222 m222(map_out_222, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_252;
	map_252 m252(map_out_252, bus, sys_cfg, ss_ctrl);
	
	
endmodule
