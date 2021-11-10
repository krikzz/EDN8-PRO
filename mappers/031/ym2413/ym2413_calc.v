//****************************************
// * Yamaha YM2413 Audio Implementation  *
// * === (c)2015-17 by Oliver Achten === *
// ***************************************

module ym2413_calc (
	clk,reset,
	ch_select,ch_dat,
	ch_op0_am,ch_op0_vib,ch_op0_egtyp,ch_op0_ksr,ch_op0_mult,ch_op0_ksl,ch_op0_tl,ch_op0_wf,ch_op0_fb,ch_op0_ar,ch_op0_dr,ch_op0_sl,ch_op0_rr,
	ch_op1_am,ch_op1_vib,ch_op1_egtyp,ch_op1_ksr,ch_op1_mult,ch_op1_ksl,ch_op1_wf,ch_op1_ar,ch_op1_dr,ch_op1_sl,ch_op1_rr,
	ch_fnum,ch_block,ch_sust_on,ch_key_on,ch_vol,ch_rhy_en, ch_rhy_key_on,ch_rhy_vol
);

/* ========================
   **** I/O Assignments ***
   ========================
*/

	input 			clk;
	input 			reset;
	
	output [3:0]	ch_select;
	
	output [10:0] 	ch_dat;

	/* Modulator output */
	
	input 			ch_op0_am;
	input				ch_op0_vib;
	input				ch_op0_egtyp;
	input				ch_op0_ksr;	
	input [3:0] 	ch_op0_mult;
	input [1:0]		ch_op0_ksl;
	input [5:0] 	ch_op0_tl;	
	input		 		ch_op0_wf;		
	input [2:0] 	ch_op0_fb;
	input [3:0] 	ch_op0_ar;
	input [3:0] 	ch_op0_dr;		
	input [3:0] 	ch_op0_sl;
	input [3:0] 	ch_op0_rr;
	
	/* Carrier input */
	
	input 			ch_op1_am;
	input				ch_op1_vib;
	input				ch_op1_egtyp;
	input				ch_op1_ksr;		
	input [3:0] 	ch_op1_mult;
	input [1:0]		ch_op1_ksl;
	input		 		ch_op1_wf;
	input [3:0] 	ch_op1_ar;
	input [3:0] 	ch_op1_dr;		
	input [3:0] 	ch_op1_sl;
	input [3:0] 	ch_op1_rr;
	
	/* Channel input */
	
	input [8:0]		ch_fnum;
	input [2:0]		ch_block;
	input				ch_sust_on;
	input				ch_key_on;	
	input [3:0]		ch_vol;	
	input				ch_rhy_en;
	input				ch_rhy_key_on;
	input	[3:0]		ch_rhy_vol;
	

/* ==============
   **** Wires ***
   ==============
*/

	wire 			op_egtyp;
	wire 			op_ksr;
	wire [3:0] 	op_ar;
	wire [3:0] 	op_dr;
	wire [3:0] 	op_sl;
	wire [3:0] 	op_rr;
	wire 			op_vib;
	wire [1:0]	op_ksl;
	wire 			op_am;
	wire 			op_wf;	

	wire [18:0]	phase_inc;	
	wire [12:0]	op_out;	
	wire [18:0]	op_phase;
	wire 			op_phase_reset;
	wire			op_reset;
	
	wire [12:0] fb_pre;
	wire [11:0] fb;
	
	wire [6:0]	env_prev;
	wire [6:0]	env_next;	
	wire [1:0]	eg_state_prev;
	wire [1:0]	eg_state_next;
	wire [6:0] 	ext_lvl;		

	wire [3:0]	ml_tab_add;
	wire [4:0]	ml_tab_dat;
	wire [14:0] fnum_scaled;
	wire [9:0] 	fnum_pre;

	wire			ch_key_on_pre;
	wire 			key_off_on_trig;
	wire			key_on_trig;
	
	wire [5:0]	pm_tab_add;
	wire [3:0]	pm_tab_dat;
	
	wire			rhy_select;
	
	wire			rhy_hh_res1;
	wire			rhy_hh_res2;

	wire 			rhy_cym_res1;
	wire			rhy_cym_res2;
	
