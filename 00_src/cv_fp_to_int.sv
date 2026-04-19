module cv_fp_to_int #(
   parameter exp_width  = 8 ,
   parameter mant_width = 24,
   parameter int_width  = 32
)(
   // inputs
   input  logic        i_unsigned,
   input  logic [2:0]  i_frm     ,
   input  logic [31:0] i_op_a    ,
   // outputs
   output logic [31:0] o_result  ,
   output logic [ 4:0] o_fflags
);

///////////////////////////////////////////////////////////////////////////////

   function integer clog2;
      input integer a;
  
      begin
         a = a - 1;
         for (clog2 = 0; a > 0; clog2 = clog2 + 1) a = a>>1;
      end

   endfunction

   localparam int_exp_width        = clog2(int_width);
   localparam norm_dist_width      = clog2(mant_width);
   localparam bound_exp_width      = (exp_width <= int_exp_width) ? exp_width - 1 : int_exp_width;

///////////////////////////////////////////////////////////////////////////////

   logic signed_out;

   logic sign_num;
   logic [exp_width-1:0]  exp_num;
   logic [mant_width-2:0] mant_num;

   logic is_num_zero, is_num_inf, is_num_qNaN, is_num_sNaN, exp_zero, mant_zero;

   logic [(norm_dist_width-1):0] norm_dist;

   logic [exp_width:0] adjusted_exp, exp_final;
   logic is_special, mag_one, mag_below_one;
   logic signed [(exp_width):0] signed_exp;
   logic [(exp_width-1):0] pos_exp; 

   logic round_mode_near_even, round_mode_min_mag, round_mode_min;
   logic round_mode_max,round_mode_near_max_mag; 

   logic [(int_width + mant_width)-2:0] shifted_sig;
   logic [int_width+1:0] aligned_sig;
   logic [int_width-1:0] unrounded_int, comp_unrounded_int, rounded_int;

   logic common_inexact, round_incr_near_even, round_incr_near_max_mag, round_incr;
   logic mag_one_overflow, common_overflow;

   logic invalid, overflow, inexact;
   logic [(int_width-1):0] exc_out;
   logic [9:0]  num_check_res;

///////////////////////////////////////////////////////////////////////////////

   assign signed_out  = !i_unsigned;

   assign {sign_num, exp_num, mant_num} = i_op_a;

   special_check #(exp_width,mant_width) special_check_in (.in (i_op_a), .result(num_check_res));

   assign is_num_zero = num_check_res[3] | num_check_res[4];
   assign is_num_inf  = num_check_res[0] | num_check_res[7];
   assign is_num_qNaN = num_check_res[9];
   assign is_num_sNaN = num_check_res[8];

   // check exponent and mantissa is zero (needs to be a better way)
   assign exp_zero   = (exp_num == 0);
   assign mant_zero  = (mant_num == 0);

   // computing location of first one 
   lead_zero_param #(mant_width-1, norm_dist_width) countLeadingZeros(mant_num, norm_dist);

   assign adjusted_exp  = (exp_zero ? norm_dist ^ ((1 << (exp_width+1))-1) : exp_num)
                       + ((1<<(exp_width-1)) | (exp_zero ? 2:1));

   assign is_special = (adjusted_exp[exp_width:(exp_width - 1)] == 'b11);
   assign exp_final[exp_width:(exp_width - 2)] = is_special ? {2'b11, !mant_zero} :is_num_zero ? 3'b000 :
                                                adjusted_exp[exp_width:(exp_width - 2)];
   assign exp_final[(exp_width - 3):0]         = adjusted_exp;

   assign signed_exp              = exp_final;
   assign mag_one                 = signed_exp[exp_width];
   assign pos_exp                 = signed_exp[(exp_width-1):0];
   assign mag_below_one           = !mag_one && (&pos_exp);

   assign round_mode_near_even    = (i_frm == 3'b000);
   assign round_mode_min_mag      = (i_frm == 3'b001);
   assign round_mode_min          = (i_frm == 3'b010);
   assign round_mode_max          = (i_frm == 3'b011);
   assign round_mode_near_max_mag = (i_frm == 3'b100);

   assign shifted_sig             = {mag_one,mant_num[(mant_width-2):0]} << 
                                    (mag_one ? signed_exp[(bound_exp_width - 1):0] : 0);
   assign aligned_sig             = {shifted_sig>>(mant_width-2), |shifted_sig[(mant_width-3):0]};
   assign unrounded_int           = aligned_sig >> 2; 

   assign common_inexact          = mag_one ? |aligned_sig[1:0] : !is_num_zero;

   assign round_incr_near_even    = (mag_one && ((&aligned_sig[2:1]) || (&aligned_sig[1:0])))  
                                   || (mag_below_one && (|aligned_sig[1:0]) );
   assign round_incr_near_max_mag = (mag_one && aligned_sig[1]) || mag_below_one ;

   assign round_incr              = (round_mode_near_even     && round_incr_near_even)    ||
                                    (round_mode_near_max_mag  && round_incr_near_max_mag) ||
                                    ((round_mode_min       )) && (sign_num && common_inexact) ||
                                    (round_mode_max           && (!sign_num && common_inexact));

   assign comp_unrounded_int      = sign_num ? ~unrounded_int : unrounded_int;
   assign rounded_int             = ((round_incr ^ sign_num) ? comp_unrounded_int+1 : comp_unrounded_int) ;
                                   
   assign mag_one_overflow        = (pos_exp == int_width-1);
   assign common_overflow         =  mag_one ? (pos_exp >= int_width) || (signed_out ? (sign_num ? mag_one_overflow
                                    && ((|unrounded_int[(int_width-2):0]) ||round_incr)
                                    : mag_one_overflow) : sign_num) : !signed_out && sign_num && round_incr;

   assign invalid  = is_num_qNaN || is_num_sNaN || is_num_inf;
   assign overflow = !invalid   && common_overflow;
   assign inexact  = !invalid && !common_overflow && common_inexact;

   int_excep #(int_width) integer_exception (
      .signed_out (signed_out),
      .is_qNaN    (is_num_qNaN),
      .is_sNaN    (is_num_sNaN),
      .sign       (sign_num),
      .execp_out  (exc_out)
   );

   assign o_result = (invalid || common_overflow) ? exc_out : rounded_int;

   assign o_fflags = {invalid, 1'b0, overflow, 1'b0, inexact};

endmodule