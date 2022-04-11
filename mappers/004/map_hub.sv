



module map_hub(
	input  MapIn mai,
	output MapOut mao
);

	
	assign mao = 
	mai.cfg.map_idx == 4	? map_out_004 :
	map_out_nom;
	
	MapOut map_out_nom;
	map_nom mnom(mai, map_out_nom);
	
	
	MapOut map_out_004;
	map_004 m004(mai, map_out_004);
	
endmodule
