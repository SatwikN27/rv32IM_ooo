module cacheline_adapter
(
    input   logic           clk,
    input   logic           rst,

    input   logic   [31:0]  line_addr,
    input   logic           line_read,
    output  logic   [255:0] line_rdata,
    output  logic           line_resp,
    output  logic           line_busy,

    output  logic   [31:0]  dram_addr,
    output  logic           dram_read,
    output  logic           dram_write,
    output  logic   [63:0]  dram_wdata,
    input   logic           dram_ready,
    input   logic   [31:0]  dram_raddr,
    input   logic   [63:0]  dram_rdata,
    input   logic           dram_rvalid
);

    enum logic [1:0] {
        IDLE,
        REQ,
        WAIT_RESP,
        DONE
    } state, state_next;

    logic   [31:0]  addr_q, addr_d;
    logic           addr_we;

    logic   [255:0] data_q, data_d;
    logic           data_we;

    logic   [1:0]   beat_q, beat_d;
    logic           beat_we;

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            addr_q <= '0;
            data_q <= '0;
            beat_q <= '0;
        end else begin
            state <= state_next;
            if (addr_we) begin
                addr_q <= addr_d;
            end
            if (data_we) begin
                data_q <= data_d;
            end
            if (beat_we) begin
                beat_q <= beat_d;
            end
        end
    end

    always_comb begin
        state_next = state;

        addr_d = 'x;
        addr_we = 1'b0;
        data_d = data_q;
        data_we = 1'b0;
        beat_d = beat_q;
        beat_we = 1'b0;

        line_rdata = data_q;
        line_resp = 1'b0;
        line_busy = (state != IDLE);

        dram_addr = addr_q;
        dram_read = 1'b0;
        dram_write = 1'b0;
        dram_wdata = '0;

        unique case (state)
        IDLE: begin
            if (line_read) begin
                addr_d = {line_addr[31:5], 5'b00000};
                addr_we = 1'b1;
                data_d = '0;
                data_we = 1'b1;
                beat_d = 2'd0;
                beat_we = 1'b1;
                state_next = REQ;
            end
        end
        REQ: begin
            dram_addr = addr_q;
            dram_read = 1'b1;
            if (dram_ready) begin
                state_next = WAIT_RESP;
            end
        end
        WAIT_RESP: begin
            if (dram_rvalid && (dram_raddr[31:5] == addr_q[31:5])) begin
                data_d = data_q;
                data_d[beat_q * 64 +: 64] = dram_rdata;
                data_we = 1'b1;
                beat_d = beat_q + 2'd1;
                beat_we = 1'b1;
                if (beat_q == 2'd3) begin
                    state_next = DONE;
                end
            end
        end
        DONE: begin
            line_resp = 1'b1;
            state_next = IDLE;
        end
        default: begin
            state_next = IDLE;
        end
        endcase
    end

endmodule : cacheline_adapter