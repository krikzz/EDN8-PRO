
`include "../base/defs.v"

module fds_snd
(bus, vol, bus_oe, dout, ss_ctrl, ss_rdat);
		
	`include "../base/bus_in.v"

	
	
	output [11:0]vol;
	output bus_oe;
	output [7:0]dout;
	
	assign bus_oe = gain_oe | ram_oe;
	
	assign dout[7:6] = 2'b01;
	assign dout[5:0] = 
	ram_oe ? {2'b00, ram_val[5:0]}:
	cpu_addr[3:0] == 4'h0 ? {2'b01, vol_gain[5:0]} : {2'b01, mod_gain[5:0]};
	
	
	
	wire gain_oe = cpu_rw & (cpu_addr[15:0] == 16'h4090 | cpu_addr[15:0] == 16'h4092);
	
	
	wire [5:0]vol_g = vol_gain > 32 ? 32 : vol_gain;
	wire [11:0]volx = vol_g * wav_val;
	wire [6:0] out1 = (master_vol != 3) ? 0 : volx[10:4];
   wire [8:0] out2 = out1 + ((master_vol != 2) ? 0 : volx[10:3]);
   wire [9:0] out4 = out2 + ((master_vol == 1) ? 0 : volx[10:2]);
   assign vol = out4 + (master_vol[1] ? 0 : volx[10:1]);

	
	
	wire ram_oe;
	wire [1:0]master_vol;
	wire [5:0]ram_val;
	wire [5:0]wav_val;	
	wire [11:0]wav_freq;
	wav_unit wav_inst(bus, mod_val, wav_val, ram_val, wav_freq, master_vol, ram_oe, ss_ctrl, ss_rdat_wav);
	
	wire [6:0]mod_counter;
	mod_unit mod_inst(bus, mod_counter, ss_ctrl, ss_rdat_mod);

	wire [5:0]vol_gain, mod_gain;
	env_unit env_inst(bus, vol_gain, mod_gain, ss_ctrl, ss_rdat_env);

	
	
	
	wire [14:0]mod_val;
	mod_calc_old mod(mod_counter, mod_gain, wav_freq, mod_val);
	

	//************************************************************* save state
	`include "../base/ss_ctrl_in.v"
	output [7:0]ss_rdat = 
	{ss_addr[7:4], 4'd0} == 8'd16 ?  ss_rdat_env[7:0] : 
	{ss_addr[7:4], 4'd0} == 8'd96 ?  ss_rdat_mod[7:0] : 
	{ss_addr[7:3], 3'd0} == 8'd112 ?  ss_rdat_mod[7:0] : 
	ss_rdat_wav[7:0];
	
	wire [7:0]ss_rdat_wav;//32-95 and 120-123
	wire [7:0]ss_rdat_mod;//96-117
	wire [7:0]ss_rdat_env;//16-31
	
endmodule






module wav_unit
(bus, mod_val, wav_val, ram_val, wav_freq, master_vol, ram_oe, ss_ctrl, ss_rdat);
	
	`include "../base/bus_in.v"

	input [14:0]mod_val;
	output reg [11:0]wav_freq;
	output reg[5:0]wav_val;
	output [5:0]ram_val;
	output reg[1:0]master_vol;
	output ram_oe;
	
	assign ram_val[5:0] = wav_ram[cpu_addr[5:0]];
	
	reg ram_we_on;
	reg wav_off;
	
	reg [5:0]wav_addr;
	reg [17:0]wav_ctr;
	reg [5:0]wav_ram[64];
	
	
	
	wire ram_area = {cpu_addr[15:6], 6'd0} == 16'h4040;//$4040 - 407F
	wire ram_we = ram_area & !cpu_rw & ram_we_on;
	assign ram_oe = ram_area & cpu_rw;
	
	wire wav_tick = wav_ctr[17] != wav_ctr[16] & !wav_off;

	//************************************************************* save state
	`include "../base/ss_ctrl_in.v"
	output[7:0]ss_rdat;
	
`ifndef SS_OFF
	assign ss_rdat[7:0] = 
	{ss_addr[7:4], 4'd0} == 8'd32 ? wav_ram[{2'd0, ss_addr[3:0]}][5:0] : 
	{ss_addr[7:4], 4'd0} == 8'd48 ? wav_ram[{2'd1, ss_addr[3:0]}][5:0] : 
	{ss_addr[7:4], 4'd0} == 8'd64 ? wav_ram[{2'd2, ss_addr[3:0]}][5:0] : 
	{ss_addr[7:4], 4'd0} == 8'd80 ? wav_ram[{2'd3, ss_addr[3:0]}][5:0] : 
	ss_addr[7:0] == 120 ? {ram_we_on, wav_off, wav_addr[5:0]}: 
	ss_addr[7:0] == 121 ? wav_freq[11:8] : 
	ss_addr[7:0] == 122 ? wav_freq[7:0] : 
	ss_addr[7:0] == 123 ? {master_vol[1:0], wav_val[5:0]} : 
	8'hff;
`endif
	
	
	always @(negedge m2)
`ifndef SS_OFF
	if(ss_act)
	begin
	
		if(ss_we & {ss_addr[7:4], 4'd0} == 8'd32)wav_ram[{2'd0, ss_addr[3:0]}][5:0] <= cpu_dat[5:0];
		if(ss_we & {ss_addr[7:4], 4'd0} == 8'd48)wav_ram[{2'd1, ss_addr[3:0]}][5:0] <= cpu_dat[5:0];
		if(ss_we & {ss_addr[7:4], 4'd0} == 8'd64)wav_ram[{2'd2, ss_addr[3:0]}][5:0] <= cpu_dat[5:0];
		if(ss_we & {ss_addr[7:4], 4'd0} == 8'd80)wav_ram[{2'd3, ss_addr[3:0]}][5:0] <= cpu_dat[5:0];
		if(ss_we & ss_addr[7:0] == 120) {ram_we_on, wav_off, wav_addr[5:0]} <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 121)wav_freq[11:8] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 122)wav_freq[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 123){master_vol[1:0], wav_val[5:0]} <= cpu_dat[7:0];
	end
		else
	//************************************************************* save state
`endif
	begin
	
		if(ram_we) wav_ram[cpu_addr[5:0]] <= cpu_dat[5:0];
		
		if(!cpu_rw & cpu_addr[15:0] == 16'h4082)wav_freq[7:0] <= cpu_dat[7:0];
		
		if(!cpu_rw & cpu_addr[15:0] == 16'h4083)
		begin
			wav_freq[11:8] <= cpu_dat[3:0];
			wav_off <= cpu_dat[7];
		end
		
		if(!cpu_rw & cpu_addr[15:0] == 16'h4089)
		begin
			ram_we_on <= cpu_dat[7];
			master_vol[1:0] <= cpu_dat[1:0];
		end
		

		if(wav_off)
		begin
			wav_addr <= 0;
			wav_ctr[15:0] <= 0;
		end
		
		if(wav_tick)wav_addr <= wav_addr + 1;
		
		if(!wav_off)wav_ctr[16:0] <= wav_ctr[16:0] + mod_val[14:0];//how many bits mod_val?
		
		wav_ctr[17] <= wav_ctr[16];
		

		if(!ram_we_on)wav_val <= wav_ram[wav_addr[5:0]];
		
	end

endmodule



module env_unit
(bus, vol_gain, mod_gain, ss_ctrl, ss_rdat);

	`include "../base/bus_in.v"
	output [5:0]vol_gain, mod_gain;
	
	
	wire env_clk_base = env_ctr_base == 7;// & !env_off;
	wire env_clk = env_clk_base & env_ctr == 0 & env_spd != 0;
	
	reg env_off;
	reg wav_off;
	reg [2:0]env_ctr_base;
	reg [7:0]env_ctr;
	reg [7:0]env_spd;
	
	//************************************************************* save state
	`include "../base/ss_ctrl_in.v"
	
	output[7:0]ss_rdat;
`ifndef SS_OFF
	assign ss_rdat[7:0] = 
	ss_addr[7:0] == 16 ? env_spd[7:0] : 
	ss_addr[7:0] == 17 ? env_ctr[7:0] : 
	ss_addr[7:0] == 18 ? {env_off, wav_off, env_ctr_base[2:0]} : 
	
	ss_addr[7:0] == 20 ? ss_rdat_evo[7:0] : 
	ss_addr[7:0] == 21 ? ss_rdat_evo[7:0] : 
	ss_addr[7:0] == 22 ? ss_rdat_evo[7:0] : ss_rdat_emo[7:0];
`endif
	
	
	always @(negedge m2)
`ifndef SS_OFF
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 16)env_spd[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 17)env_ctr[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 18){env_off, wav_off, env_ctr_base[2:0]} <= cpu_dat[7:0];
	end
		else
	//*************************************************************
`endif
	begin
		
		if(env_off)env_ctr_base <= 0;
			else
		env_ctr_base <= env_ctr_base + 1;
		
		if(env_off)env_ctr <= env_spd;
			else
		if(env_clk_base)env_ctr <= env_ctr == 0 ? env_spd : env_ctr - 1;
		
		
		if(!cpu_rw & cpu_addr[15:0] == 16'h4083){wav_off, env_off} <= cpu_dat[7:6];
		if(!cpu_rw & cpu_addr[15:0] == 16'h408A)env_spd[7:0] <= cpu_dat[7:0];
		
	end
	
	wire [7:0]ss_rdat_evo;
	wire vol_we = !cpu_rw & cpu_addr[15:0] == 16'h4080;
	envelope evol(bus, vol_we, env_clk, env_off, wav_off, vol_gain, ss_ctrl, ss_rdat_evo, 0);

	
	wire [7:0]ss_rdat_emo;
	wire mod_we = !cpu_rw & cpu_addr[15:0] == 16'h4084;
	envelope emod(bus, mod_we, env_clk, env_off, wav_off, mod_gain, ss_ctrl, ss_rdat_emo, 1);
	
endmodule


module envelope
(bus, we, env_clk, unit_off, halt, gain, ss_ctrl, ss_rdat, ss_ce);

	`include "../base/bus_in.v"
	
	input we, env_clk, unit_off, halt, ss_ce;
	output reg[5:0]gain;
	
	//can clock if spd==0 ?
	wire int_clk = env_clk & !off & int_ctr == 0 & !halt;
	
	reg [5:0]spd;
	reg dir, rst, off;
	reg [5:0]int_ctr;
	
	//************************************************************* save state
	`include "../base/ss_ctrl_in.v"
	
	output[7:0]ss_rdat;
`ifndef SS_OFF
	assign ss_rdat[7:0] = 
	ss_addr[7:0] == 20 & ss_ce == 0 ? {dir, rst, spd[5:0]} : 
	ss_addr[7:0] == 21 & ss_ce == 0 ? {off, int_ctr[5:0]} :
	ss_addr[7:0] == 22 & ss_ce == 0 ? gain[5:0] :
	
	ss_addr[7:0] == 23 & ss_ce == 1 ? {dir, rst, spd[5:0]} : 
	ss_addr[7:0] == 24 & ss_ce == 1 ? {off, int_ctr[5:0]} :
	ss_addr[7:0] == 25 & ss_ce == 1 ? gain[5:0] :
	8'hff;
`endif
	
	
	always @(negedge m2)
`ifndef SS_OFF
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 20 & ss_ce == 0){dir, rst, spd[5:0]} <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 21 & ss_ce == 0){off, int_ctr[5:0]} <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 22 & ss_ce == 0)gain[5:0] <= cpu_dat[5:0];
		
		if(ss_we & ss_addr[7:0] == 23 & ss_ce == 1){dir, rst, spd[5:0]} <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 24 & ss_ce == 1){off, int_ctr[5:0]} <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 25 & ss_ce == 1)gain[5:0] <= cpu_dat[5:0];
	end
		else
	//*************************************************************
`endif
	begin
		
		if(rst)rst <= 0;
		
		if(rst | unit_off)int_ctr <= spd;
			else
		if(env_clk & !off)int_ctr <= int_ctr == 0 ? spd : int_ctr - 1;
		
		
		if(we)
		begin
			rst <= 1; 
			dir <= cpu_dat[6];
			off <= cpu_dat[7];
			spd[5:0] <= cpu_dat[5:0];
			//if(cpu_dat[7])gain[5:0] <= cpu_dat[5:0];
		end
		
		if(we & cpu_dat[7])gain[5:0] <= cpu_dat[5:0];
			else
		if(int_clk)
		begin
			if(dir == 1 & gain[5] == 0)gain <= gain + 1;
			if(dir == 0 & gain != 0)gain <= gain - 1;
		end
	
	end
	

endmodule


module mod_unit
(bus, mod_counter, ss_ctrl, ss_rdat);
	
	`include "../base/bus_in.v"
	
	output reg [6:0]mod_counter;
	
	
	reg mod_off;
	reg [2:0]mod_table[32];
	reg [11:0]mod_freq;
	reg [17:0]mod_ctr;
	reg [5:0]mod_pos;
	
	wire mod_tick = mod_ctr[17] != mod_ctr[16] & mod_act;
	wire mod_act = !mod_off & mod_freq != 0;
	
	//************************************************************* save state
	`include "../base/ss_ctrl_in.v"
	output[7:0]ss_rdat;

`ifndef SS_OFF
	wire [4:0]sa0 = {2'd0, ss_addr[2:0]};
	wire [4:0]sa1 = {2'd1, ss_addr[2:0]};
	wire [4:0]sa2 = {2'd2, ss_addr[2:0]};
	wire [4:0]sa3 = {2'd3, ss_addr[2:0]};
	assign ss_rdat[7:0] = 
	{ss_addr[7:3], 3'd0} == 96 ? {mod_table[sa3][1:0], mod_table[sa2][1:0], mod_table[sa1][1:0], mod_table[sa0][1:0]} : 
	{ss_addr[7:3], 3'd0} == 104 ? {mod_table[sa3][2], mod_table[sa2][2], mod_table[sa1][2], mod_table[sa0][2]} : 	
	ss_addr[7:0] == 112 ? {mod_off, mod_counter[6:0]} :
	ss_addr[7:0] == 113 ? mod_freq[11:8] :
	ss_addr[7:0] == 114 ? mod_freq[7:0] :
	ss_addr[7:0] == 115 ? mod_ctr[15:8] :
	ss_addr[7:0] == 116 ? mod_ctr[7:0] :
	ss_addr[7:0] == 117 ? {mod_ctr[17:16], mod_pos[5:0]} :
	8'hff;
`endif
	
	always @(negedge m2)
`ifndef SS_OFF
	if(ss_act)
	begin
		if(ss_we & {ss_addr[7:3], 3'd0} == 96){mod_table[sa3][1:0], mod_table[sa2][1:0], mod_table[sa1][1:0], mod_table[sa0][1:0]} <= cpu_dat[7:0];
		if(ss_we & {ss_addr[7:3], 3'd0} == 104){mod_table[sa3][2], mod_table[sa2][2], mod_table[sa1][2], mod_table[sa0][2]} <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 112){mod_off, mod_counter[6:0]} <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 113)mod_freq[11:8] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 114)mod_freq[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 115)mod_ctr[15:8] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 116)mod_ctr[7:0] <= cpu_dat[7:0];
		if(ss_we & ss_addr[7:0] == 117){mod_ctr[17:16], mod_pos[5:0]} <= cpu_dat[7:0];
	end
		else
	//************************************************************* 
`endif
	begin
	
		if(!cpu_rw & cpu_addr[15:0] == 16'h4086)mod_freq[7:0] <= cpu_dat[7:0];
		
		if(!cpu_rw & cpu_addr[15:0] == 16'h4087)
		begin
			mod_freq[11:8] <= cpu_dat[3:0];
			mod_off <= cpu_dat[7];
		end
		
		if(!cpu_rw & cpu_addr[15:0] == 16'h4088 & mod_off)
		begin
			mod_pos[5:1] <= mod_pos[5:1] + 1;
			mod_table[mod_pos[5:1]] <= cpu_dat[2:0];
		end
	
		if(!cpu_rw & cpu_addr[15:0] == 16'h4085)
		begin
			mod_counter[6:0] <= cpu_dat[6:0];
			mod_pos[0] <= 0;//hack for bio miracle
		end
			else
		if(mod_tick)
		begin
				mod_counter[6:0] <=
				mod_table[mod_pos[5:1]][2:0] == 0 ? mod_counter[6:0] + 0 :
				mod_table[mod_pos[5:1]][2:0] == 1 ? mod_counter[6:0] + 1 :
				mod_table[mod_pos[5:1]][2:0] == 2 ? mod_counter[6:0] + 2 :
				mod_table[mod_pos[5:1]][2:0] == 3 ? mod_counter[6:0] + 4 :
				mod_table[mod_pos[5:1]][2:0] == 4 ? 0 :
				mod_table[mod_pos[5:1]][2:0] == 5 ? mod_counter[6:0] - 4 :
				mod_table[mod_pos[5:1]][2:0] == 6 ? mod_counter[6:0] - 2 : mod_counter[6:0] - 1;
				
				mod_pos <= mod_pos + 1;
		end
			
			
		if(mod_off)mod_ctr[15:0] <= 0;
		
		
		if(mod_act)mod_ctr[16:0] <= mod_ctr[16:0] + mod_freq;
		mod_ctr[17] <= mod_ctr[16];
		
	end
	
endmodule


module mod_calc_old
(mod_counter, mod_gain, freq, main_tick);

	input [6:0]mod_counter;
	input [5:0]mod_gain;
	input [11:0]freq;
	output [14:0]main_tick;

	wire sign_1 = mod_counter[6];
	wire [6:0] mod_counter_unsign = sign_1 ? (~mod_counter[6:0]) + 1 : mod_counter[6:0];
	wire [11:0]temp_1 = mod_counter_unsign[6:0] * mod_gain[5:0];
	wire [7:0]temp_2 = temp_1[11:4];
	wire [7:0]temp_3 = (temp_1[3:0] != 0) ? (sign_1 ? temp_2[7:0] + 1 : temp_2[7:0] + 2) : temp_2[7:0];
	wire wrap_on = (temp_3[7:0] >= 192 & !sign_1) | (temp_3[7:0] >= 64 & sign_1);
	wire sign_2 = wrap_on ? !sign_1 : sign_1;
	wire [7:0]temp_4 = wrap_on ? (~temp_3[7:0]) + 1 : temp_3[7:0];
	wire [7:0]temp_4_2 = (temp_3[7:0] >= 192 & !sign_1) ? temp_4 + 2 : temp_4;
	wire [19:0]temp_5 = temp_4_2[7:0] * freq[11:0];
	wire [13:0]temp_6 = temp_5[5:0] >= 32 ? temp_5[19:6] + 1 : temp_5[19:6];

	wire [14:0]main_tick = sign_2 ? freq - temp_6 : freq + temp_6;
	
endmodule

/*
module mod_calc
(ctr, gain, pitch, out);

	input [6:0]ctr;
	input [5:0]gain;
	input [11:0]pitch;
	output [14:0]out;

	wire neg = ctr[6];
	
	wire signed [15:0]ctr16 = neg ? ctr[6:0] | 16'hFF80 : ctr[5:0];
	wire signed [15:0]gain16 = gain;
	wire signed [15:0]pitch16 = pitch;
	
	
	wire signed[15:0]tmp1 = ctr16 * gain16;
	wire neg1 = tmp1[15];
	wire signed[15:0]tmp2 = neg1 ? {4'b1111, tmp1[15:4]} : tmp1[15:4];
	
	wire signed[15:0]tmp30 = tmp2 - 1;
	wire signed[15:0]tmp31 = tmp2 + 2;
	wire signed[15:0]tmp3 = tmp1[3:0] == 0 | tmp2[7] != 0 ? tmp2 : ctr16 < 0 ? tmp30 : tmp31;
	
	
	wire signed[15:0]tmp40 = tmp3 + 256;
	wire signed[15:0]tmp41 = tmp3 - 256;
	
	wire signed[15:0]tmp4 = tmp3 > 191 ? tmp41 : tmp3 < -64 ? tmp40 : tmp3;
	
	wire signed[15:0]tmp5 = pitch16 * tmp4;
	
	wire neg2 = tmp5[15];
	wire signed[15:0]tmp6 = neg2 ? {6'b111111, tmp5[15:6]} : tmp5[15:6];
	
	wire signed[15:0]tmp7 = tmp5[5:0] > 31 ? tmp6 + 1 : tmp6;
	
	wire signed[15:0]tmp8 = tmp7 + pitch16;
	
	assign out = tmp8;
	
endmodule*/
