module mux_2_1 (
   // input
   input  logic        i_sel,
   input  logic [31:0] i_0, i_1,
   // output
   output logic [31:0] o_data
);

   assign o_data = i_sel ? i_1 : i_0;

endmodule