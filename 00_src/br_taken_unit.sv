module br_taken_unit (
   // input
   input  logic [31:0] i_inst    ,
   input  logic        i_br_less ,
   input  logic        i_br_equal,
   // output
   output logic        o_br_taken
);

///////////////////////////////////////////////////////////////////////////////

   // opcode
   localparam [4:0] B_TYPE = 5'b11000,
                    JAL    = 5'b11011,
                    JALR   = 5'b11001;

   // funct3 branch					 
   localparam [2:0] BEQ  = 3'b000,
                    BNE  = 3'b001,
                    BLT  = 3'b100,
                    BGE  = 3'b101,
                    BLTU = 3'b110,
                    BGEU = 3'b111;

   // branch select
   localparam pc_four     = 1'b0,
              pc_plus_imm = 1'b1;

///////////////////////////////////////////////////////////////////////////////

   always_comb begin
      if(i_inst[6:2] == B_TYPE) begin   //opcode
         case(i_inst[14:12])   // func3
            BEQ    : o_br_taken   = i_br_equal ;
            BNE    : o_br_taken   = ~i_br_equal;
            BLT    : o_br_taken   = i_br_less  ;
            BGE    : o_br_taken   = ~i_br_less ;
            BLTU   : o_br_taken   = i_br_less  ;
            BGEU   : o_br_taken   = ~i_br_less ;
            default: o_br_taken   = pc_four    ;
         endcase
      end else if((i_inst[6:2] == JAL) || (i_inst[6:2] == JALR)) begin
         o_br_taken = pc_plus_imm;
      end else o_br_taken = pc_four;
   end

endmodule