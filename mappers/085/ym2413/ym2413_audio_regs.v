//****************************************
// * Yamaha YM2413 Audio Implementation  *
// * === (c)2015-17 by Oliver Achten === *
// ***************************************

module ym2413_audio_regs(
	reset,clk,d,sel_reg,sel_dat,
	r_ut_op0_am,r_ut_op0_vib,r_ut_op0_egtyp,r_ut_op0_ksr,r_ut_op0_mult,r_ut_op0_ksl,r_ut_op0_tl,r_ut_op0_wf,r_ut_op0_fb,r_ut_op0_ar,r_ut_op0_dr,r_ut_op0_sl,r_ut_op0_rr,
	r_ut_op1_am,r_ut_op1_vib,r_ut_op1_egtyp,r_ut_op1_ksr,r_ut_op1_mult,r_ut_op1_ksl,r_ut_op1_wf,r_ut_op1_ar,r_ut_op1_dr,r_ut_op1_sl,r_ut_op1_rr,
	r_ch0_fnum,r_ch1_fnum,r_ch2_fnum,r_ch3_fnum,r_ch4_fnum,r_ch5_fnum,r_ch6_fnum,r_ch7_fnum,r_ch8_fnum,
	r_ch0_block,r_ch1_block,r_ch2_block,r_ch3_block,r_ch4_block,r_ch5_block,r_ch6_block,r_ch7_block,r_ch8_block,
	r_ch0_sust_on,r_ch1_sust_on,r_ch2_sust_on,r_ch3_sust_on,r_ch4_sust_on,r_ch5_sust_on,r_ch6_sust_on,r_ch7_sust_on,r_ch8_sust_on,
	r_ch0_key_on,r_ch1_key_on,r_ch2_key_on,r_ch3_key_on,r_ch4_key_on,r_ch5_key_on,r_ch6_key_on,r_ch7_key_on,r_ch8_key_on,
	r_ch0_inst_nr,r_ch1_inst_nr,r_ch2_inst_nr,r_ch3_inst_nr,r_ch4_inst_nr,r_ch5_inst_nr,r_ch6_inst_nr,r_ch7_inst_nr,r_ch8_inst_nr,
	r_ch0_vol,r_ch1_vol,r_ch2_vol,r_ch3_vol,r_ch4_vol,r_ch5_vol,r_ch6_vol,r_ch7_vol,r_ch8_vol,
	r_ch_rhy_en,r_ch_rhy_bd_on,r_ch_rhy_sd_on,r_ch_rhy_tom_on,r_ch_rhy_cym_on,r_ch_rhy_hh_on	
);

/* ========================
   **** I/O Assignments ***
   ========================
*/

	input reset;
	input clk;
	
	input [7:0] d;
	
	input sel_reg;
	input sel_dat;
	
