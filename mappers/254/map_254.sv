
module map_254(

	input  MapIn  mai,
	output MapOut mao
);
//************************************************************* base header
	CpuBus cpu;
	PpuBus ppu;
	SysCfg cfg;
	SSTBus sst;
	assign cpu = mai.cpu;
	assign ppu = mai.ppu;
	assign cfg = mai.cfg;
	assign sst = mai.sst;
	
	MemCtrl prg;
	MemCtrl chr;
	MemCtrl srm;
	assign mao.prg = prg;
	assign mao.chr = chr;
	assign mao.srm = srm;

	assign prg.dati			= cpu.data;
	assign chr.dati			= ppu.data;
	assign srm.dati			= cpu.data;
	
	wire int_cpu_oe;
	wire int_ppu_oe;
	wire [7:0]int_cpu_data;
	wire [7:0]int_ppu_data;
	
	assign mao.map_cpu_oe	= int_cpu_oe | (srm.ce & srm.oe) | (prg.ce & prg.oe);
	assign mao.map_cpu_do	= int_cpu_oe ? int_cpu_data : srm.ce ? mai.srm_do : mai.prg_do;
	
	assign mao.map_ppu_oe	= int_ppu_oe | (chr.ce & chr.oe);
	assign mao.map_ppu_do	= int_ppu_oe ? int_ppu_data : mai.chr_do;
//************************************************************* configuration
	assign mao.prg_mask_off = 1;
	assign mao.chr_mask_off = 1;
	assign mao.srm_mask_off = 1;
	assign mao.mir_4sc		= 0;//enable support for 4-screen mirroring. for activation should be enabled in cfg.mir_4 also
	assign mao.bus_cf 		= 0;//bus conflicts
	wire cfg_fds_asw 			= cfg.map_sub[0];//fds disk auto swap
	wire cfg_fds_ebi 			= cfg.map_sub[1];
