//****************************************
// * Yamaha YM2413 Audio Implementation  *
// * === (c)2015-17 by Oliver Achten === *
// ***************************************

// Memory Map:
// -----------
// $9010 : Audio Register Select
// $9030 : Audio Register Write


module ym2413_audio(
	clk,res_n,
	cpu_d,cpu_a,cpu_ce_n,cpu_rw,
	audio_out,instrument_set
);

/* ========================
   **** I/O Assignments ***
   ========================
*/

	input				clk;
	input				res_n;
	
	input [7:0]		cpu_d;
	input [14:0]	cpu_a;
	input				cpu_ce_n;
	input				cpu_rw;
	
	output reg [10:0]	audio_out;
	
	input				instrument_set;

/* ==============
   **** Wires ***
   ==============
*/

	wire	write_reg_sel;
	wire	write_reg_dat;
	
	wire	[3:0]		ch_select;
	
	wire	[10:0]	audio_mix;

	
	wire			r_ut_op0_am;
	wire			r_ut_op0_vib;
	wire			r_ut_op0_egtyp;
	wire			r_ut_op0_ksr;
	wire	[3:0]	r_ut_op0_mult;
	wire	[1:0]	r_ut_op0_ksl;
	wire	[5:0]	r_ut_op0_tl;
	wire			r_ut_op0_wf;
	wire	[2:0]	r_ut_op0_fb;
	wire	[3:0]	r_ut_op0_ar;
	wire	[3:0]	r_ut_op0_dr;
	wire	[3:0]	r_ut_op0_sl;
	wire	[3:0]	r_ut_op0_rr;
	
	wire			r_ut_op1_am;
	wire			r_ut_op1_vib;
	wire			r_ut_op1_egtyp;
	wire			r_ut_op1_ksr;
	wire	[3:0]	r_ut_op1_mult;
	wire	[1:0]	r_ut_op1_ksl;
	wire			r_ut_op1_wf;
	wire	[3:0]	r_ut_op1_ar;
	wire	[3:0]	r_ut_op1_dr;
	wire	[3:0]	r_ut_op1_sl;
	wire	[3:0]	r_ut_op1_rr;
	
	wire	[8:0]	r_ch0_fnum;
	wire	[8:0]	r_ch1_fnum;
	wire	[8:0]	r_ch2_fnum;
	wire	[8:0]	r_ch3_fnum;
	wire	[8:0]	r_ch4_fnum;
	wire	[8:0]	r_ch5_fnum;
	wire	[8:0]	r_ch6_fnum;
	wire	[8:0]	r_ch7_fnum;
	wire	[8:0]	r_ch8_fnum;
	
	wire	[2:0]	r_ch0_block;
	wire	[2:0]	r_ch1_block;
	wire	[2:0]	r_ch2_block;
	wire	[2:0]	r_ch3_block;
	wire	[2:0]	r_ch4_block;
	wire	[2:0]	r_ch5_block;
	wire	[2:0]	r_ch6_block;
	wire	[2:0]	r_ch7_block;
	wire	[2:0]	r_ch8_block;
	
	wire			r_ch0_sust_on;
	wire			r_ch1_sust_on;
	wire			r_ch2_sust_on;
	wire			r_ch3_sust_on;
	wire			r_ch4_sust_on;
	wire			r_ch5_sust_on;
	wire			r_ch6_sust_on;
	wire			r_ch7_sust_on;
	wire			r_ch8_sust_on;
	
	wire			r_ch0_key_on;
	wire			r_ch1_key_on;
	wire			r_ch2_key_on;
	wire			r_ch3_key_on;
	wire			r_ch4_key_on;
	wire			r_ch5_key_on;
	wire			r_ch6_key_on;
	wire			r_ch7_key_on;
	wire			r_ch8_key_on;
	
	wire	[3:0]	r_ch0_inst_nr;
	wire	[3:0]	r_ch1_inst_nr;
	wire	[3:0]	r_ch2_inst_nr;
	wire	[3:0]	r_ch3_inst_nr;
	wire	[3:0]	r_ch4_inst_nr;
	wire	[3:0]	r_ch5_inst_nr;
	wire	[3:0]	r_ch6_inst_nr;
	wire	[3:0]	r_ch7_inst_nr;
	wire	[3:0]	r_ch8_inst_nr;
	
	wire	[3:0]	r_ch0_vol;
	wire	[3:0]	r_ch1_vol;
	wire	[3:0]	r_ch2_vol;
	wire	[3:0]	r_ch3_vol;
	wire	[3:0]	r_ch4_vol;
	wire	[3:0]	r_ch5_vol;
	wire	[3:0]	r_ch6_vol;
	wire	[3:0]	r_ch7_vol;
	wire	[3:0]	r_ch8_vol;

	wire			r_ch_rhy_en;
	wire			r_ch_rhy_bd_on;
	wire			r_ch_rhy_sd_on;	
	wire			r_ch_rhy_tom_on;
	wire			r_ch_rhy_cym_on;
	wire			r_ch_rhy_hh_on;
	
	wire			ch_op0_am;
	wire			ch_op0_vib;
	wire			ch_op0_egtyp;
	wire			ch_op0_ksr;
	wire	[3:0]	ch_op0_mult;
	wire	[1:0]	ch_op0_ksl;
	wire	[5:0]	ch_op0_tl;
	wire			ch_op0_wf;
	wire	[2:0]	ch_op0_fb;
	wire	[3:0]	ch_op0_ar;
	wire	[3:0]	ch_op0_dr;
	wire	[3:0]	ch_op0_sl;
	wire	[3:0]	ch_op0_rr;
	
	wire			ch_op1_am;
	wire			ch_op1_vib;
	wire			ch_op1_egtyp;
	wire			ch_op1_ksr;
	wire	[3:0]	ch_op1_mult;
	wire	[1:0]	ch_op1_ksl;
	wire			ch_op1_wf;
	wire	[3:0]	ch_op1_ar;
	wire	[3:0]	ch_op1_dr;
	wire	[3:0]	ch_op1_sl;
	wire	[3:0]	ch_op1_rr;	
	
	wire	[8:0]	ch_fnum;
	wire	[2:0]	ch_block;
	wire			ch_sust_on;
	wire			ch_key_on;
	wire	[3:0]	ch_vol;
	wire			ch_rhy_en;
	wire			ch_rhy_key_on;
	wire	[3:0]	ch_rhy_vol;
	
	
