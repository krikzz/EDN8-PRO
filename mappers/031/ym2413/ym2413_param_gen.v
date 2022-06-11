//****************************************
// * Yamaha YM2413 Audio Implementation  *
// * === (c)2015-20 by Oliver Achten === *
// ***************************************

module ym2413_param_gen(
	clk,ch_select,
	
	r_ut_op0_am,r_ut_op0_vib,r_ut_op0_egtyp,r_ut_op0_ksr,r_ut_op0_mult,r_ut_op0_ksl,r_ut_op0_tl,r_ut_op0_wf,r_ut_op0_fb,r_ut_op0_ar,r_ut_op0_dr,r_ut_op0_sl,r_ut_op0_rr,
	r_ut_op1_am,r_ut_op1_vib,r_ut_op1_egtyp,r_ut_op1_ksr,r_ut_op1_mult,r_ut_op1_ksl,r_ut_op1_wf,r_ut_op1_ar,r_ut_op1_dr,r_ut_op1_sl,r_ut_op1_rr,
	
	r_ch0_fnum,r_ch1_fnum,r_ch2_fnum,r_ch3_fnum,r_ch4_fnum,r_ch5_fnum,r_ch6_fnum,r_ch7_fnum,r_ch8_fnum,
	r_ch0_block,r_ch1_block,r_ch2_block,r_ch3_block,r_ch4_block,r_ch5_block,r_ch6_block,r_ch7_block,r_ch8_block,
	r_ch0_sust_on,r_ch1_sust_on,r_ch2_sust_on,r_ch3_sust_on,r_ch4_sust_on,r_ch5_sust_on,r_ch6_sust_on,r_ch7_sust_on,r_ch8_sust_on,
	r_ch0_key_on,r_ch1_key_on,r_ch2_key_on,r_ch3_key_on,r_ch4_key_on,r_ch5_key_on,r_ch6_key_on,r_ch7_key_on,r_ch8_key_on,
	r_ch0_inst_nr,r_ch1_inst_nr,r_ch2_inst_nr,r_ch3_inst_nr,r_ch4_inst_nr,r_ch5_inst_nr,r_ch6_inst_nr,r_ch7_inst_nr,r_ch8_inst_nr,
	r_ch0_vol,r_ch1_vol,r_ch2_vol,r_ch3_vol,r_ch4_vol,r_ch5_vol,r_ch6_vol,r_ch7_vol,r_ch8_vol,

	r_ch_rhy_en,r_ch_rhy_bd_on,r_ch_rhy_sd_on,r_ch_rhy_tom_on,r_ch_rhy_cym_on,r_ch_rhy_hh_on,
	
	ch_op0_am,ch_op0_vib,ch_op0_egtyp,ch_op0_ksr,ch_op0_mult,ch_op0_ksl,ch_op0_tl,ch_op0_wf,ch_op0_fb,ch_op0_ar,ch_op0_dr,ch_op0_sl,ch_op0_rr,
	ch_op1_am,ch_op1_vib,ch_op1_egtyp,ch_op1_ksr,ch_op1_mult,ch_op1_ksl,ch_op1_wf,ch_op1_ar,ch_op1_dr,ch_op1_sl,ch_op1_rr,
	
	ch_fnum,ch_block,ch_sust_on,ch_key_on,ch_vol,ch_rhy_en,ch_rhy_key_on,ch_rhy_vol,
	instrument_set
);

	input				clk;
	input [3:0]		ch_select;
	
	/* Register block input */
	
	input 			r_ut_op0_am;
	input				r_ut_op0_vib;
	input				r_ut_op0_egtyp;
	input				r_ut_op0_ksr;	
	input [3:0] 	r_ut_op0_mult;
	input [1:0]		r_ut_op0_ksl;
	input [5:0] 	r_ut_op0_tl;	
	input		 		r_ut_op0_wf;		
	input [2:0] 	r_ut_op0_fb;
	input [3:0] 	r_ut_op0_ar;
	input [3:0] 	r_ut_op0_dr;		
	input [3:0] 	r_ut_op0_sl;
	input [3:0] 	r_ut_op0_rr;
	
	input 			r_ut_op1_am;
	input			r_ut_op1_vib;
	input			r_ut_op1_egtyp;
	input			r_ut_op1_ksr;		
	input [3:0] 	r_ut_op1_mult;
	input [1:0]		r_ut_op1_ksl;
	input		 	r_ut_op1_wf;
	input [3:0] 	r_ut_op1_ar;
	input [3:0] 	r_ut_op1_dr;		
	input [3:0] 	r_ut_op1_sl;
	input [3:0] 	r_ut_op1_rr;	
	
	
	input [8:0]		r_ch0_fnum;
	input [8:0]		r_ch1_fnum;
	input [8:0]		r_ch2_fnum;
	input [8:0]		r_ch3_fnum;
	input [8:0]		r_ch4_fnum;
	input [8:0]		r_ch5_fnum;
	input [8:0]		r_ch6_fnum;
	input [8:0]		r_ch7_fnum;
	input [8:0]		r_ch8_fnum;
	
	input [2:0]		r_ch0_block;
	input [2:0]		r_ch1_block;
	input [2:0]		r_ch2_block;
	input [2:0]		r_ch3_block;
	input [2:0]		r_ch4_block;
	input [2:0]		r_ch5_block;
	input [2:0]		r_ch6_block;
	input [2:0]		r_ch7_block;
	input [2:0]		r_ch8_block;
	
	input			r_ch0_sust_on;
	input			r_ch1_sust_on;
	input			r_ch2_sust_on;
	input			r_ch3_sust_on;
	input			r_ch4_sust_on;
	input			r_ch5_sust_on;
	input			r_ch6_sust_on;
	input			r_ch7_sust_on;
	input			r_ch8_sust_on;

	input			r_ch0_key_on;	
	input			r_ch1_key_on;	
	input			r_ch2_key_on;	
	input			r_ch3_key_on;	
	input			r_ch4_key_on;	
	input			r_ch5_key_on;		
	input			r_ch6_key_on;		
	input			r_ch7_key_on;		
	input			r_ch8_key_on;		
	
	input [3:0]		r_ch0_inst_nr;
	input [3:0]		r_ch1_inst_nr;
	input [3:0]		r_ch2_inst_nr;
	input [3:0]		r_ch3_inst_nr;
	input [3:0]		r_ch4_inst_nr;
	input [3:0]		r_ch5_inst_nr;
	input [3:0]		r_ch6_inst_nr;
	input [3:0]		r_ch7_inst_nr;
	input [3:0]		r_ch8_inst_nr;

	input [3:0]		r_ch0_vol;
	input [3:0]		r_ch1_vol;
	input [3:0]		r_ch2_vol;
	input [3:0]		r_ch3_vol;
	input [3:0]		r_ch4_vol;
	input [3:0]		r_ch5_vol;
	input [3:0]		r_ch6_vol;
	input [3:0]		r_ch7_vol;
	input [3:0]		r_ch8_vol;
	
	input 			r_ch_rhy_en;
	input 			r_ch_rhy_bd_on;
	input 			r_ch_rhy_sd_on;	
	input 			r_ch_rhy_tom_on;
	input 			r_ch_rhy_cym_on;
	input 			r_ch_rhy_hh_on;		

	/* Modulator output */

	output 			ch_op0_am;
	output			ch_op0_vib;
	output			ch_op0_egtyp;
	output			ch_op0_ksr;	
	output [3:0] 	ch_op0_mult;
	output [1:0]	ch_op0_ksl;
	output [5:0] 	ch_op0_tl;	
	output		 	ch_op0_wf;		
	output [2:0] 	ch_op0_fb;
	output [3:0] 	ch_op0_ar;
	output [3:0] 	ch_op0_dr;		
	output [3:0] 	ch_op0_sl;
	output [3:0] 	ch_op0_rr;
	
	/* Carrier output */
	
	output 			ch_op1_am;
	output			ch_op1_vib;
	output			ch_op1_egtyp;
	output			ch_op1_ksr;		
	output [3:0] 	ch_op1_mult;
	output [1:0]	ch_op1_ksl;
	output		 	ch_op1_wf;
	output [3:0] 	ch_op1_ar;
	output [3:0] 	ch_op1_dr;		
	output [3:0] 	ch_op1_sl;
	output [3:0] 	ch_op1_rr;	

	/* Channel output */
	
	output [8:0]	ch_fnum;
	output [2:0]	ch_block;
	output			ch_sust_on;
	output			ch_key_on;	
	output [3:0]	ch_vol;
	output			ch_rhy_en;
	output			ch_rhy_key_on;
	output [3:0]	ch_rhy_vol;
	
	input				instrument_set;

