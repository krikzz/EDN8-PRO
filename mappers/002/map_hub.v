
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
	map_idx == 15  ? map_out_015 :
	map_idx == 28  ? map_out_028 : //?
	map_idx == 40  ? map_out_040 : 
	map_idx == 41  ? map_out_041 : //multi
	map_idx == 42  ? map_out_042 : 
	map_idx == 57  ? map_out_057 : //multi
	map_idx == 58  ? map_out_058 : //multi
	map_idx == 61  ? map_out_061 : //multi
	map_idx == 91  ? map_out_091 : 
	map_idx == 99  ? map_out_099 : //vs
	map_idx == 101 ? map_out_101 : //?
	map_idx == 107 ? map_out_107 :
	map_idx == 112 ? map_out_112 :
	map_idx == 164 ? map_out_164 : 
	map_idx == 168 ? map_out_168 ://broken
	map_idx == 178 ? map_out_178 :
	map_idx == 188 ? map_out_188 : 
	map_idx == 193 ? map_out_193 :
	map_idx == 200 ? map_out_200 ://multi
	map_idx == 201 ? map_out_201 ://multi
	map_idx == 202 ? map_out_202 ://multi
	map_idx == 203 ? map_out_203 ://multi
	map_idx == 212 ? map_out_212 ://multi
	map_idx == 227 ? map_out_227 ://multi
	map_idx == 231 ? map_out_231 ://multi
	map_idx == 234 ? map_out_234 ://multi
	map_idx == 240 ? map_out_240 : 
	map_idx == 241 ? map_out_241 : 
	map_idx == 242 ? map_out_242 : 
	map_idx == 246 ? map_out_246 : 
	map_out_nom;
	
	
	wire [`BW_MAP_OUT-1:0]map_out_nom;
	map_nom mnom(map_out_nom, bus, sys_cfg, ss_ctrl);

	wire [`BW_MAP_OUT-1:0]map_out_015;
	map_015 m015(map_out_015, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_028;
	map_028 m028(map_out_028, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_040;
	map_040 m040(map_out_040, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_041;
	map_041 m041(map_out_041, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_042;
	map_042 m042(map_out_042, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_057;
	map_057 m057(map_out_057, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_058;
	map_058 m058(map_out_058, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_061;
	map_061 m061(map_out_061, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_091;
	map_091 m091(map_out_091, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_099;
	map_099 m099(map_out_099, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_101;
	map_101 m101(map_out_101, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_107;
	map_107 m107(map_out_107, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_112;
	map_112 m112(map_out_112, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_164;
	map_164 m164(map_out_164, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_168;
	map_168 m168(map_out_168, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_178;
	map_178 m178(map_out_178, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_188;
	map_188 m188(map_out_188, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_193;
	map_193 m193(map_out_193, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_200;
	map_200 m200(map_out_200, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_201;
	map_201 m201(map_out_201, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_202;
	map_202 m202(map_out_202, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_203;
	map_203 m203(map_out_203, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_212;
	map_212 m212(map_out_212, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_227;
	map_227 m227(map_out_227, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_231;
	map_231 m231(map_out_231, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_234;
	map_234 m234(map_out_234, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_240;
	map_240 m240(map_out_240, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_241;
	map_241 m241(map_out_241, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_242;
	map_242 m242(map_out_242, bus, sys_cfg, ss_ctrl);
	
	wire [`BW_MAP_OUT-1:0]map_out_246;
	map_246 m246(map_out_246, bus, sys_cfg, ss_ctrl);
	
endmodule
