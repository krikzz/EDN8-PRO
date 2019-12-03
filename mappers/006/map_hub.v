
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
	map_idx == 12  ? map_out_012 : //need MMC3A, othervise game hanging at boot-up as it gets stuck in an infinite loop with the IRQ reload set to 0 
	map_idx == 47  ? map_out_047 :
	map_idx == 64  ? map_out_064 :
	map_idx == 74  ? map_out_074 :
	map_idx == 115 ? map_out_115 :
	map_idx == 118 ? map_out_118 :
	map_idx == 119 ? map_out_119 :
	map_idx == 158 ? map_out_118 :
	map_idx == 182 ? map_out_182 :
	map_idx == 189 ? map_out_189 :
	map_idx == 191 ? map_out_119 : // not working
	map_idx == 196 ? map_out_196 :
	map_idx == 205 ? map_out_205 :
	map_idx == 245 ? map_out_074 :
	map_out_nom;
	
	
	wire [`BW_MAP_OUT-1:0]map_out_nom;
	map_nom mnom(map_out_nom, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_012;
	map_012 m012(map_out_012, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_047;
	map_047 m047(map_out_047, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_064;
	map_064 m064(map_out_064, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_074;
	map_074 m074(map_out_074, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_115;
	map_115 m115(map_out_115, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_118;
	map_118 m118(map_out_118, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_119;
	map_119 m119(map_out_119, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_182;
	map_182 m182(map_out_182, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_189;
	map_189 m189(map_out_189, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_196;
	map_196 m196(map_out_196, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_205;
	map_205 m205(map_out_205, bus, sys_cfg, ss_ctrl);
	
endmodule