/* Register outputs */

	/* User tone - modulator output */

	output 			r_ut_op0_am;
	output			r_ut_op0_vib;
	output			r_ut_op0_egtyp;
	output			r_ut_op0_ksr;	
	output [3:0] 	r_ut_op0_mult;
	output [1:0]	r_ut_op0_ksl;
	output [5:0] 	r_ut_op0_tl;	
	output		 	r_ut_op0_wf;		
	output [2:0] 	r_ut_op0_fb;
	output [3:0] 	r_ut_op0_ar;
	output [3:0] 	r_ut_op0_dr;		
	output [3:0] 	r_ut_op0_sl;
	output [3:0] 	r_ut_op0_rr;
	
	/* User tone - carrier output */
	
	output 			r_ut_op1_am;
	output			r_ut_op1_vib;
	output			r_ut_op1_egtyp;
	output			r_ut_op1_ksr;		
	output [3:0] 	r_ut_op1_mult;
	output [1:0]	r_ut_op1_ksl;
	output		 	r_ut_op1_wf;
	output [3:0] 	r_ut_op1_ar;
	output [3:0] 	r_ut_op1_dr;		
	output [3:0] 	r_ut_op1_sl;
	output [3:0] 	r_ut_op1_rr;
	
	output [8:0]	r_ch0_fnum;
	output [8:0]	r_ch1_fnum;
	output [8:0]	r_ch2_fnum;
	output [8:0]	r_ch3_fnum;
	output [8:0]	r_ch4_fnum;
	output [8:0]	r_ch5_fnum;
	output [8:0]	r_ch6_fnum;
	output [8:0]	r_ch7_fnum;
	output [8:0]	r_ch8_fnum;
	
	output [2:0]	r_ch0_block;
	output [2:0]	r_ch1_block;
	output [2:0]	r_ch2_block;
	output [2:0]	r_ch3_block;
	output [2:0]	r_ch4_block;
	output [2:0]	r_ch5_block;
	output [2:0]	r_ch6_block;
	output [2:0]	r_ch7_block;
	output [2:0]	r_ch8_block;
	
	output			r_ch0_sust_on;
	output			r_ch1_sust_on;
	output			r_ch2_sust_on;
	output			r_ch3_sust_on;
	output			r_ch4_sust_on;
	output			r_ch5_sust_on;
	output			r_ch6_sust_on;
	output			r_ch7_sust_on;
	output			r_ch8_sust_on;

	output			r_ch0_key_on;	
	output			r_ch1_key_on;	
	output			r_ch2_key_on;	
	output			r_ch3_key_on;	
	output			r_ch4_key_on;	
	output			r_ch5_key_on;		
	output			r_ch6_key_on;		
	output			r_ch7_key_on;		
	output			r_ch8_key_on;		
	
	output [3:0]	r_ch0_inst_nr;
	output [3:0]	r_ch1_inst_nr;
	output [3:0]	r_ch2_inst_nr;
	output [3:0]	r_ch3_inst_nr;
	output [3:0]	r_ch4_inst_nr;
	output [3:0]	r_ch5_inst_nr;
	output [3:0]	r_ch6_inst_nr;
	output [3:0]	r_ch7_inst_nr;
	output [3:0]	r_ch8_inst_nr;

	output [3:0]	r_ch0_vol;
	output [3:0]	r_ch1_vol;
	output [3:0]	r_ch2_vol;
	output [3:0]	r_ch3_vol;
	output [3:0]	r_ch4_vol;
	output [3:0]	r_ch5_vol;
	output [3:0]	r_ch6_vol;
	output [3:0]	r_ch7_vol;
	output [3:0]	r_ch8_vol;
	
	output			r_ch_rhy_en;
	output			r_ch_rhy_bd_on;
	output			r_ch_rhy_sd_on;	
	output			r_ch_rhy_tom_on;
	output			r_ch_rhy_cym_on;
	output			r_ch_rhy_hh_on;	

