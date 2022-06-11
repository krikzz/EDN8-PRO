



module map_hub(
	input  MapIn mai,
	output MapOut mao
);

	
	assign mao = map_out_nom;
	
	MapOut map_out_nom;
	map_nom mnom(mai, map_out_nom);
	
endmodule
