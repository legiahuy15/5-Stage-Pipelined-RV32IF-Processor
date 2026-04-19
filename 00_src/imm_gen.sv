module imm_gen (
   input  logic [31:0] i_inst,
   output logic [31:0] o_imm
);

///////////////////////////////////////////////////////////////////////////////

   localparam [4:0]
      //R_TYPE = 5'b01100,
      I_TYPE = 5'b00100,
      I_LOAD = 5'b00000,
      S_TYPE = 5'b01000,
      B_TYPE = 5'b11000,
      JAL    = 5'b11011,
      JALR   = 5'b11001,
      AUIPC  = 5'b00101,
      LUI    = 5'b01101,
      //F_TYPE = 5'b10100,
      FLW    = 5'b00001,
      FSW    = 5'b01001,
      //FMADD  = 5'b10000,
      //FMSUB  = 5'b10001,
      //FNMSUB = 5'b10010,
      //FNMADD = 5'b10011,
      Z_TYPE = 5'b11100;

   // funct3 zicsr
   localparam [2:0]
      //CSRRW  = 3'b001,
      //CSRRS  = 3'b010,
      //CSRRC  = 3'b011,
      CSRRWI = 3'b101,
      CSRRSI = 3'b110,
      CSRRCI = 3'b111;

///////////////////////////////////////////////////////////////////////////////

   always_comb begin
      case(i_inst[6:2])
         // I type: sign [31:25]
         I_TYPE: o_imm = {{21{i_inst[31]}}, i_inst[30:20]};
         I_LOAD: o_imm = {{21{i_inst[31]}}, i_inst[30:20]};
         JALR  : o_imm = {{21{i_inst[31]}}, i_inst[30:20]};

         S_TYPE: o_imm = {{21{i_inst[31]}}, i_inst[30:25], i_inst[11:7]};

         B_TYPE: o_imm = {{20{i_inst[31]}}, i_inst[7], i_inst[30:25], i_inst[11:8],1'b0};
         JAL   : o_imm = {{12{i_inst[31]}}, i_inst[19:12], i_inst[20], i_inst[30:21],1'b0};

         // shift type: [31:12] << 12
         LUI   : o_imm = {i_inst[31:12], 12'b0};
         AUIPC : o_imm = {i_inst[31:12], 12'b0};

         FLW   : o_imm = {{21{i_inst[31]}}, i_inst[30:20]};
         FSW   : o_imm = {{21{i_inst[31]}}, i_inst[30:25], i_inst[11:7]};

         Z_TYPE: begin
            case(i_inst[14:12])
               CSRRWI : o_imm = {27'b0, i_inst[19:15]};
               CSRRSI : o_imm = {27'b0, i_inst[19:15]};
               CSRRCI : o_imm = {27'b0, i_inst[19:15]};
               default: o_imm = 32'b0;
            endcase
         end

         default: o_imm = 32'b0;
      endcase
   end

endmodule