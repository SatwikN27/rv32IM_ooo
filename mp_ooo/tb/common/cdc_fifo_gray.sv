
(* no_ungroup *)
(* no_boundary_optimization *)
module cdc_fifo_gray #(
  parameter int unsigned WIDTH = 1,
  parameter type T = logic [WIDTH-1:0],
  parameter int LOG_DEPTH = 3,
  parameter int SYNC_STAGES = 2
) (
  input  logic src_rst_ni,
  input  logic src_clk_i,
  input  T     src_data_i,
  input  logic src_valid_i,
  output logic src_ready_o,

  input  logic dst_rst_ni,
  input  logic dst_clk_i,
  output T     dst_data_o,
  output logic dst_valid_o,
  input  logic dst_ready_i
);

  T [2**LOG_DEPTH-1:0] async_data;
  logic [LOG_DEPTH:0]  async_wptr;
  logic [LOG_DEPTH:0]  async_rptr;

  cdc_fifo_gray_src #(
    .T         ( T         ),
    .LOG_DEPTH ( LOG_DEPTH )
  ) i_src (
    .src_rst_ni,
    .src_clk_i,
    .src_data_i,
    .src_valid_i,
    .src_ready_o,

    (* async *) .async_data_o ( async_data ),
    (* async *) .async_wptr_o ( async_wptr ),
    (* async *) .async_rptr_i ( async_rptr )
  );

  cdc_fifo_gray_dst #(
    .T         ( T         ),
    .LOG_DEPTH ( LOG_DEPTH )
  ) i_dst (
    .dst_rst_ni,
    .dst_clk_i,
    .dst_data_o,
    .dst_valid_o,
    .dst_ready_i,

    (* async *) .async_data_i ( async_data ),
    (* async *) .async_wptr_i ( async_wptr ),
    (* async *) .async_rptr_o ( async_rptr )
  );

  // Check the invariants.
  initial begin
    log_depth: assert(LOG_DEPTH > 0) else $error("LOG_DEPTH must be greater than 0");
    sync_stages: assert(SYNC_STAGES >= 2) else $error("SYNC_STAGES must be greater than or equal to 2");
  end

endmodule


(* no_ungroup *)
(* no_boundary_optimization *)
module cdc_fifo_gray_src #(
  parameter type T = logic,
  parameter int LOG_DEPTH = 3,
  parameter int SYNC_STAGES = 2
)(
  input  logic src_rst_ni,
  input  logic src_clk_i,
  input  T     src_data_i,
  input  logic src_valid_i,
  output logic src_ready_o,

  output T [2**LOG_DEPTH-1:0] async_data_o,
  output logic [LOG_DEPTH:0]  async_wptr_o,
  input  logic [LOG_DEPTH:0]  async_rptr_i
);

  localparam int PtrWidth = LOG_DEPTH+1;
  localparam logic [PtrWidth-1:0] PtrFull = (1 << LOG_DEPTH);

  T [2**LOG_DEPTH-1:0] data_q, data_d;
  logic [PtrWidth-1:0] wptr_q, wptr_d, wptr_bin, wptr_next, rptr, rptr_bin;

  // Data FIFO.
  assign async_data_o = data_q;

  always_comb begin
    data_d                          = data_q;
    data_d[wptr_bin[LOG_DEPTH-1:0]] = src_data_i;
  end

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      data_q <= '0;
    end else begin
      if (src_valid_i & src_ready_o) begin
        data_q <= data_d;
      end
    end
  end

  // Read pointer.
  for (genvar i = 0; i < PtrWidth; i++) begin : gen_sync
    sync #(.STAGES(SYNC_STAGES)) i_sync (
      .clk_i    ( src_clk_i       ),
      .rst_ni   ( src_rst_ni      ),
      .serial_i ( async_rptr_i[i] ),
      .serial_o ( rptr[i]         )
    );
  end
  gray_to_binary #(PtrWidth) i_rptr_g2b (.A(rptr), .Z(rptr_bin));

  // Write pointer.
  assign wptr_next = wptr_bin+4'd1;
  gray_to_binary #(PtrWidth) i_wptr_g2b (.A(wptr_q), .Z(wptr_bin));
  binary_to_gray #(PtrWidth) i_wptr_b2g (.A(wptr_next), .Z(wptr_d));

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      wptr_q <= '0;
    end else begin
      if (src_valid_i & src_ready_o) begin
        wptr_q <= wptr_d;
      end
    end
  end
  assign async_wptr_o = wptr_q;

  assign src_ready_o = ((wptr_bin ^ rptr_bin) != PtrFull);
endmodule


