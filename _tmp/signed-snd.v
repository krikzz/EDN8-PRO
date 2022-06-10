
module dac_ds(

	input  clk, 
	input  m2,
	input  [DEPTH-1:0]vol,
	input  [7:0]master_vol,
	output reg snd
);
	
	parameter DEPTH = 16;
	

	wire signed[DEPTH+1:0]delta;
	wire signed[DEPTH+1:0]sigma;
	

	reg signed[DEPTH+1:0] sigma_st;	
	reg signed[DEPTH-1:0] vol_mul;

	assign	delta[DEPTH+1:0] = {2'b0, vol_mul[DEPTH-1:0]} + {sigma_st[DEPTH+1], sigma_st[DEPTH+1], {(DEPTH){1'b0}}};
	assign	sigma[DEPTH+1:0] = delta[DEPTH+1:0] + sigma_st[DEPTH+1:0];

	
	reg mclk;
	always @(negedge m2)
	begin
		mclk <= !mclk;
	end
	
	always @(posedge mclk)
	begin
		vol_mul[DEPTH-1:0] 	<= (vol_s[DEPTH-1:0] * master_vol) / 128;
	end
	
	
	always @(posedge clk) 
	begin
		sigma_st[DEPTH+1:0] 	<= sigma[DEPTH+1:0];
		snd	<= !sigma_st[DEPTH+1];//inverted
	end
	
	
	
	wire signed  [DEPTH-1:0]vol_s;
	
	sig_wave sw_inst(
		
		.clk(mclk),
		.snd_i(vol),
		.snd_o(vol_s)
	);
	
endmodule 


//signed wave
module sig_wave(
 
	input clk,
	input [15:0]snd_i,
	output reg signed[15:0]snd_o
 );
 
	reg [15:0]snd_i_st;
	reg signed[16:0]delta;
	
	wire signed [17:0]snd_next = snd_o + delta;
	
	always @(posedge clk)
	begin
		
		snd_i_st <= snd_i;
		delta 	<= snd_i - snd_i_st;
		
		if(snd_next < -32768)
		begin
			snd_o <= -32768;
		end
			else
		if(snd_next > 32767)
		begin
			snd_o <= 32767;
		end
			else
		begin
			snd_o 	<= snd_next;
		end
	end
 
 endmodule
 