/* ==================
   **** Registers ***
   ==================
*/
	
	reg [5:0]	calc_cnt;
	reg [5:0]	calc_cnt_d;

	/* Audio mixing */
	
	reg [10:0]	ch_dat;
	reg [13:0]	ch_val;	
	reg [13:0]	ch_val_2;	
	reg [11:0]	rhy_val;
	
	/* Operator registers */
	
	reg [341:0]	op_phase_d;
	
	reg [8:0]	op0_reset_d;
	reg [1:0]	op1_reset_d;
	
	reg [107:0]	modulator_0;
	reg [107:0]	modulator_1;

	/* Envelope generator */
	
	reg [125:0]	env_d;	
	reg [35:0]	eg_state_d;
	
	/* Key on/off latches */
	
	reg [8:0]	ch_key_on_del_d;
	reg [8:0]	ch_key_on_d;

	reg [1:0]	rhy_key_on_del_d;
	reg [1:0]	rhy_key_on_d;
	
	reg 			ch_rhy_en_d;	
	
	/* Amplitude Modulation */
	
	reg	[5:0]		am_pre_cnt;
	reg	[6:0]		am_cnt;
	reg				am_dir;

	/* Miscellaneous */
	
	reg [15:0]	in_counter;
	reg [22:0]	noise_lfsr;	
	
