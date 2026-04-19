module mid_EX (
   input  logic        i_clk        ,
   input  logic        i_rst_n      ,

   // Write enable
   input  logic        i_fpu_start  ,
   //input  logic        i_fpu_ack    ,

   // IF-ID-EX
   input  logic [31:0] i_pc_4       ,
   input  logic [31:0] i_pc         ,
   input  logic [31:0] i_inst       ,
   input  logic        i_mispred    ,

   output logic [31:0] o_pc_4       ,
   output logic [31:0] o_pc         ,
   output logic [31:0] o_inst       ,
   output logic        o_mispred    ,

   // Control
   input  logic        i_inst_vld   ,
   input  logic        i_st_sel     ,
   input  logic        i_mem_rden   ,
   input  logic        i_mem_wren   ,
   input  logic [ 2:0] i_wb_sel     ,
   input  logic        i_int_rd_wren,
   input  logic        i_fp_rd_wren ,
   input  logic        i_fcsr_wren  ,

   output logic        o_inst_vld   ,
   output logic        o_st_sel     ,
   output logic        o_mem_rden   ,
   output logic        o_mem_wren   ,
   output logic [ 2:0] o_wb_sel     ,
   output logic        o_int_rd_wren,
   output logic        o_fp_rd_wren ,
   output logic        o_fcsr_wren
);

///////////////////////////////////////////////////////////////////////////////

   always_ff @(posedge i_clk or negedge i_rst_n) begin

      if (!i_rst_n) begin

         o_pc_4         <= 32'b0;
         o_pc           <= 32'b0;
         o_inst         <= 32'b0;
         o_mispred      <= 1'b0 ;

         o_inst_vld     <= 1'b0 ;
         o_st_sel       <= 1'b0 ;
         o_mem_rden     <= 1'b0 ;
         o_mem_wren     <= 1'b0 ;
         o_wb_sel       <= 3'h1 ;
         o_int_rd_wren  <= 1'b0 ;
         o_fp_rd_wren   <= 1'b0 ;
         o_fcsr_wren    <= 1'b0 ;

      end else if (i_fpu_start) begin

         o_pc_4         <= i_pc_4       ;
         o_pc           <= i_pc         ;
         o_inst         <= i_inst       ;
         o_mispred      <= i_mispred    ;

         o_inst_vld     <= i_inst_vld   ;
         o_st_sel       <= i_st_sel     ;
         o_mem_rden     <= i_mem_rden   ;
         o_mem_wren     <= i_mem_wren   ;
         o_wb_sel       <= i_wb_sel     ;
         o_int_rd_wren  <= i_int_rd_wren;
         o_fp_rd_wren   <= i_fp_rd_wren ;
         o_fcsr_wren    <= i_fcsr_wren  ;

      end
   end

endmodule