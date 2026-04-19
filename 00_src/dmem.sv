module dmem (
   input  logic        i_clk    ,
   input  logic        i_rst_n  ,
   input  logic        i_rden   ,
   input  logic        i_wren   ,
   input  logic [ 3:0] i_wr_op  ,
   input  logic [15:0] i_addr   ,
   input  logic [31:0] i_wr_data,
   output logic        o_ld_vld ,
   output logic [31:0] o_ld_data
);

///////////////////////////////////////////////////////////////////////////////
// Signal declaration

   localparam int SIZE_BYTES = 8192;
   localparam int DEPTH      = SIZE_BYTES/4;   // 2048 words
   localparam     BASE       = 16'h2000;

   // counter
   logic [ 1:0] cycle_num;

   // latch input
   logic [ 3:0] wr_op_q;
   logic [15:0] addr_q;
   logic [31:0] wr_data_q;

   // word address (aligned)
   logic [15:0] off ;
   logic [10:0] addr;

   // byte-wide memories for byte-enable writes
   logic [7:0] mem0 [0:DEPTH-1];
   logic [7:0] mem1 [0:DEPTH-1];
   logic [7:0] mem2 [0:DEPTH-1];
   logic [7:0] mem3 [0:DEPTH-1];

///////////////////////////////////////////////////////////////////////////////
// Latch input

   always_ff @(posedge i_clk) begin
      if (!i_rst_n) begin
         wr_op_q   <= 4'h0 ;
         addr_q    <= 16'h0;
         wr_data_q <= 32'h0;
      end else if (i_wren || i_rden) begin
         wr_op_q   <= i_wr_op;
         addr_q    <= i_addr;
         wr_data_q <= i_wr_data;
      end
   end

   assign off  = addr_q - BASE;
   assign addr = off[12:2];

///////////////////////////////////////////////////////////////////////////////
// Counter

   always_ff @(posedge i_clk) begin
      if (!i_rst_n) begin
         cycle_num <= 2'b00;
      end else if (i_rden) begin
         cycle_num <= 2'b01;
      end else if (cycle_num > 2'b00) begin
         cycle_num <= cycle_num - 1;
      end
   end

///////////////////////////////////////////////////////////////////////////////
// Load-store logic

   // Write
   always_ff @(posedge i_clk) begin
      if (wr_op_q[0]) mem0[addr] <= wr_data_q[7:0];
      if (wr_op_q[1]) mem1[addr] <= wr_data_q[15:8];
      if (wr_op_q[2]) mem2[addr] <= wr_data_q[23:16];
      if (wr_op_q[3]) mem3[addr] <= wr_data_q[31:24];
   end

   // Read
   always_ff @(posedge i_clk) begin
      if (!i_rst_n) begin
         o_ld_vld  <= 1'b0;
         o_ld_data <= 32'h0;
      end else if (cycle_num == 2'b01) begin
         o_ld_vld  <= 1'b1;
         o_ld_data <= { mem3[addr], mem2[addr], mem1[addr], mem0[addr] };
      end else begin
         o_ld_vld  <= 1'b0;
         o_ld_data <= 32'h0;
      end
   end

endmodule