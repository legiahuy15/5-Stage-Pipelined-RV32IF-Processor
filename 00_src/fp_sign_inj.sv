module fp_sign_inj #(parameter exp_width = 8, parameter mant_width = 24)
(
   // inputs
   input  wire [(exp_width + mant_width)-1:0] i_op_a  ,
   input  wire [(exp_width + mant_width)-1:0] i_op_b  ,
   input  wire [1:0]                          i_op    ,
   // outputs
   output wire [(exp_width + mant_width)-1:0] o_result,
   output wire [4:0]                          o_fflags
);

   wire                  sign_a, sign_b;
   wire [ exp_width-1:0] exp_a , exp_b ;
   wire [mant_width-2:0] mant_a, mant_b;

   assign {sign_a, exp_a, mant_a} = i_op_a;
   assign {sign_b, exp_b, mant_b} = i_op_b;

   assign o_fflags = 5'b0;

   assign o_result = ({32{i_op == 2'b00}} & {sign_b, exp_a, mant_a})  |
                     ({32{i_op == 2'b01}} & {!sign_b, exp_a, mant_a}) |
                     ({32{i_op == 2'b10}} & {sign_a^sign_b, exp_a, mant_a});

/*
   always@(*) begin
      case (i_op)
         2'b00:   o_result = { sign_b, exp_a, mant_a };           // FSGNJ.S: Copy sign from op_b
         2'b01:   o_result = { ~sign_b, exp_a, mant_a };          // FSGNJN.S: Invert sign from op_b
         2'b10:   o_result = { sign_a ^ sign_b, exp_a, mant_a };  // FSGNJX.S: XOR sign_a and sign_b
         default: o_result = 32'd0;                               // Undefined op code
      endcase
   end
*/
endmodule