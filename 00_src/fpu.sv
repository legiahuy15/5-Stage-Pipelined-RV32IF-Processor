module fpu (
   // inputs
   input  logic        i_clk     ,
   input  logic        i_rst_n   ,
   input  logic        i_start_en,   // start multi-cycle
   input  logic [ 4:0] i_fpu_op  ,
   input  logic [ 2:0] i_frm     ,
   input  logic [31:0] i_op_a    ,
   input  logic [31:0] i_op_b    ,
   input  logic [31:0] i_op_c    ,
   // outputs
   output logic        o_busy    ,   // multi-cycle only
   output logic        o_ack     ,   // multi-cycle only
   output logic [31:0] o_result  ,
   output logic [ 4:0] o_fflags
);

///////////////////////////////////////////////////////////////////////////////
// FPU opcodes

   localparam [4:0]
      ADD = 5'd0,  SUB = 5'd1,
      MUL = 5'd2,  DIV = 5'd3,
      SQRT = 5'd4,
      MADD = 5'd5,  MSUB = 5'd6,  NMSUB = 5'd7, NMADD = 5'd8,
      SGNJ = 5'd9,  SGNJN = 5'd10, SGNJX = 5'd11,
      CVTWS = 5'd12, CVTWUS = 5'd13,
      CVTSW = 5'd14, CVTSWU = 5'd15,
      MVXW = 5'd16, MVWX = 5'd17,
      FEQ = 5'd18, FLT = 5'd19, FLE = 5'd20,
      FCLASS = 5'd21,
      FMIN = 5'd22, FMAX = 5'd23;

///////////////////////////////////////////////////////////////////////////////
// Internal signals

   // Individual operation flags
   logic is_add, is_sub, is_mul, is_div, is_sqrt;
   logic is_madd, is_msub, is_nmadd, is_nmsub;
   logic is_sgnj, is_sgnjn, is_sgnjx;
   logic is_cvtws, is_cvtwus, is_cvtsw, is_cvtswu;
   logic is_mvxw, is_mvwx;
   logic is_feq, is_flt, is_fle, is_fclass;
   logic is_fmin, is_fmax;

   // Grouped operation flags
   logic is_fma, is_signinj, is_compare, is_convert, is_minmax;
   logic is_unsigned;

   // Combinational assignment 
   always_comb begin
      is_add    = (i_fpu_op == ADD);
      is_sub    = (i_fpu_op == SUB);
      is_mul    = (i_fpu_op == MUL);
      is_div    = (i_fpu_op == DIV);
      is_sqrt   = (i_fpu_op == SQRT);
      is_madd   = (i_fpu_op == MADD);
      is_msub   = (i_fpu_op == MSUB);
      is_nmadd  = (i_fpu_op == NMADD);
      is_nmsub  = (i_fpu_op == NMSUB);
      is_sgnj   = (i_fpu_op == SGNJ);
      is_sgnjn  = (i_fpu_op == SGNJN);
      is_sgnjx  = (i_fpu_op == SGNJX);
      is_cvtws  = (i_fpu_op == CVTWS);
      is_cvtwus = (i_fpu_op == CVTWUS);
      is_cvtsw  = (i_fpu_op == CVTSW);
      is_cvtswu = (i_fpu_op == CVTSWU);
      is_mvxw   = (i_fpu_op == MVXW);
      is_mvwx   = (i_fpu_op == MVWX);
      is_feq    = (i_fpu_op == FEQ);
      is_flt    = (i_fpu_op == FLT);
      is_fle    = (i_fpu_op == FLE);
      is_fclass = (i_fpu_op == FCLASS);
      is_fmin   = (i_fpu_op == FMIN);
      is_fmax   = (i_fpu_op == FMAX);

      is_fma      = is_madd | is_msub | is_nmadd | is_nmsub;
      is_signinj  = is_sgnj | is_sgnjn | is_sgnjx;
      is_compare  = is_feq | is_flt | is_fle;
      is_convert  = is_cvtws | is_cvtwus | is_cvtsw | is_cvtswu;
      is_minmax   = is_fmin | is_fmax;
      is_unsigned = is_cvtwus | is_cvtswu;
   end