/* ====================
   **** Assignments ***
   ====================
*/

	assign op_egtyp 		= calc_cnt_d[1] ? ch_op1_egtyp		: ch_op0_egtyp;
	assign op_ksr 			= calc_cnt_d[1] ? ch_op1_ksr 			: ch_op0_ksr;
	assign op_ar[3:0] 	= calc_cnt_d[1] ? ch_op1_ar[3:0] 	: ch_op0_ar[3:0];
	assign op_dr[3:0] 	= calc_cnt_d[1] ? ch_op1_dr[3:0] 	: ch_op0_dr[3:0];
	assign op_sl[3:0] 	= calc_cnt_d[1] ? ch_op1_sl[3:0] 	: ch_op0_sl[3:0];
	assign op_rr[3:0]		= calc_cnt_d[1] ? ch_op1_rr[3:0] 	: ch_op0_rr[3:0];
	assign op_ksl[1:0] 	= calc_cnt_d[1] ? ch_op1_ksl[1:0] 	: ch_op0_ksl[1:0];
	assign op_am 	 		= calc_cnt_d[1] ? ch_op1_am 			: ch_op0_am;
	assign op_wf 			= calc_cnt_d[1] ? ch_op1_wf 			: ch_op0_wf;
	assign op_vib 			= calc_cnt_d[1] ? ch_op1_vib			: ch_op0_vib;
	
	assign ch_select[3:0] = calc_cnt[5:2];
	
	assign pm_tab_add[5:0] = {(ch_fnum[8:6]&{3{op_vib}}),in_counter[12:10]};
	
	assign ml_tab_add[3:0] =   calc_cnt_d[1] ? ch_op1_mult[3:0]: ch_op0_mult[3:0];	
	assign fnum_pre[9:0] = {ch_fnum[8:0],1'b0} + {{6{pm_tab_dat[3]}},{pm_tab_dat[3:0]}};
	assign fnum_scaled[14:0] = fnum_pre[9:0] * ml_tab_dat[4:0];
	
	assign	phase_inc[18:0] 	= {6'b0,fnum_scaled[14:2]} 		& {19{ch_block[2:0]==3'b000}}
										| {5'b0,fnum_scaled[14:1]} 		& {19{ch_block[2:0]==3'b001}}
										| {4'b0,fnum_scaled[14:0]} 		& {19{ch_block[2:0]==3'b010}}
										| {3'b0,fnum_scaled[14:0],1'b0} 	& {19{ch_block[2:0]==3'b011}}
										| {2'b0,fnum_scaled[14:0],2'b0} 	& {19{ch_block[2:0]==3'b100}}
										| {1'b0,fnum_scaled[14:0],3'b0} 	& {19{ch_block[2:0]==3'b101}}
										| {fnum_scaled[14:0],4'b0} 		& {19{ch_block[2:0]==3'b110}}
										| {fnum_scaled[13:0],5'b0} 		& {19{ch_block[2:0]==3'b111}};

	assign ext_lvl[6:0] 	= calc_cnt_d[1] ? {ch_vol[3:0],3'b0} : rhy_select ? {ch_rhy_vol[3:0],3'b0} : {ch_op0_tl[5:0],1'b0};
	
	assign rhy_hh_res1 = (op_phase_d[11] ^ op_phase_d[16]) | op_phase_d[12];
	assign rhy_hh_res2 = op_phase_d[297] & ~op_phase_d[299];

	assign rhy_cym_res1 = (op_phase_d[68] ^ op_phase_d[73]) | op_phase_d[69];
	assign rhy_cym_res2 = op_phase_d[12] & ~op_phase_d[14];
	
	assign op_phase[18:0] = rhy_select ? 	((rhy_hh_res1 ^ rhy_hh_res2) ? (noise_lfsr[14] ? 19'h5a000 : 19'h46800) : (noise_lfsr[14] ? 19'h6800 : 19'h1a000)) & {19{calc_cnt_d[5:1] == 5'b01110}}	// High Hat
													|	((op_phase_d[36] ? 19'h40000 : 19'h20000)^{1'b0,noise_lfsr[14],17'b0}) & {19{calc_cnt_d[5:1] == 5'b01111}}																// Snare Drum
													|	op_phase_d[18:0] & {19{calc_cnt_d[5:1] == 5'b10000}}																																		// Tom Tom
													|	((rhy_cym_res1 ^ rhy_cym_res2) ? 19'h60000 : 19'h20000) & {19{calc_cnt_d[5:1] == 5'b10001}}																					// Cymbal
													: 	calc_cnt_d[1] ? op_phase_d[18:0] + {{modulator_0[20:12],1'b0},9'b0} : op_phase_d[18:0] + {fb[9:0],9'b0};																	// Melodic channels
	
	assign op_reset =	(calc_cnt_d[1] | rhy_select) ? op_phase_reset : op0_reset_d[0];
	
	assign fb_pre[12:0] =  ({modulator_0[11],modulator_0[11:0]} + {modulator_1[11],modulator_1[11:0]});
								
	assign fb[11:0] = (ch_op0_fb[2:0] == 3'b0) ? 12'b0 : fb_pre[12:1] 						& {12{ch_op0_fb[2:0]==3'b111}}
																		| {fb_pre[12],fb_pre[12:2]}		& {12{ch_op0_fb[2:0]==3'b110}}
																		| {{2{fb_pre[12]}},fb_pre[12:3]} & {12{ch_op0_fb[2:0]==3'b101}}
																		| {{3{fb_pre[12]}},fb_pre[12:4]} & {12{ch_op0_fb[2:0]==3'b100}}
																		| {{4{fb_pre[12]}},fb_pre[12:5]} & {12{ch_op0_fb[2:0]==3'b011}}
																		| {{5{fb_pre[12]}},fb_pre[12:6]} & {12{ch_op0_fb[2:0]==3'b010}}
																		| {{6{fb_pre[12]}},fb_pre[12:7]} & {12{ch_op0_fb[2:0]==3'b001}};
																		

	assign env_prev[6:0] = env_d[6:0];									
	assign eg_state_prev[1:0] = eg_state_d[1:0];

	assign ch_key_on_pre = ch_key_on_d[0];
	assign rhy_select = 	(calc_cnt_d[5:2] == 6'b0111)&ch_rhy_en_d
							|	(calc_cnt_d[5:2] == 6'b1000)&ch_rhy_en_d;
							
	assign key_off_on_trig = calc_cnt_d[1] | ~rhy_select ? ch_key_on_d[0] & ~ch_key_on_del_d[0] 
														: rhy_key_on_d[0] & ~rhy_key_on_del_d[0];
														
	assign key_on_trig = calc_cnt_d[1] | ~rhy_select ? ch_key_on_d[0] : rhy_key_on_d[0];
	
/* ==========================
   **** Begin of RTL Code ***
   ==========================
*/	

	/* Main Counter (NTSC) */
	/* 1,7897725 MHz / 36 = 49716Hz */
	
	/* PAL consoles will produce wrong pitch...*/

	always @(negedge clk) begin
		if (reset) begin
			calc_cnt[5:0] <= 6'b00_0000;
			calc_cnt_d[5:0] <= 6'b00_0000;
		end
		else begin
			if (calc_cnt[5:0] == 6'b10_0011) begin
				calc_cnt[5:0] <= 6'b00_0000;
			end
			else begin
				calc_cnt[5:0] <= calc_cnt[5:0] + 6'b1;
			end
			calc_cnt_d[5:0] <= calc_cnt[5:0] ;
		end
	end

	always @(negedge clk) begin
		if (reset) begin				
			in_counter[15:0] <= 16'b0;
			noise_lfsr[14:0] <= 15'b1;
			
			am_pre_cnt[4:0] <= 5'b0;
			am_cnt[6:0] <= 7'b0;
			am_dir <= 1'b0;
		end
		else begin
			if (calc_cnt_d[5:0] == 8'b10_0011) begin
				in_counter[15:0] <= in_counter[15:0] + 16'b1;
				
				/* Noise LFSR (rhythm channels) */
					
				noise_lfsr[14:0] <= {noise_lfsr[13:0],~(noise_lfsr[13]^noise_lfsr[14])};
					
				/* Calculate AM values */
	
				am_pre_cnt[5:0] <= am_pre_cnt[5:0] + 6'b1;
				if (am_pre_cnt[5:0] == 6'b0) begin
					if (~am_dir) begin
						am_cnt[6:0] <= am_cnt[6:0] + 7'b1;
						if (am_cnt[6:0] == 7'd104) begin
							am_dir <= 1'b1;
						end
					end
					else begin
						am_cnt[6:0] <= am_cnt[6:0] - 7'b1;
						if (am_cnt[6:0] == 7'd1) begin
							am_dir <= 1'b0;
						end
					end
				end
			end
			
		end
	end
	
	/* Calculate Envelope */
	
	ym2413_calc_env calc_env(
		.op_egtyp(op_egtyp),
		.op_ksr(op_ksr),
		.op_ar(op_ar[3:0]),
		.op_dr(op_dr[3:0]),
		.op_sl(op_sl[3:0]),
		.op_rr(op_rr[3:0]),
		.op_type(calc_cnt_d[1]|rhy_select), // Modulator has no release phase, except for rhythm mode
		
		.ch_sust_on(ch_sust_on),
		.ch_key_on(key_on_trig),
		.ch_fnum(ch_fnum[8:0]),
		.ch_block(ch_block[2:0]),
		
		.env_prev(env_prev[6:0]),
		.eg_state_prev(eg_state_prev[1:0]),
		.in_counter(in_counter[15:0]),
		
		.env_next(env_next[6:0]),
		.eg_state_next(eg_state_next[1:0]),
		.op_phase_reset(op_phase_reset),
		
		.key_off_on_trig(key_off_on_trig)
	);
	
	/* Calculate Operator Output */
	
	ym2413_calc_op calc_op(
		.clk			(clk),
		.reset		(reset),
		.op_phase	(op_phase[18:0]),
		.op_ksl		(op_ksl[1:0]),
		.op_am		(op_am),
		.op_wf		(op_wf),
		.ch_block	(ch_block[2:0]),
		.ch_fnum		(ch_fnum[8:0]),
		.env_lvl		(env_d[13:7]),
		.ext_lvl		(ext_lvl[6:0]),
		.am_cnt		(am_cnt[6:0]),
		.op_out		(op_out[12:0])
	);	
	
	
	always @(negedge clk) begin
		if (reset) begin		
			op_phase_d[341:0] <= 342'b0;
			op0_reset_d[8:0] 	<= 9'b0;
			
			modulator_0[107:0] <= 108'b0;
			modulator_1[107:0] <= 108'b0;

			env_d[125:0] 		<= 126'd0;			
			eg_state_d[35:0] 	<= 36'd0;

			ch_val[13:0] <= 13'b0;
			ch_dat[10:0] <= 11'b0;
			rhy_val[11:0] <= 12'b0;
			
			ch_key_on_d[8:0] <= 9'b0;
			ch_key_on_del_d[8:0] <= 9'b0;
			
			rhy_key_on_d[1:0] <= 2'b0;
			rhy_key_on_del_d[1:0] <= 2'b0;
			
			ch_rhy_en_d <= 1'b0;
		end
		else begin
			// Step 1+3: update phases & ENV for modulator/carrier
			
			if (~calc_cnt_d[0]) begin
				op_phase_d[18:0] 		<= op_reset ? 19'b0 : op_phase_d[341:323] + phase_inc[18:0];
				op_phase_d[341:19] 	<= op_phase_d[322:0];
					
				env_d[6:0] 		<= env_d[125:119];
				env_d[13:7] 	<= env_next[6:0];
				env_d[125:14] 	<= env_d[118:7];
					
				eg_state_d[1:0] 	<= eg_state_d[35:34];
				eg_state_d[3:2] 	<= eg_state_next[1:0];
				eg_state_d[35:4] 	<= eg_state_d[33:2];
			end
					
			// Step 2: calculate modulation
			if (calc_cnt_d[1:0]==2'b01) begin
				modulator_0[11:0] 	<= modulator_0[107:96];
				modulator_0[23:12] 	<= op_out[12:1];
				modulator_0[107:24] 	<= modulator_0[95:12];
					
				modulator_1[11:0] 	<= modulator_1[107:96];
				modulator_1[23:12] 	<= modulator_0[11:0];
				modulator_1[107:24] 	<= modulator_1[95:12];
			end			

			if (calc_cnt_d[1:0]==2'b10) begin
				op0_reset_d[0] 	<= op0_reset_d[8];
				op0_reset_d[1]		<= op_phase_reset;
				op0_reset_d[8:2] 	<= op0_reset_d[7:1];
			end			
			
			// Step 4 calculate audio output
			
			if (calc_cnt_d[0]==1'b1) begin
				case (calc_cnt_d[5:1])
					5'b01101 : rhy_val[11:0] <= ({{4{op_out[12]}},op_out[11:4]} & {12{ch_rhy_en_d}});						// BD
					5'b01110 : rhy_val[11:0] <= rhy_val[11:0] + ({{4{op_out[12]}},op_out[11:4]} & {12{ch_rhy_en_d}});	// HH
					5'b01111 : rhy_val[11:0] <= rhy_val[11:0] + ({{4{op_out[12]}},op_out[11:4]} & {12{ch_rhy_en_d}});	// SD
					5'b10000 : rhy_val[11:0] <= rhy_val[11:0] + ({{4{op_out[12]}},op_out[11:4]} & {12{ch_rhy_en_d}});	// TOM
					5'b10001 : rhy_val[11:0] <= rhy_val[11:0] + ({{4{op_out[12]}},op_out[11:4]} & {12{ch_rhy_en_d}});	// CYM
				endcase
			end
			
			if (calc_cnt_d[1:0]==2'b11) begin
			
				if (calc_cnt_d[5:2]== 4'b1000) begin
					ch_rhy_en_d <= ch_rhy_en;
				end
				
				ch_key_on_d[0] 	<= ch_key_on_d[8];
				ch_key_on_d[1] 	<= ch_key_on;
				ch_key_on_d[8:2] 	<= ch_key_on_d[7:1];
					
				ch_key_on_del_d[0] 	<= ch_key_on_del_d[8];
				ch_key_on_del_d[1] 	<= ch_key_on_d[0];
				ch_key_on_del_d[8:2] <= ch_key_on_del_d[7:1];

				if (rhy_select) begin
					rhy_key_on_d[0] <= rhy_key_on_d[1];
					rhy_key_on_d[1] <= ch_rhy_key_on;
					
					rhy_key_on_del_d[0] <= rhy_key_on_del_d[1];
					rhy_key_on_del_d[1] <= rhy_key_on_d[0];						
				end			

				case (calc_cnt_d[5:2])
					4'b0000 : begin
									ch_val[13:0] <= {{6{op_out[12]}},op_out[11:4]};
									ch_val_2[13:0] <= ch_val[13:0] + {rhy_val[11],rhy_val[11:0],1'b0};
								end
					4'b0001 : begin
									ch_val[13:0] <= ch_val[13:0] + {{6{op_out[12]}},op_out[11:4]};
									ch_val_2[13:0] <= ch_val_2[13:0] + 14'd1024;
								end
					4'b0010 : begin
									ch_val[13:0] <= ch_val[13:0] + {{6{op_out[12]}},op_out[11:4]};
									ch_dat[10:0] <= ch_val_2[13] ? 11'b0 : (ch_val_2[13:0] > 14'd2047) ? 11'd2047 : ch_val_2[10:0];
								end	
					4'b0011 : ch_val[13:0] <= ch_val[13:0] + {{6{op_out[12]}},op_out[11:4]};
					4'b0100 : ch_val[13:0] <= ch_val[13:0] + {{6{op_out[12]}},op_out[11:4]};
					4'b0101 : ch_val[13:0] <= ch_val[13:0] + {{6{op_out[12]}},op_out[11:4]};
					4'b0110 : ch_val[13:0] <= ch_val[13:0] + ({{6{op_out[12]}},op_out[11:4]} & {14{~ch_rhy_en_d}});
					4'b0111 : ch_val[13:0] <= ch_val[13:0] + ({{6{op_out[12]}},op_out[11:4]} & {14{~ch_rhy_en_d}});
					4'b1000 : ch_val[13:0] <= ch_val[13:0] + ({{6{op_out[12]}},op_out[11:4]} & {14{~ch_rhy_en_d}});
				endcase
			end
			
		end
	end
	
	ym2413_ml_tab ml_tab(
		.a(ml_tab_add[3:0]),
		.d(ml_tab_dat[4:0])
	);
	
	ym2413_pm_tab pm_tab(
		.a(pm_tab_add[5:0]),
		.d(pm_tab_dat[3:0])
	);
	
endmodule

module ym2413_ml_tab(a,d);

	input [3:0]	a;
	output [4:0]	d;
	
	reg [4:0] d;
	
	always @* begin
		case (a[3:0])	
			4'd0 : d = 5'd1;
			4'd1 : d = 5'd2;
			4'd2 : d = 5'd4;
			4'd3 : d = 5'd6;
			4'd4 : d = 5'd8;
			4'd5 : d = 5'd10;
			4'd6 : d = 5'd12;
			4'd7 : d = 5'd14;
			4'd8 : d = 5'd16;
			4'd9 : d = 5'd18;
			4'd10 : d = 5'd20;
			4'd11 : d = 5'd20;
			4'd12 : d = 5'd24;
			4'd13 : d = 5'd24;
			4'd14 : d = 5'd30;
			4'd15 : d = 5'd30;			
		endcase
	end
	
endmodule

module ym2413_pm_tab(a,d);

	input [5:0]	a;
	output [3:0]	d;
	
	reg [3:0] d;
	
	always @* begin
		case (a[5:0])	
			6'h00 : d = 4'b0000;
			6'h01 : d = 4'b0000;
			6'h02 : d = 4'b0000;
			6'h03 : d = 4'b0000;
			6'h04 : d = 4'b0000;
			6'h05 : d = 4'b0000;
			6'h06 : d = 4'b0000;
			6'h07 : d = 4'b0000;
			
			6'h08 : d = 4'b0000;
			6'h09 : d = 4'b0000;
			6'h0a : d = 4'b0001;
			6'h0b : d = 4'b0000;
			6'h0c : d = 4'b0000;
			6'h0d : d = 4'b0000;
			6'h0e : d = 4'b1111;
			6'h0f : d = 4'b0000;
			
			6'h10 : d = 4'b0000;
			6'h11 : d = 4'b0001;
			6'h12 : d = 4'b0010;
			6'h13 : d = 4'b0001;
			6'h14 : d = 4'b0000;
			6'h15 : d = 4'b1111;
			6'h16 : d = 4'b1110;
			6'h17 : d = 4'b1111;
			
			6'h18 : d = 4'b0000;
			6'h19 : d = 4'b0001;
			6'h1a : d = 4'b0011;
			6'h1b : d = 4'b0001;
			6'h1c : d = 4'b0000;
			6'h1d : d = 4'b1111;
			6'h1e : d = 4'b1101;
			6'h1f : d = 4'b1111;
			
			6'h20 : d = 4'b0000;
			6'h21 : d = 4'b0010;
			6'h22 : d = 4'b0100;
			6'h23 : d = 4'b0010;
			6'h24 : d = 4'b0000;
			6'h25 : d = 4'b1110;
			6'h26 : d = 4'b1100;
			6'h27 : d = 4'b1110;
			
			6'h28 : d = 4'b0000;
			6'h29 : d = 4'b0010;
			6'h2a : d = 4'b0101;
			6'h2b : d = 4'b0010;
			6'h2c : d = 4'b0000;
			6'h2d : d = 4'b1110;
			6'h2e : d = 4'b1011;
			6'h2f : d = 4'b1110;
			
			6'h30 : d = 4'b0000;
			6'h31 : d = 4'b0011;
			6'h32 : d = 4'b0110;
			6'h33 : d = 4'b0011;
			6'h34 : d = 4'b0000;
			6'h35 : d = 4'b1101;
			6'h36 : d = 4'b1010;
			6'h37 : d = 4'b1101;
			
			6'h38 : d = 4'b0000;
			6'h39 : d = 4'b0011;
			6'h3a : d = 4'b0111;
			6'h3b : d = 4'b0011;
			6'h3c : d = 4'b0000;
			6'h3d : d = 4'b1101;
			6'h3e : d = 4'b1001;
			6'h3f : d = 4'b1101;		
		endcase
	end
	
endmodule
