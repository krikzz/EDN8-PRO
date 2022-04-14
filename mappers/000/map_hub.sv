

module map_hub(
	input  MapIn mai,
	output MapOut mao
);

	
	assign mao = 	
	mai.cfg.map_idx == 0   	? map_out_000 :
	//mai.cfg.map_idx == 2   	? map_out_002 :
	//mai.cfg.map_idx == 517 	? map_out_002 :
	//mai.cfg.map_idx == 3   	? map_out_003 :
	//mai.cfg.map_idx == 7   	? map_out_007 :
	//mai.cfg.map_idx == 16  	? map_out_016 :
	//mai.cfg.map_idx == 18  	? map_out_018 :
	//mai.cfg.map_idx == 32  	? map_out_032 :
	//mai.cfg.map_idx == 33  	? map_out_033 :
	//mai.cfg.map_idx == 38  	? map_out_066 :
	//mai.cfg.map_idx == 48  	? map_out_033 :
	//mai.cfg.map_idx == 66  	? map_out_066 :
	//mai.cfg.map_idx == 71  	? map_out_071 :
	//mai.cfg.map_idx == 87  	? map_out_087 :
	//mai.cfg.map_idx == 140 	? map_out_066 :
	//mai.cfg.map_idx == 153 	? map_out_153 :
	//mai.cfg.map_idx == 157 	? map_out_157 :
	//mai.cfg.map_idx == 159	? map_out_016 :
	map_out_nom;
	
	MapOut map_out_nom;
	map_nom mnom(mai, map_out_nom);

	
	MapOut map_out_000;
	map_000 m000(mai, map_out_000);
	
	
endmodule
