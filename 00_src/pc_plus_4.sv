module pc_plus_4 (
   input  logic [31:0] i_pc,
   output logic [31:0] o_pc_plus_4
);

   assign o_pc_plus_4 = i_pc + 4;

endmodule