module fp_class (
   // input
   input  logic [31:0] i_op_a,
   // output
   output logic [31:0] o_result
);

   wire [9:0] value_check;

   special_check special_chk (.in(i_op_a), .result(value_check));

   assign o_result = {22'b0, value_check};
  
endmodule