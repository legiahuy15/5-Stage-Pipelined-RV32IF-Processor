module tb_ipc;

///////////////////////////////////////////////////////////////////////////////
// DUT I/O

   // Inputs:
   reg         i_clk     ;
   reg         i_rst_n   ;
   reg  [31:0] i_io_sw   ;
   reg  [31:0] i_io_btn  ;

   // Outputs:
   wire [31:0] o_pc_debug;
   wire        o_inst_vld;
   wire        o_mispred ; // active-low: 0 = mispredict/flush
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
// Params & counters

   localparam int               CLK_PERIOD   = 10;          // #5 toggle -> 10 time units/chu kỳ
   localparam longint unsigned  MAX_CYCLES   = 800_000;     // watchdog

   longint unsigned cycle_ctr;
   longint unsigned first_cycle, done_cycle;
   longint unsigned N_cycle, N_inst, NOP_cycles;

   bit measuring, done;
   reg [31:0] prev_ledr;

   // mispred active-low
   wire mispred_active = (o_mispred == 1'b0);

   // Biến thực để in IPC (khai báo ở cấp module để tránh lỗi parser)
   real ipc_by_count;
   real ipc_by_formula;

///////////////////////////////////////////////////////////////////////////////
// Clock

   always #5 i_clk = ~i_clk;

///////////////////////////////////////////////////////////////////////////////
// DUT instance (đổi tên module nếu khác)

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
// Init & reset

   initial begin
      // Wave dump (tùy simulator)
      $shm_open("wave.shm");
      //$dumpfile("wave.vcd"); $dumpvars(0, tb_ipc);

      $write("\n");
      $write("   Le Gia Huy - RV32IF Processor\n");
      $write("   Test: GCD\n");

      i_clk       = 1'b1;
      i_rst_n     = 1'b0;
      i_io_sw     = 32'd0;
      i_io_btn    = 32'd0;

      measuring   = 0;
      done        = 0;

      cycle_ctr   = 0;
      first_cycle = 0;
      done_cycle  = 0;

      N_cycle     = 0;
      N_inst      = 0;
      NOP_cycles  = 0;

      prev_ledr   = 32'h0;

      // Reset
      #20 i_rst_n = 1'b1;

      // Input
      i_io_sw  = 32'd12;
      i_io_btn = 32'd32;

      $write("\n   Input:\n");
      $write("      Switch: 0x%08h = %0d\n", i_io_sw, i_io_sw);
      $write("      Button: 0x%08h = %0d\n", i_io_btn, i_io_btn);
   end

///////////////////////////////////////////////////////////////////////////////
// Watchdog

   always @(posedge i_clk) begin
      if (cycle_ctr >= MAX_CYCLES && !done) begin
         $write("\n[WATCHDOG] %0d cycles have passed and are not yet complete.\n", MAX_CYCLES);
         done       <= 1;
         done_cycle <= cycle_ctr;
      end
   end

///////////////////////////////////////////////////////////////////////////////
// Global cycle counter

   always @(posedge i_clk or negedge i_rst_n) begin
      if (!i_rst_n) begin
         cycle_ctr <= 0;
      end else begin
         cycle_ctr <= cycle_ctr + 1;
      end
   end

///////////////////////////////////////////////////////////////////////////////
// Open measurement window at first valid retire
// Valid retire: o_inst_vld && o_pc_debug!=0 && !mispred_active

   always @(posedge i_clk or negedge i_rst_n) begin
      if (!i_rst_n) begin
         measuring   <= 0;
         first_cycle <= 0;
      end else if (!measuring) begin
         if (o_inst_vld && (o_pc_debug != 32'h0) && !mispred_active) begin
            measuring   <= 1;
            first_cycle <= cycle_ctr;
            //$write("   First valid retire at cycle: %0d\n", cycle_ctr, o_pc_debug);
         end
      end
   end

///////////////////////////////////////////////////////////////////////////////
// Count N_inst & NOP_cycles inside window

   always @(posedge i_clk or negedge i_rst_n) begin
      if (!i_rst_n) begin
         N_inst     <= 0;
         NOP_cycles <= 0;
      end else if (measuring && !done) begin
         if (o_inst_vld && (o_pc_debug != 32'h0) && !mispred_active)
            N_inst <= N_inst + 1;

         if (o_pc_debug == 32'h0)
            NOP_cycles <= NOP_cycles + 1;
      end
   end

///////////////////////////////////////////////////////////////////////////////
// Stop when o_io_ledr changes

   always @(posedge i_clk or negedge i_rst_n) begin
      if (!i_rst_n) begin
         prev_ledr  <= 32'h0;
         done       <= 0;
         done_cycle <= 0;
      end else begin
         if (!done && measuring && (o_io_ledr != prev_ledr)) begin
            done       <= 1;
            done_cycle <= cycle_ctr;
            $write("   Output: 0x%08h = %0d\n", o_io_ledr, o_io_ledr);
         end
         prev_ledr <= o_io_ledr;
      end
   end

///////////////////////////////////////////////////////////////////////////////
// Report

   always @(posedge i_clk) begin
      if (done) begin
         N_cycle = (done_cycle > first_cycle) ? (done_cycle - first_cycle) : 0;

         // Dùng $itor thay cho ép kiểu SV để tránh lỗi parser
         if (N_cycle != 0) begin
            ipc_by_count   = $itor(N_inst) / $itor(N_cycle);
            ipc_by_formula = $itor(N_cycle - NOP_cycles) / $itor(N_cycle);
         end else begin
            ipc_by_count   = 0.0;
            ipc_by_formula = 0.0;
         end

         $write("\n==== REPORT =======================\n");
         //$write("   First cycle   : %0d\n", first_cycle);
         //$write("   Done cycle    : %0d\n", done_cycle);
         $write("   N_cycle    : %0d\n", N_cycle);
         $write("   N_inst     : %0d\n", N_inst);
         $write("   NOP_cycles : %0d\n", NOP_cycles);
         $write("   IPC        : %f\n", ipc_by_count);
         //$write("   IPC (by formula)   : %f   // kỳ vọng trùng cách 1\n", ipc_by_formula);
         $write("===================================\n\n");

         $finish;
      end
   end

endmodule