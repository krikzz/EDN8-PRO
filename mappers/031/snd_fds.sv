

module fds_snd(

	input  CpuBus cpu,
	output bus_oe,
	output [7:0]dout,
	output [11:0]vol,
	
	input  SSTBus sst,
	output [7:0]ss_rdat
);

	assign bus_oe = gain_oe | ram_oe;
	
	assign dout[7:6] = 2'b01;
	assign dout[5:0] = 
	ram_oe ? {2'b00, ram_val[5:0]}:
	cpu.addr[3:0] == 4'h0 ? {2'b01, vol_gain[5:0]} : {2'b01, mod_gain[5:0]};
	
	
	
	wire gain_oe 		= cpu.rw & (cpu.addr[15:0] == 16'h4090 | cpu.addr[15:0] == 16'h4092);
	
	
	wire [5:0]vol_g 	= vol_gain > 32 ? 32 : vol_gain;
	wire [11:0]volx 	= vol_g * wav_val;
	wire [6:0] out1 	= (master_vol != 3) ? 0 : volx[10:4];
   wire [8:0] out2 	= out1 + ((master_vol != 2) ? 0 : volx[10:3]);
   wire [9:0] out4 	= out2 + ((master_vol == 1) ? 0 : volx[10:2]);
   assign vol 			= out4 + (master_vol[1] ? 0 : volx[10:1]);

	
	
	wire ram_oe;
	wire [1:0]master_vol;
	wire [5:0]ram_val;
	wire [5:0]wav_val;	
	wire [11:0]wav_freq;
	wav_unit wav_inst(cpu, mod_val, wav_val, ram_val, wav_freq, master_vol, ram_oe, sst, ss_rdat_wav);
	
	wire [6:0]mod_counter;
	mod_unit mod_inst(cpu, mod_counter, sst, ss_rdat_mod);

	wire [5:0]vol_gain, mod_gain;
	env_unit env_inst(cpu, vol_gain, mod_gain, sst, ss_rdat_env);

	
	
	
	wire [14:0]mod_val;
	mod_calc_old mod(mod_counter, mod_gain, wav_freq, mod_val);
	

	//************************************************************* save state
	assign ss_rdat[7:0] =
	{sst.addr[7:4], 4'd0} == 8'd16 	?  ss_rdat_env[7:0] : 
	{sst.addr[7:4], 4'd0} == 8'd96 	?  ss_rdat_mod[7:0] : 
	{sst.addr[7:3], 3'd0} == 8'd112 	?  ss_rdat_mod[7:0] : 
	ss_rdat_wav[7:0];
	
	wire [7:0]ss_rdat_wav;//32-95 and 120-123
	wire [7:0]ss_rdat_mod;//96-117
	wire [7:0]ss_rdat_env;//16-31
	
endmodule






module wav_unit
(cpu, mod_val, wav_val, ram_val, wav_freq, master_vol, ram_oe, sst, ss_rdat);
	
	input  CpuBus cpu;
	input  SSTBus sst;
	input  [14:0]mod_val;
	output reg [11:0]wav_freq;
	output reg[5:0]wav_val;
	output [5:0]ram_val;
	output reg[1:0]master_vol;
	output ram_oe;
	output [7:0]ss_rdat;

	assign ram_val[5:0] = wav_ram[cpu.addr[5:0]];
	
	reg ram_we_on;
	reg wav_off;
	
	reg [5:0]wav_addr;
	reg [17:0]wav_ctr;
	reg [5:0]wav_ram[64];
	
	
	wire ram_area 	= {cpu.addr[15:6], 6'd0} == 16'h4040;//$4040 - 407F
	wire ram_we 	= ram_area & !cpu.rw & ram_we_on;
	assign ram_oe 	= ram_area & cpu.rw;
	
	wire wav_tick 	= wav_ctr[17] != wav_ctr[16] & !wav_off;

	//************************************************************* save state	
	assign ss_rdat[7:0] = 
	{sst.addr[7:4], 4'd0} == 8'd32 ? wav_ram[{2'd0, sst.addr[3:0]}][5:0] : 
	{sst.addr[7:4], 4'd0} == 8'd48 ? wav_ram[{2'd1, sst.addr[3:0]}][5:0] : 
	{sst.addr[7:4], 4'd0} == 8'd64 ? wav_ram[{2'd2, sst.addr[3:0]}][5:0] : 
	{sst.addr[7:4], 4'd0} == 8'd80 ? wav_ram[{2'd3, sst.addr[3:0]}][5:0] : 
	sst.addr[7:0] == 120 ? {ram_we_on, wav_off, wav_addr[5:0]}: 
	sst.addr[7:0] == 121 ? wav_freq[11:8] : 
	sst.addr[7:0] == 122 ? wav_freq[7:0] : 
	sst.addr[7:0] == 123 ? {master_vol[1:0], wav_val[5:0]} : 
	8'hff;
	
	
	always @(negedge cpu.m2)
	if(sst.act)
	begin
	
		if(sst.we_reg & {sst.addr[7:4], 4'd0} == 8'd32)wav_ram[{2'd0, sst.addr[3:0]}][5:0] <= sst.dato[5:0];
		if(sst.we_reg & {sst.addr[7:4], 4'd0} == 8'd48)wav_ram[{2'd1, sst.addr[3:0]}][5:0] <= sst.dato[5:0];
		if(sst.we_reg & {sst.addr[7:4], 4'd0} == 8'd64)wav_ram[{2'd2, sst.addr[3:0]}][5:0] <= sst.dato[5:0];
		if(sst.we_reg & {sst.addr[7:4], 4'd0} == 8'd80)wav_ram[{2'd3, sst.addr[3:0]}][5:0] <= sst.dato[5:0];
		if(sst.we_reg & sst.addr[7:0] == 120) {ram_we_on, wav_off, wav_addr[5:0]} 	<= sst.dato[7:0];
		if(sst.we_reg & sst.addr[7:0] == 121)wav_freq[11:8] 								<= sst.dato[7:0];
		if(sst.we_reg & sst.addr[7:0] == 122)wav_freq[7:0] 								<= sst.dato[7:0];
		if(sst.we_reg & sst.addr[7:0] == 123){master_vol[1:0], wav_val[5:0]} 		<= sst.dato[7:0];
	end
		else
	begin
	
		if(ram_we) wav_ram[cpu.addr[5:0]] <= cpu.data[5:0];
		
		if(!cpu.rw & cpu.addr[15:0] == 16'h4082)wav_freq[7:0] <= cpu.data[7:0];
		
		if(!cpu.rw & cpu.addr[15:0] == 16'h4083)
		begin
			wav_freq[11:8] 	<= cpu.data[3:0];
			wav_off 				<= cpu.data[7];
		end
		
		if(!cpu.rw & cpu.addr[15:0] == 16'h4089)
		begin
			ram_we_on 			<= cpu.data[7];
			master_vol[1:0] 	<= cpu.data[1:0];
		end
		

		if(wav_off)
		begin
			wav_addr 		<= 0;
			wav_ctr[15:0] 	<= 0;
		end
		
		if(wav_tick)wav_addr <= wav_addr + 1;
		
		if(!wav_off)wav_ctr[16:0] <= wav_ctr[16:0] + mod_val[14:0];//how many bits mod_val?
		
		wav_ctr[17] <= wav_ctr[16];
		

		if(!ram_we_on)wav_val <= wav_ram[wav_addr[5:0]];
		
	end

endmodule



module env_unit
(cpu, vol_gain, mod_gain, sst, ss_rdat);

	input  CpuBus cpu;
	input  SSTBus sst;
	output [5:0]vol_gain, mod_gain;
	output [7:0]ss_rdat;
	
	
	wire env_clk_base = env_ctr_base == 7;// & !env_off;
	wire env_clk = env_clk_base & env_ctr == 0 & env_spd != 0;
	
	reg env_off;
	reg wav_off;
	reg [2:0]env_ctr_base;
	reg [7:0]env_ctr;
	reg [7:0]env_spd;
	
	//************************************************************* save state
	assign ss_rdat[7:0] = 
	sst.addr[7:0] == 16 ? env_spd[7:0] : 
	sst.addr[7:0] == 17 ? env_ctr[7:0] : 
	sst.addr[7:0] == 18 ? {env_off, wav_off, env_ctr_base[2:0]} : 
	
	sst.addr[7:0] == 20 ? ss_rdat_evo[7:0] : 
	sst.addr[7:0] == 21 ? ss_rdat_evo[7:0] : 
	sst.addr[7:0] == 22 ? ss_rdat_evo[7:0] : ss_rdat_emo[7:0];
	
	
	always @(negedge cpu.m2)
	if(sst.act)
	begin
		if(sst.we_reg & sst.addr[7:0] == 16)env_spd[7:0] <= sst.dato[7:0];
		if(sst.we_reg & sst.addr[7:0] == 17)env_ctr[7:0] <= sst.dato[7:0];
		if(sst.we_reg & sst.addr[7:0] == 18){env_off, wav_off, env_ctr_base[2:0]} <= sst.dato[7:0];
	end
		else
	begin
		
		if(env_off)env_ctr_base <= 0;
			else
		env_ctr_base <= env_ctr_base + 1;
		
		if(env_off)env_ctr <= env_spd;
			else
		if(env_clk_base)env_ctr <= env_ctr == 0 ? env_spd : env_ctr - 1;
		
		
		if(!cpu.rw & cpu.addr[15:0] == 16'h4083){wav_off, env_off} 	<= cpu.data[7:6];
		if(!cpu.rw & cpu.addr[15:0] == 16'h408A)env_spd[7:0] 			<= cpu.data[7:0];
		
	end
	
	wire [7:0]ss_rdat_evo;
	wire vol_we = !cpu.rw & cpu.addr[15:0] == 16'h4080;
	envelope evol(cpu, vol_we, env_clk, env_off, wav_off, vol_gain, sst, ss_rdat_evo, 0);

	
	wire [7:0]ss_rdat_emo;
	wire mod_we = !cpu.rw & cpu.addr[15:0] == 16'h4084;
	envelope emod(cpu, mod_we, env_clk, env_off, wav_off, mod_gain, sst, ss_rdat_emo, 1);
	
endmodule


module envelope
(cpu, we, env_clk, unit_off, halt, gain, sst, ss_rdat, ss_ce);

	
	input  CpuBus cpu;
	input  SSTBus sst;
	input we, env_clk, unit_off, halt, ss_ce;
	output reg[5:0]gain;
	output[7:0]ss_rdat;
	
	//can clock if spd==0 ?
	wire int_clk = env_clk & !off & int_ctr == 0 & !halt;
	
	reg [5:0]spd;
	reg dir, rst, off;
	reg [5:0]int_ctr;
	
	//************************************************************* save state
	assign ss_rdat[7:0] = 
	sst.addr[7:0] == 20 & ss_ce == 0 ? {dir, rst, spd[5:0]} : 
	sst.addr[7:0] == 21 & ss_ce == 0 ? {off, int_ctr[5:0]} :
	sst.addr[7:0] == 22 & ss_ce == 0 ? gain[5:0] :
	
	sst.addr[7:0] == 23 & ss_ce == 1 ? {dir, rst, spd[5:0]} : 
	sst.addr[7:0] == 24 & ss_ce == 1 ? {off, int_ctr[5:0]} :
	sst.addr[7:0] == 25 & ss_ce == 1 ? gain[5:0] :
	8'hff;

	
	always @(negedge cpu.m2)
	if(sst.act)
	begin
		if(sst.we_reg & sst.addr[7:0] == 20 & ss_ce == 0){dir, rst, spd[5:0]} 	<= sst.dato[7:0];
		if(sst.we_reg & sst.addr[7:0] == 21 & ss_ce == 0){off, int_ctr[5:0]} 	<= sst.dato[7:0];
		if(sst.we_reg & sst.addr[7:0] == 22 & ss_ce == 0)gain[5:0] 					<= sst.dato[5:0];
		
		if(sst.we_reg & sst.addr[7:0] == 23 & ss_ce == 1){dir, rst, spd[5:0]} 	<= sst.dato[7:0];
		if(sst.we_reg & sst.addr[7:0] == 24 & ss_ce == 1){off, int_ctr[5:0]} 	<= sst.dato[7:0];
		if(sst.we_reg & sst.addr[7:0] == 25 & ss_ce == 1)gain[5:0] 					<= sst.dato[5:0];
	end
		else
	begin
		
		if(rst)rst <= 0;
		
		if(rst | unit_off)int_ctr <= spd;
			else
		if(env_clk & !off)int_ctr <= int_ctr == 0 ? spd : int_ctr - 1;
		
		
		if(we)
		begin
			rst 		<= 1; 
			dir 		<= cpu.data[6];
			off 		<= cpu.data[7];
			spd[5:0] <= cpu.data[5:0];
		end
		
		if(we & cpu.data[7])gain[5:0] 		<= cpu.data[5:0];
			else
		if(int_clk)
		begin
			if(dir == 1 & gain[5] == 0)gain 	<= gain + 1;
			if(dir == 0 & gain != 0)gain 		<= gain - 1;
		end
	
	end
	

endmodule


module mod_unit
(cpu, mod_counter, sst, ss_rdat);
	
	
	input  CpuBus cpu;
	input  SSTBus sst;
	output reg [6:0]mod_counter;
	output[7:0]ss_rdat;
	
	
	reg mod_off;
	reg [2:0]mod_table[32];
	reg [11:0]mod_freq;
	reg [17:0]mod_ctr;
	reg [5:0]mod_pos;
	
	wire mod_tick = mod_ctr[17] != mod_ctr[16] & mod_act;
	wire mod_act = !mod_off & mod_freq != 0;
	
	//************************************************************* save state
	wire [4:0]sa0 = {2'd0, sst.addr[2:0]};
	wire [4:0]sa1 = {2'd1, sst.addr[2:0]};
	wire [4:0]sa2 = {2'd2, sst.addr[2:0]};
	wire [4:0]sa3 = {2'd3, sst.addr[2:0]};
	
	assign ss_rdat[7:0] = 
	{sst.addr[7:3], 3'd0} == 96 ? {mod_table[sa3][1:0], mod_table[sa2][1:0], mod_table[sa1][1:0], mod_table[sa0][1:0]} : 
	{sst.addr[7:3], 3'd0} == 104 ? {mod_table[sa3][2], mod_table[sa2][2], mod_table[sa1][2], mod_table[sa0][2]} : 	
	sst.addr[7:0] == 112 ? {mod_off, mod_counter[6:0]} :
	sst.addr[7:0] == 113 ? mod_freq[11:8] :
	sst.addr[7:0] == 114 ? mod_freq[7:0] :
	sst.addr[7:0] == 115 ? mod_ctr[15:8] :
	sst.addr[7:0] == 116 ? mod_ctr[7:0] :
	sst.addr[7:0] == 117 ? {mod_ctr[17:16], mod_pos[5:0]} :
	8'hff;
	
	always @(negedge cpu.m2)
	if(sst.act)
	begin
		if(sst.we_reg & {sst.addr[7:3], 3'd0} == 96){mod_table[sa3][1:0], mod_table[sa2][1:0], mod_table[sa1][1:0], mod_table[sa0][1:0]} <= sst.dato[7:0];
		if(sst.we_reg & {sst.addr[7:3], 3'd0} == 104){mod_table[sa3][2], mod_table[sa2][2], mod_table[sa1][2], mod_table[sa0][2]} 			<= sst.dato[7:0];
		if(sst.we_reg & sst.addr[7:0] == 112){mod_off, mod_counter[6:0]} <= sst.dato[7:0];
		if(sst.we_reg & sst.addr[7:0] == 113)mod_freq[11:8] 	<= sst.dato[7:0];
		if(sst.we_reg & sst.addr[7:0] == 114)mod_freq[7:0] 	<= sst.dato[7:0];
		if(sst.we_reg & sst.addr[7:0] == 115)mod_ctr[15:8] 	<= sst.dato[7:0];
		if(sst.we_reg & sst.addr[7:0] == 116)mod_ctr[7:0] 		<= sst.dato[7:0];
		if(sst.we_reg & sst.addr[7:0] == 117){mod_ctr[17:16], mod_pos[5:0]} <= sst.dato[7:0];
	end
		else
	begin
	
		if(!cpu.rw & cpu.addr[15:0] == 16'h4086)mod_freq[7:0] <= cpu.data[7:0];
		
		if(!cpu.rw & cpu.addr[15:0] == 16'h4087)
		begin
			mod_freq[11:8] 	<= cpu.data[3:0];
			mod_off 				<= cpu.data[7];
		end
		
		if(!cpu.rw & cpu.addr[15:0] == 16'h4088 & mod_off)
		begin
			mod_pos[5:1] 				<= mod_pos[5:1] + 1;
			mod_table[mod_pos[5:1]] <= cpu.data[2:0];
		end
	
		if(!cpu.rw & cpu.addr[15:0] == 16'h4085)
		begin
			mod_counter[6:0] 	<= cpu.data[6:0];
			mod_pos[0] 			<= 0;//hack for bio miracle
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
			
		if(mod_off)
		begin
			mod_ctr[15:0] <= 0;
		end
		
		if(mod_act)
		begin
			mod_ctr[16:0] <= mod_ctr[16:0] + mod_freq;
		end
		
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

