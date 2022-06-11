


module snd_vrc6(
	
	input  cpu_m2,
	input  cpu_rw,	
	input  [7:0]cpu_data,
	input  [15:0]cpu_addr,	
	input  rst,
	
	output [6:0]snd_vol,
	
	
	input  SSTBus sst,
	output [7:0]sst_di
);
//************************************************************* sst
	assign sst_di[7:0]	=
	sst.addr[7:0] == 48 ? freq_ctrl  ^ 8'hff:
	sst.addr[7:0] == 49 ? pulse1 :
	sst.addr[7:0] == 50 ? freq1[7:0] :
	sst.addr[7:0] == 51 ? freq1[11:8] :
	sst.addr[7:0] == 52 ? chan_on1 :
	sst.addr[7:0] == 53 ? pulse2 :
	sst.addr[7:0] == 54 ? freq2[7:0] :
	sst.addr[7:0] == 55 ? freq2[11:8] :
	sst.addr[7:0] == 56 ? chan_on2 :
	sst.addr[7:0] == 57 ? sw_arate :
	sst.addr[7:0] == 58 ? sw_freq[7:0] :
	sst.addr[7:0] == 59 ? sw_freq[11:8] :
	sst.addr[7:0] == 60 ? sw_chan_on :
	8'hff;
//*************************************************************
	assign snd_vol[6:0] = pgen_out1 + pgen_out2 + sw_out;
	
	
	reg [2:0]freq_ctrl;
	
	reg [7:0]pulse1;
	reg [11:0]freq1;
	reg chan_on1;
	
	reg [7:0]pulse2;
	reg [11:0]freq2;
	reg chan_on2;
	
	reg [5:0]sw_arate;
	reg [11:0]sw_freq;
	reg sw_chan_on;
	
	
	always @(negedge cpu_m2)
	if(sst.act)
	begin	
		if(sst.we_reg)
		begin
			if(sst.addr[7:0] == 48)freq_ctrl 	<= sst.dato ^ 8'hff;//keep compatibility with old saves
			if(sst.addr[7:0] == 49)pulse1 		<= sst.dato;
			if(sst.addr[7:0] == 50)freq1[7:0] 	<= sst.dato;
			if(sst.addr[7:0] == 51)freq1[11:8] 	<= sst.dato;
			if(sst.addr[7:0] == 52)chan_on1 		<= sst.dato;
			if(sst.addr[7:0] == 53)pulse2 		<= sst.dato;
			if(sst.addr[7:0] == 54)freq2[7:0] 	<= sst.dato;
			if(sst.addr[7:0] == 55)freq2[11:8] 	<= sst.dato;
			if(sst.addr[7:0] == 56)chan_on2 		<= sst.dato;
			if(sst.addr[7:0] == 57)sw_arate 		<= sst.dato;
			if(sst.addr[7:0] == 58)sw_freq[7:0] <= sst.dato;
			if(sst.addr[7:0] == 59)sw_freq[11:8]<= sst.dato;
			if(sst.addr[7:0] == 60)sw_chan_on 	<= sst.dato;
		end
	end
		else
	if(rst)
	begin
		freq_ctrl	<= 0;
		chan_on1 	<= 0;
		chan_on2 	<= 0;
		sw_chan_on 	<= 0;
	end
		else
	if(!cpu_rw)
	begin
	
		case(cpu_addr)
		
			'h9000:begin
				pulse1[7:0] <= cpu_data[7:0];
			end
			'h9001:begin
				freq1[7:0] 	<= cpu_data[7:0];
			end
			'h9002:begin
				freq1[11:8] <= cpu_data[3:0];
				chan_on1 	<= cpu_data[7];
			end
			'h9003:begin
				freq_ctrl	<= cpu_data;
			end
			
			'hA000:begin
				pulse2[7:0] <= cpu_data[7:0];
			end
			'hA001:begin
				freq2[7:0] 	<= cpu_data[7:0];
			end
			'hA002:begin
				freq2[11:8] <= cpu_data[3:0];
				chan_on2 	<= cpu_data[7];
			end
			
			'hB000:begin
				sw_arate[5:0] 	<= cpu_data[5:0];
			end
			'hB001:begin
				sw_freq[7:0] 	<= cpu_data[7:0];
			end
			'hB002:begin
				sw_freq[11:8] 	<= cpu_data[3:0];
				sw_chan_on 		<= cpu_data[7];
			end
			
		endcase
	
	end
	
	
	wire [3:0]freq_rs = 
	freq_ctrl[2] ? 8 : 
	freq_ctrl[1] ? 4 : 0;
	
	
	wire [4:0]pgen_out1;
	pulse_gen pulse_gen1(
		
		.m2(cpu_m2),
		.chan_on(chan_on1),
		.pulse(pulse1),
		.freq(freq1 >> freq_rs),
		.halt(freq_ctrl[0]),
		.snd(pgen_out1)
	);
	
	wire [4:0]pgen_out2;
	pulse_gen pulse_gen2(
		
		.m2(cpu_m2),
		.chan_on(chan_on2),
		.pulse(pulse2),
		.freq(freq2 >> freq_rs),
		.halt(freq_ctrl[0]),
		.snd(pgen_out2)
	);
	
	
	wire [4:0]sw_out;
	sawtooth sawtooth1(
		
		.m2(cpu_m2),
		.chan_on(sw_chan_on),
		.arate(sw_arate),
		.freq(sw_freq >> freq_rs),
		.halt(freq_ctrl[0]),
		.snd(sw_out)
	);
	
		
endmodule


module pulse_gen(

	input  m2,
	input  chan_on, 
	input  [7:0]pulse,
	input  [11:0]freq,
	input  halt,
	
	output [4:0]snd
);	
	
	assign snd 		= !chan_on | !chan_state ? 0 : {vol[3:0]};
	
	wire [3:0]vol 	= pulse[3:0];
	wire [2:0]duty = pulse[6:4];
	wire mode 		= pulse[7];

	
	reg [11:0]freq_ctr;
	reg [3:0]duty_ctr;
	reg chan_state;

	always @(negedge m2)
	if(!halt)
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
	
		chan_state 	<= mode ? 1 : duty_ctr[3:0] > duty[2:0];
		
	end
	
	
endmodule


module sawtooth(

	input  m2,
	input  chan_on, 
	input  [5:0]arate,
	input  [11:0]freq,
	input  halt,
	
	output [4:0]snd
);
	
	assign snd 	= !chan_on ? 0 : accum[7:3];
	
	
	reg [2:0]ctr;
	reg [7:0]accum;
	reg [11:0]freq_ctr;
	reg strobe;
	
	always @(negedge m2)
	if(!halt)
	begin
		
		
		if(freq_ctr == 0)
		begin
		
			freq_ctr <= freq;
			
			strobe 	<= !strobe;
			
			if(strobe)
			begin
				ctr 	<= ctr == 6 ? 0 : ctr + 1;
				accum <= ctr == 0 ? 0 : accum + arate;
			end
			
			
		end
			else
		begin
			freq_ctr <= freq_ctr - 1;
		end

		
	end
	

endmodule
