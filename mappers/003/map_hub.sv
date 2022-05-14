

module map_hub(
	input  MapIn mai,
	output MapOut mao
);

	
	assign mao = 	
	mai.cfg.map_idx == 79  ? map_out_079 ://ave/sachen/hes multi
	mai.cfg.map_idx == 90  ? map_out_090 : 
	mai.cfg.map_idx == 113 ? map_out_079 ://ave/sachen/hes multi
	mai.cfg.map_idx == 133 ? map_out_133 ://sachen
	mai.cfg.map_idx == 137 ? map_out_137 : 
	mai.cfg.map_idx == 138 ? map_out_137 : 
	mai.cfg.map_idx == 139 ? map_out_137 : 
	mai.cfg.map_idx == 141 ? map_out_137 : 
	mai.cfg.map_idx == 146 ? map_out_079 : //ave/sachen/hes multi
	mai.cfg.map_idx == 147 ? map_out_147 : 
	mai.cfg.map_idx == 148 ? map_out_148 : //sachen
	mai.cfg.map_idx == 150 ? map_out_243 : //sachen
	mai.cfg.map_idx == 209 ? map_out_090 :
	mai.cfg.map_idx == 211 ? map_out_090 : 
	mai.cfg.map_idx == 243 ? map_out_243 : //sachen
	map_out_nom;
	
	MapOut map_out_nom;
	map_nom mnom(mai, map_out_nom);

	
	MapOut map_out_079;
	map_079 m079(mai, map_out_079);
	
	MapOut map_out_090;
	map_090 m090(mai, map_out_090);
	
	MapOut map_out_133;
	map_133 m133(mai, map_out_133);
	
	MapOut map_out_137;
	map_137 m137(mai, map_out_137);
	
	MapOut map_out_147;
	map_147 m147(mai, map_out_147);
	
	MapOut map_out_148;
	map_148 m148(mai, map_out_148);
	
	MapOut map_out_243;
	map_243 m243(mai, map_out_243);
	
endmodule
