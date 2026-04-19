module brc (
   // input
   input  logic        i_br_un   ,
   input  logic [31:0] i_rs1_data,
   input  logic [31:0] i_rs2_data,
   // output
   output logic        o_br_less ,
   output logic        o_br_equal
);

   logic [32:0] sub;

   assign sub = {1'b0, i_rs1_data} + ~{1'b0, i_rs2_data} + 32'b1;

   always_comb begin
      o_br_equal = (i_rs1_data == i_rs2_data);
      if (i_br_un == 0) begin
         if (i_rs1_data[31] ^ i_rs2_data[31] == 1'b0) o_br_less = sub[31];
         else o_br_less = i_rs1_data[31];
      end else o_br_less = sub[32];
   end

endmodule