/* ==================
   **** Registers ***
   ==================
*/

	reg [10:0]	audio_dat;
	reg audio_res;

/* ====================
   **** Assignments ***
   ====================
*/

	assign	write_reg_sel = ~cpu_ce_n & ~cpu_rw & (cpu_a[14:0]==15'b001_0000_0001_0000); // $9010
	assign	write_reg_dat = ~cpu_ce_n & ~cpu_rw & (cpu_a[14:0]==15'b001_0000_0011_0000); // $9030

/* ==========================
   **** Begin of RTL Code ***
   ==========================
*/	

	ym2413_audio_regs audio_regs(
		.reset			(~res_n),
		.clk				(clk),
		.d					(cpu_d[7:0]),
		.sel_reg			(write_reg_sel),
		.sel_dat			(write_reg_dat),
		
		.r_ut_op0_am	(r_ut_op0_am),
		.r_ut_op0_vib	(r_ut_op0_vib),
		.r_ut_op0_egtyp(r_ut_op0_egtyp),
		.r_ut_op0_ksr	(r_ut_op0_ksr),
		.r_ut_op0_mult	(r_ut_op0_mult[3:0]),
		.r_ut_op0_ksl	(r_ut_op0_ksl[1:0]),
		.r_ut_op0_tl	(r_ut_op0_tl[5:0]),
		.r_ut_op0_wf	(r_ut_op0_wf),
		.r_ut_op0_fb	(r_ut_op0_fb[2:0]),
		.r_ut_op0_ar	(r_ut_op0_ar[3:0]),
		.r_ut_op0_dr	(r_ut_op0_dr[3:0]),
		.r_ut_op0_sl	(r_ut_op0_sl[3:0]),
		.r_ut_op0_rr	(r_ut_op0_rr[3:0]),
	
		.r_ut_op1_am	(r_ut_op1_am),
		.r_ut_op1_vib	(r_ut_op1_vib),
		.r_ut_op1_egtyp(r_ut_op1_egtyp),
		.r_ut_op1_ksr	(r_ut_op1_ksr),
		.r_ut_op1_mult	(r_ut_op1_mult[3:0]),
		.r_ut_op1_ksl	(r_ut_op1_ksl[1:0]),
		.r_ut_op1_wf	(r_ut_op1_wf),
		.r_ut_op1_ar	(r_ut_op1_ar[3:0]),
		.r_ut_op1_dr	(r_ut_op1_dr[3:0]),
		.r_ut_op1_sl	(r_ut_op1_sl[3:0]),
		.r_ut_op1_rr	(r_ut_op1_rr[3:0]),
	
		.r_ch0_fnum		(r_ch0_fnum[8:0]),
		.r_ch1_fnum		(r_ch1_fnum[8:0]),
		.r_ch2_fnum		(r_ch2_fnum[8:0]),
		.r_ch3_fnum		(r_ch3_fnum[8:0]),
		.r_ch4_fnum		(r_ch4_fnum[8:0]),
		.r_ch5_fnum		(r_ch5_fnum[8:0]),
		.r_ch6_fnum		(r_ch6_fnum[8:0]),
		.r_ch7_fnum		(r_ch7_fnum[8:0]),
		.r_ch8_fnum		(r_ch8_fnum[8:0]),
	
		.r_ch0_block	(r_ch0_block[2:0]),
		.r_ch1_block	(r_ch1_block[2:0]),
		.r_ch2_block	(r_ch2_block[2:0]),
		.r_ch3_block	(r_ch3_block[2:0]),
		.r_ch4_block	(r_ch4_block[2:0]),
		.r_ch5_block	(r_ch5_block[2:0]),
		.r_ch6_block	(r_ch6_block[2:0]),
		.r_ch7_block	(r_ch7_block[2:0]),
		.r_ch8_block	(r_ch8_block[2:0]),
	
		.r_ch0_sust_on	(r_ch0_sust_on),
		.r_ch1_sust_on	(r_ch1_sust_on),
		.r_ch2_sust_on	(r_ch2_sust_on),
		.r_ch3_sust_on	(r_ch3_sust_on),
		.r_ch4_sust_on	(r_ch4_sust_on),
		.r_ch5_sust_on	(r_ch5_sust_on),
		.r_ch6_sust_on	(r_ch6_sust_on),
		.r_ch7_sust_on	(r_ch7_sust_on),
		.r_ch8_sust_on	(r_ch8_sust_on),
	
		.r_ch0_key_on	(r_ch0_key_on),
		.r_ch1_key_on	(r_ch1_key_on),
		.r_ch2_key_on	(r_ch2_key_on),
		.r_ch3_key_on	(r_ch3_key_on),
		.r_ch4_key_on	(r_ch4_key_on),
		.r_ch5_key_on	(r_ch5_key_on),
		.r_ch6_key_on	(r_ch6_key_on),
		.r_ch7_key_on	(r_ch7_key_on),
		.r_ch8_key_on	(r_ch8_key_on),
	
		.r_ch0_inst_nr	(r_ch0_inst_nr[3:0]),
		.r_ch1_inst_nr	(r_ch1_inst_nr[3:0]),
		.r_ch2_inst_nr	(r_ch2_inst_nr[3:0]),
		.r_ch3_inst_nr	(r_ch3_inst_nr[3:0]),
		.r_ch4_inst_nr	(r_ch4_inst_nr[3:0]),
		.r_ch5_inst_nr	(r_ch5_inst_nr[3:0]),
		.r_ch6_inst_nr	(r_ch6_inst_nr[3:0]),
		.r_ch7_inst_nr	(r_ch7_inst_nr[3:0]),
		.r_ch8_inst_nr	(r_ch8_inst_nr[3:0]),
	
		.r_ch0_vol		(r_ch0_vol[3:0]),
		.r_ch1_vol		(r_ch1_vol[3:0]),
		.r_ch2_vol		(r_ch2_vol[3:0]),
		.r_ch3_vol		(r_ch3_vol[3:0]),
		.r_ch4_vol		(r_ch4_vol[3:0]),
		.r_ch5_vol		(r_ch5_vol[3:0]),
		.r_ch6_vol		(r_ch6_vol[3:0]),
		.r_ch7_vol		(r_ch7_vol[3:0]),
		.r_ch8_vol		(r_ch8_vol[3:0]),
		
		.r_ch_rhy_en		(r_ch_rhy_en),
		.r_ch_rhy_bd_on	(r_ch_rhy_bd_on),
		.r_ch_rhy_sd_on	(r_ch_rhy_sd_on),
		.r_ch_rhy_tom_on	(r_ch_rhy_tom_on),
		.r_ch_rhy_cym_on	(r_ch_rhy_cym_on),
		.r_ch_rhy_hh_on	(r_ch_rhy_hh_on)	
	);

ym2413_param_gen param_gen(
		.clk				(clk),
		.ch_select		(ch_select[3:0]),

		.r_ut_op0_am	(r_ut_op0_am),
		.r_ut_op0_vib	(r_ut_op0_vib),
		.r_ut_op0_egtyp(r_ut_op0_egtyp),
		.r_ut_op0_ksr	(r_ut_op0_ksr),
		.r_ut_op0_mult	(r_ut_op0_mult[3:0]),
		.r_ut_op0_ksl	(r_ut_op0_ksl[1:0]),
		.r_ut_op0_tl	(r_ut_op0_tl[5:0]),
		.r_ut_op0_wf	(r_ut_op0_wf),
		.r_ut_op0_fb	(r_ut_op0_fb[2:0]),
		.r_ut_op0_ar	(r_ut_op0_ar[3:0]),
		.r_ut_op0_dr	(r_ut_op0_dr[3:0]),
		.r_ut_op0_sl	(r_ut_op0_sl[3:0]),
		.r_ut_op0_rr	(r_ut_op0_rr[3:0]),
	
		.r_ut_op1_am	(r_ut_op1_am),
		.r_ut_op1_vib	(r_ut_op1_vib),
		.r_ut_op1_egtyp(r_ut_op1_egtyp),
		.r_ut_op1_ksr	(r_ut_op1_ksr),
		.r_ut_op1_mult	(r_ut_op1_mult[3:0]),
		.r_ut_op1_ksl	(r_ut_op1_ksl[1:0]),
		.r_ut_op1_wf	(r_ut_op1_wf),
		.r_ut_op1_ar	(r_ut_op1_ar[3:0]),
		.r_ut_op1_dr	(r_ut_op1_dr[3:0]),
		.r_ut_op1_sl	(r_ut_op1_sl[3:0]),
		.r_ut_op1_rr	(r_ut_op1_rr[3:0]),
	
		.r_ch0_fnum		(r_ch0_fnum[8:0]),
		.r_ch1_fnum		(r_ch1_fnum[8:0]),
		.r_ch2_fnum		(r_ch2_fnum[8:0]),
		.r_ch3_fnum		(r_ch3_fnum[8:0]),
		.r_ch4_fnum		(r_ch4_fnum[8:0]),
		.r_ch5_fnum		(r_ch5_fnum[8:0]),
		.r_ch6_fnum		(r_ch6_fnum[8:0]),
		.r_ch7_fnum		(r_ch7_fnum[8:0]),
		.r_ch8_fnum		(r_ch8_fnum[8:0]),
	
		.r_ch0_block	(r_ch0_block[2:0]),
		.r_ch1_block	(r_ch1_block[2:0]),
		.r_ch2_block	(r_ch2_block[2:0]),
		.r_ch3_block	(r_ch3_block[2:0]),
		.r_ch4_block	(r_ch4_block[2:0]),
		.r_ch5_block	(r_ch5_block[2:0]),
		.r_ch6_block	(r_ch6_block[2:0]),
		.r_ch7_block	(r_ch7_block[2:0]),
		.r_ch8_block	(r_ch8_block[2:0]),
	
		.r_ch0_sust_on	(r_ch0_sust_on),
		.r_ch1_sust_on	(r_ch1_sust_on),
		.r_ch2_sust_on	(r_ch2_sust_on),
		.r_ch3_sust_on	(r_ch3_sust_on),
		.r_ch4_sust_on	(r_ch4_sust_on),
		.r_ch5_sust_on	(r_ch5_sust_on),
		.r_ch6_sust_on	(r_ch6_sust_on),
		.r_ch7_sust_on	(r_ch7_sust_on),
		.r_ch8_sust_on	(r_ch8_sust_on),
	
		.r_ch0_key_on	(r_ch0_key_on),
		.r_ch1_key_on	(r_ch1_key_on),
		.r_ch2_key_on	(r_ch2_key_on),
		.r_ch3_key_on	(r_ch3_key_on),
		.r_ch4_key_on	(r_ch4_key_on),
		.r_ch5_key_on	(r_ch5_key_on),
		.r_ch6_key_on	(r_ch6_key_on),
		.r_ch7_key_on	(r_ch7_key_on),
		.r_ch8_key_on	(r_ch8_key_on),
	
		.r_ch0_inst_nr	(r_ch0_inst_nr[3:0]),
		.r_ch1_inst_nr	(r_ch1_inst_nr[3:0]),
		.r_ch2_inst_nr	(r_ch2_inst_nr[3:0]),
		.r_ch3_inst_nr	(r_ch3_inst_nr[3:0]),
		.r_ch4_inst_nr	(r_ch4_inst_nr[3:0]),
		.r_ch5_inst_nr	(r_ch5_inst_nr[3:0]),
		.r_ch6_inst_nr	(r_ch6_inst_nr[3:0]),
		.r_ch7_inst_nr	(r_ch7_inst_nr[3:0]),
		.r_ch8_inst_nr	(r_ch8_inst_nr[3:0]),
	
		.r_ch0_vol		(r_ch0_vol[3:0]),
		.r_ch1_vol		(r_ch1_vol[3:0]),
		.r_ch2_vol		(r_ch2_vol[3:0]),
		.r_ch3_vol		(r_ch3_vol[3:0]),
		.r_ch4_vol		(r_ch4_vol[3:0]),
		.r_ch5_vol		(r_ch5_vol[3:0]),
		.r_ch6_vol		(r_ch6_vol[3:0]),
		.r_ch7_vol		(r_ch7_vol[3:0]),
		.r_ch8_vol		(r_ch8_vol[3:0]),
		
		.r_ch_rhy_en		(r_ch_rhy_en),
		.r_ch_rhy_bd_on	(r_ch_rhy_bd_on),
		.r_ch_rhy_sd_on	(r_ch_rhy_sd_on),
		.r_ch_rhy_tom_on	(r_ch_rhy_tom_on),
		.r_ch_rhy_cym_on	(r_ch_rhy_cym_on),
		.r_ch_rhy_hh_on	(r_ch_rhy_hh_on),
	
		.ch_op0_am		(ch_op0_am),
		.ch_op0_vib		(ch_op0_vib),
		.ch_op0_egtyp	(ch_op0_egtyp),
		.ch_op0_ksr		(ch_op0_ksr),
		.ch_op0_mult	(ch_op0_mult[3:0]),
		.ch_op0_ksl		(ch_op0_ksl[1:0]),
		.ch_op0_tl		(ch_op0_tl[5:0]),
		.ch_op0_wf		(ch_op0_wf),
		.ch_op0_fb		(ch_op0_fb[2:0]),
		.ch_op0_ar		(ch_op0_ar[3:0]),
		.ch_op0_dr		(ch_op0_dr[3:0]),
		.ch_op0_sl		(ch_op0_sl[3:0]),
		.ch_op0_rr		(ch_op0_rr[3:0]),
	
		.ch_op1_am		(ch_op1_am),
		.ch_op1_vib		(ch_op1_vib),
		.ch_op1_egtyp	(ch_op1_egtyp),
		.ch_op1_ksr		(ch_op1_ksr),
		.ch_op1_mult	(ch_op1_mult[3:0]),
		.ch_op1_ksl		(ch_op1_ksl[1:0]),
		.ch_op1_wf		(ch_op1_wf),
		.ch_op1_ar		(ch_op1_ar[3:0]),
		.ch_op1_dr		(ch_op1_dr[3:0]),
		.ch_op1_sl		(ch_op1_sl[3:0]),
		.ch_op1_rr		(ch_op1_rr[3:0]),		
				
	
		.ch_fnum			(ch_fnum[8:0]),
		.ch_block		(ch_block[2:0]),
		.ch_sust_on		(ch_sust_on),
		.ch_key_on		(ch_key_on),
		.ch_vol			(ch_vol[3:0]),
		.ch_rhy_en		(ch_rhy_en),
		.ch_rhy_key_on	(ch_rhy_key_on),
		.ch_rhy_vol		(ch_rhy_vol[3:0]),
		
		.instrument_set (instrument_set)
	);
	
	ym2413_calc calc (
		.clk				(clk),
		.reset			(~res_n),
		
		.ch_select		(ch_select[3:0]),		
		.ch_dat			(audio_mix[10:0]),
		
		.ch_op0_am		(ch_op0_am),
		.ch_op0_vib		(ch_op0_vib),
		.ch_op0_egtyp	(ch_op0_egtyp),
		.ch_op0_ksr		(ch_op0_ksr),
		.ch_op0_mult	(ch_op0_mult[3:0]),
		.ch_op0_ksl		(ch_op0_ksl[1:0]),
		.ch_op0_tl		(ch_op0_tl[5:0]),
		.ch_op0_wf		(ch_op0_wf),
		.ch_op0_fb		(ch_op0_fb[2:0]),
		.ch_op0_ar		(ch_op0_ar[3:0]),
		.ch_op0_dr		(ch_op0_dr[3:0]),
		.ch_op0_sl		(ch_op0_sl[3:0]),
		.ch_op0_rr		(ch_op0_rr[3:0]),
		
		.ch_op1_am		(ch_op1_am),
		.ch_op1_vib		(ch_op1_vib),
		.ch_op1_egtyp	(ch_op1_egtyp),
		.ch_op1_ksr		(ch_op1_ksr),
		.ch_op1_mult	(ch_op1_mult[3:0]),
		.ch_op1_ksl		(ch_op1_ksl[1:0]),
		.ch_op1_wf		(ch_op1_wf),
		.ch_op1_ar		(ch_op1_ar[3:0]),
		.ch_op1_dr		(ch_op1_dr[3:0]),
		.ch_op1_sl		(ch_op1_sl[3:0]),
		.ch_op1_rr		(ch_op1_rr[3:0]),		
		
		.ch_fnum			(ch_fnum[8:0]),
		.ch_block		(ch_block[2:0]),
		.ch_sust_on		(ch_sust_on),
		.ch_key_on		(ch_key_on),
		.ch_vol			(ch_vol[3:0]),
		.ch_rhy_en		(ch_rhy_en),
		.ch_rhy_key_on	(ch_rhy_key_on),
		.ch_rhy_vol		(ch_rhy_vol[3:0])		
	);

	always @(negedge clk) 
	begin
		audio_dat[10:0] <= audio_mix[10:0];
		audio_out[10:0] <= audio_dat[10:0];
		audio_res <= res_n;
	end
	

endmodule

