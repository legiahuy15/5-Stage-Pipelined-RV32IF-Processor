module input_buffer (
   input  logic        i_clk    ,
   input  logic        i_rst_n  ,

   input  logic [15:0] i_addr   ,
   input  logic [31:0] i_io_sw  ,
   input  logic [31:0] i_io_btn ,

   output logic [31:0] o_ld_data
);

///////////////////////////////////////////////////////////////////////////////
// Read only

   always_ff @(posedge i_clk) begin
      if (!i_rst_n) begin
         o_ld_data <= 32'h0;
      end else if (i_addr[7:4] == 4'h0) begin
         o_ld_data <= i_io_sw;
      end else if (i_addr[7:4] == 4'h1) begin
         o_ld_data <= i_io_btn;
      end else o_ld_data <= 32'h0;
   end

endmodule