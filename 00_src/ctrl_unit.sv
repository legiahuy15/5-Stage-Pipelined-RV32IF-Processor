module ctrl_unit (
   // Input
   input  logic [31:0] i_inst         ,
   // Outputs
   output logic        o_inst_vld     ,
   output logic        o_br_un        ,
   output logic        o_st_sel       ,   // select data (int/fp) to store in LSU
   output logic        o_mem_rden     ,   // LSU read enable
   output logic        o_mem_wren     ,   // LSU write enable
   output logic [ 2:0] o_wb_sel       ,
   // Integer control
   output logic        o_alu_opa_sel  ,
   output logic        o_alu_opb_sel  ,
   output logic        o_int_rd_wren  ,
   output logic [ 3:0] o_alu_op       ,
   // Floating-point control
   output logic        o_fpu_opa_sel  ,
   output logic        o_fp_rd_wren   ,
   output logic [ 4:0] o_fpu_op       ,
   output logic        o_start_fpu    ,
   // FP_CSR control
   output logic [ 1:0] o_csr_op       ,
   output logic        o_csr_wdata_sel,
   output logic        o_fcsr_wren
);

///////////////////////////////////////////////////////////////////////////////
// Definition

   // opcode
   localparam [4:0]
      // Integer
      R_TYPE = 5'b01100,
      I_TYPE = 5'b00100,
      I_LOAD = 5'b00000,
      S_TYPE = 5'b01000,
      B_TYPE = 5'b11000,
      JAL    = 5'b11011,
      JALR   = 5'b11001,
      AUIPC  = 5'b00101,
      LUI    = 5'b01101,
      // Floating-point
      F_TYPE = 5'b10100,
      FLW    = 5'b00001,
      FSW    = 5'b01001,
      FMADD  = 5'b10000,
      FMSUB  = 5'b10001,
      FNMSUB = 5'b10010,
      FNMADD = 5'b10011,
      // Zicsr
      Z_TYPE = 5'b11100;

   // alu_op
   localparam [3:0]
      OP_ADD  = 4'b0000,
      OP_SUB  = 4'b0001,
      OP_SLL  = 4'b0010,
      OP_SLT  = 4'b0011,
      OP_SLTU = 4'b0100,
      OP_XOR  = 4'b0101,
      OP_SRL  = 4'b0110,
      OP_SRA  = 4'b0111,
      OP_OR   = 4'b1000,
      OP_AND  = 4'b1001,
      OP_OPB  = 4'b1010;

   // fpu_op
   localparam [4:0]
      OP_FADD   = 5'd0 ,   OP_FSUB   = 5'd1 ,
      OP_FMUL   = 5'd2 ,   OP_FDIV   = 5'd3 ,
      OP_FSQRT  = 5'd4 ,
      OP_MADD   = 5'd5 ,   OP_MSUB   = 5'd6 ,   OP_NMSUB = 5'd7 ,   OP_NMADD = 5'd8,
      OP_SGNJ   = 5'd9 ,   OP_SGNJN  = 5'd10,   OP_SGNJX = 5'd11,
      OP_CVTWS  = 5'd12,   OP_CVTWUS = 5'd13,
      OP_CVTSW  = 5'd14,   OP_CVTSWU = 5'd15,
      OP_MVXW   = 5'd16,   OP_MVWX   = 5'd17,
      OP_FEQ    = 5'd18,   OP_FLT    = 5'd19,   OP_FLE   = 5'd20,
      OP_FCLASS = 5'd21,
      OP_FMIN   = 5'd22,   OP_FMAX   = 5'd23;

   // csr_op
   localparam [1:0]
      OP_NOP = 2'b00,
      OP_RW  = 2'b01,
      OP_RS  = 2'b10,
      OP_RC  = 2'b11;

   // funct3 alu
   localparam [2:0]
      ADD  = 3'b000,   // = SUB, different funct7: i_inst[30]
      SLL  = 3'b001,
      SLT  = 3'b010,
      SLTU = 3'b011,
      XOR  = 3'b100,
      SRL  = 3'b101,   // = SRA, different funct7: i_inst[30]
      OR   = 3'b110,
      AND  = 3'b111;

   // funct3 branch
   localparam [2:0]
      BEQ  = 3'b000,
      BNE  = 3'b001,
      BLT  = 3'b100,
      BGE  = 3'b101,
      BLTU = 3'b110,
      BGEU = 3'b111;

   // funct3 store
   localparam [2:0]
      SB = 3'b000,
      SH = 3'b001,
      SW	= 3'b010;

   // funct3 load      
   localparam [2:0]
      LB  = 3'b000,
      LH  = 3'b001,
      LW  = 3'b010,
      LBU = 3'b100,
      LHU = 3'b101;

   // funct5 fpu
   localparam [4:0]
      FADD   = 5'b00000,
      FSUB   = 5'b00001,
      FMUL   = 5'b00010,
      FDIV   = 5'b00011,
      FSQRT  = 5'b01011,
      FSGNJ  = 5'b00100,   // different i_inst[14:12]
      FMIN   = 5'b00101,   // = FMAX, different i_inst[14:12]
      FCVTWS = 5'b11000,   // different i_inst[20]
      FMVXS  = 5'b11100,   // = FCLASS, different i_inst[14:12]
      FCOMP  = 5'b10100,   // different i_inst[14:12]
      FCVTSW = 5'b11010,   // different i_inst[20]
      FMVSX  = 5'b11110;

   // funct3 zicsr
   localparam [2:0]
      CSRRW  = 3'b001,
      CSRRS  = 3'b010,
      CSRRC  = 3'b011,
      CSRRWI = 3'b101,
      CSRRSI = 3'b110,
      CSRRCI = 3'b111;

   // alu_opa_sel
   localparam sel_rs1 = 1'b0;
   localparam sel_pc  = 1'b1;

   // alu_opb_sel
   localparam sel_rs2 = 1'b0;
   localparam sel_imm = 1'b1;

   // fpu_opa_sel
   localparam sel_fp_rs1  = 1'b0;
   localparam sel_int_rs1 = 1'b1;

   // st_data_sel
   localparam st_int = 1'b0;
   localparam st_fp  = 1'b1;

   // wb_data_sel
   localparam [2:0]
      wb_pc_4     = 3'b000,
      wb_alu_data = 3'b001,
      wb_lsu_data = 3'b010,
      wb_fpu_data = 3'b011,
      wb_read_csr = 3'b100;

