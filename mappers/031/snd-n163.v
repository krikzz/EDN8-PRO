
`include "../base/defs.v"


module snd_n163
(bus, vol, dout);
	
	`include "../base/bus_in.v"
	output reg [7:0]vol;
	output [7:0]dout;
	
	
	assign dout = dout_cpu;
	
	wire [7:0]reg_addr = {cpu_addr[15], cpu_addr[14:11], 3'b000};
	
	wire ram_we = reg_addr == 8'h48 & !cpu_rw & !map_rst;
	wire ram_oe = reg_addr == 8'h48 & cpu_rw;

	
	
	
	
	reg [3:0]sample;
	reg [7:0]sample_addr;
	reg [17:0]freq;
	reg [5:0]inst_len;
	reg [3:0]inst_vol;
	reg [7:0]inst_addr;
	reg [23:0]phase;
	reg [3:0]state;
	
	reg [2:0]active_chan;
	reg [2:0]chans_on;
	
	reg [6:0]ram_addr_cpu;
	reg [6:0]ram_addr_snd;
	reg[7:0]snd_dat;
	reg snd_we;
	reg auto_inc;
	
	
	wire [7:0]dout_cpu;// = snd_ram[ram_addr_cpu];
	wire [7:0]dout_snd;// = snd_ram[ram_addr_snd];	
	reg[7:0]snd_ram[128];
	
	ram_dp fifo_ram(
	
		.din_a(cpu_dat), 
		.addr_a(ram_addr_cpu), 
		.we_a(ram_we), 
		.dout_a(dout_cpu),
		.clk_a(m2),
		
		.din_b(snd_dat),
		.addr_b(ram_addr_snd), 
		.we_b(snd_we),
		.dout_b(dout_snd), 
		.clk_b(!m2)
	);
	
	
	always @(negedge m2)
	if(map_rst)
	begin
		active_chan <= 7;
		ram_addr_snd <= {1'b1, active_chan[2:0],3'b000};
		vol <= 0;
		snd_we <= 0;
		state <= 15;
	end
		else
	begin
	
		if(!cpu_rw & reg_addr == 8'hF8)
		begin
			ram_addr_cpu[6:0] <= cpu_dat[6:0];
			auto_inc <= cpu_dat[7];
		end
		
		if(reg_addr == 8'h48 & auto_inc)ram_addr_cpu <= ram_addr_cpu + 1;
	
		
		state <= state == 14 ? 0 : state + 1;
		
		
		if(ram_we)snd_ram[ram_addr_cpu] <= cpu_dat;
			else
		if(snd_we)snd_ram[ram_addr_snd] <= snd_dat;
		
		//if(!ram_we)
		case(state)
			0:begin
				freq[7:0] <= dout_snd[7:0];
				ram_addr_snd[2:0] <= ram_addr_snd[2:0]+1;
			end
			1:begin
				phase[7:0] <= dout_snd[7:0];
				ram_addr_snd[2:0] <= ram_addr_snd[2:0]+1;
			end
			2:begin
				freq[15:8] <= dout_snd[7:0];
				ram_addr_snd[2:0] <= ram_addr_snd[2:0]+1;
			end
			3:begin
				phase[15:8] <= dout_snd[7:0];
				ram_addr_snd[2:0] <= ram_addr_snd[2:0]+1;
			end
			4:begin
				freq[17:16] <= dout_snd[1:0];
				inst_len[5:0] <= dout_snd[7:2];
				ram_addr_snd[2:0] <= ram_addr_snd[2:0]+1;
			end
			5:begin
				phase[23:16] <= dout_snd[7:0];
				ram_addr_snd[2:0] <= ram_addr_snd[2:0]+1;
			end
			6:begin
				phase <= phase + freq;
				inst_addr[7:0] <= dout_snd[7:0];
				ram_addr_snd[2:0] <= ram_addr_snd[2:0]+1;
			end
			7:begin
				inst_vol[3:0] <= dout_snd[3:0];
				if(64-inst_len == phase[23:18])phase[23:16] <= 0;
				if(ram_addr_snd == 7'h7f)chans_on[2:0] <= dout_snd[6:4];
			end
			8:begin
				sample_addr <= phase[23:16] + inst_addr;
				
				snd_we <= 1;
				ram_addr_snd[2:0] <= 1;
				snd_dat[7:0] <= phase[7:0];
				
			end
			9:begin
				ram_addr_snd[2:0] <= 3;
				snd_dat[7:0] <= phase[15:8];
			end
			10:begin
				ram_addr_snd[2:0] <= 5;
				snd_dat[7:0] <= phase[23:16];
			end
			11:begin
				snd_we <= 0;
				ram_addr_snd[6:0] <= sample_addr[7:1];
			end
			13:begin
				sample[3:0] <= !sample_addr[0] ? dout_snd[3:0] : dout_snd[7:4];
				active_chan <= active_chan == 7-chans_on ? 7 : active_chan - 1;
			end
			14:begin
				ram_addr_snd <= {1'b1, active_chan[2:0],3'b000};// 7'h40 + active_chan * 8;
				vol <= (sample[3:0] * inst_vol[3:0]);
			end
			
		endcase
		
	end
	
	
	
endmodule


