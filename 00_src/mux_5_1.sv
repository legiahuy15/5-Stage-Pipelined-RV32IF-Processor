module mux_5_1 (
   // input
   input  logic [ 2:0] i_sel,
   input  logic [31:0] i_0, i_1, i_2, i_3, i_4,
   // output
   output logic [31:0] o_data
);

   always_comb begin
      case (i_sel)
         3'b000 : o_data = i_0;
         3'b001 : o_data = i_1;
         3'b010 : o_data = i_2;
         3'b011 : o_data = i_3;
         3'b100 : o_data = i_4;
         default: o_data = 32'h0;
      endcase
   end

endmodule