///////////////////////////////////////////////////////////////////////////////
// Control logic

   always_comb begin
      case(i_inst[6:2])   // opcode
//-------------------------------------------------------------------
         R_TYPE: begin
            o_inst_vld    = 1'b1;
            o_br_un       = 1'b1;
            o_st_sel      = st_int;
            o_mem_rden    = 1'b0;
            o_mem_wren    = 1'b0;
            o_wb_sel      = wb_alu_data;

            o_alu_opa_sel = sel_rs1;
            o_alu_opb_sel = sel_rs2;
            o_int_rd_wren = 1'b1;

            case(i_inst[14:12])   // funct3
               ADD : o_alu_op = (i_inst[30]) ? OP_SUB : OP_ADD; 
               SLL : o_alu_op = OP_SLL;
               SLT : o_alu_op = OP_SLT;
               SLTU: o_alu_op = OP_SLTU;
               XOR : o_alu_op = OP_XOR;
               SRL : o_alu_op = (i_inst[30]) ? OP_SRA : OP_SRL;
               OR  : o_alu_op = OP_OR;
               AND : o_alu_op = OP_AND;
            endcase

            o_fpu_opa_sel   = sel_fp_rs1;
            o_fp_rd_wren    = 1'b0;
            o_fpu_op        = OP_FADD;
            o_start_fpu     = 1'b0;

            o_csr_op        = OP_NOP;
            o_csr_wdata_sel = 1'b0;
            o_fcsr_wren     = 1'b0;
         end
//-------------------------------------------------------------------
         I_TYPE: begin
            o_inst_vld    = 1'b1;
            o_br_un       = 1'b1;
            o_st_sel      = st_int;
            o_mem_rden    = 1'b0;
            o_mem_wren    = 1'b0;
            o_wb_sel      = wb_alu_data;

            o_alu_opa_sel = sel_rs1;
            o_alu_opb_sel = sel_imm;
            o_int_rd_wren = 1'b1;

            case(i_inst[14:12])   // funct3
               ADD : o_alu_op = OP_ADD; 
               SLL : o_alu_op = OP_SLL;
               SLT : o_alu_op = OP_SLT;
               SLTU: o_alu_op = OP_SLTU;
               XOR : o_alu_op = OP_XOR;
               SRL : o_alu_op = (i_inst[30]) ? OP_SRA : OP_SRL;
               OR  : o_alu_op = OP_OR;
               AND : o_alu_op = OP_AND;
            endcase

            o_fpu_opa_sel   = sel_fp_rs1;
            o_fp_rd_wren    = 1'b0;
            o_fpu_op        = OP_FADD;
            o_start_fpu     = 1'b0;

            o_csr_op        = OP_NOP;
            o_csr_wdata_sel = 1'b0;
            o_fcsr_wren     = 1'b0;
         end
