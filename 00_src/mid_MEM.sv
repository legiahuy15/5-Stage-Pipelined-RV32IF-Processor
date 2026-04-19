module mid_MEM (
   input  logic        i_clk        ,
   input  logic        i_rst_n      ,

   // Write enable
   input  logic        i_lsu_start  ,   // add logic to pipelined: = i_lsu_wren | i_lsu_rden

   // IF-ID-EX-MEM
   input  logic [31:0] i_pc         ,
   input  logic [31:0] i_inst       ,
   input  logic        i_mispred    ,

   output logic [31:0] o_pc         ,
   output logic [31:0] o_inst       ,
   output logic        o_mispred    ,

   // Mux WB (except lsu_ld_data)
   input  logic [31:0] i_pc_4       ,
   input  logic [31:0] i_alu_data   ,
   input  logic [31:0] i_fpu_data   ,
   input  logic [31:0] i_read_csr   ,

   output logic [31:0] o_pc_4       ,
   output logic [31:0] o_alu_data   ,
   output logic [31:0] o_fpu_data   ,
   output logic [31:0] o_read_csr   ,

   // FCSR
   input  logic [31:0] i_fcsr       ,
   output logic [31:0] o_fcsr       ,

   // Control
   input  logic        i_inst_vld   ,
   input  logic [ 2:0] i_wb_sel     ,
   input  logic        i_int_rd_wren,
   input  logic        i_fp_rd_wren ,
   input  logic        i_fcsr_wren  ,

   output logic        o_inst_vld   ,
   output logic [ 2:0] o_wb_sel     ,
   output logic        o_int_rd_wren,
   output logic        o_fp_rd_wren ,
   output logic        o_fcsr_wren
);

///////////////////////////////////////////////////////////////////////////////

   always_ff @(posedge i_clk or negedge i_rst_n) begin

      if (!i_rst_n) begin

         o_pc           <= 32'b0;
         o_inst         <= 32'b0;
         o_mispred      <= 1'b0 ;

         o_pc_4         <= 32'h0;
         o_alu_data     <= 32'h0;
         o_fpu_data     <= 32'h0;
         o_read_csr     <= 32'h0;

         o_fcsr         <= 32'h0;

         o_inst_vld     <= 1'b0 ;
         o_wb_sel       <= 3'h1 ;
         o_int_rd_wren  <= 1'b0 ;
         o_fp_rd_wren   <= 1'b0 ;
         o_fcsr_wren    <= 1'b0 ;

      end else if (i_lsu_start) begin

         o_pc           <= i_pc         ;
         o_inst         <= i_inst       ;
         o_mispred      <= i_mispred    ;

         o_pc_4         <= i_pc_4       ;
         o_alu_data     <= i_alu_data   ;
         o_fpu_data     <= i_fpu_data   ;
         o_read_csr     <= i_read_csr   ;

         o_fcsr         <= i_fcsr       ;

         o_inst_vld     <= i_inst_vld   ;
         o_wb_sel       <= i_wb_sel     ;
         o_int_rd_wren  <= i_int_rd_wren;
         o_fp_rd_wren   <= i_fp_rd_wren ;
         o_fcsr_wren    <= i_fcsr_wren  ;

      end
   end

endmodule