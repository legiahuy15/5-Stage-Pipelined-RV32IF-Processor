module forwarding_unit (
   // input
   input  logic [31:0] i_ID_inst        ,
   input  logic [31:0] i_EX_inst        ,

   input  logic [31:0] i_MEM_inst       ,
   input  logic        i_MEM_int_rd_wren,
   input  logic        i_MEM_fp_rd_wren ,
   input  logic        i_MEM_fcsr_wren  ,

   input  logic [31:0] i_WB_inst        ,
   input  logic        i_WB_int_rd_wren ,
   input  logic        i_WB_fp_rd_wren  ,
   input  logic        i_WB_fcsr_wren   ,
   
   // output
   output logic        o_fw_int_rs1_sel ,
   output logic        o_fw_int_rs2_sel ,

   output logic        o_fw_fp_rs1_sel  ,
   output logic        o_fw_fp_rs2_sel  ,
   output logic        o_fw_fp_rs3_sel  ,

   output logic [ 2:0] o_fw_int_opa_sel ,
   output logic [ 2:0] o_fw_int_opb_sel ,

   output logic [ 1:0] o_fw_fp_opa_sel  ,
   output logic [ 1:0] o_fw_fp_opb_sel  ,
   output logic [ 1:0] o_fw_fp_opc_sel  ,

   output logic        o_fw_fcsr_en     ,
   output logic        o_fw_fcsr_sel
);

///////////////////////////////////////////////////////////////////////////////
// Definition

   localparam [4:0]
      // Integer
      R_TYPE = 5'b01100,
      I_TYPE = 5'b00100,
      //I_LOAD = 5'b00000,
      S_TYPE = 5'b01000,
      B_TYPE = 5'b11000,
      JAL    = 5'b11011,
      JALR   = 5'b11001,
      AUIPC  = 5'b00101,
      LUI    = 5'b01101,
      // Floating-point
      F_TYPE = 5'b10100,
      //FLW    = 5'b00001,
      //FSW    = 5'b01001,
      FMADD  = 5'b10000,
      FMSUB  = 5'b10001,
      FNMSUB = 5'b10010,
      FNMADD = 5'b10011,
      // Zicsr
      Z_TYPE = 5'b11100;

   // WB forward to ID
   localparam
      regfile_non_fw = 1'b0,
      regfile_fw     = 1'b1;
   
   // int_rs_data to ALU
   localparam [2:0]
      int_no_fw      = 3'b000,
      int_mem_alu    = 3'b001,
      int_mem_fpu    = 3'b010,
      int_mem_rd_csr = 3'b011,
      int_wb_rd_data = 3'b100;
   
   // fp_rs_data to FPU
   localparam [1:0]
      fp_no_fw      = 2'b00,
      fp_mem_fpu    = 2'b01,
      fp_wb_rd_data = 2'b10;

   // fp_csr
   localparam
      mem_fcsr = 1'b0,
      wb_fcsr  = 1'b1;

///////////////////////////////////////////////////////////////////////////////

   // register address
   logic [4:0] ID_rs1_addr, ID_rs2_addr, ID_rs3_addr;
   logic [4:0] EX_rs1_addr, EX_rs2_addr, EX_rs3_addr;
   logic [4:0] MEM_rd_addr, WB_rd_addr ;

   assign ID_rs1_addr = i_ID_inst[19:15];
   assign ID_rs2_addr = i_ID_inst[24:20];   
   assign ID_rs3_addr = i_ID_inst[31:27];

   assign EX_rs1_addr = i_EX_inst[19:15];
   assign EX_rs2_addr = i_EX_inst[24:20];
   assign EX_rs3_addr = i_EX_inst[31:27];

   assign MEM_rd_addr = i_MEM_inst[11:7];
   assign WB_rd_addr  = i_WB_inst[11:7];

   // opcode
   logic [4:0] EX_opcode, MEM_opcode;

   assign EX_opcode  = i_EX_inst[6:2] ;
   assign MEM_opcode = i_MEM_inst[6:2];

   // opcode detect
   logic EX_is_fp , EX_is_zicsr;
   logic MEM_is_int, MEM_is_fp, MEM_is_zicsr;

   // inst = integer
   assign MEM_is_int =  (MEM_opcode == R_TYPE) || (MEM_opcode == I_TYPE) || (MEM_opcode == S_TYPE) ||
                        (MEM_opcode == B_TYPE) || (MEM_opcode == JAL) || (MEM_opcode == JALR) ||
                        (MEM_opcode == AUIPC) || (MEM_opcode == LUI);

   // inst = floating-point
   assign EX_is_fp = (EX_opcode == F_TYPE) ||
                     (EX_opcode == FMADD) || (EX_opcode == FMSUB) || (EX_opcode == FNMSUB) || (EX_opcode == FNMADD);

   assign MEM_is_fp = (MEM_opcode == F_TYPE) ||
                      (MEM_opcode == FMADD) || (MEM_opcode == FMSUB) || (MEM_opcode == FNMSUB) || (MEM_opcode == FNMADD);

   // inst = zicsr
   assign EX_is_zicsr  = (EX_opcode == Z_TYPE) ;
   assign MEM_is_zicsr = (MEM_opcode == Z_TYPE);