///////////////////////////////////////////////////////////////////////////////
// Simple FSM for div/sqrt (no input latching)

   typedef enum logic [0:0] { S_IDLE=1'b0, S_WAIT=1'b1 } state_e;
   state_e state, next_state;

   // Track which multi-cycle op is in-flight (no operand/opcode latching)
   logic inflight_div, inflight_sqrt;

   // Multi-cycle submodule wires
   logic        div_out_valid, div_in_ready;
   logic        sqrt_out_valid, sqrt_in_ready;
   logic [31:0] div_result, sqrt_result;
   logic [ 4:0] div_fflags, sqrt_fflags;

   // Busy register to satisfy "busy turns on immediately on start"
   logic busy_reg;

   // Start condition for multi-cycle ops
   wire start_mc = i_start_en && (is_div || is_sqrt);

   // FSM state
   always_ff @(posedge i_clk or negedge i_rst_n) begin
      if (!i_rst_n) state <= S_IDLE;
      else          state <= next_state;
   end

   // In-flight tracking (1 bit each). Set on start, clear on ack.
   always_ff @(posedge i_clk or negedge i_rst_n) begin
      if (!i_rst_n) begin
         inflight_div  <= 1'b0;
         inflight_sqrt <= 1'b0;
      end else begin
         if (start_mc) begin
            inflight_div  <= is_div;
            inflight_sqrt <= is_sqrt;
         end else if ((state == S_WAIT) &&
                      ((inflight_div  && div_out_valid) ||
                       (inflight_sqrt && sqrt_out_valid))) begin
            inflight_div  <= 1'b0;
            inflight_sqrt <= 1'b0;
         end
      end
   end

   // Next state: go WAIT on start, return to IDLE when the corresponding result is valid
   always_comb begin
      next_state = state;
      unique case (state)
         S_IDLE: if (start_mc) next_state = S_WAIT;
         S_WAIT: if ( (inflight_div  && div_out_valid) ||
                      (inflight_sqrt && sqrt_out_valid) ) next_state = S_IDLE;
      endcase
   end

   // Busy register: set on start, clear on ack edge
   always_ff @(posedge i_clk or negedge i_rst_n) begin
      if (!i_rst_n) busy_reg <= 1'b0;
      else begin
         if (start_mc) busy_reg <= 1'b1;
         else if ( (state == S_WAIT) &&
                   ( (inflight_div  && div_out_valid) ||
                     (inflight_sqrt && sqrt_out_valid) ) ) busy_reg <= 1'b0;
      end
   end

   // Handshake outputs
   // o_busy must go high immediately when i_start_en is asserted (for DIV/SQRT)
   assign o_busy = busy_reg || start_mc;

