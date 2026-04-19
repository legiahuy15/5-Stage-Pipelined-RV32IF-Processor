module mux_3_1 (
   // input
   input  logic [ 1:0] i_sel,
   input  logic [31:0] i_0, i_1, i_2,
   // output
   output logic [31:0] o_data
);

   always_comb begin
      case (i_sel)
         2'b00  : o_data = i_0;
         2'b01  : o_data = i_1;
         2'b10  : o_data = i_2;
         default: o_data = 32'h0;
      endcase
   end

endmodule