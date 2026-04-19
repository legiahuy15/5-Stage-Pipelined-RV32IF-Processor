module ID_EX (
   input  logic        i_clk             ,
   input  logic        i_rst_n           ,
   input  logic        i_flush           ,

   // IF-ID-EX
   input  logic [31:0] i_ID_pc_4         ,
   input  logic [31:0] i_ID_pc           ,
   input  logic [31:0] i_ID_inst         ,   // funct3 to control LSU at MEM, rd_addr to regfile
   input  logic        i_ID_mispred      ,

   output logic [31:0] o_EX_pc_4         ,
   output logic [31:0] o_EX_pc           ,  
   output logic [31:0] o_EX_inst         ,   // funct3 to control LSU at MEM, rd_addr to regfile
   output logic        o_EX_mispred      ,

   // Immediate
   input  logic [31:0] i_ID_imm_data     ,
   output logic [31:0] o_EX_imm_data     ,

   // Int_RegFile
   input  logic [31:0] i_ID_int_rs1_data ,
   input  logic [31:0] i_ID_int_rs2_data ,

   output logic [31:0] o_EX_int_rs1_data ,
   output logic [31:0] o_EX_int_rs2_data ,

   // FP_RegFile
   input  logic [31:0] i_ID_fp_rs1_data  ,
   input  logic [31:0] i_ID_fp_rs2_data  ,
   input  logic [31:0] i_ID_fp_rs3_data  ,

   output logic [31:0] o_EX_fp_rs1_data  ,
   output logic [31:0] o_EX_fp_rs2_data  ,
   output logic [31:0] o_EX_fp_rs3_data  ,

   // Control
   input  logic        i_ID_inst_vld     ,
   input  logic        i_ID_br_un        ,
   input  logic        i_ID_st_sel       ,
   input  logic        i_ID_mem_rden     ,
   input  logic        i_ID_mem_wren     ,
   input  logic [ 2:0] i_ID_wb_sel       ,
   input  logic        i_ID_alu_opa_sel  ,
   input  logic        i_ID_alu_opb_sel  ,
   input  logic        i_ID_int_rd_wren  ,
   input  logic [ 3:0] i_ID_alu_op       ,
   input  logic        i_ID_fpu_opa_sel  ,
   input  logic        i_ID_fp_rd_wren   ,
   input  logic [ 4:0] i_ID_fpu_op       ,
   input  logic        i_ID_start_fpu    ,
   input  logic [ 1:0] i_ID_csr_op       ,
   input  logic        i_ID_csr_wdata_sel,
   input  logic        i_ID_fcsr_wren    ,

   output logic        o_EX_inst_vld     ,
   output logic        o_EX_br_un        ,
   output logic        o_EX_st_sel       ,
   output logic        o_EX_mem_rden     ,
   output logic        o_EX_mem_wren     ,
   output logic [ 2:0] o_EX_wb_sel       ,
   output logic        o_EX_alu_opa_sel  ,
   output logic        o_EX_alu_opb_sel  ,
   output logic        o_EX_int_rd_wren  ,
   output logic [ 3:0] o_EX_alu_op       ,
   output logic        o_EX_fpu_opa_sel  ,
   output logic        o_EX_fp_rd_wren   ,
   output logic [ 4:0] o_EX_fpu_op       ,
   output logic        o_EX_start_fpu    ,
   output logic [ 1:0] o_EX_csr_op       ,
   output logic        o_EX_csr_wdata_sel,
   output logic        o_EX_fcsr_wren
);

