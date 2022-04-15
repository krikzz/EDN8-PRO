

module map_hub(
	input  MapIn mai,
	output MapOut mao
);

	
	assign mao = 	
	mai.cfg.map_idx == 0   	? map_out_000 :
	mai.cfg.map_idx == 2   	? map_out_002 :
	mai.cfg.map_idx == 3   	? map_out_003 :
	mai.cfg.map_idx == 7   	? map_out_007 :
	mai.cfg.map_idx == 16  	? map_out_016 :
	mai.cfg.map_idx == 18  	? map_out_018 :
	mai.cfg.map_idx == 32  	? map_out_032 :
	mai.cfg.map_idx == 33  	? map_out_033 :
	mai.cfg.map_idx == 38  	? map_out_066 :
	mai.cfg.map_idx == 48  	? map_out_033 :
	mai.cfg.map_idx == 66  	? map_out_066 :
	mai.cfg.map_idx == 71  	? map_out_071 :
	mai.cfg.map_idx == 87  	? map_out_087 :
	mai.cfg.map_idx == 140 	? map_out_066 :
	mai.cfg.map_idx == 153 	? map_out_153 :
	mai.cfg.map_idx == 157 	? map_out_157 :
	mai.cfg.map_idx == 159	? map_out_016 :
	mai.cfg.map_idx == 517 	? map_out_002 :
	map_out_nom;
	
	MapOut map_out_nom;
	map_nom mnom(mai, map_out_nom);

	
	MapOut map_out_000;
	map_000 m000(mai, map_out_000);
	
	MapOut map_out_002;
	map_002 m002(mai, map_out_002);
	
	MapOut map_out_003;
	map_003 m003(mai, map_out_003);
	
	MapOut map_out_007;
	map_007 m007(mai, map_out_007);
	
	MapOut map_out_016;
	map_016 m016(mai, map_out_016);
	
	MapOut map_out_018;
	map_018 m018(mai, map_out_018);
	
	MapOut map_out_032;
	map_032 m032(mai, map_out_032);
	
	MapOut map_out_033;
	map_033 m033(mai, map_out_033);
	
	MapOut map_out_066;
	map_066 m066(mai, map_out_066);
	
	MapOut map_out_071;
	map_071 m071(mai, map_out_071);
	
	MapOut map_out_087;
	map_087 m087(mai, map_out_087);
	
	MapOut map_out_153;
	map_153 m153(mai, map_out_153);
	
	MapOut map_out_157;
	map_157 m157(mai, map_out_157);
	
endmodule
