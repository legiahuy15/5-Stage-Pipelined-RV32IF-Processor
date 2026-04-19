module EX_MEM (
   input logic         i_clk             ,
   input logic         i_rst_n           ,

   // IF-ID-EX-MEM
   input  logic [31:0] i_EX_pc_4         ,   // wb
   input  logic [31:0] i_EX_pc           ,   // debug
   input  logic [31:0] i_EX_inst         ,   // funct3, rd_addr
   input  logic        i_EX_mispred      ,

   output logic [31:0] o_MEM_pc_4        ,
   output logic [31:0] o_MEM_pc          ,
   output logic [31:0] o_MEM_inst        ,
   output logic        o_MEM_mispred     ,

   // ALU
   input  logic [31:0] i_EX_alu_data     ,   // LSU address
   output logic [31:0] o_MEM_alu_data    ,

   // FPU
   input  logic [31:0] i_EX_fpu_data     ,
   output logic [31:0] o_MEM_fpu_data    ,

   // FCSR
   input  logic [31:0] i_EX_read_csr     ,   // wb to rd
   input  logic [31:0] i_EX_fcsr         ,   // wb to fcsr

   output logic [31:0] o_MEM_read_csr    ,
   output logic [31:0] o_MEM_fcsr        ,

   // LSU
   input  logic [31:0] i_EX_int_rs2_data ,   // LSU store data
   input  logic [31:0] i_EX_fp_rs2_data  ,   // LSU store data

   output logic [31:0] o_MEM_int_rs2_data,   
   output logic [31:0] o_MEM_fp_rs2_data ,

   // Control
   input  logic        i_EX_inst_vld     ,
   input  logic        i_EX_st_sel       ,
   input  logic        i_EX_mem_wren     ,
   input  logic [ 2:0] i_EX_wb_sel       ,
   input  logic        i_EX_int_rd_wren  ,
   input  logic        i_EX_fp_rd_wren   ,
   input  logic        i_EX_fcsr_wren    ,

   output logic        o_MEM_inst_vld    ,
   output logic        o_MEM_st_sel      ,
   output logic        o_MEM_mem_wren    ,
   output logic [ 2:0] o_MEM_wb_sel      ,
   output logic        o_MEM_int_rd_wren ,
   output logic        o_MEM_fp_rd_wren  ,
   output logic        o_MEM_fcsr_wren   ,

   // Multi-cycle processing
   input  logic        i_fpu_ack          ,

   input  logic [31:0] i_midEX_pc_4       ,
   input  logic [31:0] i_midEX_pc         ,
   input  logic [31:0] i_midEX_inst       ,
   input  logic        i_midEX_mispred    ,

   input  logic        i_midEX_inst_vld   ,
   input  logic        i_midEX_st_sel     ,
   input  logic        i_midEX_mem_wren   ,
   input  logic [ 2:0] i_midEX_wb_sel     ,
   input  logic        i_midEX_int_rd_wren,
   input  logic        i_midEX_fp_rd_wren ,
   input  logic        i_midEX_fcsr_wren
);

///////////////////////////////////////////////////////////////////////////////

   always_ff @(posedge i_clk or negedge i_rst_n) begin
      
      if (!i_rst_n) begin
      
         o_MEM_pc_4         <= 32'b0;
         o_MEM_pc           <= 32'b0;
         o_MEM_inst         <= 32'b0;
         o_MEM_mispred      <= 1'b0 ;

         o_MEM_alu_data     <= 32'b0;

         o_MEM_fpu_data     <= 32'b0;

         o_MEM_read_csr     <= 32'b0;
         o_MEM_fcsr         <= 32'b0;

         o_MEM_int_rs2_data <= 32'b0;
         o_MEM_fp_rs2_data  <= 32'b0;

         o_MEM_inst_vld     <= 1'b0 ;
         o_MEM_st_sel       <= 1'b0 ;
         o_MEM_mem_wren     <= 1'b0 ;
         o_MEM_wb_sel       <= 3'b0 ;
         o_MEM_int_rd_wren  <= 1'b0 ;
         o_MEM_fp_rd_wren   <= 1'b0 ;
         o_MEM_fcsr_wren    <= 1'b0 ;

      end else begin

         o_MEM_pc_4         <= i_fpu_ack ? i_midEX_pc_4    : i_EX_pc_4   ;
         o_MEM_pc           <= i_fpu_ack ? i_midEX_pc      : i_EX_pc     ;
         o_MEM_inst         <= i_fpu_ack ? i_midEX_inst    : i_EX_inst   ;
         o_MEM_mispred      <= i_fpu_ack ? i_midEX_mispred : i_EX_mispred;

         o_MEM_alu_data     <= i_EX_alu_data;

         o_MEM_fpu_data     <= i_EX_fpu_data;

         o_MEM_read_csr     <= i_EX_read_csr;
         o_MEM_fcsr         <= i_EX_fcsr    ;

         o_MEM_int_rs2_data <= i_EX_int_rs2_data;
         o_MEM_fp_rs2_data  <= i_EX_fp_rs2_data ;

         o_MEM_inst_vld     <= i_fpu_ack ? i_midEX_inst_vld    : i_EX_inst_vld   ;
         o_MEM_st_sel       <= i_fpu_ack ? i_midEX_st_sel      : i_EX_st_sel     ;
         o_MEM_mem_wren     <= i_fpu_ack ? i_midEX_mem_wren    : i_EX_mem_wren   ;
         o_MEM_wb_sel       <= i_fpu_ack ? i_midEX_wb_sel      : i_EX_wb_sel     ;
         o_MEM_int_rd_wren  <= i_fpu_ack ? i_midEX_int_rd_wren : i_EX_int_rd_wren;
         o_MEM_fp_rd_wren   <= i_fpu_ack ? i_midEX_fp_rd_wren  : i_EX_fp_rd_wren ;
         o_MEM_fcsr_wren    <= i_fpu_ack ? i_midEX_fcsr_wren   : i_EX_fcsr_wren  ;

      end
   end

endmodule