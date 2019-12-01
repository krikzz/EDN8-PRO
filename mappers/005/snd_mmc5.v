
`include "../base/defs.v"

module snd_mmc5
(bus, vol);

	`include "../base/bus_in.v"
	
	output [9:0]vol;
	
	reg l_clk;
	reg e_clk;
	reg [1:0]cfg;
	reg [7:0]pcm;
	reg [15:0]frame_ctr;
	
	
	always @(negedge m2)
	if(map_rst)cfg <= 0;
		else
	begin
		
		if(cpu_addr[14:0] == 15'h5011 & cpu_ce)pcm[7:0] <= cpu_dat[7:0];
		
		if(cpu_addr[14:0] == 15'h5015 & cpu_ce)cfg[1:0] <= cpu_dat[1:0];
		
		frame_ctr <= frame_ctr == 29828+1 ? 0 : frame_ctr + 1;
		
		if(frame_ctr == 7457)e_clk <= 1;
		if(frame_ctr == 14912)e_clk <= 1;
		if(frame_ctr == 22370)e_clk <= 1;
		if(frame_ctr == 29828)e_clk <= 1;
		
		if(frame_ctr == 14912)l_clk <= 1;
		if(frame_ctr == 29828)l_clk <= 1;
		
		if(e_clk)e_clk <= 0;
		if(l_clk)l_clk <= 0;
	end
	
	wire puls_ce_1 = cpu_addr[14:2] == 13'h1400;
	wire [3:0]snd_p1;
	pulse pulse_1(cpu_dat, cpu_addr[1:0], cpu_rw, puls_ce_1, !m2, e_clk, e_clk, snd_p1, cfg[0], l_ctr_nz, 1);
	
	wire puls_ce_2 = cpu_addr[14:2] == 13'h1401;
	wire [3:0]snd_p2;
	pulse pulse_2(cpu_dat, cpu_addr[1:0], cpu_rw, puls_ce_2, !m2, e_clk, e_clk, snd_p2, cfg[1], l_ctr_nz, 0);


	
	assign vol[9:0] = {snd_p1, 4'd0} + {snd_p2, 4'd0} + pcm;
	
endmodule



module pulse
(cpu_dat, cpu_addr, cpu_rw, reg_ce, cpu_clk, l_clk, e_clk, snd, on, l_ctr_nz, sube);

	input [7:0]cpu_dat;
	input [1:0]cpu_addr;
	input cpu_rw, reg_ce, cpu_clk, l_clk, e_clk;
	output [3:0]snd;
	input sube, on;
	output l_ctr_nz;
	
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
	
	assign l_ctr_nz = len_ctr != 0;
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
			
			
			
			/*if(swp_reload)swp_pctr[2:0] <= swp_cfg[6:4];
				else
			if(swp_pctr != 0)swp_pctr <= swp_pctr - 1;
				else
			begin
				swp_pctr[2:0] <= swp_cfg[6:4];
				if(swp_cfg[7] & !regs_we & !swp_over) {swp_over, puls_cfg[3][2:0], puls_cfg[2][7:0]} <= 
				swp_cfg[3] ? (timer - (timer >> swp_cfg[2:0])) - sube : timer + (timer >> swp_cfg[2:0]);
			end
			
			if(swp_reload)swp_reload <= 0;*/
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
	
	
	wire [4:0]l_ctr_in = cpu_dat[7:3];// puls_cfg[3][7:3];
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
