

module map_hub(
	input  MapIn mai,
	output MapOut mao
);

	
	assign mao = 	
	mai.cfg.map_idx == 11  ? map_out_011 :
	mai.cfg.map_idx == 13  ? map_out_013 :
	mai.cfg.map_idx == 34  ? map_out_034 :
	mai.cfg.map_idx == 65  ? map_out_065 :
	mai.cfg.map_idx == 67  ? map_out_067 :
	mai.cfg.map_idx == 68  ? map_out_068 :
	mai.cfg.map_idx == 70  ? map_out_070 :
	mai.cfg.map_idx == 72  ? map_out_072 :
	mai.cfg.map_idx == 76  ? map_out_076 :
	mai.cfg.map_idx == 77  ? map_out_077 :
	mai.cfg.map_idx == 78  ? map_out_078 :
	mai.cfg.map_idx == 80  ? map_out_080 :
	mai.cfg.map_idx == 82  ? map_out_082 :
	mai.cfg.map_idx == 86  ? map_out_086 :
	mai.cfg.map_idx == 88  ? map_out_088 :
	mai.cfg.map_idx == 89  ? map_out_089 :
	mai.cfg.map_idx == 92  ? map_out_072 :
	mai.cfg.map_idx == 93  ? map_out_093 :
	mai.cfg.map_idx == 95  ? map_out_088 :
	mai.cfg.map_idx == 94  ? map_out_094 :
	mai.cfg.map_idx == 96  ? map_out_096 :
	mai.cfg.map_idx == 97  ? map_out_097 :
	mai.cfg.map_idx == 144 ? map_out_011 :
	mai.cfg.map_idx == 152 ? map_out_070 :
	mai.cfg.map_idx == 154 ? map_out_088 :
	mai.cfg.map_idx == 180 ? map_out_180 :
	mai.cfg.map_idx == 184 ? map_out_184 :
	mai.cfg.map_idx == 185 ? map_out_185 :
	mai.cfg.map_idx == 206 ? map_out_088 :
	mai.cfg.map_idx == 232 ? map_out_232 :
	map_out_nom;
	
	
	MapOut map_out_nom;
	map_nom mnom(mai, map_out_nom);

	MapOut map_out_011;
	map_011 m011(mai, map_out_011);
	
	MapOut map_out_013;
	map_013 m012(mai, map_out_013);
	
	MapOut map_out_034;
	map_034 m034(mai, map_out_034);
	
	MapOut map_out_065;
	map_065 m065(mai, map_out_065);
	
	MapOut map_out_067;
	map_067 m067(mai, map_out_067);
	
	MapOut map_out_068;
	map_068 m068(mai, map_out_068);
	
	MapOut map_out_070;
	map_070 m070(mai, map_out_070);
	
	MapOut map_out_072;
	map_072 m072(mai, map_out_072);
	
	MapOut map_out_076;
	map_076 m076(mai, map_out_076);
	
	MapOut map_out_077;
	map_077 m077(mai, map_out_077);
	
	MapOut map_out_078;
	map_078 m078(mai, map_out_078);
	
	MapOut map_out_080;
	map_080 m080(mai, map_out_080);
	
	MapOut map_out_082;
	map_082 m082(mai, map_out_082);
	
	MapOut map_out_086;
	map_086 m086(mai, map_out_086);
	
	MapOut map_out_088;
	map_088 m088(mai, map_out_088);
	
	MapOut map_out_089;
	map_089 m089(mai, map_out_089);
	
	MapOut map_out_093;
	map_093 m093(mai, map_out_093);
	
	MapOut map_out_094;
	map_094 m094(mai, map_out_094);
	
	MapOut map_out_096;
	map_096 m096(mai, map_out_096);
	
	MapOut map_out_097;
	map_097 m097(mai, map_out_097);
	
	MapOut map_out_180;
	map_180 m180(mai, map_out_180);
	
	MapOut map_out_184;
	map_184 m184(mai, map_out_184);
	
	MapOut map_out_185;
	map_185 m185(mai, map_out_185);
	
	MapOut map_out_232;
	map_232 m232(mai, map_out_232);
	
endmodule
