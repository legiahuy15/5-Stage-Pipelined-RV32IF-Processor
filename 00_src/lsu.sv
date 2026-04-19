module lsu (
   // input
   input  logic        i_clk     ,
   input  logic        i_rst_n   ,

   input  logic        i_lsu_rden,
   input  logic        i_lsu_wren,
   input  logic [ 2:0] i_lsu_op  ,
   input  logic [31:0] i_lsu_addr,
   input  logic [31:0] i_st_data ,

   input  logic [31:0] i_io_sw   ,
   input  logic [31:0] i_io_btn  ,

   // output
   output logic        o_lsu_busy,
   output logic        o_lsu_ack ,
   output logic [31:0] o_ld_data ,

   output logic [31:0] o_io_ledr ,
   output logic [31:0] o_io_ledg ,
   output logic [ 6:0] o_io_hex0 ,
   output logic [ 6:0] o_io_hex1 ,
   output logic [ 6:0] o_io_hex2 ,
   output logic [ 6:0] o_io_hex3 ,
   output logic [ 6:0] o_io_hex4 ,
   output logic [ 6:0] o_io_hex5 ,
   output logic [ 6:0] o_io_hex6 ,
   output logic [ 6:0] o_io_hex7 ,
   output logic [31:0] o_io_lcd
);

///////////////////////////////////////////////////////////////////////////////
// Internal signal

   localparam [1:0] SB  = 2'b00 ,
                    SH  = 2'b01 ,
                    SW  = 2'b10 ;

   localparam [2:0] LB  = 3'b000,
                    LH  = 3'b001,
                    LW  = 3'b010,
                    LBU = 3'b100,
                    LHU = 3'b101;

   // counter
   logic [1:0] cycle_num_in, cycle_num;

   // store
   logic [ 3:0] wr_op, wr_op_q;
   logic [15:0] addr;
   logic [31:0] wr_data;

   // load
   logic [ 2:0] ld_op  , ld_op_q  ;
   logic [ 4:0] offset ;
   logic [15:0] rd_addr, rd_addr_q;

   // address decode
   logic is_in_buff  ;
   logic is_out_buff ;
   logic is_dmem     ;

   // start multi-cycle / single-cycle
   logic multi_cycle_en;
   logic single_cycle_en;

   // per-target enables
   logic dmem_wren, dmem_rden;
   logic out_buff_wren , out_buff_rden;

   // input_buffer signals
   logic [31:0] in_buff_data;

   // output_buffer signals
   logic        out_ld_vld;
   logic [31:0] out_buff_data;

   // dmem signals
   logic        dmem_ld_vld;
   logic [31:0] dmem_data;

   // select load source
   logic use_dmem;
   logic use_in_buff;

   // raw load data
   logic [31:0] ld_data_raw;

///////////////////////////////////////////////////////////////////////////////
// Submodules

   input_buffer In_Buffer (
      .i_clk     (i_clk)        ,
      .i_rst_n   (i_rst_n)      ,
      .i_addr    (i_lsu_addr[15:0]),
      .i_io_sw   (i_io_sw)      ,
      .i_io_btn  (i_io_btn)     ,
      .o_ld_data (in_buff_data)
   );

   output_buffer Out_Buffer (
      .i_clk     (i_clk)        ,
      .i_rst_n   (i_rst_n)      ,

      .i_rden    (out_buff_rden),
      .i_wren    (out_buff_wren),
      .i_wr_op   (wr_op)        ,
      .i_addr    (addr)         ,
      .i_wr_data (wr_data)      ,

      .o_ld_vld  (out_ld_vld)   ,
      .o_ld_data (out_buff_data),

      .o_io_ledr (o_io_ledr)    ,
      .o_io_ledg (o_io_ledg)    ,
      .o_io_hex0 (o_io_hex0)    ,
      .o_io_hex1 (o_io_hex1)    ,
      .o_io_hex2 (o_io_hex2)    ,
      .o_io_hex3 (o_io_hex3)    ,
      .o_io_hex4 (o_io_hex4)    ,
      .o_io_hex5 (o_io_hex5)    ,
      .o_io_hex6 (o_io_hex6)    ,
      .o_io_hex7 (o_io_hex7)    ,
      .o_io_lcd  (o_io_lcd)
   );

   dmem DMEM (
      .i_clk     (i_clk)        ,
      .i_rst_n   (i_rst_n)      ,
      .i_rden    (dmem_rden)    ,
      .i_wren    (dmem_wren)    ,
      .i_wr_op   (wr_op)        ,
      .i_addr    (addr)         ,
      .i_wr_data (wr_data)      ,
      .o_ld_vld  (dmem_ld_vld)  ,
      .o_ld_data (dmem_data)
   );

