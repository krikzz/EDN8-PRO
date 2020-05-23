
`include "../base/defs.v"

module map_hub
(sys_cfg, bus, map_out, ss_ctrl);

	
	`include "../base/sys_cfg_in.v"
	
	input [`BW_SYS_CFG-1:0]sys_cfg;
	input [`BW_SYS_BUS-1:0]bus;
	output [`BW_MAP_OUT-1:0]map_out;
	input [`BW_SS_CTRL-1:0]ss_ctrl;
	
	
	
	assign map_out = 
	map_idx == 30  ? map_out_030 :
	map_idx == 36  ? map_out_036 :
	map_idx == 46  ? map_out_046 :
	map_idx == 83  ? map_out_083 :
	map_idx == 104 ? map_out_104 :
	map_idx == 111 ? map_out_111 :
	map_idx == 162 ? map_out_162 :
	map_idx == 163 ? map_out_163 :
	map_idx == 170 ? map_out_170 :
	map_idx == 190 ? map_out_190 :
	map_idx == 207 ? map_out_207 :
	map_idx == 210 ? map_out_210 :
	map_idx == 218 ? map_out_218 :
	map_idx == 225 ? map_out_225 :
	map_idx == 226 ? map_out_226 :
	map_idx == 228 ? map_out_228 :
	map_idx == 230 ? map_out_230 :
	map_idx == 233 ? map_out_233 :
	map_idx == 235 ? map_out_235 :
	map_out_nom;
	
	
	wire [`BW_MAP_OUT-1:0]map_out_nom;
	map_nom mnom(map_out_nom, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_030;
	map_030 m030(map_out_030, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_036;
	map_036 m036(map_out_036, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_046;
	map_046 m046(map_out_046, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_083;
	map_083 m083(map_out_083, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_104;
	map_104 m104(map_out_104, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_111;
	map_111 m111(map_out_111, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_163;
	map_163 m163(map_out_163, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_162;
	map_162 m162(map_out_162, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_170;
	map_170 m170(map_out_170, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_190;
	map_190 m190(map_out_190, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_207;
	map_207 m207(map_out_207, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_210;
	map_210 m210(map_out_210, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_218;
	map_218 m218(map_out_218, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_225;
	map_225 m225(map_out_225, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_226;
	map_226 m226(map_out_226, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_228;
	map_228 m228(map_out_228, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_230;
	map_230 m230(map_out_230, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_233;
	map_233 m233(map_out_233, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_235;
	map_235 m235(map_out_235, bus, sys_cfg, ss_ctrl);

endmodule