/* ==================
   **** Registers ***
   ==================
*/
	
	reg 			r_ut_op0_am;
	reg			r_ut_op0_vib;
	reg			r_ut_op0_egtyp;
	reg			r_ut_op0_ksr;	
	reg [3:0] 	r_ut_op0_mult;
	reg [1:0]	r_ut_op0_ksl;
	reg [5:0] 	r_ut_op0_tl;	
	reg		 	r_ut_op0_wf;		
	reg [2:0] 	r_ut_op0_fb;
	reg [3:0] 	r_ut_op0_ar;
	reg [3:0] 	r_ut_op0_dr;		
	reg [3:0] 	r_ut_op0_sl;
	reg [3:0] 	r_ut_op0_rr;
	
	reg 		r_ut_op1_am;
	reg			r_ut_op1_vib;
	reg			r_ut_op1_egtyp;
	reg			r_ut_op1_ksr;		
	reg [3:0] 	r_ut_op1_mult;
	reg [1:0]	r_ut_op1_ksl;
	reg		 	r_ut_op1_wf;
	reg [3:0] 	r_ut_op1_ar;
	reg [3:0] 	r_ut_op1_dr;		
	reg [3:0] 	r_ut_op1_sl;
	reg [3:0] 	r_ut_op1_rr;
	
	reg [8:0]	r_ch0_fnum;
	reg [8:0]	r_ch1_fnum;
	reg [8:0]	r_ch2_fnum;
	reg [8:0]	r_ch3_fnum;
	reg [8:0]	r_ch4_fnum;
	reg [8:0]	r_ch5_fnum;
	reg [8:0]	r_ch6_fnum;
	reg [8:0]	r_ch7_fnum;
	reg [8:0]	r_ch8_fnum;
	
	reg [2:0]	r_ch0_block;
	reg [2:0]	r_ch1_block;
	reg [2:0]	r_ch2_block;
	reg [2:0]	r_ch3_block;
	reg [2:0]	r_ch4_block;
	reg [2:0]	r_ch5_block;
	reg [2:0]	r_ch6_block;
	reg [2:0]	r_ch7_block;
	reg [2:0]	r_ch8_block;
	
	reg			r_ch0_sust_on;
	reg			r_ch1_sust_on;
	reg			r_ch2_sust_on;
	reg			r_ch3_sust_on;
	reg			r_ch4_sust_on;
	reg			r_ch5_sust_on;
	reg			r_ch6_sust_on;
	reg			r_ch7_sust_on;
	reg			r_ch8_sust_on;

	reg			r_ch0_key_on;	
	reg			r_ch1_key_on;	
	reg			r_ch2_key_on;	
	reg			r_ch3_key_on;	
	reg			r_ch4_key_on;	
	reg			r_ch5_key_on;	
	reg			r_ch6_key_on;	
	reg			r_ch7_key_on;	
	reg			r_ch8_key_on;	
	
	reg [3:0]	r_ch0_inst_nr;
	reg [3:0]	r_ch1_inst_nr;
	reg [3:0]	r_ch2_inst_nr;
	reg [3:0]	r_ch3_inst_nr;
	reg [3:0]	r_ch4_inst_nr;
	reg [3:0]	r_ch5_inst_nr;
	reg [3:0]	r_ch6_inst_nr;
	reg [3:0]	r_ch7_inst_nr;
	reg [3:0]	r_ch8_inst_nr;

	reg [3:0]	r_ch0_vol;
	reg [3:0]	r_ch1_vol;
	reg [3:0]	r_ch2_vol;
	reg [3:0]	r_ch3_vol;
	reg [3:0]	r_ch4_vol;
	reg [3:0]	r_ch5_vol;
	reg [3:0]	r_ch6_vol;
	reg [3:0]	r_ch7_vol;
	reg [3:0]	r_ch8_vol;

	reg 			r_ch_rhy_en;
	reg 			r_ch_rhy_bd_on;
	reg 			r_ch_rhy_sd_on;	
	reg 			r_ch_rhy_tom_on;
	reg 			r_ch_rhy_cym_on;
	reg 			r_ch_rhy_hh_on;		
	
	reg [5:0]		reg_add;

