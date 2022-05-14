

module snd_mmc5(
	
	input  CpuBus cpu,
	input  map_rst,
	output [9:0]vol
);
	
	assign vol[9:0] = {snd_p1, 4'd0} + {snd_p2, 4'd0} + pcm;
	
	
	reg l_clk;
	reg e_clk;
	reg [1:0]cfg;
	reg [7:0]pcm;
	reg [15:0]frame_ctr;
	
	
	always @(negedge cpu.m2)
	if(map_rst)
	begin
		cfg <= 0;
	end
		else
	begin
		
		if(cpu.addr[14:0] == 15'h5011 & !cpu.addr[15])pcm[7:0] <= cpu.data[7:0];
		
		if(cpu.addr[14:0] == 15'h5015 & !cpu.addr[15])cfg[1:0] <= cpu.data[1:0];
		
		frame_ctr <= frame_ctr == 29828+1 ? 0 : frame_ctr + 1;
		
		if(frame_ctr == 7457)e_clk 	<= 1;
		if(frame_ctr == 14912)e_clk 	<= 1;
		if(frame_ctr == 22370)e_clk 	<= 1;
		if(frame_ctr == 29828)e_clk 	<= 1;
		
		if(frame_ctr == 14912)l_clk 	<= 1;
		if(frame_ctr == 29828)l_clk 	<= 1;
		
		if(e_clk)e_clk	<= 0;
		if(l_clk)l_clk <= 0;
		
	end
	
	
	wire puls_ce_1 = cpu.addr[14:2] == 13'h1400;
	wire [3:0]snd_p1;
	
	pulse pulse_1(
	
		.cpu_dat(cpu.data),
		.cpu_addr(cpu.addr[1:0]),
		.cpu_rw(cpu.rw),
		.reg_ce(puls_ce_1),
		.cpu_clk(!cpu.m2),
		.l_clk(e_clk),
		.e_clk(e_clk),
		.on(cfg[0]),
		.snd(snd_p1)
	);
	
	
	wire puls_ce_2 = cpu.addr[14:2] == 13'h1401;
	wire [3:0]snd_p2;
	
	pulse pulse_2(
	
		.cpu_dat(cpu.data),
		.cpu_addr(cpu.addr[1:0]),
		.cpu_rw(cpu.rw),
		.reg_ce(puls_ce_2),
		.cpu_clk(!cpu.m2),
		.l_clk(e_clk),
		.e_clk(e_clk),
		.on(cfg[1]),
		.snd(snd_p2)
	);
	
endmodule



module pulse(

	input [7:0]cpu_dat,
	input [1:0]cpu_addr,
	input cpu_rw, 
	input reg_ce, 
	input cpu_clk, 
	input l_clk,
	input e_clk,
	input on,
	
	output [3:0]snd
);


	
	
	reg [7:0]puls_cfg[4];
	reg [7:0]len_ctr;
	
	
	wire [7:0]duty_table = 
	env_cfg[7:6] == 0 ? 8'b01000000 :
	env_cfg[7:6] == 1 ? 8'b01100000 :
	env_cfg[7:6] == 2 ? 8'b01111000 : 8'b10011111;
	
	wire duty_state = duty_table[duty_ctr];
	
	
	reg start;
	
	
	wire [7:0]env_cfg = puls_cfg[0];
	wire [7:0]swp_cfg = puls_cfg[1];
	wire [10:0]timer = {puls_cfg[3][2:0], puls_cfg[2][7:0]};
	
	
	reg [2:0]duty_ctr;
	reg [10:0]freq_ctr;
	
	assign snd[3:0] = !duty_state ? 0 : current_vol[3:0];
	wire [3:0]current_vol = env_cfg[4] ? env_cfg[3:0] : envelope[3:0];
	
	wire silent = len_silent | swp_over | !on;
	
	
	reg swp_over;
	reg len_silent;
	
	wire regs_we = reg_ce & !cpu_rw;
	wire regs_we0 = regs_we & cpu_addr == 0;
	wire regs_we1 = regs_we & cpu_addr == 1;
	wire regs_we2 = regs_we & cpu_addr == 2;
	wire regs_we3 = regs_we & cpu_addr == 3;
	
	reg swp_reload;
	wire lock_len_reload = len_ctr != 0 & l_clk;
	//sweep: freq inc/dec
	//envel: volume subtract (looped)
	always @(posedge cpu_clk)
	begin
		
	
		if(regs_we)puls_cfg[cpu_addr][7:0] <= cpu_dat;

		if(freq_ctr != 0 & !regs_we3)freq_ctr <= freq_ctr - 1;
			else
		begin
			freq_clk <= !freq_clk;
			freq_ctr <= timer;
		end
		
		if(regs_we1)swp_reload <= 1;
		
		if(!on)len_ctr <= 0;
		len_silent <= len_ctr == 0;
//*************************************************************************** sweep frame		
		//len/sweep ctr
		if(regs_we3 & !lock_len_reload)
		begin
			len_ctr[7:0] <= len_ctr_val[7:0];
			swp_over <= 0;
			swp_reload <= 1;
		end
			//else
		if(l_clk)
		begin
		
			if(len_ctr != 0 & !env_cfg[5])len_ctr <= len_ctr - 1;
		end		
//***************************************************************************	envelope frame	
		//envelope/linear ctr
		if(regs_we3)
		begin
			env_pctr[3:0] <= puls_cfg[0][3:0];
			envelope <= 15;
		end
			else
		if(e_clk)
		begin
			
			if(env_pctr[3:0] != 0)env_pctr[3:0] <= env_pctr[3:0] - 1;
				else
			begin
				env_pctr[3:0] <= puls_cfg[0][3:0];
				if(envelope != 0 | puls_cfg[0][5])envelope <= envelope - 1;
			end
		end
		
		
		
	end
	
	
	reg [2:0]swp_pctr;
	reg [3:0]env_pctr;
	reg [3:0]envelope;
	
	reg freq_clk;
	always @(negedge freq_clk)
	begin
		if(!silent)duty_ctr <= duty_ctr + 1;
	end
	
	
	wire [4:0]l_ctr_in = cpu_dat[7:3];
	wire [7:0]len_ctr_val = 
	l_ctr_in == 6'h01 ? 254 : 
	l_ctr_in == 6'h0A ? 60 : 
	l_ctr_in == 6'h0C ? 14 : 
	l_ctr_in == 6'h0E ? 26 : 
	l_ctr_in == 6'h1A ? 72 : 
	l_ctr_in == 6'h1C ? 16 : 
	l_ctr_in == 6'h1E ? 32 : 
	l_ctr_in[0] ? {l_ctr_in[4:1], 1'b0} : 
	l_ctr_in[4] ? (12 << l_ctr_in[3:1]) : (10 << l_ctr_in[3:1]);

endmodule
