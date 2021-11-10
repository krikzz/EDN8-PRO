
`include "../base/defs.v"


module map_208
(map_out, bus, sys_cfg, ss_ctrl);

	`include "../base/bus_in.v"
	`include "../base/map_out.v"
	`include "../base/sys_cfg_in.v"
	`include "../base/ss_ctrl_in.v"
	
	output [`BW_MAP_OUT-1:0]map_out;
	input [`BW_SYS_CFG-1:0]sys_cfg;
	
	
	assign sync_m2 = 1;
	assign mir_4sc = 1;//enable support for 4-screen mirroring. for activation should be ensabled in sys_cfg also
	assign srm_addr[12:0] = cpu_addr[12:0];
	assign prg_oe = cpu_rw;
	assign chr_oe = !ppu_oe;
	wire cfg_mmc3a = map_sub == 4;
	//*************************************************************  save state setup
	assign ss_rdat[7:0] = 
	ss_addr[7:3] == 0   ? bank_dat[ss_addr[2:0]]:
	ss_addr[7:0] == 8   ? bank_sel : 
	ss_addr[7:0] == 9   ? mmc_ctrl[0] : 
	ss_addr[7:0] == 10  ? mmc_ctrl[1] : 
	ss_addr[7:3] == 2   ? irq_ss_dat : //addr 16-23 for irq
	
	ss_addr[7:0] == 32  ? prot_val[0] :
	ss_addr[7:0] == 33  ? prot_val[1] :
	ss_addr[7:0] == 34  ? prot_val[2] :
	ss_addr[7:0] == 35  ? prot_val[3] :
	ss_addr[7:0] == 36  ? prot_idx :
	ss_addr[7:0] == 37  ? {mir_mod, prg_bank[1:0]} :
	
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************
	assign ram_ce = 0;//{cpu_addr[15:13], 13'd0} == 16'h6000 & ram_ce_on;
	assign ram_we = !cpu_rw & ram_ce & !ram_we_off;
	assign rom_ce = cpu_addr[15];
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram & !ppu_we;
	
	assign map_cpu_oe = {cpu_addr[15:11], 11'd0} == 16'h5800;
	assign map_cpu_dout[7:0] = prot_val[cpu_addr[1:0]][7:0];
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = !mir_mod ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	
	assign prg_addr[14:0] = cpu_addr[14:0];
	assign prg_addr[16:15] = prg_bank[1:0];
	
	assign chr_addr[9:0] = ppu_addr[9:0];
	assign chr_addr[17:10] = cfg_chr_ram ? chr[4:0] : chr[7:0];//ines 2.0 reuired to support 32k ram
	
	wire [7:0]chr = 
	ppu_addr[12:11] == {chr_mod, 1'b0} ? {bank_dat[0][7:1], ppu_addr[10]} :
	ppu_addr[12:11] == {chr_mod, 1'b1} ? {bank_dat[1][7:1], ppu_addr[10]} : 
	ppu_addr[11:10] == 0 ? bank_dat[2][7:0] : 
	ppu_addr[11:10] == 1 ? bank_dat[3][7:0] : 
	ppu_addr[11:10] == 2 ? bank_dat[4][7:0] : 
   bank_dat[5][7:0];
	
	wire [15:0]reg_addr = {cpu_addr[15:13], 12'd0,  cpu_addr[0]};
	
	wire prg_mod = bank_sel[6];
	wire chr_mod = bank_sel[7];
	//wire mir_mod = mmc_ctrl[0][0];
	wire ram_we_off = mmc_ctrl[1][6];
	wire ram_ce_on = mmc_ctrl[1][7];
	
	reg [7:0]bank_sel;
	reg [7:0]bank_dat[8];
	reg [7:0]mmc_ctrl[2];
	
	reg [1:0]prg_bank;
	reg mir_mod;
	reg [7:0]prot_idx;
	reg [7:0]prot_val[4];
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:3] == 0)bank_dat[ss_addr[2:0]] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 8)bank_sel <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 9)mmc_ctrl[0] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 10)mmc_ctrl[1] <= cpu_dat;
		
		if(ss_we & ss_addr[7:0] == 32)prot_val[0] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 33)prot_val[1] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 34)prot_val[2] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 35)prot_val[3] <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 36)prot_idx <= cpu_dat;
		if(ss_we & ss_addr[7:0] == 37){mir_mod, prg_bank[1:0]} <= cpu_dat;
	end
		else
	if(map_rst)
	begin
		bank_sel[7:0] <= 0;
		
		mmc_ctrl[0][0] <= !cfg_mir_v;
		mmc_ctrl[1][7:0] <= 0;
	
		bank_dat[0][7:0] <= 0;
		bank_dat[1][7:0] <= 2;
		bank_dat[2][7:0] <= 4;
		bank_dat[3][7:0] <= 5;
		bank_dat[4][7:0] <= 6;
		bank_dat[5][7:0] <= 7;
		bank_dat[6][7:0] <= 0;
		bank_dat[7][7:0] <= 1;
		
		prg_bank[1:0] <= 2'b11;
		mir_mod <= 0;
	end
		else
	if(!cpu_rw)
	begin
	
		if((cpu_addr[15:0] & 16'hD800) == 16'h4800)
		begin
			prg_bank[1:0] <= {cpu_dat[4], cpu_dat[0]};
			mir_mod <= cpu_dat[5];
		end
	
		if({cpu_addr[15:11], 11'd0} == 16'h5000)prot_idx[7:0] <= cpu_dat[7:0];
		if({cpu_addr[15:11], 11'd0} == 16'h5800)prot_val[cpu_addr[1:0]][7:0] <= cpu_dat[7:0] ^ rom_dout[7:0];
	
		case(reg_addr[15:0])
			16'h8000:bank_sel[7:0] <= cpu_dat[7:0];
			16'h8001:bank_dat[bank_sel[2:0]][7:0] <= cpu_dat[7:0];
			16'hA000:mmc_ctrl[0][7:0] <= cpu_dat[7:0];
			16'hA001:mmc_ctrl[1][7:0] <= cpu_dat[7:0];
		endcase
	end
	
	wire [7:0]rom_dout;
	rom rom_inst(prot_idx, rom_dout, m2);
	
//***************************************************************************** IRQ	
	
	wire [7:0]irq_ss_dat;
	irq_mmc3 irq_inst(
		.bus(bus), 
		.ss_ctrl(ss_ctrl),
		.mmc3a(cfg_mmc3a),
		.irq(irq),
		.ss_dout(irq_ss_dat)
	);


endmodule



module rom 
(addr, dout, clk);

	input [7:0]addr;
	output reg[7:0]dout;
	input clk;
   
	reg [7:0]rom[256];
	
	initial
	begin
		$readmemh("rom_208.txt", rom);
	end
	
	always @(negedge clk)
	begin
		dout[7:0] <= rom[addr];
	end

endmodule


