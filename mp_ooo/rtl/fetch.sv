module fetch
(
    input   logic           clk,
    input   logic           rst,

    output  logic   [31:0]  line_addr,
    output  logic           line_read,
    input   logic   [255:0] line_rdata,
    input   logic           line_resp,
    input   logic           line_busy,

    input   logic           fetch_ready,
    output  logic           fetch_valid,
    output  logic   [31:0]  fetch_pc,
    output  logic   [31:0]  fetch_inst
);

    enum logic [1:0] {
        READY,
        MISS_WAIT
    } state, state_next;

    logic   [31:0]  pc_q, pc_d;
    logic           pc_we;

    logic   [255:0] linebuffer_q, linebuffer_d;
    logic           linebuffer_we;

    logic   [26:0]  line_tag_q, line_tag_d;
    logic           line_tag_we;

    logic           line_valid_q, line_valid_d;
    logic           line_valid_we;

    logic           line_hit;
    logic   [31:0]  buffered_inst;
    logic           take_inst;

    assign line_hit = line_valid_q && (line_tag_q == pc_q[31:5]);
    assign buffered_inst = linebuffer_q[pc_q[4:2] * 32 +: 32];
    assign take_inst = fetch_ready && line_hit;

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= READY;
            pc_q <= 32'haaaaa000;
            linebuffer_q <= '0;
            line_tag_q <= '0;
            line_valid_q <= 1'b0;
        end else begin
            state <= state_next;
            if (pc_we) begin
                pc_q <= pc_d;
            end
            if (linebuffer_we) begin
                linebuffer_q <= linebuffer_d;
            end
            if (line_tag_we) begin
                line_tag_q <= line_tag_d;
            end
            if (line_valid_we) begin
                line_valid_q <= line_valid_d;
            end
        end
    end

    always_comb begin
        state_next = state;

        pc_d = 'x;
        pc_we = 1'b0;
        linebuffer_d = 'x;
        linebuffer_we = 1'b0;
        line_tag_d = 'x;
        line_tag_we = 1'b0;
        line_valid_d = 'x;
        line_valid_we = 1'b0;

        line_addr = {pc_q[31:5], 5'b00000};
        line_read = 1'b0;

        fetch_valid = line_hit;
        fetch_pc = pc_q;
        fetch_inst = buffered_inst;

        unique case (state)
        READY: begin
            if (take_inst) begin
                pc_d = pc_q + 32'd4;
                pc_we = 1'b1;
            end else if (!line_hit && !line_busy) begin
                line_read = 1'b1;
                state_next = MISS_WAIT;
            end
        end
        MISS_WAIT: begin
            if (line_resp) begin
                linebuffer_d = line_rdata;
                linebuffer_we = 1'b1;
                line_tag_d = pc_q[31:5];
                line_tag_we = 1'b1;
                line_valid_d = 1'b1;
                line_valid_we = 1'b1;
                state_next = READY;
            end
        end
        default: begin
            state_next = READY;
        end
        endcase
    end

endmodule : fetch