///////////////////////////////////////////////////////////////////////////////
// Forwarding logic

   always_comb begin

      if (i_WB_int_rd_wren && (WB_rd_addr != 5'b0) && (WB_rd_addr == ID_rs1_addr)) o_fw_int_rs1_sel = regfile_fw;
      else o_fw_int_rs1_sel = regfile_non_fw;

      if (i_WB_int_rd_wren && (WB_rd_addr != 5'b0) && (WB_rd_addr == ID_rs2_addr)) o_fw_int_rs2_sel = regfile_fw;
      else o_fw_int_rs2_sel = regfile_non_fw;

      if (i_WB_fp_rd_wren && (WB_rd_addr == ID_rs1_addr)) o_fw_fp_rs1_sel = regfile_fw;
      else o_fw_fp_rs1_sel = regfile_non_fw;

      if (i_WB_fp_rd_wren && (WB_rd_addr == ID_rs2_addr)) o_fw_fp_rs2_sel = regfile_fw;
      else o_fw_fp_rs2_sel = regfile_non_fw;

      if (i_WB_fp_rd_wren && (WB_rd_addr == ID_rs3_addr)) o_fw_fp_rs3_sel = regfile_fw;
      else o_fw_fp_rs3_sel = regfile_non_fw;

   end

//-------------------------------------------------------------------

   always_comb begin

      if (MEM_is_int && i_MEM_int_rd_wren && (MEM_rd_addr != 5'b0) && (MEM_rd_addr == EX_rs1_addr)) o_fw_int_opa_sel = int_mem_alu;
      else if (MEM_is_fp && i_MEM_int_rd_wren && (MEM_rd_addr != 5'b0) && (MEM_rd_addr == EX_rs1_addr)) o_fw_int_opa_sel = int_mem_fpu;
      else if (MEM_is_zicsr && i_MEM_int_rd_wren && (MEM_rd_addr != 5'b0) && (MEM_rd_addr == EX_rs1_addr)) o_fw_int_opa_sel = int_mem_rd_csr;
      else if (i_WB_int_rd_wren && (WB_rd_addr != 5'b0) && (WB_rd_addr == EX_rs1_addr)) o_fw_int_opa_sel = int_wb_rd_data;
      else o_fw_int_opa_sel = int_no_fw;

      if (MEM_is_int && i_MEM_int_rd_wren && (MEM_rd_addr != 5'b0) && (MEM_rd_addr == EX_rs2_addr)) o_fw_int_opb_sel = int_mem_alu;
      else if (MEM_is_fp && i_MEM_int_rd_wren && (MEM_rd_addr != 5'b0) && (MEM_rd_addr == EX_rs2_addr)) o_fw_int_opb_sel = int_mem_fpu;
      else if (MEM_is_zicsr && i_MEM_int_rd_wren && (MEM_rd_addr != 5'b0) && (MEM_rd_addr == EX_rs2_addr)) o_fw_int_opb_sel = int_mem_rd_csr;
      else if (i_WB_int_rd_wren && (WB_rd_addr != 5'b0) && (WB_rd_addr == EX_rs2_addr)) o_fw_int_opb_sel = int_wb_rd_data;
      else o_fw_int_opb_sel = int_no_fw;

      if (i_MEM_fp_rd_wren && (MEM_rd_addr == EX_rs1_addr)) o_fw_fp_opa_sel = fp_mem_fpu;
      else if (i_WB_fp_rd_wren && (WB_rd_addr == EX_rs1_addr)) o_fw_fp_opa_sel = fp_wb_rd_data;
      else o_fw_fp_opa_sel = fp_no_fw;

      if (i_MEM_fp_rd_wren && (MEM_rd_addr == EX_rs2_addr)) o_fw_fp_opb_sel = fp_mem_fpu;
      else if (i_WB_fp_rd_wren && (WB_rd_addr == EX_rs2_addr)) o_fw_fp_opb_sel = fp_wb_rd_data;
      else o_fw_fp_opb_sel = fp_no_fw;

      if (i_MEM_fp_rd_wren && (MEM_rd_addr == EX_rs3_addr)) o_fw_fp_opc_sel = fp_mem_fpu;
      else if (i_WB_fp_rd_wren && (WB_rd_addr == EX_rs3_addr)) o_fw_fp_opc_sel = fp_wb_rd_data;
      else o_fw_fp_opc_sel = fp_no_fw;

   end

//-------------------------------------------------------------------

   always_comb begin
      if (EX_is_zicsr || EX_is_fp) begin
         if (i_MEM_fcsr_wren) begin
            o_fw_fcsr_en  = 1'b1;
            o_fw_fcsr_sel = mem_fcsr;
         end else if (i_WB_fcsr_wren) begin
            o_fw_fcsr_en  = 1'b1;
            o_fw_fcsr_sel = wb_fcsr;
         end else begin
            o_fw_fcsr_en  = 1'b0;
            o_fw_fcsr_sel = mem_fcsr;
         end
      end else begin
         o_fw_fcsr_en  = 1'b0;
         o_fw_fcsr_sel = mem_fcsr;
      end
   end

endmodule