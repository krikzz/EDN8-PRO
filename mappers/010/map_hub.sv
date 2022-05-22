

module map_hub(
	input  MapIn mai,
	output MapOut mao
);

	
	assign mao =
	mai.cfg.map_idx == 74 	? map_out_192 :
	mai.cfg.map_idx == 192 	? map_out_192 :
	mai.cfg.map_idx == 198 	? map_out_198 :
	mai.cfg.map_idx == 245 	? map_out_245 :
	map_out_nom;
	
	MapOut map_out_nom;
	map_nom mnom(mai, map_out_nom);

	
	MapOut map_out_192;
	map_192 m192(mai, map_out_192);
	
	MapOut map_out_198;
	map_198 m198(mai, map_out_198);
	
	MapOut map_out_245;
	map_245 m245(mai, map_out_245);

	
endmodule
