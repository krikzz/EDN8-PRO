

module map_hub(
	input  MapIn mai,
	output MapOut mao
);

	
	assign mao = 	
	mai.cfg.map_idx == 5  	? map_out_005 :
	map_out_nom;
	
	MapOut map_out_nom;
	map_nom mnom(mai, map_out_nom);

	
	MapOut map_out_005;
	map_005 m005(mai, map_out_005);
	
	
endmodule