/* ==========================
   **** Begin of RTL Code ***
   ==========================
*/	
	
	/* Register address latch */
	
	always @(negedge clk) begin
		if (reset) begin
			reg_add[5:0] <= 6'b0;
		end
		else begin
			if (sel_reg) begin
				reg_add <= d[5:0];
			end
		end	
	end
	
	/* Register value latch */

	always @(negedge clk) begin
		if (reset) begin		
			r_ut_op0_am 		<= 1'b0;
			r_ut_op0_vib 		<= 1'b0;
			r_ut_op0_egtyp 		<= 1'b0;
			r_ut_op0_ksr 		<= 1'b0;	
			r_ut_op0_mult[3:0] 	<= 4'b0;
			r_ut_op0_ksl[1:0] 	<= 2'b0;
			r_ut_op0_tl[5:0] 	<= 6'b0;	
			r_ut_op0_wf 		<= 1'b0;		
			r_ut_op0_fb[2:0] 	<= 3'b0;
			r_ut_op0_ar[3:0] 	<= 4'b0;
			r_ut_op0_dr[3:0] 	<= 4'b0;		
			r_ut_op0_sl[3:0] 	<= 4'b0;
			r_ut_op0_rr[3:0] 	<= 4'b0;
	
			r_ut_op1_am 		<= 1'b0;
			r_ut_op1_vib 		<= 1'b0;
			r_ut_op1_egtyp	 	<= 1'b0;
			r_ut_op1_ksr 		<= 1'b0;		
			r_ut_op1_mult[3:0] 	<= 4'b0;
			r_ut_op1_ksl[1:0] 	<= 2'b0;
			r_ut_op1_wf 		<= 1'b0;

			r_ch0_fnum[8:0] 	<= 9'b0;
			r_ch1_fnum[8:0] 	<= 9'b0;
			r_ch2_fnum[8:0] 	<= 9'b0;
			r_ch3_fnum[8:0] 	<= 9'b0;
			r_ch4_fnum[8:0] 	<= 9'b0;
			r_ch5_fnum[8:0] 	<= 9'b0;
			r_ch6_fnum[8:0] 	<= 9'b0;
			r_ch7_fnum[8:0] 	<= 9'b0;
			r_ch8_fnum[8:0] 	<= 9'b0;

			r_ch0_block[2:0] 	<= 3'b0;
			r_ch1_block[2:0] 	<= 3'b0;
			r_ch2_block[2:0] 	<= 3'b0;
			r_ch3_block[2:0] 	<= 3'b0;
			r_ch4_block[2:0] 	<= 3'b0;
			r_ch5_block[2:0] 	<= 3'b0;
			r_ch6_block[2:0] 	<= 3'b0;
			r_ch7_block[2:0] 	<= 3'b0;
			r_ch8_block[2:0] 	<= 3'b0;
			
			r_ch0_sust_on 		<= 1'b0;
			r_ch1_sust_on 		<= 1'b0;
			r_ch2_sust_on 		<= 1'b0;
			r_ch3_sust_on 		<= 1'b0;
			r_ch4_sust_on 		<= 1'b0;
			r_ch5_sust_on 		<= 1'b0;
			r_ch6_sust_on 		<= 1'b0;
			r_ch7_sust_on 		<= 1'b0;
			r_ch8_sust_on 		<= 1'b0;

			r_ch0_key_on 		<= 1'b0;	
			r_ch1_key_on 		<= 1'b0;	
			r_ch2_key_on 		<= 1'b0;	
			r_ch3_key_on 		<= 1'b0;	
			r_ch4_key_on 		<= 1'b0;	
			r_ch5_key_on 		<= 1'b0;	
			r_ch6_key_on 		<= 1'b0;	
			r_ch7_key_on 		<= 1'b0;	
			r_ch8_key_on 		<= 1'b0;	
	
			r_ch0_inst_nr[3:0] 	<= 4'b0;
			r_ch1_inst_nr[3:0] 	<= 4'b0;
			r_ch2_inst_nr[3:0] 	<= 4'b0;
			r_ch3_inst_nr[3:0] 	<= 4'b0;
			r_ch4_inst_nr[3:0] 	<= 4'b0;
			r_ch5_inst_nr[3:0] 	<= 4'b0;
			r_ch6_inst_nr[3:0] 	<= 4'b0;
			r_ch7_inst_nr[3:0] 	<= 4'b0;
			r_ch8_inst_nr[3:0] 	<= 4'b0;

			r_ch0_vol[3:0] 		<= 4'b0;
			r_ch1_vol[3:0] 		<= 4'b0;
			r_ch2_vol[3:0] 		<= 4'b0;
			r_ch3_vol[3:0] 		<= 4'b0;
			r_ch4_vol[3:0] 		<= 4'b0;
			r_ch5_vol[3:0] 		<= 4'b0;			
			r_ch6_vol[3:0] 		<= 4'b0;			
			r_ch7_vol[3:0] 		<= 4'b0;			
			r_ch8_vol[3:0] 		<= 4'b0;		
		
			r_ch_rhy_en				<= 1'b0;
			r_ch_rhy_bd_on			<= 1'b0;
			r_ch_rhy_sd_on			<= 1'b0;	
			r_ch_rhy_tom_on		<= 1'b0;
			r_ch_rhy_cym_on		<= 1'b0;
			r_ch_rhy_hh_on			<= 1'b0;	
		end
		else begin
			if (sel_dat) begin
				case (reg_add[5:0])
					
					// Custom Voice
					6'h00 : {r_ut_op0_am,r_ut_op0_vib,r_ut_op0_egtyp,r_ut_op0_ksr,r_ut_op0_mult[3:0]} <= d[7:0];
					6'h01 : {r_ut_op1_am,r_ut_op1_vib,r_ut_op1_egtyp,r_ut_op1_ksr,r_ut_op1_mult[3:0]} <= d[7:0];
					6'h02 : {r_ut_op0_ksl[1:0],r_ut_op0_tl[5:0]} <= d[7:0];
					6'h03 : {r_ut_op1_ksl[1:0],r_ut_op1_wf,r_ut_op0_wf,r_ut_op0_fb[2:0]} <= {d[7:6],d[4:0]};
					6'h04 : {r_ut_op0_ar[3:0],r_ut_op0_dr[3:0]} <= d[7:0];
					6'h05 : {r_ut_op1_ar[3:0],r_ut_op1_dr[3:0]} <= d[7:0];
					6'h06 : {r_ut_op0_sl[3:0],r_ut_op0_rr[3:0]} <= d[7:0];
					6'h07 : {r_ut_op1_sl[3:0],r_ut_op1_rr[3:0]} <= d[7:0];
					
					// Rhythm section
					6'h0e : {r_ch_rhy_en,r_ch_rhy_bd_on,r_ch_rhy_sd_on,r_ch_rhy_tom_on,r_ch_rhy_cym_on,r_ch_rhy_hh_on} <= d[5:0];
					
					// Frequencies
					6'h10 : r_ch0_fnum[7:0] <= d[7:0];
					6'h11 : r_ch1_fnum[7:0] <= d[7:0];
					6'h12 : r_ch2_fnum[7:0] <= d[7:0];
					6'h13 : r_ch3_fnum[7:0] <= d[7:0];
					6'h14 : r_ch4_fnum[7:0] <= d[7:0];
					6'h15 : r_ch5_fnum[7:0] <= d[7:0];
					6'h16 : r_ch6_fnum[7:0] <= d[7:0];
					6'h17 : r_ch7_fnum[7:0] <= d[7:0];
					6'h18 : r_ch8_fnum[7:0] <= d[7:0];

					6'h20 : {r_ch0_sust_on,r_ch0_key_on,r_ch0_block[2:0],r_ch0_fnum[8]} <= d[5:0];
					6'h21 : {r_ch1_sust_on,r_ch1_key_on,r_ch1_block[2:0],r_ch1_fnum[8]} <= d[5:0];
					6'h22 : {r_ch2_sust_on,r_ch2_key_on,r_ch2_block[2:0],r_ch2_fnum[8]} <= d[5:0];
					6'h23 : {r_ch3_sust_on,r_ch3_key_on,r_ch3_block[2:0],r_ch3_fnum[8]} <= d[5:0];
					6'h24 : {r_ch4_sust_on,r_ch4_key_on,r_ch4_block[2:0],r_ch4_fnum[8]} <= d[5:0];
					6'h25 : {r_ch5_sust_on,r_ch5_key_on,r_ch5_block[2:0],r_ch5_fnum[8]} <= d[5:0];
					6'h26 : {r_ch6_sust_on,r_ch6_key_on,r_ch6_block[2:0],r_ch6_fnum[8]} <= d[5:0];
					6'h27 : {r_ch7_sust_on,r_ch7_key_on,r_ch7_block[2:0],r_ch7_fnum[8]} <= d[5:0];
					6'h28 : {r_ch8_sust_on,r_ch8_key_on,r_ch8_block[2:0],r_ch8_fnum[8]} <= d[5:0];

					6'h30 : {r_ch0_inst_nr[3:0],r_ch0_vol[3:0]} <= d[7:0];
					6'h31 : {r_ch1_inst_nr[3:0],r_ch1_vol[3:0]} <= d[7:0];
					6'h32 : {r_ch2_inst_nr[3:0],r_ch2_vol[3:0]} <= d[7:0];
					6'h33 : {r_ch3_inst_nr[3:0],r_ch3_vol[3:0]} <= d[7:0];
					6'h34 : {r_ch4_inst_nr[3:0],r_ch4_vol[3:0]} <= d[7:0];
					6'h35 : {r_ch5_inst_nr[3:0],r_ch5_vol[3:0]} <= d[7:0];
					6'h36 : {r_ch6_inst_nr[3:0],r_ch6_vol[3:0]} <= d[7:0];
					6'h37 : {r_ch7_inst_nr[3:0],r_ch7_vol[3:0]} <= d[7:0];
					6'h38 : {r_ch8_inst_nr[3:0],r_ch8_vol[3:0]} <= d[7:0];
				endcase
			end
		end	
	end	
	
endmodule	