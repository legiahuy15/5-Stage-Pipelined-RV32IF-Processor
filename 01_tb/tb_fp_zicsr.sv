module tb_fp_zicsr;

///////////////////////////////////////////////////////////////////////////////

   // Input
   reg         i_clk     ;
   reg         i_rst_n   ;
   reg  [31:0] i_io_sw   ;
   reg  [31:0] i_io_btn  ;

   // Output
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

   pipelined DUT (
      .i_clk      (i_clk)     ,
      .i_rst_n    (i_rst_n)   ,
      .i_io_sw    (i_io_sw)   ,
      .i_io_btn   (i_io_btn)  ,
      .o_pc_debug (o_pc_debug),
      .o_inst_vld (o_inst_vld),
      .o_mispred  (o_mispred) ,   // active-low
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

   //logic [31:0] pc_debug;

   //assign pc_debug = o_inst_vld ? o_pc_debug : 32'h0;

   logic insn_vld;

   always #5 i_clk = ~i_clk;

   initial begin
      i_clk       = 1'b1;
      i_rst_n     = 1'b0;

      // Input
      i_io_sw     = 32'd12;
      i_io_btn    = 32'd32;

      // Reset
      #20 i_rst_n = 1'b1;

      // Timeout guard
      repeat (1000) @(posedge i_clk);
      $display("\nTimeout...\n\nDUT is considered\tP A S S E D\n");
      $finish;
   end

   always_comb begin
      if (o_pc_debug != 0) begin
      case (o_pc_debug)
         32'h0004: begin
            $display("TEST for RV32F & Zicsr");
            insn_vld = 1;
         end
         32'h038: begin if (o_io_ledr == 32'h40A00000) $write("PASSED\n"); else $write("FAILED\n"); $write("[%8t]:: 1::FMADD.S...........", $time); end
         32'h040: begin if (o_io_ledr == 32'hBF800000) $write("PASSED\n"); else $write("FAILED\n"); $write("[%8t]:: 2::FMSUB.S...........", $time); end
         32'h048: begin if (o_io_ledr == 32'h3F800000) $write("PASSED\n"); else $write("FAILED\n"); $write("[%8t]:: 3::FNMSUB.S..........", $time); end
         32'h050: begin if (o_io_ledr == 32'hC0A00000) $write("PASSED\n"); else $write("FAILED\n"); $write("[%8t]:: 4::FNMADD.S..........", $time); end
         32'h058: begin if (o_io_ledr == 32'h40400000) $write("PASSED\n"); else $write("FAILED\n"); $write("[%8t]:: 5::FADD.S............", $time); end
         32'h060: begin if (o_io_ledr == 32'h3F800000) $write("PASSED\n"); else $write("FAILED\n"); $write("[%8t]:: 6::FSUB.S............", $time); end
         32'h068: begin if (o_io_ledr == 32'h40000000) $write("PASSED\n"); else $write("FAILED\n"); $write("[%8t]:: 7::FMUL.S............", $time); end
         32'h070: begin if (o_io_ledr == 32'h40000000) $write("PASSED\n"); else $write("FAILED\n"); $write("[%8t]:: 8::FDIV.S............", $time); end
         32'h078: begin if (o_io_ledr == 32'h3FB504F3) $write("PASSED\n"); else $write("FAILED\n"); $write("[%8t]:: 9::FSQRT.S...........", $time); end
         32'h080: begin if (o_io_ledr == 32'h3F800000) $write("PASSED\n"); else $write("FAILED\n"); $write("[%8t]::10::FSGNJ.S...........", $time); end
         32'h088: begin if (o_io_ledr == 32'hBF800000) $write("PASSED\n"); else $write("FAILED\n"); $write("[%8t]::11::FSGNJN.S..........", $time); end
         32'h090: begin if (o_io_ledr == 32'h3F800000) $write("PASSED\n"); else $write("FAILED\n"); $write("[%8t]::12::FSGNJX.S..........", $time); end
         32'h098: begin if (o_io_ledr == 32'h3F800000) $write("PASSED\n"); else $write("FAILED\n"); $write("[%8t]::13::FMIN.S............", $time); end
         32'h0A0: begin if (o_io_ledr == 32'h40000000) $write("PASSED\n"); else $write("FAILED\n"); $write("[%8t]::14::FMAX.S............", $time); end
         32'h0A8: begin if (o_io_ledr == 32'h00000001) $write("PASSED\n"); else $write("FAILED\n"); $write("[%8t]::15::FCVT.W.S..........", $time); end
         32'h0B0: begin if (o_io_ledr == 32'h00000002) $write("PASSED\n"); else $write("FAILED\n"); $write("[%8t]::16::FCVT.WU.S.........", $time); end
         32'h0B8: begin if (o_io_ledr == 32'h40400000) $write("PASSED\n"); else $write("FAILED\n"); $write("[%8t]::17::FMV.X.S...........", $time); end
         32'h0C0: begin if (o_io_ledr == 32'h00000000) $write("PASSED\n"); else $write("FAILED\n"); $write("[%8t]::18::FEQ.S.............", $time); end
         32'h0C8: begin if (o_io_ledr == 32'h00000001) $write("PASSED\n"); else $write("FAILED\n"); $write("[%8t]::19::FLT.S.............", $time); end
         32'h0D0: begin if (o_io_ledr == 32'h00000000) $write("PASSED\n"); else $write("FAILED\n"); $write("[%8t]::20::FLE.S.............", $time); end
         32'h0D8: begin if (o_io_ledr == 32'h00000040) $write("PASSED\n"); else $write("FAILED\n"); $write("[%8t]::21::FCLASS.S..........", $time); end
         32'h0E4: begin if (o_io_ledr == 32'h42280000) $write("PASSED\n"); else $write("FAILED\n"); $write("[%8t]::22::FCVT.S.W..........", $time); end
         32'h0F0: begin if (o_io_ledr == 32'h42C80000) $write("PASSED\n"); else $write("FAILED\n"); $write("[%8t]::23::FCVT.S.WU.........", $time); end
         32'h0F8: begin if (o_io_ledr == 32'h00000064) $write("PASSED\n"); else $write("FAILED\n"); $write("[%8t]::24::FMV.S.X...........", $time); end
         32'h11C: begin if (o_io_ledr == 32'hC1200000) $write("PASSED\n"); else $write("FAILED\n"); $write("[%8t]::25::FLW & FSW.........", $time); end
         32'h120: begin if (o_io_ledr == 32'hC1200000) $write("PASSED\n"); else $write("FAILED\n"); $write("[%8t]::25::FLW & FSW.........", $time); end
         32'h128: begin if (o_io_ledr == 32'h00000009) $write("PASSED\n"); else $write("FAILED\n"); $write("[%8t]::26::CSRRWI............", $time); end
         32'h130: begin if (o_io_ledr == 32'h00000000) $write("PASSED\n"); else $write("FAILED\n"); $write("[%8t]::27::CSRRW.............", $time); end
         32'h138: begin if (o_io_ledr == 32'h0000001F) $write("PASSED\n"); else $write("FAILED\n"); $write("[%8t]::28::CSRRS.............", $time); end
         32'h140: begin if (o_io_ledr == 32'h000000BF) $write("PASSED\n"); else $write("FAILED\n"); $write("[%8t]::29::CSRRC.............", $time); end
         32'h148: begin if (o_io_ledr == 32'h000000B8) $write("PASSED\n"); else $write("FAILED\n"); $write("[%8t]::30::CSRRSI............", $time); end
         32'h150: begin if (o_io_ledr == 32'h000000BC) $write("PASSED\n"); else $write("FAILED\n"); $write("[%8t]::31::CSRRCI............", $time); end
         32'h154: begin
         if (o_inst_vld == 0) insn_vld = 0;
      end
         32'h158: begin if (insn_vld) $write("PASSED\n"); else $write("FAILED\n"); end
      endcase
   end
   end

endmodule