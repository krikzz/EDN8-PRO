
`include "../base/defs.v"

module map_hub
(sys_cfg, bus, map_out, ss_ctrl);

	
	`include "../base/sys_cfg_in.v"
	
	input [`BW_SYS_CFG-1:0]sys_cfg;
	input [`BW_SYS_BUS-1:0]bus;
	output [`BW_MAP_OUT-1:0]map_out;
	input [`BW_SS_CTRL-1:0]ss_ctrl;
	
	assign map_out = 
	map_idx == 11  ? map_out_011 :
	map_idx == 13  ? map_out_013 :
	map_idx == 34  ? map_out_034 :
	map_idx == 65  ? map_out_065 :
	map_idx == 67  ? map_out_067 :
	map_idx == 68  ? map_out_068 :
	map_idx == 70  ? map_out_070 :
	map_idx == 72  ? map_out_072 :
	map_idx == 76  ? map_out_076 :
	map_idx == 77  ? map_out_077 :
	map_idx == 78  ? map_out_078 :
	map_idx == 80  ? map_out_080 :
	map_idx == 82  ? map_out_082 :
	map_idx == 86  ? map_out_086 :
	map_idx == 88  ? map_out_088 :
	map_idx == 89  ? map_out_089 :
	map_idx == 92  ? map_out_072 :
	map_idx == 93  ? map_out_093 :
	map_idx == 95  ? map_out_088 :
	map_idx == 94  ? map_out_094 :
	map_idx == 96  ? map_out_096 :
	map_idx == 97  ? map_out_097 :
	map_idx == 144 ? map_out_011 :
	map_idx == 152 ? map_out_070 :
	map_idx == 154 ? map_out_088 :
	map_idx == 180 ? map_out_180 :
	map_idx == 184 ? map_out_184 :
	map_idx == 185 ? map_out_185 :
	map_idx == 206 ? map_out_088 :
	map_idx == 232 ? map_out_232 :
	map_out_nom;
	
	
	wire [`BW_MAP_OUT-1:0]map_out_nom;
	map_nom mnom(map_out_nom, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_011;
	map_011 m011(map_out_011, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_013;
	map_013 m013(map_out_013, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_034;
	map_034 m034(map_out_034, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_065;
	map_065 m065(map_out_065, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_067;
	map_067 m067(map_out_067, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_068;
	map_068 m068(map_out_068, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_070;
	map_070 m070(map_out_070, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_072;
	map_072 m072(map_out_072, bus, sys_cfg, ss_ctrl);//*
	
	wire [`BW_MAP_OUT-1:0]map_out_076;
	map_076 m076(map_out_076, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_077;
	map_077 m077(map_out_077, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_078;
	map_078 m078(map_out_078, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_080;
	map_080 m080(map_out_080, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_082;
	map_082 m082(map_out_082, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_086;
	map_086 m086(map_out_086, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_088;
	map_088 m088(map_out_088, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_089;
	map_089 m089(map_out_089, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_093;
	map_093 m093(map_out_093, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_094;
	map_094 m094(map_out_094, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_096;
	map_096 m096(map_out_096, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_097;
	map_097 m097(map_out_097, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_180;
	map_180 m180(map_out_180, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_184;
	map_184 m184(map_out_184, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_185;
	map_185 m185(map_out_185, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_232;
	map_232 m232(map_out_232, bus, sys_cfg, ss_ctrl);
	
endmodule