//-------------------------------------------------------------------
         I_LOAD: begin
            o_inst_vld      = ((i_inst[14:12] == LB)||(i_inst[14:12] == LH)||(i_inst[14:12] == LW)||(i_inst[14:12] == LBU)||(i_inst[14:12] == LHU)) ? 1'b1 : 1'b0;
            o_br_un         = 1'b1;
            o_st_sel        = st_int;
            o_mem_rden      = (i_inst[1:0] == 2'b11) ? 1'b1 : 1'b0;   // fix bug i_inst = 32'h0
            o_mem_wren      = 1'b0;
            o_wb_sel        = wb_lsu_data;

            o_alu_opa_sel   = sel_rs1;
            o_alu_opb_sel   = sel_imm;
            o_int_rd_wren   = 1'b1;
            o_alu_op        = OP_ADD;

            o_fpu_opa_sel   = sel_fp_rs1;
            o_fp_rd_wren    = 1'b0;
            o_fpu_op        = OP_FADD;
            o_start_fpu     = 1'b0;

            o_csr_op        = OP_NOP;
            o_csr_wdata_sel = 1'b0;
            o_fcsr_wren     = 1'b0;
         end
//-------------------------------------------------------------------
         S_TYPE: begin
            o_inst_vld      = ((i_inst[14:12] == SB)||(i_inst[14:12] == SH)||(i_inst[14:12] == SW)) ? 1'b1 : 1'b0;
            o_br_un         = 1'b1;
            o_st_sel        = st_int;
            o_mem_rden      = 1'b0;
            o_mem_wren      = 1'b1;
            o_wb_sel        = wb_lsu_data;

            o_alu_opa_sel   = sel_rs1;
            o_alu_opb_sel   = sel_imm;
            o_int_rd_wren   = 1'b0;
            o_alu_op        = OP_ADD;

            o_fpu_opa_sel   = sel_fp_rs1;
            o_fp_rd_wren    = 1'b0;
            o_fpu_op        = OP_FADD;
            o_start_fpu     = 1'b0;

            o_csr_op        = OP_NOP;
            o_csr_wdata_sel = 1'b0;
            o_fcsr_wren     = 1'b0;
         end
//-------------------------------------------------------------------
         B_TYPE: begin
            o_st_sel        = st_int;
            o_mem_rden      = 1'b0;
            o_mem_wren      = 1'b0;
            o_wb_sel        = wb_alu_data;

            o_alu_opa_sel   = sel_pc;
            o_alu_opb_sel   = sel_imm;
            o_int_rd_wren   = 1'b0;
            o_alu_op        = OP_ADD;

            o_fpu_opa_sel   = sel_fp_rs1;
            o_fp_rd_wren    = 1'b0;
            o_fpu_op        = OP_FADD;
            o_start_fpu     = 1'b0;

            o_csr_op        = OP_NOP;
            o_csr_wdata_sel = 1'b0;
            o_fcsr_wren     = 1'b0;

            case(i_inst[14:12])   // funct3
               BEQ: begin
                  o_inst_vld = 1'b1;
                  o_br_un    = 1'b0;
               end
               
               BNE: begin
                  o_inst_vld = 1'b1;
                  o_br_un    = 1'b0;
               end
               
               BLT: begin
                  o_inst_vld = 1'b1;
                  o_br_un    = 1'b0;
               end
               
               BGE: begin
                  o_inst_vld = 1'b1;
                  o_br_un    = 1'b0;
               end
               
               BLTU: begin
                  o_inst_vld = 1'b1;
                  o_br_un    = 1'b1;
               end
               
               BGEU: begin
                  o_inst_vld = 1'b1;
                  o_br_un    = 1'b1;
               end
               
               default: begin
                  o_inst_vld = 1'b0;
                  o_br_un    = 1'b1;
               end
            endcase
         end
//-------------------------------------------------------------------
         JAL: begin
            o_inst_vld      = 1'b1;
            o_br_un         = 1'b1;
            o_st_sel        = st_int;
            o_mem_rden      = 1'b0;
            o_mem_wren      = 1'b0;
            o_wb_sel        = wb_pc_4;

            o_alu_opa_sel   = sel_pc;
            o_alu_opb_sel   = sel_imm;
            o_int_rd_wren   = 1'b1;
            o_alu_op        = OP_ADD;

            o_fpu_opa_sel   = sel_fp_rs1;
            o_fp_rd_wren    = 1'b0;
            o_fpu_op        = OP_FADD;
            o_start_fpu     = 1'b0;

            o_csr_op        = OP_NOP;
            o_csr_wdata_sel = 1'b0;
            o_fcsr_wren     = 1'b0;
         end
//-------------------------------------------------------------------
         JALR: begin
            o_inst_vld      = 1'b1;
            o_br_un         = 1'b1;
            o_st_sel        = st_int;
            o_mem_rden      = 1'b0;
            o_mem_wren      = 1'b0;
            o_wb_sel        = wb_pc_4;

            o_alu_opa_sel   = sel_rs1;
            o_alu_opb_sel   = sel_imm;
            o_int_rd_wren   = 1'b1;
            o_alu_op        = OP_ADD;

            o_fpu_opa_sel   = sel_fp_rs1;
            o_fp_rd_wren    = 1'b0;
            o_fpu_op        = OP_FADD;
            o_start_fpu     = 1'b0;

            o_csr_op        = OP_NOP;
            o_csr_wdata_sel = 1'b0;
            o_fcsr_wren     = 1'b0;
         end
//-------------------------------------------------------------------
         AUIPC: begin
            o_inst_vld      = 1'b1;
            o_br_un         = 1'b1;
            o_st_sel        = st_int;
            o_mem_rden      = 1'b0;
            o_mem_wren      = 1'b0;
            o_wb_sel        = wb_alu_data;

            o_alu_opa_sel   = sel_pc;
            o_alu_opb_sel   = sel_imm;
            o_int_rd_wren   = 1'b1;
            o_alu_op        = OP_ADD;

            o_fpu_opa_sel   = sel_fp_rs1;
            o_fp_rd_wren    = 1'b0;
            o_fpu_op        = OP_FADD;
            o_start_fpu     = 1'b0;

            o_csr_op        = OP_NOP;
            o_csr_wdata_sel = 1'b0;
            o_fcsr_wren     = 1'b0;
         end
//-------------------------------------------------------------------
         LUI: begin
            o_inst_vld      = 1'b1;
            o_br_un         = 1'b1;
            o_st_sel        = st_int;
            o_mem_rden      = 1'b0;
            o_mem_wren      = 1'b0;
            o_wb_sel        = wb_alu_data;

            o_alu_opa_sel   = sel_rs1;
            o_alu_opb_sel   = sel_imm;
            o_int_rd_wren   = 1'b1;
            o_alu_op        = OP_OPB;

            o_fpu_opa_sel   = sel_fp_rs1;
            o_fp_rd_wren    = 1'b0;
            o_fpu_op        = OP_FADD;
            o_start_fpu     = 1'b0;

            o_csr_op        = OP_NOP;
            o_csr_wdata_sel = 1'b0;
            o_fcsr_wren     = 1'b0;
         end
//-------------------------------------------------------------------
         F_TYPE: begin
            o_br_un         = 1'b1;
            o_st_sel        = st_fp;
            o_mem_rden      = 1'b0;
            o_mem_wren      = 1'b0;
            o_wb_sel        = wb_fpu_data;

            o_alu_opa_sel   = sel_rs1;
            o_alu_opb_sel   = sel_rs2;
            o_alu_op        = OP_ADD;

            o_csr_op        = OP_NOP;
            o_csr_wdata_sel = 1'b0;

            case(i_inst[31:27])   // funct5
               FADD: begin
                  o_inst_vld    = 1'b1;
                  o_int_rd_wren = 1'b0;
                  o_fp_rd_wren  = 1'b1;
                  o_fpu_opa_sel = sel_fp_rs1;
                  o_fpu_op      = OP_FADD;
                  o_start_fpu   = 1'b0;
                  o_fcsr_wren   = 1'b1;
               end

               FSUB: begin
                  o_inst_vld    = 1'b1;
                  o_int_rd_wren = 1'b0;
                  o_fp_rd_wren  = 1'b1;
                  o_fpu_opa_sel = sel_fp_rs1;
                  o_fpu_op      = OP_FSUB;
                  o_start_fpu   = 1'b0;
                  o_fcsr_wren   = 1'b1;
               end

               FMUL: begin
                  o_inst_vld    = 1'b1;
                  o_int_rd_wren = 1'b0;
                  o_fp_rd_wren  = 1'b1;
                  o_fpu_opa_sel = sel_fp_rs1;
                  o_fpu_op      = OP_FMUL;
                  o_start_fpu   = 1'b0;
                  o_fcsr_wren   = 1'b1;
               end

               FDIV: begin
                  o_inst_vld    = 1'b1;
                  o_int_rd_wren = 1'b0;
                  o_fp_rd_wren  = 1'b1;
                  o_fpu_opa_sel = sel_fp_rs1;
                  o_fpu_op      = OP_FDIV;
                  o_start_fpu   = 1'b1;
                  o_fcsr_wren   = 1'b1;
               end

               FSQRT: begin
                  o_inst_vld    = 1'b1;
                  o_int_rd_wren = 1'b0;
                  o_fp_rd_wren  = 1'b1;
                  o_fpu_opa_sel = sel_fp_rs1;
                  o_fpu_op      = OP_FSQRT;
                  o_start_fpu   = 1'b1;
                  o_fcsr_wren   = 1'b1;
               end

               FSGNJ: begin
                  o_int_rd_wren = 1'b0;
                  o_fpu_opa_sel = sel_fp_rs1;
                  o_start_fpu   = 1'b0;

                  case(i_inst[14:12])
                     3'b000: begin
                        o_inst_vld   = 1'b1;
                        o_fpu_op     = OP_SGNJ;
                        o_fp_rd_wren = 1'b1;
                        o_fcsr_wren  = 1'b1;
                     end
                     3'b001: begin
                        o_inst_vld   = 1'b1;
                        o_fpu_op     = OP_SGNJN;
                        o_fp_rd_wren = 1'b1;
                        o_fcsr_wren  = 1'b1;
                     end
                     3'b010: begin
                        o_inst_vld   = 1'b1;
                        o_fpu_op     = OP_SGNJX;
                        o_fp_rd_wren = 1'b1;
                        o_fcsr_wren  = 1'b1;
                     end
                     default: begin
                        o_inst_vld   = 1'b0;
                        o_fpu_op     = OP_FADD;
                        o_fp_rd_wren = 1'b0;
                        o_fcsr_wren  = 1'b0;
                     end
                  endcase
               end

               FMIN: begin
                  o_int_rd_wren = 1'b0;
                  o_fpu_opa_sel = sel_fp_rs1;
                  o_start_fpu   = 1'b0;

                  case(i_inst[14:12])
                     3'b000: begin
                        o_inst_vld   = 1'b1;
                        o_fpu_op     = OP_FMIN;
                        o_fp_rd_wren = 1'b1;
                        o_fcsr_wren  = 1'b1;
                     end
                     3'b001: begin
                        o_inst_vld   = 1'b1;
                        o_fpu_op     = OP_FMAX;
                        o_fp_rd_wren = 1'b1;
                        o_fcsr_wren  = 1'b1;
                     end
                     default: begin
                        o_inst_vld   = 1'b0;
                        o_fpu_op     = OP_FADD;
                        o_fp_rd_wren = 1'b0;
                        o_fcsr_wren  = 1'b0;
                     end
                  endcase
               end

               FCVTWS: begin
                  o_fp_rd_wren  = 1'b0;
                  o_fpu_opa_sel = sel_fp_rs1;
                  o_start_fpu   = 1'b0;

                  case(i_inst[24:20])
                     5'b00000: begin
                        o_inst_vld    = 1'b1;
                        o_fpu_op      = OP_CVTWS;
                        o_int_rd_wren = 1'b1;
                        o_fcsr_wren   = 1'b1;
                     end
                     5'b00001: begin
                        o_inst_vld    = 1'b1;
                        o_fpu_op      = OP_CVTWUS;
                        o_int_rd_wren = 1'b1;
                        o_fcsr_wren   = 1'b1;
                     end
                     default: begin
                        o_inst_vld    = 1'b0;
                        o_fpu_op      = OP_FADD;
                        o_int_rd_wren = 1'b0;
                        o_fcsr_wren   = 1'b0;
                     end
                  endcase
               end

               FMVXS: begin
                  o_fp_rd_wren  = 1'b0;
                  o_fpu_opa_sel = sel_fp_rs1;
                  o_start_fpu   = 1'b0;

                  case(i_inst[14:12])
                     3'b000: begin
                        o_inst_vld    = 1'b1;
                        o_fpu_op      = OP_MVXW;
                        o_int_rd_wren = 1'b1;
                        o_fcsr_wren   = 1'b1;
                     end
                     3'b001: begin
                        o_inst_vld    = 1'b1;
                        o_fpu_op      = OP_FCLASS;
                        o_int_rd_wren = 1'b1;
                        o_fcsr_wren   = 1'b1;
                     end
                     default: begin
                        o_inst_vld    = 1'b0;
                        o_fpu_op      = OP_FADD;
                        o_int_rd_wren = 1'b0;
                        o_fcsr_wren   = 1'b0;
                     end
                  endcase
               end

               FCOMP: begin
                  o_fp_rd_wren  = 1'b0;
                  o_fpu_opa_sel = sel_fp_rs1;
                  o_start_fpu   = 1'b0;

                  case(i_inst[14:12])
                     3'b000: begin
                        o_inst_vld    = 1'b1;
                        o_fpu_op      = OP_FLE;
                        o_int_rd_wren = 1'b1;
                        o_fcsr_wren   = 1'b1;
                     end
                     3'b001: begin
                        o_inst_vld    = 1'b1;
                        o_fpu_op      = OP_FLT;
                        o_int_rd_wren = 1'b1;
                        o_fcsr_wren   = 1'b1;
                     end
                     3'b010: begin
                        o_inst_vld    = 1'b1;
                        o_fpu_op      = OP_FEQ;
                        o_int_rd_wren = 1'b1;
                        o_fcsr_wren   = 1'b1;
                     end
                     default: begin
                        o_inst_vld    = 1'b0;
                        o_fpu_op      = OP_FADD;
                        o_int_rd_wren = 1'b0;
                        o_fcsr_wren   = 1'b0;
                     end
                  endcase
               end

               FCVTSW: begin
                  o_int_rd_wren = 1'b0;
                  o_fpu_opa_sel = sel_int_rs1;
                  o_start_fpu   = 1'b0;

                  case(i_inst[24:20])
                     5'b00000: begin
                        o_inst_vld   = 1'b1;
                        o_fpu_op     = OP_CVTSW;
                        o_fp_rd_wren = 1'b1;
                        o_fcsr_wren  = 1'b1;
                     end
                     5'b00001: begin
                        o_inst_vld   = 1'b1;
                        o_fpu_op     = OP_CVTSWU;
                        o_fp_rd_wren = 1'b1;
                        o_fcsr_wren  = 1'b1;
                     end
                     default: begin
                        o_inst_vld   = 1'b0;
                        o_fpu_op     = OP_FADD;
                        o_fp_rd_wren = 1'b0;
                        o_fcsr_wren  = 1'b0;
                     end
                  endcase
               end

               FMVSX: begin
                  o_inst_vld    = 1'b1;
                  o_int_rd_wren = 1'b0;
                  o_fp_rd_wren  = 1'b1;
                  o_fpu_opa_sel = sel_int_rs1;
                  o_fpu_op      = OP_MVWX;
                  o_start_fpu   = 1'b0;
                  o_fcsr_wren   = 1'b1;
               end

               default: begin
                  o_inst_vld    = 1'b0;
                  o_int_rd_wren = 1'b0;
                  o_fp_rd_wren  = 1'b0;
                  o_fpu_opa_sel = sel_fp_rs1;
                  o_fpu_op      = OP_FADD;
                  o_start_fpu   = 1'b0;
                  o_fcsr_wren   = 1'b0;
               end
            endcase
         end
//-------------------------------------------------------------------
         FLW: begin
            o_inst_vld      = 1'b1;
            o_br_un         = 1'b1;
            o_st_sel        = st_int;
            o_mem_rden      = 1'b1;
            o_mem_wren      = 1'b0;
            o_wb_sel        = wb_lsu_data;

            o_alu_opa_sel   = sel_rs1;
            o_alu_opb_sel   = sel_imm;
            o_int_rd_wren   = 1'b0;
            o_alu_op        = OP_ADD;

            o_fpu_opa_sel   = sel_fp_rs1;
            o_fp_rd_wren    = 1'b1;
            o_fpu_op        = OP_FADD;
            o_start_fpu     = 1'b0;

            o_csr_op        = OP_NOP;
            o_csr_wdata_sel = 1'b0;
            o_fcsr_wren     = 1'b0;
         end
//-------------------------------------------------------------------
         FSW: begin
            o_inst_vld      = 1'b1;
            o_br_un         = 1'b1;
            o_st_sel        = st_fp;
            o_mem_rden      = 1'b0;
            o_mem_wren      = 1'b1;
            o_wb_sel        = wb_lsu_data;

            o_alu_opa_sel   = sel_rs1;
            o_alu_opb_sel   = sel_imm;
            o_int_rd_wren   = 1'b0;
            o_alu_op        = OP_ADD;

            o_fpu_opa_sel   = sel_fp_rs1;
            o_fp_rd_wren    = 1'b0;
            o_fpu_op        = OP_FADD;
            o_start_fpu     = 1'b0;

            o_csr_op        = OP_NOP;
            o_csr_wdata_sel = 1'b0;
            o_fcsr_wren     = 1'b0;
         end
//-------------------------------------------------------------------
         FMADD: begin
            o_inst_vld      = 1'b1;
            o_br_un         = 1'b1;
            o_st_sel        = st_int;
            o_mem_rden      = 1'b0;
            o_mem_wren      = 1'b0;
            o_wb_sel        = wb_fpu_data;

            o_alu_opa_sel   = sel_rs1;
            o_alu_opb_sel   = sel_rs2;
            o_int_rd_wren   = 1'b0;
            o_alu_op        = OP_ADD;

            o_fpu_opa_sel   = sel_fp_rs1;
            o_fp_rd_wren    = 1'b1;
            o_fpu_op        = OP_MADD;
            o_start_fpu     = 1'b0;

            o_csr_op        = OP_NOP;
            o_csr_wdata_sel = 1'b0;
            o_fcsr_wren     = 1'b1;
         end
//-------------------------------------------------------------------
         FMSUB: begin
            o_inst_vld      = 1'b1;
            o_br_un         = 1'b1;
            o_st_sel        = st_int;
            o_mem_rden      = 1'b0;
            o_mem_wren      = 1'b0;
            o_wb_sel        = wb_fpu_data;

            o_alu_opa_sel   = sel_rs1;
            o_alu_opb_sel   = sel_rs2;
            o_int_rd_wren   = 1'b0;
            o_alu_op        = OP_ADD;

            o_fpu_opa_sel   = sel_fp_rs1;
            o_fp_rd_wren    = 1'b1;
            o_fpu_op        = OP_MSUB;
            o_start_fpu     = 1'b0;

            o_csr_op        = OP_NOP;
            o_csr_wdata_sel = 1'b0;
            o_fcsr_wren     = 1'b1;
         end
//-------------------------------------------------------------------
         FNMSUB: begin
            o_inst_vld      = 1'b1;
            o_br_un         = 1'b1;
            o_st_sel        = st_int;
            o_mem_rden      = 1'b0;
            o_mem_wren      = 1'b0;
            o_wb_sel        = wb_fpu_data;

            o_alu_opa_sel   = sel_rs1;
            o_alu_opb_sel   = sel_rs2;
            o_int_rd_wren   = 1'b0;
            o_alu_op        = OP_ADD;

            o_fpu_opa_sel   = sel_fp_rs1;
            o_fp_rd_wren    = 1'b1;
            o_fpu_op        = OP_NMSUB;
            o_start_fpu     = 1'b0;

            o_csr_op        = OP_NOP;
            o_csr_wdata_sel = 1'b0;
            o_fcsr_wren     = 1'b1;
         end
//-------------------------------------------------------------------
         FNMADD: begin
            o_inst_vld      = 1'b1;
            o_br_un         = 1'b1;
            o_st_sel        = st_int;
            o_mem_rden      = 1'b0;
            o_mem_wren      = 1'b0;
            o_wb_sel        = wb_fpu_data;

            o_alu_opa_sel   = sel_rs1;
            o_alu_opb_sel   = sel_rs2;
            o_int_rd_wren   = 1'b0;
            o_alu_op        = OP_ADD;

            o_fpu_opa_sel   = sel_fp_rs1;
            o_fp_rd_wren    = 1'b1;
            o_fpu_op        = OP_NMADD;
            o_start_fpu     = 1'b0;

            o_csr_op        = OP_NOP;
            o_csr_wdata_sel = 1'b0;
            o_fcsr_wren     = 1'b1;
         end
//-------------------------------------------------------------------
         Z_TYPE: begin
            //o_inst_vld      = 1'b1;
            o_br_un         = 1'b1;
            o_st_sel        = st_int;
            o_mem_rden      = 1'b0;
            o_mem_wren      = 1'b0;
            o_wb_sel        = wb_read_csr;

            o_alu_opa_sel   = sel_rs1;
            o_alu_opb_sel   = sel_rs2;
            //o_int_rd_wren   = 1'b0;
            o_alu_op        = OP_ADD;

            o_fpu_opa_sel   = sel_fp_rs1;
            o_fp_rd_wren    = 1'b0;
            o_fpu_op        = OP_FADD;
            o_start_fpu     = 1'b0;

            case(i_inst[14:12])
               CSRRW: begin
                  o_inst_vld      = 1'b1;
                  o_int_rd_wren   = 1'b1;
                  o_csr_op        = OP_RW;
                  o_csr_wdata_sel = 1'b0;   // int_rs1
                  o_fcsr_wren     = 1'b1;
               end

               CSRRS: begin
                  o_inst_vld      = 1'b1;
                  o_int_rd_wren   = 1'b1;
                  o_csr_op        = OP_RS;
                  o_csr_wdata_sel = 1'b0;   // int_rs1
                  o_fcsr_wren     = 1'b1;
               end

               CSRRC: begin
                  o_inst_vld      = 1'b1;
                  o_int_rd_wren   = 1'b1;
                  o_csr_op        = OP_RC;
                  o_csr_wdata_sel = 1'b0;   // int_rs1
                  o_fcsr_wren     = 1'b1;
               end

               CSRRWI: begin
                  o_inst_vld      = 1'b1;
                  o_int_rd_wren   = 1'b1;
                  o_csr_op        = OP_RW;
                  o_csr_wdata_sel = 1'b1;   // imm
                  o_fcsr_wren     = 1'b1;
               end

               CSRRSI: begin
                  o_inst_vld      = 1'b1;
                  o_int_rd_wren   = 1'b1;
                  o_csr_op        = OP_RS;
                  o_csr_wdata_sel = 1'b1;   // imm
                  o_fcsr_wren     = 1'b1;
               end

               CSRRCI: begin
                  o_inst_vld      = 1'b1;
                  o_int_rd_wren   = 1'b1;
                  o_csr_op        = OP_RC;
                  o_csr_wdata_sel = 1'b1;   // imm
                  o_fcsr_wren     = 1'b1;
               end
   
               default: begin
                  o_inst_vld      = 1'b0;
                  o_int_rd_wren   = 1'b0;
                  o_csr_op        = OP_NOP;
                  o_csr_wdata_sel = 1'b0;
                  o_fcsr_wren     = 1'b0;
               end
            endcase
         end
//-------------------------------------------------------------------
         default: begin
            o_inst_vld      = 1'b0;
            o_br_un         = 1'b1;
            o_st_sel        = st_int;
            o_mem_rden      = 1'b0;
            o_mem_wren      = 1'b0;
            o_wb_sel        = wb_alu_data;

            o_alu_opa_sel   = sel_rs1;
            o_alu_opb_sel   = sel_rs2;
            o_int_rd_wren   = 1'b0;
            o_alu_op        = OP_ADD;

            o_fpu_opa_sel   = sel_fp_rs1;
            o_fp_rd_wren    = 1'b0;
            o_fpu_op        = OP_FADD;
            o_start_fpu     = 1'b0;

            o_csr_op        = OP_NOP;
            o_csr_wdata_sel = 1'b0;
            o_fcsr_wren     = 1'b0;
         end
      endcase
   end

endmodule