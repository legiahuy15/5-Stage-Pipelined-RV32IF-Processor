module fp_regfile (
   // input
   input  logic        i_clk     ,
   input  logic        i_rst_n   ,
   input  logic [ 4:0] i_rs1_addr,
   input  logic [ 4:0] i_rs2_addr,
   input  logic [ 4:0] i_rs3_addr,
   input  logic        i_rd_wren ,
   input  logic [ 4:0] i_rd_addr ,
   input  logic [31:0] i_rd_data ,
   // output
   output logic [31:0] o_rs1_data,
   output logic [31:0] o_rs2_data,
   output logic [31:0] o_rs3_data
);

///////////////////////////////////////////////////////////////////////////////
// Internal registers

   logic [31:0] register [0:31];

///////////////////////////////////////////////////////////////////////////////
// Write data

   always_ff @(posedge i_clk or negedge i_rst_n) begin 
      if (!i_rst_n) begin
         for (int i = 0; i < 32; i = i + 1) 
            register[i] <= 32'b0;
      end else if (i_rd_wren) begin
         register[i_rd_addr] <= i_rd_data;          
      end
   end

///////////////////////////////////////////////////////////////////////////////
// Read data

   always_comb begin
      o_rs1_data = register[i_rs1_addr];
      o_rs2_data = register[i_rs2_addr];
      o_rs3_data = register[i_rs3_addr];
   end

endmodule