///

	reg 			ch_op0_am;
	reg			ch_op0_vib;
	reg			ch_op0_egtyp;
	reg			ch_op0_ksr;	
	reg [3:0] 	ch_op0_mult;
	reg [1:0]	ch_op0_ksl;
	reg [5:0] 	ch_op0_tl;	
	reg		 	ch_op0_wf;		
	reg [2:0] 	ch_op0_fb;
	reg [3:0] 	ch_op0_ar;
	reg [3:0] 	ch_op0_dr;		
	reg [3:0] 	ch_op0_sl;
	reg [3:0] 	ch_op0_rr;
	
	/* Carrier reg */
	
	reg 			ch_op1_am;
	reg			ch_op1_vib;
	reg			ch_op1_egtyp;
	reg			ch_op1_ksr;		
	reg [3:0] 	ch_op1_mult;
	reg [1:0]	ch_op1_ksl;
	reg		 	ch_op1_wf;
	reg [3:0] 	ch_op1_ar;
	reg [3:0] 	ch_op1_dr;		
	reg [3:0] 	ch_op1_sl;
	reg [3:0] 	ch_op1_rr;	

	/* Channel output */
	
	reg [8:0]	ch_fnum;
	reg [2:0]	ch_block;
	reg			ch_sust_on;
	reg			ch_key_on;	
	reg [3:0]	ch_vol;
	reg			ch_rhy_en;
	reg			ch_rhy_key_on;
	reg [3:0]	ch_rhy_vol;
	
	wire [4:0]	inst_select;
	wire [63:0] inst_data;
	wire [63:0] inst_rom_data;	
	
	assign inst_data[63:0] = (inst_select[4:0] != 5'b0) ? inst_rom_data[63:0] :
		{
			r_ut_op1_sl[3:0],
			r_ut_op1_rr[3:0],	
			
			r_ut_op0_sl[3:0],
			r_ut_op0_rr[3:0],	
			
			r_ut_op1_ar[3:0],		//$05
			r_ut_op1_dr[3:0],
			
			r_ut_op0_ar[3:0],		//$04
			r_ut_op0_dr[3:0],
			
			r_ut_op1_ksl[1:0],	//$03
			1'bz,
			r_ut_op1_wf,
			r_ut_op0_wf,	
			r_ut_op0_fb[2:0],
			
			r_ut_op0_ksl[1:0],	//$02
			r_ut_op0_tl[5:0],
			
			r_ut_op1_am,			//$01
			r_ut_op1_vib,
			r_ut_op1_egtyp,
			r_ut_op1_ksr,	
			r_ut_op1_mult[3:0],
			
			r_ut_op0_am,			//$00
			r_ut_op0_vib,
			r_ut_op0_egtyp,
			r_ut_op0_ksr,	
			r_ut_op0_mult[3:0],		
		};
		
	assign inst_select[4:0] = {1'b0,r_ch0_inst_nr[3:0]} & {5{ch_select[3:0]==4'd0}}	
							| {1'b0,r_ch1_inst_nr[3:0]} & {5{ch_select[3:0]==4'd1}}	
							| {1'b0,r_ch2_inst_nr[3:0]} & {5{ch_select[3:0]==4'd2}}	
							| {1'b0,r_ch3_inst_nr[3:0]} & {5{ch_select[3:0]==4'd3}}	
							| {1'b0,r_ch4_inst_nr[3:0]} & {5{ch_select[3:0]==4'd4}}	
							| {1'b0,r_ch5_inst_nr[3:0]} & {5{ch_select[3:0]==4'd5}}
							| (r_ch_rhy_en ? 5'h10 : {1'b0,r_ch6_inst_nr[3:0]}) & {5{ch_select[3:0]==4'd6}}
							| (r_ch_rhy_en ? 5'h11 : {1'b0,r_ch7_inst_nr[3:0]}) & {5{ch_select[3:0]==4'd7}}
							| (r_ch_rhy_en ? 5'h12 : {1'b0,r_ch8_inst_nr[3:0]}) & {5{ch_select[3:0]==4'd8}}
							;	

	always @(negedge clk) begin
		 ch_op1_sl[3:0] 	<= inst_data[63:60];//$07
		 ch_op1_rr[3:0]	<= inst_data[59:56];		
	
		 ch_op0_sl[3:0] 	<= inst_data[55:52];//$06
		 ch_op0_rr[3:0]	<= inst_data[51:48];	
	
		 ch_op1_ar[3:0] 	<= inst_data[47:44];//$05
		 ch_op1_dr[3:0] 	<= inst_data[43:40];			
	
		 ch_op0_ar[3:0] 	<= inst_data[39:36];//$04
		 ch_op0_dr[3:0] 	<= inst_data[35:32];			
	
		 ch_op1_ksl[1:0] 	<= inst_data[31:30]; //$03
		 ch_op1_wf 			<= inst_data[28];
		 ch_op0_wf			<= inst_data[27];		
		 ch_op0_fb[2:0] 	<= inst_data[26:24];
		 	
		 ch_op0_ksl[1:0] 	<= inst_data[23:22]; //$02
		 ch_op0_tl[5:0] 	<= inst_data[21:16];	
	
		 ch_op1_am 			<= inst_data[15];		//$01
		 ch_op1_vib 		<= inst_data[14];
		 ch_op1_egtyp 		<= inst_data[13];
		 ch_op1_ksr 		<= inst_data[12];		
		 ch_op1_mult[3:0] <= inst_data[11:8];

		 ch_op0_am 			<= inst_data[7];		//$00
		 ch_op0_vib  		<= inst_data[6];
		 ch_op0_egtyp  	<= inst_data[5];
		 ch_op0_ksr 	 	<= inst_data[4];	
		 ch_op0_mult[3:0] <= inst_data[3:0];
	
		 ch_fnum[8:0] <= r_ch0_fnum[8:0] & {9{ch_select[3:0]==4'd0}}
					| r_ch1_fnum[8:0] & {9{ch_select[3:0]==4'd1}}
					| r_ch2_fnum[8:0] & {9{ch_select[3:0]==4'd2}}
					| r_ch3_fnum[8:0] & {9{ch_select[3:0]==4'd3}}
					| r_ch4_fnum[8:0] & {9{ch_select[3:0]==4'd4}}
					| r_ch5_fnum[8:0] & {9{ch_select[3:0]==4'd5}}
					| r_ch6_fnum[8:0] & {9{ch_select[3:0]==4'd6}}
					| r_ch7_fnum[8:0] & {9{ch_select[3:0]==4'd7}}
					| r_ch8_fnum[8:0] & {9{ch_select[3:0]==4'd8}}
					
					;
	
		 ch_block[2:0] <= r_ch0_block[2:0] & {3{ch_select[3:0]==4'd0}}
					| r_ch1_block[2:0] & {3{ch_select[3:0]==4'd1}}
					| r_ch2_block[2:0] & {3{ch_select[3:0]==4'd2}}
					| r_ch3_block[2:0] & {3{ch_select[3:0]==4'd3}}
					| r_ch4_block[2:0] & {3{ch_select[3:0]==4'd4}}
					| r_ch5_block[2:0] & {3{ch_select[3:0]==4'd5}}
					| r_ch6_block[2:0] & {3{ch_select[3:0]==4'd6}}
					| r_ch7_block[2:0] & {3{ch_select[3:0]==4'd7}}
					| r_ch8_block[2:0] & {3{ch_select[3:0]==4'd8}}
					;

		 ch_sust_on <= r_ch0_sust_on & (ch_select[3:0]==4'd0)
					| r_ch1_sust_on & (ch_select[3:0]==4'd1)						
					| r_ch2_sust_on & (ch_select[3:0]==4'd2)						
					| r_ch3_sust_on & (ch_select[3:0]==4'd3)						
					| r_ch4_sust_on & (ch_select[3:0]==4'd4)						
					| r_ch5_sust_on & (ch_select[3:0]==4'd5)
					| r_ch6_sust_on & (ch_select[3:0]==4'd6)
					| r_ch7_sust_on & (ch_select[3:0]==4'd7)
					| r_ch8_sust_on & (ch_select[3:0]==4'd8)					
					;				

		ch_key_on <= r_ch0_key_on & (ch_select[3:0]==4'd0)
					| r_ch1_key_on & (ch_select[3:0]==4'd1)						
					| r_ch2_key_on & (ch_select[3:0]==4'd2)						
					| r_ch3_key_on & (ch_select[3:0]==4'd3)						
					| r_ch4_key_on & (ch_select[3:0]==4'd4)						
					| r_ch5_key_on & (ch_select[3:0]==4'd5)
					
					| (r_ch6_key_on | (r_ch_rhy_bd_on & ch_rhy_en))  & (ch_select[3:0]==4'd6)
					| (r_ch7_key_on | (r_ch_rhy_sd_on & ch_rhy_en))  & (ch_select[3:0]==4'd7)
					| (r_ch8_key_on | (r_ch_rhy_cym_on & ch_rhy_en))  & (ch_select[3:0]==4'd8)							
					;				
				
		ch_rhy_key_on <= (r_ch7_key_on | (r_ch_rhy_hh_on & ch_rhy_en))  & (ch_select[3:0]==4'd7)
							| (r_ch8_key_on | (r_ch_rhy_tom_on & ch_rhy_en))  & (ch_select[3:0]==4'd8);
					
		 ch_vol[3:0] <= r_ch0_vol[3:0] & {4{ch_select[3:0]==4'd0}}	
					| r_ch1_vol[3:0] & {4{ch_select[3:0]==4'd1}}	
					| r_ch2_vol[3:0] & {4{ch_select[3:0]==4'd2}}	
					| r_ch3_vol[3:0] & {4{ch_select[3:0]==4'd3}}	
					| r_ch4_vol[3:0] & {4{ch_select[3:0]==4'd4}}	
					| r_ch5_vol[3:0] & {4{ch_select[3:0]==4'd5}}
					| r_ch6_vol[3:0] & {4{ch_select[3:0]==4'd6}}
					| r_ch7_vol[3:0] & {4{ch_select[3:0]==4'd7}}
					| r_ch8_vol[3:0] & {4{ch_select[3:0]==4'd8}}
					;	
		
		ch_rhy_vol[3:0] <= r_ch7_inst_nr[3:0] & {4{ch_select[3:0]==4'd7}}
								| r_ch8_inst_nr[3:0] & {4{ch_select[3:0]==4'd8}}
					;	
					
		ch_rhy_en <= r_ch_rhy_en
					;
	end
	


	ym2413_inst_rom inst_rom(
		.a({instrument_set,inst_select[4:0]}),
		.d({inst_rom_data[7:0],inst_rom_data[15:8],inst_rom_data[23:16],inst_rom_data[31:24],inst_rom_data[39:32],inst_rom_data[47:40],inst_rom_data[55:48],inst_rom_data[63:56]})
	);

endmodule

module ym2413_inst_rom (a,d);

// Update (09.07.2020) - Now using bit exact dumps from real chip

	input [5:0]	a;
	output [63:0] d;
	
	reg [63:0]	d;

	always @(*) begin
		case (a[5:0])
		
		// Melodic instruments (VRC7)
		
			6'h1 : d = 64'h03210506E8814227;
			6'h2 : d = 64'h1341140DD8F62312;
			6'h3 : d = 64'h11110808FAB22012;
			6'h4 : d = 64'h31610C07A8646127;
			6'h5 : d = 64'h32211E06E1760128;
			6'h6 : d = 64'h02010600A3E2F4F4;
			6'h7 : d = 64'h21611D0782811107;
			6'h8 : d = 64'h23212217A2720117;
			6'h9 : d = 64'h3511250040737201;
			6'ha : d = 64'hB5010F0FA8A55102;
			6'hb : d = 64'h17C12407F8F82212;
			6'hc : d = 64'h7123110665741816;
			6'hd : d = 64'h0102D305C9950302;
			6'he : d = 64'h61630C0094C033F6;
			6'hf : d = 64'h21720D00C1D55606;
				
		// Rhythm instruments
	
			6'h10 : d = 64'h0101180FDFF86A6D; // BD
			6'h11 : d = 64'h01010000C8D8A768; // HH / SD
			6'h12 : d = 64'h05010000F8AA5955; // TOM / CYM
		
		// Melodic instruments (YM2413)			
			
			6'h21 : d = 64'h71611E17D0780017;	
			6'h22 : d = 64'h13411A0DD8F72313;	
			6'h23 : d = 64'h13019900F2C41123;	
			6'h24 : d = 64'h31610E07A8647027;	
			6'h25 : d = 64'h32211E06E0760028;	
			6'h26 : d = 64'h31221605E0710018;	
			6'h27 : d = 64'h21611D0782811007;	
			6'h28 : d = 64'h23212D14A2720007;	
			6'h29 : d = 64'h61611B0664651017;	
			6'h2a : d = 64'h41610B1885F77107;	
			6'h2b : d = 64'h13018311FAE41004;	
			6'h2c : d = 64'h17C12407F8F82212;	
			6'h2d : d = 64'h61500C05C2F52042;	
			6'h2e : d = 64'h01015503C9950302;	
			6'h2f : d = 64'h61418903F1E44013;	
			
		// Rhythm instruments
		
			6'h30 : d = 64'h0101180FDFF86A6D; // BD
			6'h31 : d = 64'h01010000C8D8A748; // HH / SD
			6'h32 : d = 64'h05010000F8AA5955; // TOM / CYM			
	
			default: d = 64'h0;
		endcase
	end

endmodule
