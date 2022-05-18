//**********************************************
// * SUNSOFT 5A/5B/FME-7 Mapper Implementation *
// *        for EVERDRIVE N8 by krikzz         *
// *     === (c) 2015 by Necronomfive ===      *
// *********************************************

module ym2149(
cpu_d,cpu_a, cpu_ce_n, cpu_rw, phi_2,
audio_out, map_enable);

/* ========================
   **** I/O Assignments ***
   ========================
*/

	input				phi_2;
	
	input [7:0]		cpu_d;
	input [14:10]	cpu_a;
	input				cpu_ce_n;
	input				cpu_rw;
	
	output reg		[11:0]audio_out;

	input				map_enable;
	

/* ==============
   **** Wires ***
   ==============
*/

	
	
	wire [2:0]	pulse_out;
	wire			noise_out;
	wire [2:0]	mix_out;
	
	wire [4:0]	env_out;

	wire [4:0]	voice0;
	wire [4:0]	voice1;
	wire [4:0]	voice2;
	
	wire [7:0]	level0;
	wire [7:0]	level1;
	wire [7:0]	level2;
	

	
/* ==================
   **** Registers ***
   ==================
*/

	reg [3:0]	aud_dat;
	
	
	reg [3:0]	aud_reg;
	
	reg [2:0]	aud_pulse_mix;
	reg [2:0]	aud_noise_mix;
	
	reg [4:0]	aud_lvl_cnt0;
	reg [4:0]	aud_lvl_cnt1;
	reg [4:0]	aud_lvl_cnt2;
	
	reg [3:0]	aud_env_mode;
	
	reg [7:0]	level0_l;
	reg [7:0]	level1_l;
	reg [7:0]	level2_l;	
	
	
