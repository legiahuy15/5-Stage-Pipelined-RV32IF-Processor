module fp_fma (
   // inputs
   input  logic [ 1:0] i_op    ,   // 00: A*B + C, 01: A*B - C, 10: -A*B + C, 11: -A*B - C
   input  logic [ 2:0] i_frm   ,
   input  logic [31:0] i_op_a  ,
   input  logic [31:0] i_op_b  ,
   input  logic [31:0] i_op_c  ,
   // outputs
   output logic [31:0] o_result,
   output logic [ 4:0] o_fflags
);

///////////////////////////////////////////////////////////////////////////////

   // Internal wires
   logic [31:0] mul_result;
   logic [ 4:0] mul_fflags;
   logic [31:0] add_result;
   logic [ 4:0] add_fflags;

   // Operand sign modifiers
   logic [31:0] op_a_mod, mul_result_mod, op_c_mod;
   logic        add_sub;

///////////////////////////////////////////////////////////////////////////////

   assign op_a_mod       = i_op[1] ? {~i_op_a[31], i_op_a[30:0]} : i_op_a;         // Negate A if needed
   //assign op_c_mod       = i_op[0] ? {~i_op_c[31], i_op_c[30:0]} : i_op_c;         // Negate C if needed
   assign add_sub        = i_op[0];                                               // Add or subtract

   // Instantiate fp_mul (purely combinational)
   fp_mul #(8, 24) u_mul (
      .i_frm    (i_frm)     ,
      .i_op_a   (op_a_mod)  ,
      .i_op_b   (i_op_b)    ,
      .o_result (mul_result),
      .o_fflags (mul_fflags)
   );

   // Instantiate fp_add_sub (purely combinational)
   fp_add_sub u_add_sub (
      .i_op     (add_sub)   ,
      .i_frm    (i_frm)     ,
      .i_op_a   (mul_result),
      .i_op_b   (i_op_c)    ,
      .o_result (add_result),
      .o_fflags (add_fflags)
   );

///////////////////////////////////////////////////////////////////////////////

   assign o_result = add_result;
   assign o_fflags = mul_fflags | add_fflags;

endmodule