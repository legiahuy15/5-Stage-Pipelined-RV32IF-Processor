module hazard_detect (
   // input
   //input  logic [31:0] i_ID_inst       ,
   input  logic [31:0] i_EX_inst       ,

   input  logic        i_fpu_ack       ,
   input  logic        i_fpu_busy      ,

   input  logic        i_lsu_ack       ,
   input  logic        i_lsu_busy      ,
   // output
   output logic        o_pc_en         ,
   output logic        o_IF_ID_stall   ,
   output logic        o_ID_EX_flush
);

///////////////////////////////////////////////////////////////////////////////

/*
   logic [4:0] ID_rs1_addr, ID_rs2_addr, ID_rs3_addr;
   logic [4:0] EX_rd_addr;

   assign ID_rs1_addr = i_ID_inst[19:15];
   assign ID_rs2_addr = i_ID_inst[24:20];
   assign ID_rs3_addr = i_ID_inst[31:27];

   assign EX_rd_addr  = i_EX_inst[11:7];
*/

   logic [6:0] EX_opcode;
   assign EX_opcode   = i_EX_inst[6:0];

   logic EX_is_ls;
   assign EX_is_ls = (EX_opcode == 7'h3)  || (EX_opcode == 7'h7) ||   // I_load_type & FLW
                     (EX_opcode == 7'h23) || (EX_opcode == 7'h27);    // S_type & FSW

/*
   logic load_use_hazard;
   assign load_use_hazard   = ((EX_opcode == 7'h3) && (EX_rd_addr != 5'b0) && ((EX_rd_addr == ID_rs1_addr) || (EX_rd_addr == ID_rs2_addr))) ||
                              ((EX_opcode == 7'h7) && ((EX_rd_addr == ID_rs1_addr) || (EX_rd_addr == ID_rs2_addr) || (EX_rd_addr == ID_rs3_addr)));
*/

   logic multicycle_hazard;
   assign multicycle_hazard = (i_fpu_busy ^ i_fpu_ack) || EX_is_ls || (i_lsu_busy ^ i_lsu_ack);

///////////////////////////////////////////////////////////////////////////////

   always_comb begin
      /*
      if (load_use_hazard) begin
         o_pc_en       = 1'b0;   // stall IF
         o_IF_ID_stall = 1'b1;   // stall ID
         o_ID_EX_flush = 1'b1;   // flush EX
      */
      if (multicycle_hazard) begin
         o_pc_en       = 1'b0;   // stall IF
         o_IF_ID_stall = 1'b1;   // stall ID
         o_ID_EX_flush = 1'b1;   // flush EX
      end else begin
         o_pc_en       = 1'b1;
         o_IF_ID_stall = 1'b0;
         o_ID_EX_flush = 1'b0;
      end
   end

endmodule