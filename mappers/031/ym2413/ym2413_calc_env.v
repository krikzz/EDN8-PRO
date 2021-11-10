//****************************************
// * Yamaha YM2413 Audio Implementation  *
// * === (c)2015-17 by Oliver Achten === *
// ***************************************

module ym2413_calc_env(op_egtyp,op_ksr,op_ar,op_dr,op_sl,op_rr,op_type,
	ch_sust_on,ch_key_on,ch_fnum,ch_block,
	env_prev,eg_state_prev,in_counter,
	env_next,eg_state_next,op_phase_reset,key_off_on_trig
);

	parameter	EG_DAMP 		= 2'b00;
	parameter	EG_ATTACK 	= 2'b01;
	parameter	EG_DECAY 	= 2'b10;
	parameter	EG_SUSTAIN 	= 2'b11;

/* ========================
   **** I/O Assignments ***
   ========================
*/
	
	input				op_egtyp;
	input				op_ksr;
	input [3:0] 	op_ar;
	input [3:0] 	op_dr;		
	input [3:0] 	op_sl;
	input [3:0] 	op_rr;
	
	input				op_type; // 0 = Modulator, 1 = Carrier
	
	input				ch_sust_on;
	input				ch_key_on;	
	input [8:0]		ch_fnum;
	input [2:0]		ch_block;
	
	input	[6:0]		env_prev;
	
	input [1:0]		eg_state_prev;
	
	input	[15:0] 	in_counter;
	
	input				key_off_on_trig;
	
	output reg 	[6:0]	env_next;
	output reg	[1:0]	eg_state_next;
	
	output reg			op_phase_reset;

/* ==================
   **** Registers ***
   ==================
*/
	
	reg	[3:0]		basic_rate;
	reg	[2:0]		column;
	reg				attack;	
	