/* ====================
   **** Assignments ***
   ====================
*/	

	
	wire	cpu_sel_aud_reg = ~cpu_ce_n & ~cpu_rw & (cpu_a[14:13]==2'b10) & map_enable;
	wire	cpu_sel_aud_dat = ~cpu_ce_n & ~cpu_rw & (cpu_a[14:13]==2'b11) & map_enable;
	
	wire	cpu_sel_aud_frq0 = cpu_sel_aud_dat & (aud_reg[3:1]==3'b000);
	wire	cpu_sel_aud_frq1 = cpu_sel_aud_dat & (aud_reg[3:1]==3'b001);	
	wire	cpu_sel_aud_frq2 = cpu_sel_aud_dat & (aud_reg[3:1]==3'b010);	
	
	wire	cpu_sel_noise_frq = cpu_sel_aud_dat & (aud_reg[3:0]==4'b0110);
	
	wire	cpu_sel_env_frq = cpu_sel_aud_dat & ((aud_reg[3:0]==4'b1011) | (aud_reg[3:0]==4'b1100));	
	wire	cpu_sel_env_trigger = cpu_sel_aud_dat & (aud_reg[3:0]==4'b1101);	
	

// ======= Audio Part ======


	always @(negedge phi_2) begin
		if (~map_enable) begin
			aud_lvl_cnt0[4:0] <= 5'b0;
			aud_lvl_cnt1[4:0] <= 5'b0;
			aud_lvl_cnt2[4:0] <= 5'b0;
			aud_pulse_mix[2:0] <= 3'b0;
			aud_noise_mix[2:0] <= 3'b0;
			aud_env_mode[3:0]	<= 3'b0;
		end
		else begin
			if (cpu_sel_aud_reg) begin
				aud_reg[3:0] <= cpu_d[3:0];
			end
			else if (cpu_sel_aud_dat) begin
				case (aud_reg[3:0])				
					4'b0111 : {aud_noise_mix[2:0],aud_pulse_mix[2:0]} <= cpu_d[5:0];
					4'b1000 : aud_lvl_cnt0[4:0] <= cpu_d[4:0];
					4'b1001 : aud_lvl_cnt1[4:0] <= cpu_d[4:0];
					4'b1010 : aud_lvl_cnt2[4:0] <= cpu_d[4:0];
					4'b1101 : aud_env_mode[3:0] <= cpu_d[3:0];					
				endcase				
			end
		end		
	end

	// Pulse wave generators
	
	pulse_gen pulse_0(
		.clk	(phi_2),
		.reset(~map_enable),
		.d		(cpu_d[7:0]),
		.sel	(aud_reg[0]),
		.write(cpu_sel_aud_frq0),
		.wave	(pulse_out[0])
	);
	
	pulse_gen pulse_1(
		.clk	(phi_2),
		.reset(~map_enable),
		.d		(cpu_d[7:0]),
		.sel	(aud_reg[0]),
		.write(cpu_sel_aud_frq1),
		.wave	(pulse_out[1])
	);

	pulse_gen pulse_2(
		.clk	(phi_2),
		.reset(~map_enable),
		.d		(cpu_d[7:0]),
		.sel	(aud_reg[0]),
		.write(cpu_sel_aud_frq2),
		.wave	(pulse_out[2])
	);	
	
	// Noise generator
	
	noise_gen noise(
		.clk	(phi_2),
		.reset(~map_enable),
		.d		(cpu_d[4:0]),
		.write(cpu_sel_noise_frq),
		.wave	(noise_out)
	);	
	
	// Envelope generator
	
	evelope_gen envelope(
		.clk			(phi_2),
		.reset		(~map_enable),
		.d				(cpu_d[7:0]),
		.sel			(aud_reg[0]),
		.write		(cpu_sel_env_frq),
		.env_trigger(cpu_sel_env_trigger),
		.env_mode	(aud_env_mode[3:0]),
		.env_out		(env_out[4:0])	
	);
	
	// Mix stage 1: pulse + noise
	
	assign mix_out[2:0] = {(pulse_out[2]|aud_pulse_mix[2])&(noise_out|aud_noise_mix[2])
								, (pulse_out[1]|aud_pulse_mix[1])&(noise_out|aud_noise_mix[1])
								, (pulse_out[0]|aud_pulse_mix[0])&(noise_out|aud_noise_mix[0])};
	
	// Mix stage 2: voice + volume (fixed or envelope)
	
	assign voice0[4:0] = mix_out[0] ? (aud_lvl_cnt0[4] ? env_out[4:0] : {aud_lvl_cnt0[3:0],1'b0}) : 5'b00000;
	assign voice1[4:0] = mix_out[1] ? (aud_lvl_cnt1[4] ? env_out[4:0] : {aud_lvl_cnt1[3:0],1'b0}) : 5'b00000;	
	assign voice2[4:0] = mix_out[2] ? (aud_lvl_cnt2[4] ? env_out[4:0] : {aud_lvl_cnt2[3:0],1'b0}) : 5'b00000;		
	
	// Mix stage 3: linear -> logarithmic volume curve (based on chip measurements)
	
	log_table conv_lev0(
		.in	(voice0[4:0]),
		.out	(level0[7:0])
	);
	
	log_table conv_lev1(
		.in	(voice1[4:0]),
		.out	(level1[7:0])
	);

	log_table conv_lev2(
		.in	(voice2[4:0]),
		.out	(level2[7:0])
	);
	
	// Mix stage 4: final mix & volume
	
	always @(negedge phi_2) 
	begin
	
		level0_l[7:0] <= level0[7:0];
		level1_l[7:0] <= level1[7:0];		
		level2_l[7:0] <= level2[7:0];
			
		audio_out[11:0] <= {2'b00,level0_l[7:0],2'b00}
								+ {2'b00,level1_l[7:0],2'b00}
								+ {2'b00,level2_l[7:0],2'b00}
								+ {4'b0000,level0_l[7:0]}
								+ {4'b0000,level1_l[7:0]}
								+ {4'b0000,level2_l[7:0]};
	end
	

	
endmodule

/* ===================================================================================================== */

// Pulse waveform generator

module pulse_gen(clk,reset,
	d,sel,write,
	wave);

	input		clk;
	input		reset;

	input	[7:0] d;
	input		sel;
	input		write;
	
	output	wave;
	
	reg [15:0]	audio_phase;
	reg [11:0]	audio_period;
	reg			wave;
	
	always @(negedge clk) begin
		audio_period[11:0] <= write ? (sel ? {d[3:0],audio_period[7:0]}:{audio_period[11:8],d[7:0]} ): audio_period[11:0];	
	end
	
	always @(negedge clk) begin
		if (reset) begin
			audio_phase[15:0] = 16'b0;
			wave <= 1'b0;
		end
		else begin
			if (audio_phase[15:4] >= audio_period[11:0]) begin
				audio_phase[15:0] = 16'b0;
				wave <= ~wave;
			end
			else begin
				audio_phase[15:0] <= audio_phase[15:0] + 16'b1;
			end
		end
	end
	
endmodule

/* ===================================================================================================== */

// Noise waveform generator

module noise_gen(clk,reset,
	d,write,
	wave);

	input		clk;
	input		reset;

	input	[4:0] d;
	input		write;
	
	output	wave;
		
	reg [4:0]	noise_period;
	reg [9:0]	noise_phase;
	reg [16:0]	noise_lfsr;
	
	assign	wave = noise_lfsr[16];
	
	always @(negedge clk) begin
		noise_period[4:0] <= write ? d[4:0] : noise_period[4:0];	
	end	
	
	always @(negedge clk) begin
		if (reset) begin
			noise_phase[9:0] <= 10'b1;
			noise_lfsr[16:0] <= 17'b0;
		end
		else begin
			if (noise_phase[9:5] >= noise_period[4:0]) begin
				noise_phase[9:0] <= 10'b0;
				noise_lfsr[16:0] <= {noise_lfsr[16:1],noise_lfsr[16]^noise_lfsr[13]};
			end
			else begin
				noise_phase[9:0] <= noise_phase[9:0] + 10'b1;
			end
		end
	end
	
endmodule

/* ===================================================================================================== */

// Envelope generator

module evelope_gen(clk,reset,
	d,sel,write,
	env_trigger,env_mode,env_out);

	input		clk;
	input		reset;

	input	[7:0] d;
	input		sel;
	input		write;
	
	input				env_trigger;
	input  [3:0]	env_mode;
	output [4:0]	env_out;
	
	
	reg [15:0]		env_period;
	reg [15:0]		env_phase;
	reg [8:0]		env_cnt;
	
	reg				env_stop;
	reg				env_cycle;
	
	assign			env_out[4:0] = env_cnt[8:4] ^ {5{env_mode[2]}} ^ {5{env_cycle}}; 
	
	always @(negedge clk) begin
		env_period[15:0] <= write ? (~sel ? {d[7:0],env_period[7:0]}:{env_period[15:8],d[7:0]} ): env_period[11:0];	
	end	
	
	always @(negedge clk) begin
		if (reset) begin
			env_phase[15:0] = 16'b0;
			env_cnt[8:0] = 9'b0;
		end
		else begin
			if (env_trigger) begin
				env_phase[15:0] = 16'b0;
				env_cnt[8:0] <= 9'b0;
				env_cycle <= 1'b0;
			end
			else if (env_phase[15:0] == env_period[15:0]) begin
				env_phase[15:0] = 16'b0;
				if (env_cnt[8:0] != 9'b1_1111_1111) begin
					env_cnt[8:0] <= env_cnt[8:0]+ 9'b1;
				end
				else begin
					env_cnt[8:0] <=  env_mode[0]|env_mode[3] ? env_cnt[8:0] :  env_cnt[8:0] + 9'b1;
					env_cycle <= (env_mode[3] ? env_mode[1] : env_mode[2]) ? ~env_cycle : env_cycle;
				end
			end
			else begin
				env_phase[15:0] <= env_phase[15:0] + 16'b1;
			end
		end
	end	
	
endmodule

/* ===================================================================================================== */

// Log table based on AY-3-8910 chip measurements

module log_table(in,out);

	input	[4:0]		in;
	output [7:0]	out;	

	reg [7:0] out;
	
	always @* begin
		case (in)
			5'b0_0000 : out = 8'd0;
			5'b0_0001 : out = 8'd1;
			5'b0_0010 : out = 8'd2;
			5'b0_0011 : out = 8'd3;
			5'b0_0100 : out = 8'd3;
			5'b0_0101 : out = 8'd4;
			5'b0_0110 : out = 8'd5;
			5'b0_0111 : out = 8'd6;
			5'b0_1000 : out = 8'd8;
			5'b0_1001 : out = 8'd9;
			5'b0_1010 : out = 8'd11;
			5'b0_1011 : out = 8'd13;
			5'b0_1100 : out = 8'd16;
			5'b0_1101 : out = 8'd18;
			5'b0_1110 : out = 8'd24;
			5'b0_1111 : out = 8'd29;
			5'b1_0000 : out = 8'd32;
			5'b1_0001 : out = 8'd34;
			5'b1_0010 : out = 8'd44;
			5'b1_0011 : out = 8'd55;
			5'b1_0100 : out = 8'd61;
			5'b1_0101 : out = 8'd66;
			5'b1_0110 : out = 8'd82;
			5'b1_0111 : out = 8'd98;
			5'b1_1000 : out = 8'd114;
			5'b1_1001 : out = 8'd130;
			5'b1_1010 : out = 8'd148;
			5'b1_1011 : out = 8'd166;
			5'b1_1100 : out = 8'd187;
			5'b1_1101 : out = 8'd207;
			5'b1_1110 : out = 8'd231;
			5'b1_1111 : out = 8'd255;			
		endcase
	end
endmodule

/* ===================================================================================================== */

// Delta-sigma DAC

module DAC_delta_sigma (
	clk_i,reset_n_i,
	dac_input_i,dac_output_o
);

parameter DEPTH = 12;

/* ========================
   **** I/O Assignments ***
   ========================
*/

// Clock & reset
	
	input						clk_i;
	input						reset_n_i;
	
// Digital in / output

	input		[DEPTH-1:0]	dac_input_i;
	output					dac_output_o;

/* ==============
   **** Wires ***
   ==============
*/

	wire		[DEPTH+1:0]	delta_add;
	wire		[DEPTH+1:0]	sigma_add;
	
/* ==================
   **** Registers ***
   ==================
*/

	reg		[DEPTH+1:0]	sigma_latch;	
	reg		[DEPTH-1:0]	dac_input;
	reg						dac_output_o;

	
/* ====================
   **** Assignments ***
   ====================
*/	

	assign	delta_add[DEPTH+1:0] = {2'b0,dac_input[DEPTH-1:0]} + {sigma_latch[DEPTH+1],sigma_latch[DEPTH+1],{(DEPTH){1'b0}}};
	assign	sigma_add[DEPTH+1:0] = delta_add[DEPTH+1:0] + sigma_latch[DEPTH+1:0];

/* ==========================
   **** Begin of RTL Code ***
   ==========================
*/

	always @(posedge clk_i) begin
		if (~reset_n_i) begin
			sigma_latch[DEPTH+1:0] 	<= {2'b01,{(DEPTH){1'b0}}};
			dac_input[DEPTH-1:0] 	<= {(DEPTH){1'b0}};
			dac_output_o 				<= 1'b0;
		end
		else begin
			sigma_latch[DEPTH+1:0] 	<= sigma_add[DEPTH+1:0];
			dac_input[DEPTH-1:0] 	<= dac_input_i[DEPTH-1:0];
			dac_output_o 				<= sigma_latch[DEPTH+1];
		end
	end
	
endmodule 