module ym2413_calc_op(clk,reset,
	op_phase,op_ksl,op_am,op_wf,
	ch_block,ch_fnum,
	env_lvl,ext_lvl,am_cnt,
	op_out
);

	input				clk;
	input				reset;

	input	[18:0]	op_phase;
	input	[1:0]		op_ksl;
	input				op_am;
	input				op_wf;
	
	input	[2:0]		ch_block;
	input	[8:0]		ch_fnum;
	
	input [6:0]		env_lvl;
	input	[6:0]		ext_lvl;
	
	input	[6:0]		am_cnt;
	
	output [12:0]	op_out;
	
	
	wire [3:0]	am_val = op_am ? am_cnt[6:3] : 4'b0;
	
	/* Key Scale Level */
	
	wire [6:0]  ksl_tbl_out;
	wire [7:0]	ksl_tmp = {1'b0,ch_block[2:0],4'b0000} - {1'b0,ksl_tbl_out[6:0]};	// signed!
	wire [6:0]	ksl_max = ksl_tmp[7] ? 7'b0 : ksl_tmp[6:0];
	wire [6:0]	ksl_val = (op_ksl[1:0] == 2'b0) ? 7'b0 :	  {2'b00,ksl_max[6:2]} &  	{7{op_ksl[1:0] == 2'b01}}
																			| {1'b0,ksl_max[6:1]}  & 	{7{op_ksl[1:0] == 2'b10}}
																			| {ksl_max[6:0]}       &	{7{op_ksl[1:0] == 2'b11}};
	/* Attenuation */
	
	wire [8:0]	att_tmp = {2'b0,ext_lvl[6:0]} + {2'b0,ksl_val[6:0]} + {2'b0,env_lvl[6:0]} + {5'b0,am_val[3:0]};
	wire [6:0]	att = att_tmp[8] | att_tmp[7] ? 7'b111_1111 : att_tmp[6:0];
	
	
	/* Log-Sin Calculation */
	wire [7:0] 	adr_sin = op_phase[17] ? ~op_phase[16:9] : op_phase[16:9];
	wire [11:0]	out_sin;
	wire [12:0] dat_sin = {op_phase[18],out_sin[11:0]} | {1'b0,{12{op_wf & op_phase[18]}}};
	
	/* EXP Calculation */
	
	wire [13:0] pre_adr_exp = {dat_sin[12],{1'b0,dat_sin[11:0]} + {2'b0,att[6:0],4'b0}};
	
	wire [7:0] 	adr_exp = ~pre_adr_exp[7:0];
	wire [9:0]	out_exp;
	
	wire [11:0] dat_exp_pre1 = {1'b1,out_exp[9:0],1'b0};
	wire [11:0] dat_exp_pre2 =	dat_exp_pre1[11:0] 			& {12{pre_adr_exp[12:8] == 5'b00000}}
									| 	{1'b0,dat_exp_pre1[11:1]} 	& {12{pre_adr_exp[12:8] == 5'b00001}}
									| 	{2'b0,dat_exp_pre1[11:2]}  & {12{pre_adr_exp[12:8] == 5'b00010}}
									| 	{3'b0,dat_exp_pre1[11:3]}  & {12{pre_adr_exp[12:8] == 5'b00011}}
									| 	{4'b0,dat_exp_pre1[11:4]}  & {12{pre_adr_exp[12:8] == 5'b00100}}
									| 	{5'b0,dat_exp_pre1[11:5]}  & {12{pre_adr_exp[12:8] == 5'b00101}}
									| 	{6'b0,dat_exp_pre1[11:6]}  & {12{pre_adr_exp[12:8] == 5'b00110}}
									| 	{7'b0,dat_exp_pre1[11:7]}  & {12{pre_adr_exp[12:8] == 5'b00111}}
									| 	{8'b0,dat_exp_pre1[11:8]}  & {12{pre_adr_exp[12:8] == 5'b01000}}
									| 	{9'b0,dat_exp_pre1[11:9]}  & {12{pre_adr_exp[12:8] == 5'b01001}}
									| 	{10'b0,dat_exp_pre1[11:10]}& {12{pre_adr_exp[12:8] == 5'b01010}}
									| 	{11'b0,dat_exp_pre1[11]}   & {12{pre_adr_exp[12:8] == 5'b01011}};
	
	assign op_out[12:0] = (env_lvl[6:2] == 5'b1_1111) ? 12'b0 : {pre_adr_exp[13],{pre_adr_exp[13] ? ~dat_exp_pre2[11:0] : dat_exp_pre2[11:0]}};
	
	ym2413_ksl_tbl ksl_tbl(
		.a(ch_fnum[8:5]),
		.d(ksl_tbl_out[6:0])
		);
	

	ym2413_logsin_rom logsin_rom(
		.a(adr_sin[7:0]),
		.d(out_sin[11:0])
	);
	
	ym2413_exp_rom exp_rom(
		.a(adr_exp[7:0]),
		.d(out_exp[9:0])
	);
	
endmodule

module ym2413_ksl_tbl(a,d);

	input [3:0]	a;
	output [6:0]	d;
	
	reg [6:0] d;
	
	always @* begin
		case (a[3:0])	
			4'd15 : d = 7'd0;
			4'd14 : d = 7'd2;
			4'd13 : d = 7'd4;
			4'd12 : d = 7'd6;
			4'd11 : d = 7'd8;
			4'd10 : d = 7'd10;
			4'd9 : d = 7'd12;
			4'd8 : d = 7'd16;
			4'd7 : d = 7'd18;
			4'd6 : d = 7'd22;
			4'd5 : d = 7'd26;
			4'd4 : d = 7'd32;
			4'd3 : d = 7'd38;
			4'd2 : d = 7'd48;
			4'd1 : d = 7'd64;
			4'd0 : d = 7'd112;			
		endcase
	end
	
endmodule