///////////////////////////////////////////////////////////////////////////////
// Submodules

   logic [31:0] result_addsub, result_mul, result_fma, result_signinj;
   logic [31:0] result_cmp, result_class, result_minmax;
   logic [31:0] result_cvt_fp2i, result_cvt_i2fp;
   logic [4:0]  fflags_addsub, fflags_mul, fflags_fma;
   logic [4:0]  fflags_cmp, fflags_minmax;
   logic [4:0]  fflags_cvt_fp2i, fflags_cvt_i2fp;
   logic [4:0]  fflags_singinj;

   logic [31:0] result_cvt;
   logic [4:0]  fflags_cvt;

   logic [1:0] fma_op;
   always_comb begin
      if      (is_nmadd) fma_op = 2'b11;
      else if (is_nmsub) fma_op = 2'b10;
      else if (is_msub)  fma_op = 2'b01;
      else               fma_op = 2'b00;
   end

   fp_add_sub u_addsub (
      .i_op     (is_sub),
      .i_frm    (i_frm),
      .i_op_a   (i_op_a),
      .i_op_b   (i_op_b),
      .o_result (result_addsub),
      .o_fflags (fflags_addsub)
   );

   fp_mul u_mul (
      .i_frm    (i_frm),
      .i_op_a   (i_op_a),
      .i_op_b   (i_op_b),
      .o_result (result_mul),
      .o_fflags (fflags_mul)
   );

   fp_fma u_fma (
      .i_op     (fma_op),
      .i_frm    (i_frm),
      .i_op_a   (i_op_a),
      .i_op_b   (i_op_b),
      .i_op_c   (i_op_c),
      .o_result (result_fma),
      .o_fflags (fflags_fma)
   );

   // For multi-cycle units: drive in_valid directly from i_start_en & opcode (no latching)
   fp_div u_div (
      .i_clk     (i_clk),
      .i_rst_n   (i_rst_n),
      .in_valid  (i_start_en && is_div),
      .in_ready  (div_in_ready),
      .i_op_a    (i_op_a),
      .i_op_b    (i_op_b),
      .i_frm     (i_frm),
      .i_cancel  (1'b0),
      .out_valid (div_out_valid),
      .o_result  (div_result),
      .o_fflags  (div_fflags)
   );

   fp_sqrt u_sqrt (
      .i_clk     (i_clk),
      .i_rst_n   (i_rst_n),
      .in_valid  (i_start_en && is_sqrt),
      .in_ready  (sqrt_in_ready),
      .i_op_a    (i_op_a),
      .i_frm     (i_frm),
      .i_cancel  (1'b0),
      .out_valid (sqrt_out_valid),
      .o_result  (sqrt_result),
      .o_fflags  (sqrt_fflags)
   );

   fp_sign_inj #(8,24) u_signinj (
      .i_op_a   (i_op_a),
      .i_op_b   (i_op_b),
      .i_op     (is_sgnjx ? 2'b10 : (is_sgnjn ? 2'b01 : 2'b00)),
      .o_result (result_signinj),
      .o_fflags (fflags_singinj)
   );

   fp_compare #(8,24) u_cmp (
      .i_op     (is_fle ? 2'b00 : (is_flt ? 2'b01 : 2'b10)),
      .i_op_a   (i_op_a),
      .i_op_b   (i_op_b),
      .o_result (result_cmp),
      .o_fflags (fflags_cmp)
   );

   fp_class u_class (
      .i_op_a   (i_op_a),
      .o_result (result_class)
   );

   fp_min_max u_minmax (
      .i_op     (is_fmax),
      .i_op_a   (i_op_a),
      .i_op_b   (i_op_b),
      .o_result (result_minmax),
      .o_fflags (fflags_minmax)
   );

   cv_fp_to_int #(8,24,32) u_cvti (
      .i_unsigned (is_unsigned),
      .i_frm      (i_frm),
      .i_op_a     (i_op_a),
      .o_result   (result_cvt_fp2i),
      .o_fflags   (fflags_cvt_fp2i)
   );

   cv_int_to_fp u_cvtf (
      .i_unsigned (is_unsigned),
      .i_frm      (i_frm),
      .i_op_a     (i_op_a),
      .o_result   (result_cvt_i2fp),
      .o_fflags   (fflags_cvt_i2fp)
   );

   assign result_cvt = (is_cvtws || is_cvtwus) ? result_cvt_fp2i : result_cvt_i2fp;
   assign fflags_cvt = (is_cvtws || is_cvtwus) ? fflags_cvt_fp2i : fflags_cvt_i2fp;

///////////////////////////////////////////////////////////////////////////////
// Output logic

   logic [31:0] result_comb;
   logic [ 4:0] fflags_comb;
   logic        ack_comb;

   always_comb begin
      result_comb = 32'h0;
      fflags_comb = 5'h0;
      ack_comb    = 1'b0;

      unique case (1'b1)
         is_add, is_sub: begin
            result_comb = result_addsub;
            fflags_comb = fflags_addsub;
         end
         is_mul: begin
            result_comb = result_mul;
            fflags_comb = fflags_mul;
         end
         is_fma: begin
            result_comb = result_fma;
            fflags_comb = fflags_fma;
         end
         is_signinj: begin
            result_comb = result_signinj;
            fflags_comb = fflags_singinj;
         end
         is_compare: begin
            result_comb = result_cmp;
            fflags_comb = fflags_cmp;
         end
         is_fclass: begin
            result_comb = result_class;
            fflags_comb = 5'b00000;
         end
         is_minmax: begin
            result_comb = result_minmax;
            fflags_comb = fflags_minmax;
         end
         is_convert: begin
            result_comb = result_cvt;
            fflags_comb = fflags_cvt;
         end
         is_mvxw, is_mvwx: begin
            result_comb = i_op_a;
            fflags_comb = 5'b00000;
         end
         default: begin
            result_comb = 32'hDEADBEEF;
            fflags_comb = 5'b11111;
         end
      endcase

      // Override with multi-cycle results when ready (and assert ack for 1 cycle)
      if (state == S_WAIT && inflight_div && div_out_valid) begin
         result_comb = div_result;
         fflags_comb = div_fflags;
         ack_comb    = 1'b1;
      end else if (state == S_WAIT && inflight_sqrt && sqrt_out_valid) begin
         result_comb = sqrt_result;
         fflags_comb = sqrt_fflags;
         ack_comb    = 1'b1;
      end
   end

   assign o_result = result_comb;
   assign o_fflags = fflags_comb;
   assign o_ack    = ack_comb;  // 1 chu kỳ đúng tại thời điểm out_valid của phép đang in-flight

endmodule