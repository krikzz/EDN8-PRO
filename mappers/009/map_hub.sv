

module map_hub(
	input  MapIn mai,
	output MapOut mao
);

	
	assign mao = 	
	mai.cfg.map_idx == 83 	? map_out_083 :
	mai.cfg.map_idx == 105 	? map_out_105 :
	map_out_nom;
	
	MapOut map_out_nom;
	map_nom mnom(mai, map_out_nom);

	
	MapOut map_out_083;
	map_083 m083(mai, map_out_083);
	
	MapOut map_out_105;
	map_105 m105(mai, map_out_105);
	
	
endmodule
