
module chip_vrc1(

	input  cpu_m2,
	input  cpu_rw,
	input  cpu_a12,
	input  cpu_a13,
	input  cpu_a14,
	input  cpu_ce_n,
	input  ppu_oe_n,
	input  [3:0]cpu_data,
	input  [13:10]ppu_addr,
	
	output ciram_a10,
	output prg_ce_n,
	output chr_ce_n,
	output [16:13]prg_addr,
	output [16:12]chr_addr,
	
	
	input  rst,
	input  SSTBus sst,
	output [7:0]sst_di
	
);
//************************************************************* sst
	assign sst_di[7:0] =
	sst.addr[7:0] == 0 ? prg0 : 
	sst.addr[7:0] == 1 ? prg1 : 
	sst.addr[7:0] == 2 ? prg2 : 
	sst.addr[7:0] == 3 ? chr0 : 
	sst.addr[7:0] == 4 ? chr1 : 
	sst.addr[7:0] == 5 ? mir_mode : 
	8'hff;
//************************************************************* sst
	assign ciram_a10		= !mir_mode ? ppu_addr[10] : ppu_addr[11];
	assign prg_ce_n		= !cpu_addr[15];
	assign chr_ce_n		= ppu_addr[13];
	
	assign prg_addr[16:13] 	=
	cpu_addr[14:13] == 0 ? prg0[3:0] : 
	cpu_addr[14:13] == 1 ? prg1[3:0] : 
	cpu_addr[14:13] == 2 ? prg2[3:0] : 
	4'b1111;
	
	assign chr_addr[16:12] 	= !ppu_addr[12] ? chr0[4:0] : chr1[4:0];
	
	
	wire [15:0]cpu_addr 	= {!cpu_ce_n, cpu_a14, cpu_a13, cpu_a12, 12'd0};
	
	reg [3:0]prg0, prg1, prg2;
	reg [4:0]chr0, chr1;
	reg mir_mode;
	
	always @(negedge cpu_m2)
	if(sst.act)
	begin
		if(sst.we_reg & sst.addr[7:0] == 0)prg0 <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 1)prg1 <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 2)prg2 <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 3)chr0 <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 4)chr1 <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 5)mir_mode <= sst.dato[0];
	end
		else
	if(!cpu_rw)
	case(cpu_addr[15:0])
		16'h8000:prg0[3:0] <= cpu_data[3:0];
		16'h9000:{chr1[4], chr0[4], mir_mode} <= cpu_data[2:0];
		16'hA000:prg1[3:0] <= cpu_data[3:0];
		16'hC000:prg2[3:0] <= cpu_data[3:0];
		16'hE000:chr0[3:0] <= cpu_data[3:0];
		16'hF000:chr1[3:0] <= cpu_data[3:0];
	endcase

endmodule
