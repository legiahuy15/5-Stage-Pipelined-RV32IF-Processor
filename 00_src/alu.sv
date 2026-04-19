module alu (
   // input
   input  logic [31:0] i_op_a,
   input  logic [31:0] i_op_b,
   input  logic [ 3:0] i_alu_op,
   // output
   output logic [31:0] o_alu_data
);

///////////////////////////////////////////////////////////////////////////////

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
						
   logic [32:0] temp, stage1, stage2, stage3, stage4;

///////////////////////////////////////////////////////////////////////////////

   assign temp = {1'b0, i_op_a} + ~{1'b0, i_op_b} + 32'b1;

   always_comb begin
      stage1 = 32'b0;
      stage2 = 32'b0;
      stage3 = 32'b0;
      stage4 = 32'b0;
    
      case (i_alu_op)
         // arithmatic
         OP_ADD: o_alu_data = i_op_a + i_op_b;
         OP_SUB: o_alu_data = temp[31:0];

         // bitwise logic
         OP_XOR: o_alu_data = i_op_a ^ i_op_b;
         OP_OR : o_alu_data = i_op_a | i_op_b;
         OP_AND: o_alu_data = i_op_a & i_op_b;

         // compare
         OP_SLT: begin
            if (i_op_a[31] ^ i_op_b[31] == 1'b0) begin
              o_alu_data = {31'b0,temp[31]};
            end else begin
              o_alu_data = {31'b0,i_op_a[31]};
            end
         end
         OP_SLTU: o_alu_data = {31'b0,temp[32]};

         // shift
         OP_SLL: begin
            stage1     = i_op_b[0] ? {i_op_a[30:0], 1'b0}  : i_op_a[31:0];
            stage2     = i_op_b[1] ? {stage1[29:0], 2'b0}  : stage1[31:0];
            stage3     = i_op_b[2] ? {stage2[27:0], 4'b0}  : stage2[31:0];
            stage4     = i_op_b[3] ? {stage3[23:0], 8'b0}  : stage3[31:0];
            o_alu_data = i_op_b[4] ? {stage4[15:0], 16'b0} : stage4[31:0];
         end
         OP_SRL: begin
            stage1     = i_op_b[0] ? {1'b0 , i_op_a[31:1]}  : i_op_a[31:0];
            stage2     = i_op_b[1] ? {2'b0 , stage1[31:2]}  : stage1[31:0];
            stage3     = i_op_b[2] ? {4'b0 , stage2[31:4]}  : stage2[31:0];
            stage4     = i_op_b[3] ? {8'b0 , stage3[31:8]}  : stage3[31:0];
            o_alu_data = i_op_b[4] ? {16'b0, stage4[31:16]} : stage4[31:0];
         end
         OP_SRA: begin
            stage1     = i_op_b[0] ? {i_op_a[31]      , i_op_a[31:1]}  : i_op_a[31:0];
            stage2     = i_op_b[1] ? {{2{stage1[31]}} , stage1[31:2]}  : stage1[31:0];
            stage3     = i_op_b[2] ? {{4{stage2[31]}} , stage2[31:4]}  : stage2[31:0];
            stage4     = i_op_b[3] ? {{8{stage3[31]}} , stage3[31:8]}  : stage3[31:0];
            o_alu_data = i_op_b[4] ? {{16{stage4[31]}}, stage4[31:16]} : stage4[31:0];
         end

         // grab only operand b
         OP_OPB: o_alu_data = i_op_b;

         // default (opcode error)
         default: o_alu_data = 32'b0;
      endcase
   end

endmodule