(* no_ungroup *)
(* no_boundary_optimization *)
module cdc_fifo_gray_dst #(
  parameter type T = logic,
  parameter int LOG_DEPTH = 3,
  parameter int SYNC_STAGES = 2
)(
  input  logic dst_rst_ni,
  input  logic dst_clk_i,
  output T     dst_data_o,
  output logic dst_valid_o,
  input  logic dst_ready_i,

  input  T [2**LOG_DEPTH-1:0] async_data_i,
  input  logic [LOG_DEPTH:0]  async_wptr_i,
  output logic [LOG_DEPTH:0]  async_rptr_o
);

  localparam int PtrWidth = LOG_DEPTH+1;
  localparam logic [PtrWidth-1:0] PtrEmpty = '0;

  T dst_data;
  logic [PtrWidth-1:0] rptr_q, rptr_d, rptr_bin, rptr_bin_d, rptr_next, wptr, wptr_bin;
  logic dst_valid, dst_ready;
  assign dst_data = async_data_i[rptr_bin[LOG_DEPTH-1:0]];

  // Read pointer.
  assign rptr_next = rptr_bin+4'd1;
  gray_to_binary #(PtrWidth) i_rptr_g2b (.A(rptr_q), .Z(rptr_bin));
  binary_to_gray #(PtrWidth) i_rptr_b2g (.A(rptr_next), .Z(rptr_d));
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      rptr_q <= '0;
    end else begin
      if (dst_valid & dst_ready) begin
        rptr_q <= rptr_d;
      end
    end
  end
  assign async_rptr_o = rptr_q;

  // Write pointer.
  for (genvar i = 0; i < PtrWidth; i++) begin : gen_sync
    sync #(.STAGES(SYNC_STAGES)) i_sync (
      .clk_i    ( dst_clk_i       ),
      .rst_ni   ( dst_rst_ni      ),
      .serial_i ( async_wptr_i[i] ),
      .serial_o ( wptr[i]         )
    );
  end
  gray_to_binary #(PtrWidth) i_wptr_g2b (.A(wptr), .Z(wptr_bin));

  assign dst_valid = ((wptr_bin ^ rptr_bin) != PtrEmpty);

  spill_register #(
    .T       ( T           )
  ) i_spill_register (
    .clk_i   ( dst_clk_i   ),
    .rst_ni  ( dst_rst_ni  ),
    .valid_i ( dst_valid   ),
    .ready_o ( dst_ready   ),
    .data_i  ( dst_data    ),
    .valid_o ( dst_valid_o ),
    .ready_i ( dst_ready_i ),
    .data_o  ( dst_data_o  )
  );

endmodule

module gray_to_binary #(
    parameter int N = -1
)(
    input  logic [N-1:0] A,
    output logic [N-1:0] Z
);
    for (genvar i = 0; i < N; i++)
        assign Z[i] = ^A[N-1:i];
endmodule


module binary_to_gray #(
    parameter int N = -1
)(
    input  logic [N-1:0] A,
    output logic [N-1:0] Z
);
    assign Z = A ^ (A >> 1);
endmodule

module spill_register #(
  parameter type T      = logic,
  parameter bit  Bypass = 1'b0   
) (
  input  logic clk_i   ,
  input  logic rst_ni  ,
  input  logic valid_i ,
  output logic ready_o ,
  input  T     data_i  ,
  output logic valid_o ,
  input  logic ready_i ,
  output T     data_o
);

  spill_register_flushable #(
    .T(T),
    .Bypass(Bypass)
  ) spill_register_flushable_i (
    .clk_i,
    .rst_ni,
    .valid_i,
    .flush_i(1'b0),
    .ready_o,
    .data_i,
    .valid_o,
    .ready_i,
    .data_o
  );

endmodule


module spill_register_flushable #(
  parameter type T           = logic,
  parameter bit  Bypass      = 1'b0  
) (
  input  logic clk_i   ,
  input  logic rst_ni  ,
  input  logic valid_i ,
  input  logic flush_i ,
  output logic ready_o ,
  input  T     data_i  ,
  output logic valid_o ,
  input  logic ready_i ,
  output T     data_o
);

  if (Bypass) begin : gen_bypass
    assign valid_o = valid_i;
    assign ready_o = ready_i;
    assign data_o  = data_i;
  end else begin : gen_spill_reg
    T a_data_q;
    logic a_full_q;
    logic a_fill, a_drain;

    always_ff @(posedge clk_i or negedge rst_ni) begin : ps_a_data
      if (!rst_ni)
        a_data_q <= T'('0);
      else if (a_fill)
        a_data_q <= data_i;
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin : ps_a_full
      if (!rst_ni)
        a_full_q <= '0;
      else if (a_fill || a_drain)
        a_full_q <= a_fill;
    end

    T b_data_q;
    logic b_full_q;
    logic b_fill, b_drain;

    always_ff @(posedge clk_i or negedge rst_ni) begin : ps_b_data
      if (!rst_ni)
        b_data_q <= T'('0);
      else if (b_fill)
        b_data_q <= a_data_q;
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin : ps_b_full
      if (!rst_ni)
        b_full_q <= '0;
      else if (b_fill || b_drain)
        b_full_q <= b_fill;
    end

    assign a_fill = valid_i && ready_o && (!flush_i);
    assign a_drain = (a_full_q && !b_full_q) || flush_i;

    assign b_fill = a_drain && (!ready_i) && (!flush_i);
    assign b_drain = (b_full_q && ready_i) || flush_i;

    assign ready_o = !a_full_q || !b_full_q;

    assign valid_o = a_full_q | b_full_q;

    assign data_o = b_full_q ? b_data_q : a_data_q;
  end
endmodule

module sync #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

   (* dont_touch = "true" *)
   (* async_reg = "true" *)
   logic [STAGES-1:0] reg_q;

    always_ff @(posedge clk_i, negedge rst_ni) begin
        if (!rst_ni) begin
            reg_q <= {STAGES{ResetValue}};
        end else begin
            reg_q <= {reg_q[STAGES-2:0], serial_i};
        end
    end

    assign serial_o = reg_q[STAGES-1];

endmodule