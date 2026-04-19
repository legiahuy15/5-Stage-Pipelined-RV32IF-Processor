module cv_int_to_fp (
   // inputs
   input  logic        i_unsigned,
   input  logic [ 2:0] i_frm,
   input  logic [31:0] i_op_a,
   // outputs
   output logic [31:0] o_result,
   output logic [ 4:0] o_fflags
);

///////////////////////////////////////////////////////////////////////////////

   wire        sign;
   wire        is_zero,rounding_overflow;

   wire [4:0]  index, shift_amount;
   wire [22:0] mantissa;
   wire [7:0]  exp;
   wire [31:0] shifted_num;
   wire [26:0] mant;
   wire [23:0] rounded_mantissa;
   wire [31:0] new_num;
   wire invalid;
   wire div_by_zero;
   wire overflow;
   wire underflow;
   wire inexact;

///////////////////////////////////////////////////////////////////////////////

   // check if input number is zero
   assign is_zero          = !(|i_op_a);

   // determining sign of result  
   assign sign             = (!i_unsigned) && i_op_a[31];
   assign new_num          = sign ? -i_op_a : i_op_a;

   // position of leading one  
   leading_ones lead_one (
      .in  (new_num),
      .out (index)
   );

   // calculating shift amount of the basis of leading one
   assign shift_amount = 5'd31 - index;

   // shifting number
   assign shifted_num = new_num << shift_amount;

   // compress number to 27 bits
   assign mant = {shifted_num[31:6], |shifted_num[5:0]};

   // rounding the number  
   rounding rounder(
      .sign              (sign),
      .mantisa           (mant),
      .round_mode        (i_frm),
      .rounded_mantisa   (rounded_mantissa),
      .rounding_overflow (rounding_overflow)
   );

   // exponent of the result  
   assign exp              = index + 8'd127 + rounding_overflow;

   // mantissa of the result  
   assign mantissa         = rounded_mantissa[22:0];

   // final result  
   assign o_result              = is_zero ? {32'd0} : {sign, exp, mantissa};

   // redundant exceptions
   assign invalid          = 1'b0; 
   assign div_by_zero      = 1'b0;
   assign overflow         = 1'b0;
   assign underflow        = 1'b0;

   // inexact result flag  
   assign inexact          = |mant[2:0];

   assign o_fflags         = {invalid, div_by_zero, overflow, underflow, inexact}; 

endmodule