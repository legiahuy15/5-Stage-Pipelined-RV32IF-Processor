module MEM_WB (
   input  logic         i_clk           ,
   input  logic         i_rst_n         ,

   // IF-ID-EX-MEM-WB
   input  logic [31:0] i_MEM_pc         ,   // debug
   input  logic [31:0] i_MEM_inst       ,   // func3, rd_addr
   input  logic        i_MEM_mispred    ,

   output logic [31:0] o_WB_pc          ,
   output logic [31:0] o_WB_inst        ,
   output logic        o_WB_mispred     ,

   // Mux WB
   input  logic [31:0] i_MEM_pc_4       ,
   input  logic [31:0] i_MEM_alu_data   ,
   input  logic [31:0] i_MEM_ld_data    ,
   input  logic [31:0] i_MEM_fpu_data   ,
   input  logic [31:0] i_MEM_read_csr   ,

   output logic [31:0] o_WB_pc_4        ,
   output logic [31:0] o_WB_alu_data    ,
   output logic [31:0] o_WB_ld_data     ,
   output logic [31:0] o_WB_fpu_data    ,
   output logic [31:0] o_WB_read_csr    ,

   // FCSR
   input  logic [31:0] i_MEM_fcsr       ,
   output logic [31:0] o_WB_fcsr        ,

   // Control
   input  logic        i_MEM_inst_vld   ,
   input  logic [ 2:0] i_MEM_wb_sel     ,
   input  logic        i_MEM_int_rd_wren,
   input  logic        i_MEM_fp_rd_wren ,
   input  logic        i_MEM_fcsr_wren  ,

   output logic        o_WB_inst_vld    ,
   output logic [ 2:0] o_WB_wb_sel      ,
   output logic        o_WB_int_rd_wren ,
   output logic        o_WB_fp_rd_wren  ,
   output logic        o_WB_fcsr_wren   ,

   // Multi-cycle processing
   input  logic        i_lsu_ack           ,

   input  logic [31:0] i_midMEM_pc         ,
   input  logic [31:0] i_midMEM_inst       ,
   input  logic        i_midMEM_mispred    ,

   input  logic [31:0] i_midMEM_pc_4       ,
   input  logic [31:0] i_midMEM_alu_data   ,
   input  logic [31:0] i_midMEM_fpu_data   ,
   input  logic [31:0] i_midMEM_read_csr   ,

   input  logic [31:0] i_midMEM_fcsr       ,

   input  logic        i_midMEM_inst_vld   ,
   input  logic [ 2:0] i_midMEM_wb_sel     ,
   input  logic        i_midMEM_int_rd_wren,
   input  logic        i_midMEM_fp_rd_wren ,
   input  logic        i_midMEM_fcsr_wren
);

///////////////////////////////////////////////////////////////////////////////

   always_ff @(posedge i_clk or negedge i_rst_n) begin

      if(!i_rst_n) begin

         o_WB_pc          <= 32'b0;
         o_WB_inst        <= 32'b0;
         o_WB_mispred     <= 1'b0 ;

         o_WB_pc_4        <= 32'b0;
         o_WB_alu_data    <= 32'b0;
         o_WB_ld_data     <= 32'b0;
         o_WB_fpu_data    <= 32'b0;
         o_WB_read_csr    <= 32'b0;

         o_WB_fcsr        <= 32'h0;

         o_WB_inst_vld    <= 1'b0 ;
         o_WB_wb_sel      <= 3'b1 ;
         o_WB_int_rd_wren <= 1'b0 ;
         o_WB_fp_rd_wren  <= 1'b0 ;
         o_WB_fcsr_wren   <= 1'b0 ;

      end else if (i_lsu_ack) begin

         o_WB_pc          <= i_midMEM_pc         ;
         o_WB_inst        <= i_midMEM_inst       ;
         o_WB_mispred     <= i_midMEM_mispred    ;

         o_WB_pc_4        <= i_midMEM_pc_4       ;
         o_WB_alu_data    <= i_midMEM_alu_data   ;
         o_WB_ld_data     <= i_MEM_ld_data       ;   // from LSU
         o_WB_fpu_data    <= i_midMEM_fpu_data   ;
         o_WB_read_csr    <= i_midMEM_read_csr   ;

         o_WB_fcsr        <= i_midMEM_fcsr       ;

         o_WB_inst_vld    <= i_midMEM_inst_vld   ;
         o_WB_wb_sel      <= i_midMEM_wb_sel     ;
         o_WB_int_rd_wren <= i_midMEM_int_rd_wren;
         o_WB_fp_rd_wren  <= i_midMEM_fp_rd_wren ;
         o_WB_fcsr_wren   <= i_midMEM_fcsr_wren  ;

      end else begin

         o_WB_pc          <= i_MEM_pc         ;
         o_WB_inst        <= i_MEM_inst       ;
         o_WB_mispred     <= i_MEM_mispred    ;

         o_WB_pc_4        <= i_MEM_pc_4       ;
         o_WB_alu_data    <= i_MEM_alu_data   ;
         o_WB_ld_data     <= i_MEM_ld_data    ;
         o_WB_fpu_data    <= i_MEM_fpu_data   ;
         o_WB_read_csr    <= i_MEM_read_csr   ;

         o_WB_fcsr        <= i_MEM_fcsr       ;

         o_WB_inst_vld    <= i_MEM_inst_vld   ;
         o_WB_wb_sel      <= i_MEM_wb_sel     ;
         o_WB_int_rd_wren <= i_MEM_int_rd_wren;
         o_WB_fp_rd_wren  <= i_MEM_fp_rd_wren ;
         o_WB_fcsr_wren   <= i_MEM_fcsr_wren  ;

      end
   end

endmodule