///////////////////////////////////////////////////////////////////////////////

   always_ff @(posedge i_clk or negedge i_rst_n) begin
      if (!i_rst_n) o_EX_inst_vld <= 1'b0;
      else          o_EX_inst_vld <= i_ID_inst_vld;

      if (!i_rst_n) begin

         o_EX_pc_4          <= 32'b0;
         o_EX_pc            <= 32'b0;
         o_EX_inst          <= 32'b0;
         o_EX_mispred       <= 1'b0 ;

         o_EX_imm_data      <= 32'b0;

         o_EX_int_rs1_data  <= 32'b0;
         o_EX_int_rs2_data  <= 32'b0;

         o_EX_fp_rs1_data   <= 32'b0;
         o_EX_fp_rs2_data   <= 32'b0;
         o_EX_fp_rs3_data   <= 32'b0;

         o_EX_br_un         <= 1'b0 ;
         o_EX_st_sel        <= 1'b0 ;
         o_EX_mem_rden      <= 1'b0 ;
         o_EX_mem_wren      <= 1'b0 ;
         o_EX_wb_sel        <= 3'h2 ;
         o_EX_alu_opa_sel   <= 1'b0 ;
         o_EX_alu_opb_sel   <= 1'b0 ;
         o_EX_int_rd_wren   <= 1'b0 ;
         o_EX_alu_op        <= 4'b0 ;
         o_EX_fpu_opa_sel   <= 1'b0 ;
         o_EX_fp_rd_wren    <= 1'b0 ;
         o_EX_fpu_op        <= 5'b0 ;
         o_EX_start_fpu     <= 1'b0 ;
         o_EX_csr_op        <= 2'b0 ;
         o_EX_csr_wdata_sel <= 1'b0 ;
         o_EX_fcsr_wren     <= 1'b0 ;

      end else if (i_flush) begin

         o_EX_pc_4          <= 32'b0;
         o_EX_pc            <= 32'b0;
         o_EX_inst          <= 32'b0;
         o_EX_mispred       <= 1'b1 ;

         o_EX_imm_data      <= 32'b0;

         o_EX_int_rs1_data  <= 32'b0;
         o_EX_int_rs2_data  <= 32'b0;

         o_EX_fp_rs1_data   <= 32'b0;
         o_EX_fp_rs2_data   <= 32'b0;
         o_EX_fp_rs3_data   <= 32'b0;

         o_EX_br_un         <= 1'b0 ;
         o_EX_st_sel        <= 1'b0 ;
         o_EX_mem_rden      <= 1'b0 ;
         o_EX_mem_wren      <= 1'b0 ;
         o_EX_wb_sel        <= 3'h2 ;
         o_EX_alu_opa_sel   <= 1'b0 ;
         o_EX_alu_opb_sel   <= 1'b0 ;
         o_EX_int_rd_wren   <= 1'b0 ;
         o_EX_alu_op        <= 4'b0 ;
         o_EX_fpu_opa_sel   <= 1'b0 ;
         o_EX_fp_rd_wren    <= 1'b0 ;
         o_EX_fpu_op        <= 5'b0 ;
         o_EX_start_fpu     <= 1'b0 ;
         o_EX_csr_op        <= 2'b0 ;
         o_EX_csr_wdata_sel <= 1'b0 ;
         o_EX_fcsr_wren     <= 1'b0 ;

      end else begin
         
         o_EX_pc_4          <= i_ID_pc_4;
         o_EX_pc            <= i_ID_pc;
         o_EX_inst          <= i_ID_inst;
         o_EX_mispred       <= i_ID_mispred;

         o_EX_imm_data      <= i_ID_imm_data;

         o_EX_int_rs1_data  <= i_ID_int_rs1_data;
         o_EX_int_rs2_data  <= i_ID_int_rs2_data;

         o_EX_fp_rs1_data   <= i_ID_fp_rs1_data;
         o_EX_fp_rs2_data   <= i_ID_fp_rs2_data;
         o_EX_fp_rs3_data   <= i_ID_fp_rs3_data;

         o_EX_br_un         <= i_ID_br_un        ;
         o_EX_st_sel        <= i_ID_st_sel       ;
         o_EX_mem_rden      <= i_ID_mem_rden     ;
         o_EX_mem_wren      <= i_ID_mem_wren     ;
         o_EX_wb_sel        <= i_ID_wb_sel       ;
         o_EX_alu_opa_sel   <= i_ID_alu_opa_sel  ;
         o_EX_alu_opb_sel   <= i_ID_alu_opb_sel  ;
         o_EX_int_rd_wren   <= i_ID_int_rd_wren  ;
         o_EX_alu_op        <= i_ID_alu_op       ;
         o_EX_fpu_opa_sel   <= i_ID_fpu_opa_sel  ;
         o_EX_fp_rd_wren    <= i_ID_fp_rd_wren   ;
         o_EX_fpu_op        <= i_ID_fpu_op       ;
         o_EX_start_fpu     <= i_ID_start_fpu    ;
         o_EX_csr_op        <= i_ID_csr_op       ;
         o_EX_csr_wdata_sel <= i_ID_csr_wdata_sel;
         o_EX_fcsr_wren     <= i_ID_fcsr_wren    ;

      end
   end

endmodule