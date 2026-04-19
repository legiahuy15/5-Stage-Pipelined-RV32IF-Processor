module br_pred_unit (
   // input
   input  logic        i_clk      ,
   input  logic        i_rst_n    ,
   
   input  logic [31:0] i_IF_pc    ,
   input  logic [31:0] i_ID_pc    ,
   input  logic [31:0] i_EX_pc    ,
   input  logic [31:0] i_EX_pc_4  ,
   
   input  logic [31:0] i_alu_data ,
   
   input  logic [31:0] i_IF_inst  ,
   input  logic [31:0] i_EX_inst  ,
   
   input  logic        i_brc_taken,
   // output
   output logic        o_flush    ,
   output logic [31:0] o_next_pc
);

///////////////////////////////////////////////////////////////////////////////
// Definition

   localparam [4:0] B_TYPE = 5'b11000,
                    JAL    = 5'b11011,
                    JALR   = 5'b11001;

   localparam [1:0] STRONG_NOT_TAKEN = 2'b00,
                    WEAK_NOT_TAKEN   = 2'b01,
                    WEAK_TAKEN       = 2'b10,
                    STRONG_TAKEN     = 2'b11;

///////////////////////////////////////////////////////////////////////////////
// Internal signal

   logic [7:0] IF_index, EX_index;
   assign IF_index = i_IF_pc[9:2];
   assign EX_index = i_EX_pc[9:2];

   logic [2:0] IF_tag, EX_tag;
   assign IF_tag = i_IF_pc[12:10];
   assign EX_tag = i_EX_pc[12:10];

   logic [4:0] IF_opcode, EX_opcode;
   assign IF_opcode = i_IF_inst[6:2];
   assign EX_opcode = i_EX_inst[6:2];

   logic jump_branch_IF, jump_branch_EX;   //detect jump/branch instruction
   assign jump_branch_IF = (IF_opcode == B_TYPE) | (IF_opcode == JAL) | (IF_opcode == JALR);
   assign jump_branch_EX = (EX_opcode == B_TYPE) | (EX_opcode == JAL) | (EX_opcode == JALR);

///////////////////////////////////////////////////////////////////////////////
// GHR

   logic [7:0] ghr;   // global history register   

   always_ff @(posedge i_clk or negedge i_rst_n) begin
      if (!i_rst_n) begin
         ghr <= 8'b0;
      end else if (jump_branch_EX) begin
         ghr <= {ghr[6:0], i_brc_taken};
      end
   end

///////////////////////////////////////////////////////////////////////////////
// Pattern

   logic [7:0] pattern_IF, pattern_ID, pattern_EX;   // (8-bit PC xor GHR) as pattern for PHT
   assign pattern_IF = i_IF_pc[9:2] ^ ghr;

   always_ff @(posedge i_clk or negedge i_rst_n) begin
      if (~i_rst_n) begin
         {pattern_ID, pattern_EX} <= 16'b0;
      end else begin
         pattern_EX <= pattern_ID;
         pattern_ID <= pattern_IF;
      end 
   end

///////////////////////////////////////////////////////////////////////////////
// PHT (Pattern History Table)

   logic [1:0] pht [255:0]; 
   logic [1:0] predict_state, fix_state, true_state;

   assign predict_state = pht[pattern_IF];
   assign fix_state     = pht[pattern_EX];

   always_comb begin
      case (fix_state)
         STRONG_NOT_TAKEN: begin
            if (~jump_branch_EX)  true_state = STRONG_NOT_TAKEN;
            else if (i_brc_taken) true_state = WEAK_NOT_TAKEN;
            else                  true_state = STRONG_NOT_TAKEN;
         end

         WEAK_NOT_TAKEN: begin
            if (~jump_branch_EX)  true_state = WEAK_NOT_TAKEN;
            else if (i_brc_taken) true_state = WEAK_TAKEN;
            else                  true_state = STRONG_NOT_TAKEN;
         end

         WEAK_TAKEN: begin
            if (~jump_branch_EX)  true_state = WEAK_TAKEN;
            else if (i_brc_taken) true_state = STRONG_TAKEN;
            else                  true_state = WEAK_NOT_TAKEN;
         end

         STRONG_TAKEN: begin
            if (~jump_branch_EX)  true_state = STRONG_TAKEN;
            else if (i_brc_taken) true_state = STRONG_TAKEN;
            else                  true_state = WEAK_TAKEN;
         end
      endcase
   end

   always_ff @(posedge i_clk or negedge i_rst_n) begin
      if (!i_rst_n) begin   
         for( int k = 0; k < 256; k++) pht[k] <= 2'b00;
      end else begin
         pht[pattern_EX] <= true_state;
      end
   end

///////////////////////////////////////////////////////////////////////////////
// BTB (Branch Target Buffer)

   logic [14:0] btb [255:0];

   always_ff @(posedge i_clk or negedge i_rst_n) begin
      if (!i_rst_n) begin 
         for (int i = 0; i < 255; i++) btb[i] <= 15'b0;
      end else if(jump_branch_EX) begin
         btb[EX_index] <= {1'b1, EX_tag, i_alu_data[12:2]};
      end
   end

   logic [31:0] btb_pc_predict;
   assign btb_pc_predict = {19'b0, btb[IF_index][10:0], 2'b00};

   logic btb_valid;
   assign btb_valid = btb[IF_index][14];

   logic [2:0] btb_tag;
   assign btb_tag = btb[IF_index][13:11];

///////////////////////////////////////////////////////////////////////////////
// Output logic

   logic hit;
   // btb valid, tag IF equal to tag btb, jump/branch instruction
   assign hit = btb_valid & (btb_tag == IF_tag) & jump_branch_IF & predict_state[1];

   logic [31:0] EX_true_pc, IF_predict_pc;

   assign IF_predict_pc = hit ? btb_pc_predict : (i_IF_pc + 32'd4);   // pc_predict
   assign EX_true_pc = i_brc_taken ? i_alu_data : i_EX_pc_4;          // pc_true

   assign o_flush = jump_branch_EX & (EX_true_pc != i_ID_pc);         // check_predict_EX_stage
   assign o_next_pc = o_flush ? EX_true_pc : IF_predict_pc;           // fix_pc

endmodule