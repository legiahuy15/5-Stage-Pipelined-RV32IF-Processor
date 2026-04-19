module fp_min_max #(parameter exp_width = 8, parameter mant_width = 24)
(
   // inputs
   input wire [(exp_width + mant_width)-1:0]  i_op_a,
   input wire [(exp_width + mant_width)-1:0]  i_op_b,
   input wire                                 i_op, // 0: min - 1: max
   // outputs
   output wire [(exp_width + mant_width)-1:0] o_result,
   output wire [4:0]                          o_fflags
);

   wire [(exp_width + mant_width)-1:0] max, min, qnan, snan;
   wire [9:0] check_a, check_b;
   wire comp, both_zero, a_nan, b_nan;
   wire pos_comp;
   wire invalid;

   special_check #(exp_width, mant_width) spec_check_a (.in(i_op_a), .result(check_a));
   special_check #(exp_width, mant_width) spec_check_b (.in(i_op_b), .result(check_b));

   assign both_zero = (check_a [3] | check_a [4]) & (check_b [3] | check_b [4]) ;

   assign pos_comp  = (i_op_a[(exp_width + mant_width)-2:mant_width-1] == i_op_b[(exp_width + mant_width)-2:mant_width-1]) ? 
                      (i_op_a[mant_width-2:0] < i_op_b[mant_width-2:0]) : (i_op_a[(exp_width + mant_width)-2:mant_width-1] < 
                      i_op_b[(exp_width + mant_width)-2:mant_width-1]);

   assign comp      = (check_a[1] | check_a[2] | check_a[3]) & (check_b[5] | check_b[6] | check_b[4]) ? 1'b1 : 
                      (check_b[1] | check_b[2] | check_b[3]) & (check_a[5] | check_a[6] | check_a[4]) ? 1'b0 : 
                      (check_a[1] | check_a[2] | check_a[3]) & (check_b[1] | check_b[2] | check_b[3]) ? !pos_comp : pos_comp;
  
   assign max       = (both_zero & check_a[4]) ? i_op_a : (both_zero & check_a[3]) ? i_op_b : check_a[7] ? i_op_a : check_a[0] ? 
                      i_op_b : check_b[0] ? i_op_a : comp ? i_op_b : i_op_a;

   assign min       = (both_zero & check_a[4]) ? i_op_b : (both_zero & check_a[3]) ? i_op_a : check_a[7] ? i_op_b : check_a[0] ?
                      i_op_a : check_b[0] ? i_op_b : comp ? i_op_a : i_op_b;
  
   assign qnan      = 32'h7fc00000;
  
   assign invalid   = check_a[8] || check_b[8];

   assign o_result  = (((check_a[9] && check_b[9]) | (check_a[8] && check_b[8]) | (check_a[8] & check_b[9]) | (check_a[9] & check_b[8]))
                      ? qnan :((check_a[9] | check_a[8]) ? i_op_b : ((check_b[9] | check_b[8]) ? i_op_a : (i_op ? max : min))));
  
   assign o_fflags  = {invalid, 4'b0};

endmodule