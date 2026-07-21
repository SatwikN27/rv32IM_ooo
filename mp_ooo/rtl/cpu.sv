module cpu
(
    input   logic               clk,
    input   logic               rst,

    output  logic   [31:0]      dram_addr,
    output  logic               dram_read,
    output  logic               dram_write,
    output  logic   [63:0]      dram_wdata,
    input   logic               dram_ready,

    input   logic   [31:0]      dram_raddr,
    input   logic   [63:0]      dram_rdata,
    input   logic               dram_rvalid

);

    import rv32im_types::*;

    logic   [31:0]  fetch_line_addr;
    logic           fetch_line_read;
    logic   [255:0] fetch_line_rdata;
    logic           fetch_line_resp;
    logic           fetch_line_busy;

    logic           fetch_valid;
    logic   [31:0]  fetch_pc;
    logic   [31:0]  fetch_inst;

    decoded_inst_t  decoded_inst;
    logic           rename_stall;

    fetch fetch_i (
        .clk            (clk),
        .rst            (rst),

        .line_addr      (fetch_line_addr),
        .line_read      (fetch_line_read),
        .line_rdata     (fetch_line_rdata),
        .line_resp      (fetch_line_resp),
        .line_busy      (fetch_line_busy),

        .fetch_ready    (!rename_stall),
        .fetch_valid    (fetch_valid),
        .fetch_pc       (fetch_pc),
        .fetch_inst     (fetch_inst)
    );

    decode_rename decode_rename_i (
        .clk            (clk),
        .rst            (rst),

        .valid          (fetch_valid),
        .inst           (fetch_inst),
        .pc             (fetch_pc),
        .order          (64'b0),
        .free_flag      (1'b0),
        .pr_addr_free   (6'b000000),

        .decoded        (decoded_inst),
        .rename_stall   (rename_stall)
    );

    cacheline_adapter cacheline_adapter_i (
        .clk            (clk),
        .rst            (rst),

        .line_addr      (fetch_line_addr),
        .line_read      (fetch_line_read),
        .line_rdata     (fetch_line_rdata),
        .line_resp      (fetch_line_resp),
        .line_busy      (fetch_line_busy),

        .dram_addr      (dram_addr),
        .dram_read      (dram_read),
        .dram_write     (dram_write),
        .dram_wdata     (dram_wdata),
        .dram_ready     (dram_ready),
        .dram_raddr     (dram_raddr),
        .dram_rdata     (dram_rdata),
        .dram_rvalid    (dram_rvalid)
    );

endmodule : cpu
