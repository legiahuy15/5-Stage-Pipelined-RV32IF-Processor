module pc (
   input  logic        i_clk    ,
   input  logic        i_rst_n  ,
   input  logic        i_en_pc  ,
   input  logic [31:0] i_next_pc,
   output logic [31:0] o_pc
);

   logic [31:0] next_pc, present_pc;

   always_comb begin
      next_pc = i_en_pc ? i_next_pc : present_pc; 
   end

   always_ff @(posedge i_clk or negedge i_rst_n) begin
      if (!i_rst_n) begin
         present_pc <= 32'b0;
      end else begin
         present_pc <= next_pc;
      end
   end

   assign o_pc = present_pc;

endmodule