//************************************************************* save state regs read
	assign mao.sst_di[7:0] =
	sst.addr[7:0] == 0 	? disk_addr[15:8] :
	sst.addr[7:0] == 1 	? disk_addr[7:0] :
	sst.addr[7:0] == 2 	? disk_side[1:0] :
	sst.addr[7:0] == 3 	? reg25[7:0] :
	sst.addr[7:0] == 4 	? reg30[7:0] :
	sst.addr[7:0] == 5 	? irq_reload[15:8] :
	sst.addr[7:0] == 6 	? irq_reload[7:0] :
	sst.addr[7:0] == 7 	? irq_ctr[15:8] :
	sst.addr[7:0] == 8 	? irq_ctr[7:0] :
	sst.addr[7:0] == 9 	? delay[7:0] :
	sst.addr[7:0] == 10 	? {4'h0, irq_re, irq_on, disk_end, inc_disk_addr} :
	sst.addr[7:0] == 127 ? cfg.map_idx : ss_rdat_snd[7:0];
//************************************************************* mapper-controlled pins
	assign srm.ce				= disk_ce;
	assign srm.oe				= cpu.rw;
	assign srm.we				= disk_we;
	assign srm.addr[15:0]	= disk_addr[15:0];
	assign srm.addr[17:16] 	= disk_addr[17:16] & cfg.fds_msk[1:0];
	
	assign prg.ce				= wram_ce | (bios_ce & cfg_fds_ebi);
	assign prg.oe 				= cpu.rw;
	assign prg.we				= (wram_ce & !cpu.rw);
	assign prg.addr[22:0]	= (bios_ce & cfg_fds_ebi) ? bios_addr[22:0] : wram_addr[22:0];
	
	assign chr.ce 				= mao.ciram_ce;
	assign chr.oe 				= !ppu.oe;
	assign chr.we 				= !ppu.we & mao.ciram_ce;
	assign chr.addr[12:0]	= ppu.addr[12:0];

	
	//A10-Vmir, A11-Hmir
	assign mao.ciram_a10 	= !reg25[3] ? ppu.addr[10] : ppu.addr[11];
	assign mao.ciram_ce 		= !ppu.addr[13];
	
	assign mao.irq				= reg30[0] | (reg30[1] & reg25[7]);
	assign mao.chr_xram_ce	= chr.ce;
	assign int_cpu_oe			= (regs_oe & !disk_ce) | snd_oe | (bios_ce & cpu.rw & !cfg_fds_ebi);
	assign int_cpu_data		=
	cpu.addr[15:0] == 16'h4030 ? reg30[7:0] :
	cpu.addr[15:0] == 16'h4032 ? reg32[7:0] :
	cpu.addr[15:0] == 16'h4033 ? 8'hff :
	snd_oe 							? snd_dout[7:0] : 
	bios_do[7:0];
	assign mao.snd[15:0]		= {snd_vol[11:0], 4'd0};
	assign mao.led				= disk_txf | disk_eject;
//************************************************************* mapper implementation
	wire regs_we 		= {cpu.addr[15:4], 4'd0} == 16'h4020 & cpu.rw == 0;
	wire regs_oe 		= {cpu.addr[15:4], 4'd0} == 16'h4030 & cpu.rw == 1;
	
	wire disk_we 		= disk_wr_ce & cpu.rw == 0 & disk_we_on;
	wire disk_oe 		= disk_rd_ce & cpu.rw == 1;
	wire disk_wr_ce 	= cpu.addr[15:0] == 16'h4024;
	wire disk_rd_ce 	= cpu.addr[15:0] == 16'h4031;
	wire disk_ce 		= disk_wr_ce | disk_rd_ce;
	
	wire bios_ce 		= {cpu.addr[15:13], 13'd0} == 16'hE000;
	wire wram_ce 		= 
	{cpu.addr[15:13], 13'd0} == 16'h6000 |
	{cpu.addr[15:13], 13'd0} == 16'h8000 | 
	{cpu.addr[15:13], 13'd0} == 16'hA000 |
	{cpu.addr[15:13], 13'd0} == 16'hC000;
	
	
	//{6'h3F, 4'h3, cpu.addr[12:0]};//bios rom locatd in OS binary. 0x6000. BANK3
	wire [22:0]bios_addr = {8'h01, 2'h0, cpu.addr[12:0]};
	wire [22:0]wram_addr = {8'h00, cpu.addr[14:0]};//work ram located at 0x000000
	
	wire disk_txf 		= reg25[0] & !reg25[1];
	wire disk_back 	= reg25[0] & reg25[1];
	wire read_mode 	= reg25[2];
	wire transfer_irq = delay == 0 & disk_txf & !disk_end & reg25[7];
	wire disk_we_on 	= !read_mode & disk_txf & !disk_end;
	
	
	wire [7:0]reg32;
	assign reg32[0] 	= disk_eject;
	assign reg32[1] 	= reg25[1] | disk_end;
	assign reg32[2] 	= disk_eject;
	assign reg32[7:3] = 5'b11111;
	
	reg [7:0]reg25;
	reg [7:0]reg30;
	reg [15:0]irq_reload;
	reg [15:0]irq_ctr;
	reg [18:0]disk_addr;
	reg [7:0]delay;
	reg irq_re, irq_on;
	reg disk_end;
	reg inc_disk_addr;
	
	always @(negedge cpu.m2)
	if(sst.act)
	begin
		if(sst.we_reg & sst.addr[7:0] == 0)disk_addr[15:8] 	<= sst.dato[7:0];
		if(sst.we_reg & sst.addr[7:0] == 1)disk_addr[7:0] 		<= sst.dato[7:0];
		//if(sst.we_reg & sst.addr[7:0] == 2)disk_side[1:0] 	<= sst.dato[7:0];
		if(sst.we_reg & sst.addr[7:0] == 3)reg25[7:0] 			<= sst.dato[7:0];
		if(sst.we_reg & sst.addr[7:0] == 4)reg30[7:0] 			<= sst.dato[7:0];
		if(sst.we_reg & sst.addr[7:0] == 5)irq_reload[15:8] 	<= sst.dato[7:0];
		if(sst.we_reg & sst.addr[7:0] == 6)irq_reload[7:0]		<= sst.dato[7:0];
		if(sst.we_reg & sst.addr[7:0] == 7)irq_ctr[15:8] 		<= sst.dato[7:0];
		if(sst.we_reg & sst.addr[7:0] == 8)irq_ctr[7:0] 		<= sst.dato[7:0];
		if(sst.we_reg & sst.addr[7:0] == 9)delay[7:0] 			<= sst.dato[7:0];
		if(sst.we_reg & sst.addr[7:0] == 10){irq_re, irq_on, disk_end, inc_disk_addr} <= sst.dato[3:0];
	end
		else
	begin
	
	
		disk_addr[17:16] <= disk_side[1:0];
	
		if(disk_addr[15:0] == 65500)disk_end <= 1;
			else
		if(disk_addr[15:0] == 0)disk_end <= 0;
		
		
		if(inc_disk_addr)inc_disk_addr <= 0;
		if(inc_disk_addr & !disk_back)disk_addr[15:0] <= disk_addr[15:0] + 1;
		
		if(disk_back)
		begin
			if(disk_addr[15:0] != 0)disk_addr[15:0] <= 0;
		end
			else
		if(transfer_irq)
		begin
			if(reg30[1] == 0)reg30[1] <= 1;
		end
		
		if(irq_on & irq_ctr == 1)
		begin
			reg30[0] <= 1;
		end
		
		if(irq_on)irq_ctr <= irq_ctr - 1;
		
		if(!disk_txf | delay == 0 | disk_end | !reg25[7])
		begin
			delay <= 140;
		end
			else
		begin
			delay <= delay - 1;
		end
		
		
		if(regs_oe)//0x403x
		case(cpu.addr[3:0])
			0:reg30[1:0] <= 2'b00;
			1:begin
				if(disk_txf & !disk_end)inc_disk_addr <= 1;
				reg30[1] <= 0;
			end
		endcase
		
		
		if(regs_we)//0x402x
		case(cpu.addr[3:0])
			0:irq_reload[7:0]  <= cpu.data[7:0];
			1:irq_reload[15:8] <= cpu.data[7:0];
			2:begin
				irq_re 		<= cpu.data[0];
				irq_on 		<= cpu.data[1];
				irq_ctr 		<= irq_reload;
			end
			4:reg30[1] 		<= 0;
			5:reg25[7:0] 	<= cpu.data[7:0];
		endcase
		

		
	end


	
	wire eject_req = (mai.fds_sw & !cfg.ct_ss_btn) | auto_swp_req | sw_swap_req;
	wire [1:0]disk_side;
	wire disk_eject;
	
	disk_swap swap_inst(cpu, eject_req, disk_eject, disk_side, sst);
	
	wire auto_swp_off = !cfg_fds_asw | disk_eject; 
	wire auto_swp_req;
	
	swap_auto swp_inst_au(cpu, auto_swp_off, auto_swp_req);
	
	wire sw_swap_req;
	swap_sw swp_inst_sw(cpu, sw_swap_req, sst.act);

	
	wire [7:0]ss_rdat_snd;
	wire [11:0]snd_vol;
	wire [7:0]snd_dout;
	wire snd_oe;

	fds_snd snd_inst(cpu, snd_vol, snd_oe, snd_dout, sst, ss_rdat_snd);
	
	wire [7:0]bios_do;
	rom bios(cpu.addr[12:0], bios_do, mai.clk);

endmodule

module swap_sw
(cpu, swp_req, sst_act);

	input CpuBus cpu;
	output reg swp_req;
	input sst_act;
	
	always @(negedge cpu.m2)
	begin
		
		if(cpu.addr[15:0] == 16'h402D & cpu.rw == 0 & sst_act == 1)swp_req <= 1;
		if(cpu.addr[15:0] == 16'h4032 & cpu.rw == 1 & sst_act == 0)swp_req <= 0;
		
	end

endmodule

module swap_auto
(cpu, swp_off, swp_req);

	input CpuBus cpu;
	input swp_off;
	output swp_req;
	
	assign swp_req = swp_req_ctr[8];
	
	reg [8:0]swp_req_ctr;
	reg [21:0]swp_lock_ctr;
	
	always @(negedge cpu.m2)
	if(swp_off)
	begin
		swp_req_ctr 	<= 0;
		swp_lock_ctr 	<= 0;
	end
		else
	if(swp_req)
	begin
		swp_req_ctr 	<= 0;
		swp_lock_ctr 	<= 1;
	end
		else
	if(swp_lock_ctr != 0)swp_lock_ctr <= swp_lock_ctr + 1;
		else
	begin
		if(cpu.addr[15:0] == 16'h4024 & cpu.rw == 0)swp_req_ctr <= 0;
		if(cpu.addr[15:0] == 16'h4031 & cpu.rw == 1)swp_req_ctr <= 0;
		if(cpu.addr[15:0] == 16'h4032 & cpu.rw == 1)swp_req_ctr <= swp_req_ctr + 1;
	end
	
endmodule

module disk_swap
(cpu, eject_req, disk_eject, disk_side, sst);
	
	input  CpuBus cpu;
	input  eject_req;
	output disk_eject;
	output reg[1:0]disk_side;
	input  SSTBus sst;

	
	
	assign disk_eject = eject_req_st | eject_ctr != 0;
	
	reg [20:0]eject_ctr;
	reg eject_req_st;
	reg [1:0]eject_st;

	
	
	always @(negedge cpu.m2)
	if(sst.act)
	begin
		if(sst.we_reg & sst.addr[7:0] == 2)disk_side[1:0] <= cpu.data[1:0];
		if(sst.we_reg)eject_ctr <= 0;
		if(sst.we_reg)eject_st 	<= 0;
	end
		else
	begin
	
		if(eject_st[1:0] == 2'b01)disk_side[1:0] <= disk_side[1:0] + 1;
	
		eject_req_st <= eject_req;
		
		if(eject_req_st)eject_ctr <= 1;
			else
		if(eject_ctr != 0)eject_ctr <= eject_ctr + 1;
		
		eject_st[1:0] <= {eject_st[0], disk_eject};
		
	end

endmodule



module rom 
(addr, dout, clk);

	input [12:0]addr;
	output reg[7:0]dout;
	input clk;
   
	reg [7:0]rom[8192];
	
	initial
	begin
		$readmemh("disksys.rom.txt", rom);
	end
	
	always @(posedge clk)
	begin
		dout[7:0] <= rom[addr];
	end

endmodule