/* ==============
   **** Wires ***
   ==============
*/

	wire	[3:0]		bf = 			{ch_block[2:0],ch_fnum[8]};
	wire	[3:0]		rks = 		op_ksr ? bf[3:0] : {2'b0,bf[3:2]};
	wire	[6:0]		rate_pre = 	{1'b0,basic_rate[3:0],2'b00} + {3'b0,rks[3:0]};
	wire	[5:0]		rate = 		rate_pre[6] ? 6'b11_1111 : rate_pre[5:0];
	
	wire	[3:0]		shift = 4'd13 - rate[5:2];
	
	wire	[1:0]		row = rate[1:0];

	wire  [2:0]		column_shifted =    in_counter[2:0] 	& {3{(shift[3:0] == 4'b0000)}}
												| in_counter[3:1] 	& {3{(shift[3:0] == 4'b0001)}}
												| in_counter[4:2] 	& {3{(shift[3:0] == 4'b0010)}}
												| in_counter[5:3] 	& {3{(shift[3:0] == 4'b0011)}}
												| in_counter[6:4] 	& {3{(shift[3:0] == 4'b0100)}}
												| in_counter[7:5] 	& {3{(shift[3:0] == 4'b0101)}}
												| in_counter[8:6] 	& {3{(shift[3:0] == 4'b0110)}}
												| in_counter[9:7] 	& {3{(shift[3:0] == 4'b0111)}}
												| in_counter[10:8] 	& {3{(shift[3:0] == 4'b1000)}}
												| in_counter[11:9] 	& {3{(shift[3:0] == 4'b1001)}}
												| in_counter[12:10] 	& {3{(shift[3:0] == 4'b1010)}}
												| in_counter[13:11] 	& {3{(shift[3:0] == 4'b1011)}}
												| in_counter[14:12] 	& {3{(shift[3:0] == 4'b1100)}}
												| in_counter[15:13] 	& {3{(shift[3:0] == 4'b1101)}};	
	
	wire  [2:0]		column_anded =  {in_counter[3:2],1'b0};
	
	wire	[4:0]		eg_add = {row[1:0],column[2:0]};
	wire				eg_out;
	
	wire	[12:0]	mask =   {13'b0000000000001} & {13{(shift[3:0] == 4'b0001)}}
								 | {13'b0000000000011} & {13{(shift[3:0] == 4'b0010)}}
								 | {13'b0000000000111} & {13{(shift[3:0] == 4'b0011)}}
								 | {13'b0000000001111} & {13{(shift[3:0] == 4'b0100)}}
								 | {13'b0000000011111} & {13{(shift[3:0] == 4'b0101)}}
								 | {13'b0000000111111} & {13{(shift[3:0] == 4'b0110)}}
								 | {13'b0000001111111} & {13{(shift[3:0] == 4'b0111)}}
								 | {13'b0000011111111} & {13{(shift[3:0] == 4'b1000)}}
								 | {13'b0000111111111} & {13{(shift[3:0] == 4'b1001)}}
								 | {13'b0001111111111} & {13{(shift[3:0] == 4'b1010)}}
								 | {13'b0011111111111} & {13{(shift[3:0] == 4'b1011)}}
								 | {13'b0111111111111} & {13{(shift[3:0] == 4'b1100)}}
								 | {13'b1111111111111} & {13{(shift[3:0] == 4'b1101)}};
	
	wire				counter_evt_mask = (in_counter[12:0] & mask[12:0]) == 13'b0;
	wire				counter_evt_mask_anded = (in_counter[12:0] & mask[12:0] & 13'b1_1111_1111_1100) == 13'b0;
	
	wire [7:0]		env_add_table 			= {1'b0,env_prev[6:0]} + {7'b0,eg_out};
	wire [7:0]		env_add_table_plus_1 = env_add_table[7:0] + 8'b1;
	wire [7:0]		env_plus_2	 			= {1'b0,env_prev[6:0]} + 8'd2;

/* ==========================
   **** Begin of RTL Code ***
   ==========================
*/	

	ym2413_eg_table eg_table(
		.a(eg_add[4:0]),
		.d(eg_out)
	);
	
	/* State transitions */
	
	always @(*) begin;
		if (key_off_on_trig)  begin
			eg_state_next[1:0] = EG_DAMP;
			op_phase_reset = 1'b0;
		end
		else if ((eg_state_prev[1:0]==EG_DAMP)&(env_prev[6:2]==5'b1_1111)) begin
			eg_state_next[1:0] = EG_ATTACK;
			op_phase_reset = 1'b1;
		end
		else if ((eg_state_prev[1:0]==EG_ATTACK)&(env_prev[6:0]== 7'b000_0000))begin
			eg_state_next[1:0] = EG_DECAY;
			op_phase_reset = 1'b0;
		end
		else if ((eg_state_prev[1:0]==EG_DECAY)&(env_prev[6:3]==op_sl[3:0])) begin
			eg_state_next[1:0] = EG_SUSTAIN;
			op_phase_reset = 1'b0;
		end
		else begin
			eg_state_next[1:0] = eg_state_prev[1:0];
			op_phase_reset = 1'b0;			
		end
	end
	
	/* Basic rate calculation */
	
	always @(*) begin
		if (~ch_key_on & op_type) begin
			basic_rate[3:0] = op_egtyp ? op_rr[3:0] : (ch_sust_on ? 4'd5 : 4'd7);
			attack = 1'b0;
		end
		else begin
			case (eg_state_next[1:0])
				EG_DAMP : begin
					basic_rate[3:0] = 4'd12;
					attack = 1'b0;
				end
				EG_ATTACK : begin
					basic_rate[3:0] = op_ar[3:0];
					attack = 1'b1;
				end
				EG_DECAY : begin
					basic_rate[3:0] = op_dr[3:0];
					attack = 1'b0;
				end
				EG_SUSTAIN : begin
					basic_rate[3:0] = op_egtyp ? 4'b0 : op_rr[3:0];
					attack = 1'b0;
				end
			endcase
		end
	end
	
	/* Envelope calculation */
	
	always @(*) begin	
		if (attack == 1'b1) begin
			if (~((rate[5:2]==4'hf)| (rate[5:2]==4'h0))) begin
				if (rate[5:2]>4'hb) begin	// 12,13,14
					column[2:0] = column_anded[2:0];
					case (rate[5:2])
						4'd12 : env_next[6:0] = env_prev[6:0] - {eg_out ? {3'b0,env_prev[6:3]} : {4'b0,env_prev[6:4]}} - 7'b1;
						4'd13 : env_next[6:0] = env_prev[6:0] - {eg_out ? {2'b0,env_prev[6:2]} : {3'b0,env_prev[6:3]}} - 7'b1;
						default : env_next[6:0] = env_prev[6:0] - {eg_out ? {1'b0,env_prev[6:1]} : {2'b0,env_prev[6:2]}} - 7'b1; 
					endcase
				end
				else begin // 1,2,3,4,5,6,7,8,9,10,11
					column[2:0] = column_shifted[2:0];
					if (counter_evt_mask_anded) begin
						env_next[6:0] = eg_out ? env_prev[6:0] - {4'b0,env_prev[6:4]} - 7'b1 : env_prev[6:0];
					end
					else begin
						env_next[6:0] = env_prev[6:0];
					end
				end
			end
			else if (rate[5:2]==4'hf) begin
				column[2:0] = 3'b0;
				env_next[6:0] = 7'b0;
			end
			else begin
				column[2:0] = 3'b0;
				env_next[6:0] = env_prev[6:0];
			end
		end
		else begin
			if (rate[5:2] != 4'b0) begin
				if (rate[5:2]==4'd13) begin
					column[2:0] = column_anded[2:0] | {2'b0,in_counter[0]};
					env_next[6:0] = env_add_table[7] ? 7'b111_1111 : env_add_table[6:0];
				end
				else if (rate[5:2]==4'd14) begin
					column[2:0] = column_anded[2:0];
					env_next[6:0] = env_add_table_plus_1[7] ? 7'b111_1111 : env_add_table_plus_1[6:0];
				end
				else if (rate[5:2]==4'd15) begin
					column[2:0] = 3'b0;
					env_next[6:0] = env_plus_2[7] ? 7'b111_1111 : env_plus_2[6:0];
				end
				else begin
					column[2:0] = column_shifted[2:0];
					if (counter_evt_mask) begin
						env_next[6:0] = env_add_table[7] ? 7'b111_1111 : env_add_table[6:0];
					end
					else begin
						column[2:0] = 3'b0;
						env_next[6:0] = env_prev[6:0];
					end
				end
			end
			else begin
				column[2:0] = 3'b0;
				env_next[6:0] = env_prev[6:0];
			end
		end
	end
		
endmodule

module ym2413_eg_table (a,d);

	input [4:0]	a;
	output d;
	
	reg d;

	always @* begin
		case (a[4:0])
			5'h0 : d = 1'b0;
			5'h1 : d = 1'b1;
			5'h2 : d = 1'b0;
			5'h3 : d = 1'b1;
			5'h4 : d = 1'b0;
			5'h5 : d = 1'b1;
			5'h6 : d = 1'b0;
			5'h7 : d = 1'b1;
			
			5'h8 : d = 1'b0;
			5'h9 : d = 1'b1;
			5'ha : d = 1'b0;
			5'hb : d = 1'b1;
			5'hc : d = 1'b1;
			5'hd : d = 1'b1;
			5'he : d = 1'b0;
			5'hf : d = 1'b1;

			5'h10 : d = 1'b0;
			5'h11 : d = 1'b1;
			5'h12 : d = 1'b1;
			5'h13 : d = 1'b1;
			5'h14 : d = 1'b0;
			5'h15 : d = 1'b1;
			5'h16 : d = 1'b1;
			5'h17 : d = 1'b1;
			
			5'h18 : d = 1'b0;
			5'h19 : d = 1'b1;
			5'h1a : d = 1'b1;
			5'h1b : d = 1'b1;
			5'h1c : d = 1'b1;
			5'h1d : d = 1'b1;
			5'h1e : d = 1'b1;
			5'h1f : d = 1'b1;			
		endcase
	end

endmodule
