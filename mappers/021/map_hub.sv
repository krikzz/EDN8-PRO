



module map_hub(
	input  MapIn mai,
	output MapOut mao
);

	
	assign mao = 
	mai.cfg.map_idx == 21 ? map_out_021 : 
	mai.cfg.map_idx == 22 ? map_out_021 : 
	mai.cfg.map_idx == 23 ? map_out_021 : 
	//mai.cfg.map_idx == 24 ? map_out_024 : 
	mai.cfg.map_idx == 25 ? map_out_021 : 
	//mai.cfg.map_idx == 26 ? map_out_024 : 
	//mai.cfg.map_idx == 73 ? map_out_073 : 
	//mai.cfg.map_idx == 75 ? map_out_075 : 
	//mai.cfg.map_idx == 151 ? map_out_075 : //vs mapper
	map_out_nom;
	
	MapOut map_out_nom;
	map_nom mnom(mai, map_out_nom);

	
	MapOut map_out_021;
	map_021 m021(mai, map_out_021);
	

	
endmodule
