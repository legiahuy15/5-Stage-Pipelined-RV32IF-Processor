module tb_pipelined;

///////////////////////////////////////////////////////////////////////////////
// Signal declaration

   // Inputs:
   reg        i_clk;
   reg        i_rst_n;
   reg [31:0] i_io_sw;
   reg [31:0] i_io_btn;

   // Outputs:
   wire [31:0] o_pc_debug;
   wire        o_inst_vld;
   wire        o_mispred ;
   wire [31:0] o_io_ledr ;
   wire [31:0] o_io_ledg ;
   wire [ 6:0] o_io_hex0 ;
   wire [ 6:0] o_io_hex1 ;
   wire [ 6:0] o_io_hex2 ;
   wire [ 6:0] o_io_hex3 ;
   wire [ 6:0] o_io_hex4 ;
   wire [ 6:0] o_io_hex5 ;
   wire [ 6:0] o_io_hex6 ;
   wire [ 6:0] o_io_hex7 ;
   wire [31:0] o_io_lcd  ;

///////////////////////////////////////////////////////////////////////////////
// Clock generation

   always #5 i_clk = ~i_clk;

///////////////////////////////////////////////////////////////////////////////
// Instantiation

   pipelined DUT (
       .i_clk      (i_clk)     ,
       .i_rst_n    (i_rst_n)   ,
       .i_io_sw    (i_io_sw)   ,
       .i_io_btn   (i_io_btn)  ,
       .o_pc_debug (o_pc_debug),
       .o_inst_vld (o_inst_vld),
       .o_mispred  (o_mispred) ,
       .o_io_ledr  (o_io_ledr) ,
       .o_io_ledg  (o_io_ledg) ,
       .o_io_hex0  (o_io_hex0) ,
       .o_io_hex1  (o_io_hex1) ,
       .o_io_hex2  (o_io_hex2) ,
       .o_io_hex3  (o_io_hex3) ,
       .o_io_hex4  (o_io_hex4) ,
       .o_io_hex5  (o_io_hex5) ,
       .o_io_hex6  (o_io_hex6) ,
       .o_io_hex7  (o_io_hex7) ,
       .o_io_lcd   (o_io_lcd)
   );

///////////////////////////////////////////////////////////////////////////////
// Simulation logic

   initial begin
      $shm_open("wave.shm");

      i_clk = 0;
      i_rst_n = 0;
      i_io_sw = 32'h0;
      i_io_btn = 32'h0;

      // Reset CPU
      #10 i_rst_n = 1;
      i_io_sw  = 32'd5;

      #2500;
      $finish;
   end

endmodule