///////////////////////////////////////////////////////////////////////////////
// Address decode

   always_comb begin
      is_in_buff  = (i_lsu_addr[15:0] >= 16'h7800) && (i_lsu_addr[15:0] <= 16'h781F);
      is_out_buff = (i_lsu_addr[15:0] >= 16'h7000) && (i_lsu_addr[15:0] <= 16'h703F);
      is_dmem     = (i_lsu_addr[15:0] >= 16'h2000) && (i_lsu_addr[15:0] <= 16'h3FFF);
   end

   assign multi_cycle_en  = ( (i_lsu_wren || i_lsu_rden) && (is_dmem || is_out_buff) );
   assign single_cycle_en = i_lsu_rden && is_in_buff;

///////////////////////////////////////////////////////////////////////////////
// Counter

   assign cycle_num_in = multi_cycle_en ? 2'h3 : single_cycle_en ? 2'h1 : 2'h0;

   always_ff @(posedge i_clk) begin
      if (!i_rst_n) begin
         cycle_num <= 2'h0;
      end else if (multi_cycle_en || single_cycle_en) begin
         cycle_num <= cycle_num_in;
      end else if (cycle_num > 2'h0) begin
         cycle_num <= cycle_num - 1;
      end
   end

   assign o_lsu_busy = multi_cycle_en || single_cycle_en || (cycle_num != 2'h0);
   assign o_lsu_ack  = (cycle_num == 2'h1);

///////////////////////////////////////////////////////////////////////////////
// Store logic

   always_comb begin
      case (i_lsu_op[1:0])
         SB: wr_op_q = (4'b0001) << i_lsu_addr[1:0];
         SH: wr_op_q = (4'b0011) << (i_lsu_addr[1:0] & 2'b10);
         SW: wr_op_q = 4'b1111;
         default: wr_op_q = 4'b0000;
      endcase
   end

   always_ff @(posedge i_clk) begin
      if (!i_rst_n) begin
         wr_op         <= 4'b0;
         dmem_wren     <= 1'b0;
         out_buff_wren <= 1'b0;
      end else if (i_lsu_wren && (is_dmem || is_out_buff)) begin
         wr_op         <= wr_op_q;
         dmem_wren     <= is_dmem;
         out_buff_wren <= is_out_buff;
      end else begin
         wr_op         <= 4'b0;
         dmem_wren     <= 1'b0;
         out_buff_wren <= 1'b0;
      end
   end

   always_ff @(posedge i_clk) begin
      if (!i_rst_n) begin
         addr    <= 16'h0;
         wr_data <= 32'h0;
      end else begin
         addr    <= i_lsu_addr[15:0];
         wr_data <= i_st_data;
      end
   end

///////////////////////////////////////////////////////////////////////////////
// Load logic

   always_ff @(posedge i_clk) begin
      if (!i_rst_n) begin
         dmem_rden     <= 1'b0;
         out_buff_rden <= 1'b0;
      end else if (i_lsu_rden && (is_dmem || is_out_buff)) begin
         dmem_rden     <= is_dmem;
         out_buff_rden <= is_out_buff;
      end else begin
         dmem_rden     <= 1'b0;
         out_buff_rden <= 1'b0;
      end
   end

   always_comb begin
      ld_op_q = i_lsu_op;
      unique case (i_lsu_op)
         LB, LBU: rd_addr_q = i_lsu_addr[15:0];
         LH, LHU: rd_addr_q = {i_lsu_addr[15:1], (i_lsu_addr[0] & 1'b0)};    // 2B aligned
         LW     : rd_addr_q = {i_lsu_addr[15:2], (i_lsu_addr[1:0] & 2'b0)};  // 4B aligned
         default: rd_addr_q = i_lsu_addr[15:0];
      endcase
   end

   always_ff @(posedge i_clk) begin
      if (!i_rst_n) begin
         ld_op       <= 3'h0 ;
         rd_addr     <= 16'h0;
         use_dmem    <= 1'b0 ;
         use_in_buff <= 1'b0 ;
      end else if (i_lsu_rden && (is_in_buff || is_out_buff || is_dmem)) begin
         ld_op       <= ld_op_q   ;
         rd_addr     <= rd_addr_q ;
         use_dmem    <= is_dmem   ;
         use_in_buff <= is_in_buff;
      end
   end

   assign ld_data_raw = use_dmem ? dmem_data : use_in_buff ? in_buff_data : out_buff_data;

   always_comb begin
      offset = ({3'b0, rd_addr[1:0]} << 3);
      unique case (ld_op)
         LB : o_ld_data = {{24{ld_data_raw[offset + 7]}}, ld_data_raw[offset +:8]};
         LH : o_ld_data = {{16{ld_data_raw[offset + 15]}}, ld_data_raw[offset +:16]};
         LW : o_ld_data = ld_data_raw;
         LBU: o_ld_data = {24'b0, ld_data_raw[offset +:8]};
         LHU: o_ld_data = {16'b0, ld_data_raw[offset +:16]};
         default: o_ld_data = 32'b0;
      endcase
   end

endmodule