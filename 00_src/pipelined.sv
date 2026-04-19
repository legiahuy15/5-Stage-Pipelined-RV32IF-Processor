module pipelined (
   // Clock & Reset
   input  logic        i_clk     ,
   input  logic        i_rst_n   ,
   // Input peripheral
   input  logic [31:0] i_io_btn  ,
   input  logic [31:0] i_io_sw   ,
   // Debug
   output logic [31:0] o_pc_debug,
   output logic        o_inst_vld,
   output logic        o_mispred ,
   // Output peripheral
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

   logic        IF_mispred;

   // PC
   logic [31:0] IF_pc, IF_pc_4;

   // IMEM
   logic [31:0] IF_inst;

   // Branch Prediction
   logic [31:0] next_pc;
   logic        pred_flush;

   // IF_ID_reg
   logic        ID_mispred;
   logic [31:0] ID_pc, ID_pc_4;
   logic [31:0] ID_inst;

   // Control Unit
   logic        ID_inst_vld;
   logic        ID_br_un, ID_st_sel, ID_mem_rden, ID_mem_wren;
   logic [ 2:0] ID_wb_sel;

   logic        ID_alu_opa_sel, ID_alu_opb_sel;
   logic        ID_int_rd_wren;
   logic [ 3:0] ID_alu_op;

   logic        ID_fpu_opa_sel, ID_fp_rd_wren;
   logic [ 4:0] ID_fpu_op;
   logic        ID_start_fpu;

   logic [ 1:0] ID_csr_op;
   logic        ID_csr_wdata_sel, ID_fcsr_wren;

   // Integer RegFile
   logic [ 4:0] int_rs1_addr, int_rs2_addr;
   logic [31:0] int_rs1_data, int_rs2_data;

   assign int_rs1_addr = ID_inst[19:15];
   assign int_rs2_addr = ID_inst[24:20];

   // Floating-point RegFile
   logic [ 4:0] fp_rs1_addr, fp_rs2_addr, fp_rs3_addr;
   logic [31:0] fp_rs1_data, fp_rs2_data, fp_rs3_data;

   assign fp_rs1_addr = ID_inst[19:15];
   assign fp_rs2_addr = ID_inst[24:20];
   assign fp_rs3_addr = ID_inst[31:27];

   // Immediate Generator
   logic [31:0] ID_imm_data;

   // ID register data
   logic [31:0] ID_int_rs1_data, ID_int_rs2_data; 
   logic [31:0] ID_fp_rs1_data, ID_fp_rs2_data, ID_fp_rs3_data;

   // ID_EX_reg
   logic        EX_mispred;
   logic [31:0] EX_pc, EX_pc_4;
   logic [31:0] EX_inst;

   logic [31:0] EX_imm_data;

   logic [31:0] EX_int_rs1_data, EX_int_rs2_data;

   logic [31:0] EX_fp_rs1_data, EX_fp_rs2_data, EX_fp_rs3_data;

   logic        EX_inst_vld;
   logic        EX_br_un, EX_st_sel, EX_mem_rden, EX_mem_wren;
   logic [ 2:0] EX_wb_sel;

   logic        EX_alu_opa_sel, EX_alu_opb_sel;
   logic        EX_int_rd_wren;
   logic [ 3:0] EX_alu_op;

   logic        EX_fpu_opa_sel, EX_fp_rd_wren;
   logic [ 4:0] EX_fpu_op;
   logic        EX_start_fpu;

   logic [ 1:0] EX_csr_op;
   logic        EX_csr_wdata_sel, EX_fcsr_wren;

   // ALU
   logic [31:0] forward_int_a_data, forward_int_b_data;
   logic [31:0] alu_opa_data, alu_opb_data;
   logic [31:0] EX_alu_data;

   // FPU
   logic [31:0] forward_fp_a_data, forward_fp_b_data, forward_fp_c_data;
   logic [31:0] fpu_opa_data;
   logic [31:0] EX_fpu_result;
   logic [ 4:0] fpu_fflags;
   logic        fpu_busy, fpu_ack;

   // FCSR
   logic [11:0] csr_addr;
   logic [31:0] csr_wdata;
   logic [31:0] fw_fcsr;
   logic [ 2:0] frm;
   logic [31:0] EX_read_csr;
   logic [31:0] z_fcsr, nz_fcsr;

   assign csr_addr = EX_inst[31:20];

   logic        EX_fcsr_sel;
   logic [31:0] EX_fcsr;

   assign EX_fcsr_sel = (EX_inst[6:0] == 7'b1110011) ? 1'b1 : 1'b0;
   assign nz_fcsr     = {24'b0 , frm, fpu_fflags};

   // Branch Compare & Taken
   logic        br_less, br_equal;
   logic        br_taken;

   // Mid_EX_reg
   logic        midEX_mispred;
   logic [31:0] midEX_pc, midEX_pc_4;
   logic [31:0] midEX_inst;

   logic        midEX_inst_vld;
   logic        midEX_st_sel, midEX_mem_rden, midEX_mem_wren;
   logic [ 2:0] midEX_wb_sel;
   logic        midEX_int_rd_wren, midEX_fp_rd_wren, midEX_fcsr_wren;

   // EX_MEM_reg
   logic        MEM_mispred;
   logic [31:0] MEM_pc, MEM_pc_4;
   logic [31:0] MEM_inst;

   logic [31:0] MEM_alu_data, MEM_fpu_data;
   logic [31:0] MEM_read_csr, MEM_fcsr;

   logic [31:0] MEM_int_rs2_data, MEM_fp_rs2_data;

   logic        MEM_inst_vld;
   logic        MEM_st_sel, MEM_mem_rden, MEM_mem_wren;
   logic [ 2:0] MEM_wb_sel;
   logic        MEM_int_rd_wren, MEM_fp_rd_wren, MEM_fcsr_wren;

   // LSU
   logic [ 2:0] lsu_op;
   logic [31:0] lsu_st_data;
   logic [31:0] MEM_ld_data;
   logic        lsu_busy, lsu_ack;

   assign lsu_op = MEM_inst[14:12];   // funct3

   // mid_MEM_reg
   logic        lsu_start_en;

   logic        midMEM_mispred;
   logic [31:0] midMEM_pc, midMEM_pc_4;
   logic [31:0] midMEM_inst;

   logic [31:0] midMEM_alu_data, midMEM_fpu_data, midMEM_read_csr;
   logic [31:0] midMEM_fcsr;

   logic        midMEM_inst_vld;
   logic [ 2:0] midMEM_wb_sel;
   logic        midMEM_int_rd_wren, midMEM_fp_rd_wren, midMEM_fcsr_wren;

   assign lsu_start_en = MEM_mem_rden || MEM_mem_wren;

   // MEM_WB_reg
   logic        WB_mispred;
   logic [31:0] WB_pc, WB_pc_4;
   logic [31:0] WB_inst;

   logic [31:0] WB_alu_data, WB_ld_data, WB_fpu_data, WB_read_csr;
   logic [31:0] WB_fcsr;

   logic        WB_inst_vld;
   logic [ 2:0] WB_wb_sel;
   logic        WB_int_rd_wren, WB_fp_rd_wren, WB_fcsr_wren;

   // Write-back
   logic [ 4:0] rd_addr;
   logic [31:0] wb_data;

   // Hazard Detection
   logic        pc_hazard_en, IF_ID_hazard_stall, ID_EX_hazard_flush, ID_EX_flush;

   assign ID_EX_flush = ID_EX_hazard_flush | pred_flush;

   // Forwarding
   logic        fw_int_rs1_sel, fw_int_rs2_sel;
   logic        fw_fp_rs1_sel, fw_fp_rs2_sel, fw_fp_rs3_sel;
   logic [ 2:0] fw_int_opa_sel, fw_int_opb_sel;
   logic [ 1:0] fw_fp_opa_sel, fw_fp_opb_sel, fw_fp_opc_sel;
   logic        fw_fcsr_en, fw_fcsr_sel;

///////////////////////////////////////////////////////////////////////////////
// Submodule

//------------------------------------------------------------------- IF-stage

   assign IF_mispred = 1'b1;

   pc PC (
      .i_clk     (i_clk),
      .i_rst_n   (i_rst_n),
      .i_en_pc   (pc_hazard_en),
      .i_next_pc (next_pc),
      .o_pc      (IF_pc)
   );

   pc_plus_4 PC_plus_4 (
      .i_pc        (IF_pc),
      .o_pc_plus_4 (IF_pc_4)
   );

   br_pred_unit Br_Pred_Unit (
      .i_clk       (i_clk),
      .i_rst_n     (i_rst_n),

      .i_IF_pc     (IF_pc),
      .i_ID_pc     (ID_pc),
      .i_EX_pc     (EX_pc),
      .i_EX_pc_4   (EX_pc_4),

      .i_alu_data  (EX_alu_data),

      .i_IF_inst   (IF_inst),
      .i_EX_inst   (EX_inst),
      .i_brc_taken (br_taken),

      .o_flush     (pred_flush),
      .o_next_pc   (next_pc)
   );

   imem IMEM (
      .i_pc_addr (IF_pc),
      .o_inst    (IF_inst)
   );

//------------------------------------------------------------------- IF/ID

   IF_ID IF_ID_reg (
      .i_clk        (i_clk),
      .i_rst_n      (i_rst_n),

      .i_flush      (pred_flush),
      .i_stall      (IF_ID_hazard_stall),

      .i_IF_mispred (IF_mispred),
      .i_IF_pc_4    (IF_pc_4),
      .i_IF_pc      (IF_pc),
      .i_IF_inst    (IF_inst),

      .o_ID_mispred (ID_mispred),
      .o_ID_pc_4    (ID_pc_4),
      .o_ID_pc      (ID_pc),
      .o_ID_inst    (ID_inst)
   );

//------------------------------------------------------------------- ID-stage

   ctrl_unit Control_Unit (
      .i_inst          (ID_inst),

      .o_inst_vld      (ID_inst_vld),
      .o_br_un         (ID_br_un),
      .o_st_sel        (ID_st_sel),
      .o_mem_rden      (ID_mem_rden),
      .o_mem_wren      (ID_mem_wren),
      .o_wb_sel        (ID_wb_sel),

      .o_alu_opa_sel   (ID_alu_opa_sel),
      .o_alu_opb_sel   (ID_alu_opb_sel),
      .o_int_rd_wren   (ID_int_rd_wren),
      .o_alu_op        (ID_alu_op),

      .o_fpu_opa_sel   (ID_fpu_opa_sel),
      .o_fp_rd_wren    (ID_fp_rd_wren),
      .o_fpu_op        (ID_fpu_op),
      .o_start_fpu     (ID_start_fpu),

      .o_csr_op        (ID_csr_op),
      .o_csr_wdata_sel (ID_csr_wdata_sel),
      .o_fcsr_wren     (ID_fcsr_wren)
   );

   int_regfile Int_RegFile (
      .i_clk      (i_clk),
      .i_rst_n    (i_rst_n),

      .i_rs1_addr (int_rs1_addr),
      .i_rs2_addr (int_rs2_addr),

      .i_rd_wren  (WB_int_rd_wren),
      .i_rd_addr  (rd_addr),
      .i_rd_data  (wb_data),

      .o_rs1_data (int_rs1_data),
      .o_rs2_data (int_rs2_data)
   );

   mux_2_1 forward_int_rs1_mux (
      .i_sel  (fw_int_rs1_sel),
      .i_0    (int_rs1_data),
      .i_1    (wb_data),
      .o_data (ID_int_rs1_data)
   );

   mux_2_1 forward_int_rs2_mux (
      .i_sel  (fw_int_rs2_sel),
      .i_0    (int_rs2_data),
      .i_1    (wb_data),
      .o_data (ID_int_rs2_data)
   );

   fp_regfile FP_RegFile (
      .i_clk      (i_clk),
      .i_rst_n    (i_rst_n),

      .i_rs1_addr (fp_rs1_addr),
      .i_rs2_addr (fp_rs2_addr),
      .i_rs3_addr (fp_rs3_addr),

      .i_rd_wren  (WB_fp_rd_wren),
      .i_rd_addr  (rd_addr),
      .i_rd_data  (wb_data),

      .o_rs1_data (fp_rs1_data),
      .o_rs2_data (fp_rs2_data),
      .o_rs3_data (fp_rs3_data)
   );

   mux_2_1 forward_fp_rs1_mux (
      .i_sel  (fw_fp_rs1_sel),
      .i_0    (fp_rs1_data),
      .i_1    (wb_data),
      .o_data (ID_fp_rs1_data)
   );

   mux_2_1 forward_fp_rs2_mux (
      .i_sel  (fw_fp_rs2_sel),
      .i_0    (fp_rs2_data),
      .i_1    (wb_data),
      .o_data (ID_fp_rs2_data)
   );

   mux_2_1 forward_fp_rs3_mux (
      .i_sel  (fw_fp_rs3_sel),
      .i_0    (fp_rs3_data),
      .i_1    (wb_data),
      .o_data (ID_fp_rs3_data)
   );

   imm_gen Imm_Gen (
      .i_inst (ID_inst),
      .o_imm  (ID_imm_data)
   );

//------------------------------------------------------------------- ID/EX

   ID_EX ID_EX_reg (
      .i_clk              (i_clk),
      .i_rst_n            (i_rst_n),
      .i_flush            (ID_EX_flush),

      // IF-ID-EX
      .i_ID_pc_4          (ID_pc_4),
      .i_ID_pc            (ID_pc),
      .i_ID_inst          (ID_inst),
      .i_ID_mispred       (ID_mispred),

      .o_EX_pc_4          (EX_pc_4),
      .o_EX_pc            (EX_pc),
      .o_EX_inst          (EX_inst),
      .o_EX_mispred       (EX_mispred),

      // Immediate
      .i_ID_imm_data      (ID_imm_data),
      .o_EX_imm_data      (EX_imm_data),

      // Int_RegFile
      .i_ID_int_rs1_data  (ID_int_rs1_data),
      .i_ID_int_rs2_data  (ID_int_rs2_data),

      .o_EX_int_rs1_data  (EX_int_rs1_data),
      .o_EX_int_rs2_data  (EX_int_rs2_data),

      // FP_RegFile
      .i_ID_fp_rs1_data   (ID_fp_rs1_data),
      .i_ID_fp_rs2_data   (ID_fp_rs2_data),
      .i_ID_fp_rs3_data   (ID_fp_rs3_data),

      .o_EX_fp_rs1_data   (EX_fp_rs1_data),
      .o_EX_fp_rs2_data   (EX_fp_rs2_data),
      .o_EX_fp_rs3_data   (EX_fp_rs3_data),

      // Control
      .i_ID_inst_vld      (ID_inst_vld),
      .i_ID_br_un         (ID_br_un),
      .i_ID_st_sel        (ID_st_sel),
      .i_ID_mem_rden      (ID_mem_rden),
      .i_ID_mem_wren      (ID_mem_wren),
      .i_ID_wb_sel        (ID_wb_sel),
      .i_ID_alu_opa_sel   (ID_alu_opa_sel),
      .i_ID_alu_opb_sel   (ID_alu_opb_sel),
      .i_ID_int_rd_wren   (ID_int_rd_wren),
      .i_ID_alu_op        (ID_alu_op),
      .i_ID_fpu_opa_sel   (ID_fpu_opa_sel),
      .i_ID_fp_rd_wren    (ID_fp_rd_wren),
      .i_ID_fpu_op        (ID_fpu_op),
      .i_ID_start_fpu     (ID_start_fpu),
      .i_ID_csr_op        (ID_csr_op),
      .i_ID_csr_wdata_sel (ID_csr_wdata_sel),
      .i_ID_fcsr_wren     (ID_fcsr_wren),

      .o_EX_inst_vld      (EX_inst_vld),
      .o_EX_br_un         (EX_br_un),
      .o_EX_st_sel        (EX_st_sel),
      .o_EX_mem_rden      (EX_mem_rden),
      .o_EX_mem_wren      (EX_mem_wren),
      .o_EX_wb_sel        (EX_wb_sel),
      .o_EX_alu_opa_sel   (EX_alu_opa_sel),
      .o_EX_alu_opb_sel   (EX_alu_opb_sel),
      .o_EX_int_rd_wren   (EX_int_rd_wren),
      .o_EX_alu_op        (EX_alu_op),
      .o_EX_fpu_opa_sel   (EX_fpu_opa_sel),
      .o_EX_fp_rd_wren    (EX_fp_rd_wren),
      .o_EX_fpu_op        (EX_fpu_op),
      .o_EX_start_fpu     (EX_start_fpu),
      .o_EX_csr_op        (EX_csr_op),
      .o_EX_csr_wdata_sel (EX_csr_wdata_sel),
      .o_EX_fcsr_wren     (EX_fcsr_wren)
   );

//------------------------------------------------------------------- EX-stage

   mux_5_1 forward_int_a_mux (
      .i_sel  (fw_int_opa_sel),
      .i_0    (EX_int_rs1_data),
      .i_1    (MEM_alu_data),
      .i_2    (MEM_fpu_data),
      .i_3    (MEM_read_csr),
      .i_4    (wb_data),
      .o_data (forward_int_a_data)
   );

   mux_5_1 forward_int_b_mux (
      .i_sel  (fw_int_opb_sel),
      .i_0    (EX_int_rs2_data),
      .i_1    (MEM_alu_data),
      .i_2    (MEM_fpu_data),
      .i_3    (MEM_read_csr),
      .i_4    (wb_data),
      .o_data (forward_int_b_data)
   );

   mux_2_1 alu_op_a_mux (
      .i_sel  (EX_alu_opa_sel),
      .i_0    (forward_int_a_data),
      .i_1    (EX_pc),
      .o_data (alu_opa_data)
   );

   mux_2_1 alu_op_b_mux (
      .i_sel  (EX_alu_opb_sel),
      .i_0    (forward_int_b_data),
      .i_1    (EX_imm_data),
      .o_data (alu_opb_data)
   );

   alu ALU (
      .i_op_a     (alu_opa_data),
      .i_op_b     (alu_opb_data),
      .i_alu_op   (EX_alu_op),
      .o_alu_data (EX_alu_data)
   );

   brc Br_Comp_Unit (
      .i_br_un    (EX_br_un),
      .i_rs1_data (forward_int_a_data),
      .i_rs2_data (forward_int_b_data),
      .o_br_less  (br_less),
      .o_br_equal (br_equal)
   );

   br_taken_unit Br_Taken_Unit (
      .i_inst     (EX_inst),
      .i_br_less  (br_less),
      .i_br_equal (br_equal),
      .o_br_taken (br_taken)
   );

   mux_3_1 forward_fp_a_mux (
      .i_sel  (fw_fp_opa_sel),
      .i_0    (EX_fp_rs1_data),
      .i_1    (MEM_fpu_data),
      .i_2    (wb_data),
      .o_data (forward_fp_a_data)
   );

   mux_3_1 forward_fp_b_mux (
      .i_sel  (fw_fp_opb_sel),
      .i_0    (EX_fp_rs2_data),
      .i_1    (MEM_fpu_data),
      .i_2    (wb_data),
      .o_data (forward_fp_b_data)
   );

   mux_3_1 forward_fp_c_mux (
      .i_sel  (fw_fp_opc_sel),
      .i_0    (EX_fp_rs3_data),
      .i_1    (MEM_fpu_data),
      .i_2    (wb_data),
      .o_data (forward_fp_c_data)
   );

   mux_2_1 fpu_op_a_mux (
      .i_sel  (EX_fpu_opa_sel),
      .i_0    (forward_fp_a_data),
      .i_1    (forward_int_a_data),
      .o_data (fpu_opa_data)
   );

   fpu FPU (
      .i_clk      (i_clk),
      .i_rst_n    (i_rst_n),

      .i_start_en (EX_start_fpu),   // start multi-cycle   
      .i_fpu_op   (EX_fpu_op),
      .i_frm      (frm),
      .i_op_a     (fpu_opa_data),
      .i_op_b     (forward_fp_b_data),
      .i_op_c     (forward_fp_c_data),

      .o_busy     (fpu_busy),   // multi-cycle only
      .o_ack      (fpu_ack),   // multi-cycle only
      .o_result   (EX_fpu_result),
      .o_fflags   (fpu_fflags)
   );

   mux_2_1 csr_wdata_mux (
      .i_sel  (EX_csr_wdata_sel),
      .i_0    (forward_int_a_data),
      .i_1    (EX_imm_data),
      .o_data (csr_wdata)
   );

   mux_2_1 forward_fcsr_mux (
      .i_sel  (fw_fcsr_sel),
      .i_0    (MEM_fcsr),
      .i_1    (WB_fcsr),
      .o_data (fw_fcsr)
   );

   fp_csr FCSR (
      .i_clk       (i_clk),
      .i_rst_n     (i_rst_n),

      // CSR operation (ID)
      .i_csr_op    (EX_csr_op),
      .i_csr_addr  (csr_addr),
      .i_csr_wdata (csr_wdata),

      // Forwarding
      .i_fw_en     (fw_fcsr_en),
      .i_fw_fcsr   (fw_fcsr),

      // Write-back
      .i_wb_wren   (WB_fcsr_wren),
      .i_wb_fcsr   (WB_fcsr),

      // Output
      .o_frm       (frm),
      .o_read_csr  (EX_read_csr),
      .o_fcsr      (z_fcsr)
   );

   mux_2_1 EX_fcsr_mux (
      .i_sel  (EX_fcsr_sel),
      .i_0    (nz_fcsr),
      .i_1    (z_fcsr),
      .o_data (EX_fcsr)
   );

//------------------------------------------------------------------- mid-EX

   mid_EX mid_EX_reg (
      .i_clk         (i_clk),
      .i_rst_n       (i_rst_n),

      // Write enable
      .i_fpu_start   (EX_start_fpu),

      // IF-ID-EX
      .i_pc_4        (EX_pc_4),
      .i_pc          (EX_pc),
      .i_inst        (EX_inst),
      .i_mispred     (EX_mispred),

      .o_pc_4        (midEX_pc_4),
      .o_pc          (midEX_pc),
      .o_inst        (midEX_inst),
      .o_mispred     (midEX_mispred),

      // Control
      .i_inst_vld    (EX_inst_vld),
      .i_st_sel      (EX_st_sel),
      .i_mem_rden    (EX_mem_rden),
      .i_mem_wren    (EX_mem_wren),
      .i_wb_sel      (EX_wb_sel),
      .i_int_rd_wren (EX_int_rd_wren),
      .i_fp_rd_wren  (EX_fp_rd_wren),
      .i_fcsr_wren   (EX_fcsr_wren),

      .o_inst_vld    (midEX_inst_vld),
      .o_st_sel      (midEX_st_sel),
      .o_mem_rden    (midEX_mem_rden),
      .o_mem_wren    (midEX_mem_wren),
      .o_wb_sel      (midEX_wb_sel),
      .o_int_rd_wren (midEX_int_rd_wren),
      .o_fp_rd_wren  (midEX_fp_rd_wren),
      .o_fcsr_wren   (midEX_fcsr_wren)
   );

//------------------------------------------------------------------- EX/MEM

   EX_MEM EX_MEM_reg (
      .i_clk              (i_clk),
      .i_rst_n            (i_rst_n),

      // IF-ID-EX-MEM
      .i_EX_pc_4          (EX_pc_4),   // wb
      .i_EX_pc            (EX_pc),   // debug
      .i_EX_inst          (EX_inst),   // funct3, rd_addr
      .i_EX_mispred       (EX_mispred),

      .o_MEM_pc_4         (MEM_pc_4),
      .o_MEM_pc           (MEM_pc),
      .o_MEM_inst         (MEM_inst),
      .o_MEM_mispred      (MEM_mispred),

      // ALU
      .i_EX_alu_data      (EX_alu_data),   // LSU address
      .o_MEM_alu_data     (MEM_alu_data),

      // FPU
      .i_EX_fpu_data      (EX_fpu_result),
      .o_MEM_fpu_data     (MEM_fpu_data),

      // FCSR
      .i_EX_read_csr      (EX_read_csr),   // wb to rd
      .i_EX_fcsr          (EX_fcsr),   // wb to fcsr

      .o_MEM_read_csr     (MEM_read_csr),
      .o_MEM_fcsr         (MEM_fcsr),

      // LSU
      .i_EX_int_rs2_data  (forward_int_b_data),   // LSU store data
      .i_EX_fp_rs2_data   (forward_fp_b_data),   // LSU store data

      .o_MEM_int_rs2_data (MEM_int_rs2_data),   
      .o_MEM_fp_rs2_data  (MEM_fp_rs2_data),

      // Control
      .i_EX_inst_vld      (EX_inst_vld),
      .i_EX_st_sel        (EX_st_sel),
      .i_EX_mem_rden      (EX_mem_rden),
      .i_EX_mem_wren      (EX_mem_wren),
      .i_EX_wb_sel        (EX_wb_sel),
      .i_EX_int_rd_wren   (EX_int_rd_wren),
      .i_EX_fp_rd_wren    (EX_fp_rd_wren),
      .i_EX_fcsr_wren     (EX_fcsr_wren),

      .o_MEM_inst_vld     (MEM_inst_vld),
      .o_MEM_st_sel       (MEM_st_sel),
      .o_MEM_mem_rden     (MEM_mem_rden),
      .o_MEM_mem_wren     (MEM_mem_wren),
      .o_MEM_wb_sel       (MEM_wb_sel),
      .o_MEM_int_rd_wren  (MEM_int_rd_wren),
      .o_MEM_fp_rd_wren   (MEM_fp_rd_wren),
      .o_MEM_fcsr_wren    (MEM_fcsr_wren),

      // Multi-cycle processing
      .i_fpu_ack           (fpu_ack),

      .i_midEX_pc_4        (midEX_pc_4),
      .i_midEX_pc          (midEX_pc),
      .i_midEX_inst        (midEX_inst),
      .i_midEX_mispred     (midEX_mispred),

      .i_midEX_inst_vld    (midEX_inst_vld),
      .i_midEX_st_sel      (midEX_st_sel),
      .i_midEX_mem_rden    (midEX_mem_rden),
      .i_midEX_mem_wren    (midEX_mem_wren),
      .i_midEX_wb_sel      (midEX_wb_sel),
      .i_midEX_int_rd_wren (midEX_int_rd_wren),
      .i_midEX_fp_rd_wren  (midEX_fp_rd_wren),
      .i_midEX_fcsr_wren   (midEX_fcsr_wren)
   );

//------------------------------------------------------------------- MEM-stage

   mux_2_1 st_data_mux (
      .i_sel  (MEM_st_sel),
      .i_0    (MEM_int_rs2_data),
      .i_1    (MEM_fp_rs2_data),
      .o_data (lsu_st_data)
   );

   lsu LSU (
      .i_clk      (i_clk),
      .i_rst_n    (i_rst_n),

      .i_lsu_rden (MEM_mem_rden),
      .i_lsu_wren (MEM_mem_wren),
      .i_lsu_op   (lsu_op),
      .i_lsu_addr (MEM_alu_data),
      .i_st_data  (lsu_st_data),

      .i_io_sw    (i_io_sw),
      .i_io_btn   (i_io_btn),

      .o_lsu_busy (lsu_busy),
      .o_lsu_ack  (lsu_ack),
      .o_ld_data  (MEM_ld_data),

      .o_io_ledr  (o_io_ledr),
      .o_io_ledg  (o_io_ledg),
      .o_io_hex0  (o_io_hex0),
      .o_io_hex1  (o_io_hex1),
      .o_io_hex2  (o_io_hex2),
      .o_io_hex3  (o_io_hex3),
      .o_io_hex4  (o_io_hex4),
      .o_io_hex5  (o_io_hex5),
      .o_io_hex6  (o_io_hex6),
      .o_io_hex7  (o_io_hex7),
      .o_io_lcd   (o_io_lcd)
   );

//------------------------------------------------------------------- mid-MEM

   mid_MEM mid_MEM_reg (
      .i_clk         (i_clk),
      .i_rst_n       (i_rst_n),

      // Write enable
      .i_lsu_start   (lsu_start_en),

      // IF-ID-EX-MEM
      .i_pc          (MEM_pc),
      .i_inst        (MEM_inst),
      .i_mispred     (MEM_mispred),

      .o_pc          (midMEM_pc),
      .o_inst        (midMEM_inst),
      .o_mispred     (midMEM_mispred),

      // Mux WB (except lsu_ld_data)
      .i_pc_4        (MEM_pc_4),
      .i_alu_data    (MEM_alu_data),
      .i_fpu_data    (MEM_fpu_data),
      .i_read_csr    (MEM_read_csr),

      .o_pc_4        (midMEM_pc_4),
      .o_alu_data    (midMEM_alu_data),
      .o_fpu_data    (midMEM_fpu_data),
      .o_read_csr    (midMEM_read_csr),

      // FCSR
      .i_fcsr        (MEM_fcsr),
      .o_fcsr        (midMEM_fcsr),

      // Control
      .i_inst_vld    (MEM_inst_vld),
      .i_wb_sel      (MEM_wb_sel),
      .i_int_rd_wren (MEM_int_rd_wren),
      .i_fp_rd_wren  (MEM_fp_rd_wren),
      .i_fcsr_wren   (MEM_fcsr_wren),

      .o_inst_vld    (midMEM_inst_vld),
      .o_wb_sel      (midMEM_wb_sel),
      .o_int_rd_wren (midMEM_int_rd_wren),
      .o_fp_rd_wren  (midMEM_fp_rd_wren),
      .o_fcsr_wren   (midMEM_fcsr_wren)
   );

//------------------------------------------------------------------- MEM/WB

   MEM_WB MEM_WB_reg (
      .i_clk                (i_clk),
      .i_rst_n              (i_rst_n),

      // IF-ID-EX-MEM-WB
      .i_MEM_pc             (MEM_pc),   // debug
      .i_MEM_inst           (MEM_inst),   // funct3, rd_addr
      .i_MEM_mispred        (MEM_mispred),

      .o_WB_pc              (WB_pc),
      .o_WB_inst            (WB_inst),
      .o_WB_mispred         (WB_mispred),

      // Mux WB
      .i_MEM_pc_4           (MEM_pc_4),
      .i_MEM_alu_data       (MEM_alu_data),
      .i_MEM_ld_data        (MEM_ld_data),
      .i_MEM_fpu_data       (MEM_fpu_data),
      .i_MEM_read_csr       (MEM_read_csr),

      .o_WB_pc_4            (WB_pc_4),
      .o_WB_alu_data        (WB_alu_data),
      .o_WB_ld_data         (WB_ld_data),
      .o_WB_fpu_data        (WB_fpu_data),
      .o_WB_read_csr        (WB_read_csr),

      // FCSR
      .i_MEM_fcsr           (MEM_fcsr),
      .o_WB_fcsr            (WB_fcsr),

      // Control
      .i_MEM_inst_vld       (MEM_inst_vld),
      .i_MEM_wb_sel         (MEM_wb_sel),
      .i_MEM_int_rd_wren    (MEM_int_rd_wren),
      .i_MEM_fp_rd_wren     (MEM_fp_rd_wren),
      .i_MEM_fcsr_wren      (MEM_fcsr_wren),

      .o_WB_inst_vld        (WB_inst_vld),
      .o_WB_wb_sel          (WB_wb_sel),
      .o_WB_int_rd_wren     (WB_int_rd_wren),
      .o_WB_fp_rd_wren      (WB_fp_rd_wren),
      .o_WB_fcsr_wren       (WB_fcsr_wren),

      // Multi-cycle processing
      .i_lsu_ack            (lsu_ack),

      .i_midMEM_pc          (midMEM_pc),
      .i_midMEM_inst        (midMEM_inst),
      .i_midMEM_mispred     (midMEM_mispred),

      .i_midMEM_pc_4        (midMEM_pc_4),
      .i_midMEM_alu_data    (midMEM_alu_data),
      .i_midMEM_fpu_data    (midMEM_fpu_data),
      .i_midMEM_read_csr    (midMEM_read_csr),

      .i_midMEM_fcsr        (midMEM_fcsr),

      .i_midMEM_inst_vld    (midMEM_inst_vld),
      .i_midMEM_wb_sel      (midMEM_wb_sel),
      .i_midMEM_int_rd_wren (midMEM_int_rd_wren),
      .i_midMEM_fp_rd_wren  (midMEM_fp_rd_wren),
      .i_midMEM_fcsr_wren   (midMEM_fcsr_wren)
   );

//------------------------------------------------------------------- WB-stage

   mux_5_1 wb_data_mux (
      .i_sel  (WB_wb_sel),
      .i_0    (WB_pc_4),
      .i_1    (WB_alu_data),
      .i_2    (WB_ld_data),
      .i_3    (WB_fpu_data),
      .i_4    (WB_read_csr),
      .o_data (wb_data)
   );

   assign rd_addr = WB_inst[11:7];

//------------------------------------------------------------------- Hazard Detection

   hazard_detect Hazard_Detection_Unit (
      //.i_ID_inst        (ID_inst),
      .i_EX_inst        (EX_inst),

      .i_fpu_busy       (fpu_busy),
      .i_fpu_ack        (fpu_ack),

      .i_lsu_busy       (lsu_busy),
      .i_lsu_ack        (lsu_ack),

      .o_pc_en          (pc_hazard_en),
      .o_IF_ID_stall    (IF_ID_hazard_stall),
      .o_ID_EX_flush    (ID_EX_hazard_flush)
   );

//------------------------------------------------------------------- Forwardation

   forwarding_unit Forwarding_Unit (
      .i_ID_inst         (ID_inst),
      .i_EX_inst         (EX_inst),

      .i_MEM_inst        (MEM_inst),
      .i_MEM_int_rd_wren (MEM_int_rd_wren),
      .i_MEM_fp_rd_wren  (MEM_fp_rd_wren),
      .i_MEM_fcsr_wren   (MEM_fcsr_wren),

      .i_WB_inst         (WB_inst),
      .i_WB_int_rd_wren  (WB_int_rd_wren),
      .i_WB_fp_rd_wren   (WB_fp_rd_wren),
      .i_WB_fcsr_wren    (WB_fcsr_wren),

      .o_fw_int_rs1_sel  (fw_int_rs1_sel),
      .o_fw_int_rs2_sel  (fw_int_rs2_sel),

      .o_fw_fp_rs1_sel   (fw_fp_rs1_sel),
      .o_fw_fp_rs2_sel   (fw_fp_rs2_sel),
      .o_fw_fp_rs3_sel   (fw_fp_rs3_sel),

      .o_fw_int_opa_sel  (fw_int_opa_sel),
      .o_fw_int_opb_sel  (fw_int_opb_sel),

      .o_fw_fp_opa_sel   (fw_fp_opa_sel),
      .o_fw_fp_opb_sel   (fw_fp_opb_sel),
      .o_fw_fp_opc_sel   (fw_fp_opc_sel),

      .o_fw_fcsr_en      (fw_fcsr_en),
      .o_fw_fcsr_sel     (fw_fcsr_sel)
   );

///////////////////////////////////////////////////////////////////////////////
// Debug

   always_ff @(posedge i_clk) begin
      if (!i_rst_n) begin
         o_inst_vld <= 1'b0;
      end else begin
         o_inst_vld <= WB_inst_vld;
      end

      o_pc_debug <= WB_pc;
      o_mispred  <= WB_mispred;
   end

endmodule