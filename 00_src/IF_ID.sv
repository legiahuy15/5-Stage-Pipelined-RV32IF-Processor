module IF_ID (
   input  logic        i_clk       ,
   input  logic        i_rst_n     ,
   input  logic        i_flush     ,
   input  logic        i_stall     ,

   input  logic        i_IF_mispred,
   input  logic [31:0] i_IF_pc_4   ,
   input  logic [31:0] i_IF_pc     ,
   input  logic [31:0] i_IF_inst   ,

   output logic        o_ID_mispred,
   output logic [31:0] o_ID_pc_4   ,
   output logic [31:0] o_ID_pc     ,
   output logic [31:0] o_ID_inst
);

   always_ff @(posedge i_clk or negedge i_rst_n) begin
      if (!i_rst_n) begin
         o_ID_pc_4    <= 32'b0;
         o_ID_pc      <= 32'b0;
         o_ID_inst    <= 32'b0;
         o_ID_mispred <= 1'b0 ;
      end else if ((!i_stall) && i_flush) begin
         o_ID_pc_4    <= 32'b0;
         o_ID_pc      <= 32'b0;
         o_ID_inst    <= 32'b0;
         o_ID_mispred <= 1'b0 ;
      end else if(!i_stall) begin
         o_ID_pc_4    <= i_IF_pc_4   ;
         o_ID_pc      <= i_IF_pc     ;
         o_ID_inst    <= i_IF_inst   ;
         o_ID_mispred <= i_IF_mispred;
      end
   end

endmodule