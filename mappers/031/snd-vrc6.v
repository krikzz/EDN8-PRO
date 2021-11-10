
`include "../base/defs.v"

module snd_vrc6
(bus, snd_vol, chr_reg_addr);

	`include "../base/bus_in.v"
	
	output [6:0]snd_vol;
	input [1:0]chr_reg_addr;
	
	
	reg [7:0]pulse1;
	reg [11:0]freq1;
	reg chan_on1;
	
	reg [7:0]pulse2;
	reg [11:0]freq2;
	reg chan_on2;
	
	reg [5:0]sw_arate;
	reg [11:0]sw_freq;
	reg sw_chan_on;
	
	always @(negedge m2)
	if(map_rst)
	begin
		chan_on1 <= 0;
		chan_on2 <= 0;
		sw_chan_on <= 0;
	end
		else
	if(!cpu_ce & !cpu_rw)
	case(cpu_addr[14:12])
		1:begin//snd
			if(chr_reg_addr == 0)pulse1[7:0] <= cpu_dat[7:0];
				else
			if(chr_reg_addr == 1)freq1[7:0] <= cpu_dat[7:0];
				else
			if(chr_reg_addr == 2)
			begin
				freq1[11:8] <= cpu_dat[3:0];
				chan_on1 <= cpu_dat[7];
			end
		end
		2:begin//snd
			if(chr_reg_addr == 0)pulse2[7:0] <= cpu_dat[7:0];
				else
			if(chr_reg_addr == 1)freq2[7:0] <= cpu_dat[7:0];
				else
			if(chr_reg_addr == 2)
			begin
				freq2[11:8] <= cpu_dat[3:0];
				chan_on2 <= cpu_dat[7];
			end
		end
		3:begin
			if(chr_reg_addr == 0)sw_arate[5:0] <= cpu_dat[5:0];
				else
			if(chr_reg_addr == 1)sw_freq[7:0] <= cpu_dat[7:0];
				else
			if(chr_reg_addr == 2)
			begin
				sw_freq[11:8] <= cpu_dat[3:0];
				sw_chan_on <= cpu_dat[7];
			end
				//else
			
				//else
			//prg_mode <= cpu_dat[1];
		end
	endcase

	
	wire [4:0]pgen_out1;
	pulse_gen pulse_gen1(pulse1, freq1, chan_on1, m2, pgen_out1, snd_dac_clk);
	
	wire [4:0]pgen_out2;
	pulse_gen pulse_gen2(pulse2, freq2, chan_on2, m2, pgen_out2, snd_dac_clk);
	
	
	wire [4:0]sw_out;
	sawtooth sawtooth1(sw_arate, sw_freq, sw_chan_on, m2, sw_out, snd_dac_clk);
	
	
	assign snd_vol[6:0] = pgen_out1 + pgen_out2 + sw_out;

	
endmodule


module pulse_gen
(pulse, freq, chan_on, m2, snd, clk);
	
	input [7:0]pulse;
	input [11:0]freq;
	input chan_on, m2, clk;
	output [4:0]snd;
	
	wire [3:0]vol = pulse[3:0];
	wire [2:0]duty = pulse[6:4];
	wire mode = pulse[7];
	
	reg [11:0]freq_ctr;
	reg [3:0]duty_ctr;
	reg chan_state;
	

	//reg [4:0]vol_ctr;
	assign snd = !chan_on | !chan_state ? 0 : {vol[3:0]};

	always @(negedge m2)
	begin
	
		if(freq_ctr == 0)
		begin
			freq_ctr <= freq;
			duty_ctr <= duty_ctr + 1;
		end
			else
		begin
			freq_ctr <= freq_ctr - 1;
		end
	
		chan_state <= mode ? 1 : duty_ctr[3:0] > duty[2:0];
		
	end
	
	
endmodule


module sawtooth
(arate, freq, chan_on, m2, snd, clk);
	
	input [5:0]arate;
	input [11:0]freq;
	input chan_on, m2, clk;
	output [4:0]snd;
	
	
	reg [2:0]ctr;
	reg [7:0]accum;
	reg [11:0]freq_ctr;
	reg strobe;
	assign snd = !chan_on ? 0 : accum[7:3];
	

	always @(negedge m2)
	begin
		
		
		if(freq_ctr == 0)
		begin
			freq_ctr <= freq;
			
			strobe <= !strobe;
			if(strobe)
			begin
				ctr <= ctr == 6 ? 0 : ctr + 1;
				accum <= ctr == 0 ? 0 : accum + arate;
			end
			
			
		end
			else
		begin
			freq_ctr <= freq_ctr - 1;
		end

		
	end
	

endmodule
