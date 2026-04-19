module imem (
   input  logic [31:0] i_pc_addr,
   output logic [31:0] o_inst
);

   logic [3:0][7:0] inst_mem [0:(2**11)-1];   // 8 KB

   initial begin
      $readmemh("00_src/instmem_data.hex", inst_mem);
   end

   always_comb begin
      o_inst = inst_mem[i_pc_addr[12:2]];
   end

endmodule