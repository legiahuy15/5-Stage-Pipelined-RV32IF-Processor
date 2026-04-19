module fp_csr (
   // Clock & Reset
   input  logic        i_clk      ,
   input  logic        i_rst_n    ,
   // CSR operation from ID stage
   input  logic [ 1:0] i_csr_op   ,   // 2'b01 = RW, 10 = RS, 11 = RC
   input  logic [11:0] i_csr_addr ,   // CSR address (0x001, 0x002, 0x003)
   input  logic [31:0] i_csr_wdata,   // rs1_data or uimm
   // Forwarding control
   input  logic        i_fw_en    ,   // forward enable
   input  logic [31:0] i_fw_fcsr  ,   // FCSR forwarded
   // Write-back control (from WB stage)
   input  logic        i_wb_wren  ,   // write-back enable
   input  logic [31:0] i_wb_fcsr  ,   // final FCSR value to write
   // Output
   output logic [ 2:0] o_frm      ,   // current rounding mode for FPU
   output logic [31:0] o_read_csr ,   // old CSR value (to rd)
   output logic [31:0] o_fcsr         // new FCSR value (only valid if Zicsr)
);

///////////////////////////////////////////////////////////////////////////////

   // Internal register holding current FCSR
   logic [31:0] fcsr_reg;

   // Combinational wires
   logic [31:0] fcsr_val;
   logic [ 4:0] fflags_z;
   logic [ 2:0] frm_z;
   logic [ 7:0] fcsr_z;

///////////////////////////////////////////////////////////////////////////////
// FCSR register update

   always_ff @(posedge i_clk or negedge i_rst_n) begin
      if (!i_rst_n) begin
         fcsr_reg <= 32'b0;
      end else if (i_wb_wren) begin
         fcsr_reg <= i_wb_fcsr;
      end
   end

///////////////////////////////////////////////////////////////////////////////
// Forwarding MUX

   assign fcsr_val = (i_fw_en ? i_fw_fcsr : fcsr_reg);

///////////////////////////////////////////////////////////////////////////////
// Default outputs

   assign o_frm  = fcsr_val[7:5];     // current frm (forwarded or reg)
   assign o_fcsr = {24'b0, fcsr_z};   // CSR update result

///////////////////////////////////////////////////////////////////////////////
// CSR combinational logic

   always_comb begin
      // Default from current value (after forwarding mux)
      fflags_z   = fcsr_val[4:0];
      frm_z      = fcsr_val[7:5];
      fcsr_z     = fcsr_val[7:0];
      o_read_csr = 32'b0;

      case (i_csr_addr)
         12'h001: begin // fflags
            o_read_csr = {27'b0, fcsr_val[4:0]};
            case (i_csr_op)
               2'b01: fflags_z = i_csr_wdata[4:0];                  // RW
               2'b10: fflags_z = fcsr_val[4:0] | i_csr_wdata[4:0];  // RS
               2'b11: fflags_z = fcsr_val[4:0] & ~i_csr_wdata[4:0]; // RC
               default: ;
            endcase
            fcsr_z = {frm_z, fflags_z};
         end

         12'h002: begin // frm
            o_read_csr = {29'b0, fcsr_val[7:5]};
            case (i_csr_op)
               2'b01: frm_z = i_csr_wdata[2:0];                  // RW
               2'b10: frm_z = fcsr_val[7:5] | i_csr_wdata[2:0];  // RS
               2'b11: frm_z = fcsr_val[7:5] & ~i_csr_wdata[2:0]; // RC
               default: ;
            endcase
            fcsr_z = {frm_z, fflags_z};
         end

         12'h003: begin // fcsr
            o_read_csr = {24'b0, fcsr_val[7:0]};
            case (i_csr_op)
               2'b01: fcsr_z = i_csr_wdata[7:0];                  // RW
               2'b10: fcsr_z = fcsr_val[7:0] | i_csr_wdata[7:0];  // RS
               2'b11: fcsr_z = fcsr_val[7:0] & ~i_csr_wdata[7:0]; // RC
               default: ;
            endcase
         end

         default: begin
            o_read_csr = 32'b0;
            fcsr_z = fcsr_val[7:0]; // preserve original
         end
      endcase
   end

endmodule