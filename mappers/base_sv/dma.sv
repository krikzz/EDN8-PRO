

//on-board mcu has access to the cart memory via dma controller.
module dma_io(
		
	input PiBus pi,
	
	input [7:0]prg_do,
	input [7:0]chr_do,
	input [7:0]srm_do,
	
	output DmaBus dma
);
	
	MemCtrl mem;
	assign dma.mem 			= mem;
	
	
	assign mem.dati[7:0]		= pi.dato[7:0];
	assign mem.addr[22:0]	= pi.addr[22:0];
	assign mem.ce				= pi.act & (pi.we | pi.oe);
	assign mem.oe				= pi.act & pi.oe;
	assign mem.we				= pi.act & pi.we;
	assign mem.async_io		= 1;
	
	assign dma.req_prg 		= pi.map.ce_prg;
	assign dma.req_chr 		= pi.map.ce_chr;
	assign dma.req_srm 		= pi.map.ce_srm;
	assign dma.mem_req		= dma.req_prg | dma.req_chr | dma.req_srm;
	
	assign dma.pi_di[7:0] 	= 
	dma.req_prg ? prg_do[7:0] : 
	dma.req_chr ? chr_do[7:0] : 
	dma.req_srm ? srm_do[7:0] : 8'hff;
	
endmodule
