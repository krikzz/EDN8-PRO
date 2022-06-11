
	`define SST_OFF	//save state
	`define GGC_OFF	//cheats engine

module map_hub(
	input  MapIn mai,
	output MapOut mao
);

	
	assign mao = 
	mai.cfg.map_idx ==31		? map_out_031 :
	map_out_nom;
	
	MapOut map_out_nom;
	map_nom mnom(mai, map_out_nom);

	MapOut map_out_031;
	map_031 m031(mai, map_out_031);
	
	
endmodule
