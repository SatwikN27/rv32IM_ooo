module memory_model(
    input   logic               clk,
    input   logic               dram_clk,
    input   logic               rst,

    dram_if.dram                 dram_if
);

    import "DPI-C" context function void ram_init(string cfgfile, string elffile);
    import "DPI-C" context function void ram_tick();
    import "DPI-C" context function int  ram_can_accept();
    import "DPI-C" context function int  ram_push_req(
        input int unsigned addr,
        input int we,
        input bit [255:0] wdata  
    );
    import "DPI-C" context function int  ram_has_resp();
    import "DPI-C" context function int  ram_get_resp(
        output int unsigned addr,
        output bit [255:0] rdata 
    );

    string cfgfile, elffile;
    initial begin
        $value$plusargs("MEM_CFG=%s", cfgfile);
        $value$plusargs("PROGRAM_ELF=%s", elffile);
        ram_init(cfgfile, elffile);
    end

    always_ff @(posedge dram_clk) begin
        if (!rst) begin
            ram_tick();
        end
    end

    typedef struct packed {
        logic [31:0] addr;
        logic        we;
        logic [255:0] wdata;
    } ram_req_t;

    typedef struct packed {
        logic [31:0] addr;
        logic [255:0] rdata;
    } ram_resp_t;

    // Request CDC FIFO signals (clk -> dram_clk)
    ram_req_t req_fifo_data_in, req_fifo_data_out;
    logic req_fifo_valid_in, req_fifo_ready_out;
    logic req_fifo_valid_out, req_fifo_ready_in;

    // Response CDC FIFO signals (dram_clk -> clk)
    ram_resp_t resp_fifo_data_in, resp_fifo_data_out;
    logic resp_fifo_valid_in, resp_fifo_ready_out;
    logic resp_fifo_valid_out, resp_fifo_ready_in;

    cdc_fifo_gray #(
        .T(ram_req_t),
        .LOG_DEPTH(3),  // 8 entries
        .SYNC_STAGES(2)
    ) req_cdc_fifo (
        .src_rst_ni(~rst),
        .src_clk_i(clk),
        .src_data_i(req_fifo_data_in),
        .src_valid_i(req_fifo_valid_in),
        .src_ready_o(req_fifo_ready_out),

        .dst_rst_ni(~rst),
        .dst_clk_i(dram_clk),
        .dst_data_o(req_fifo_data_out),
        .dst_valid_o(req_fifo_valid_out),
        .dst_ready_i(req_fifo_ready_in)
    );

    // Instantiate response CDC FIFO (DRAM clk -> CPU clk)
    cdc_fifo_gray #(
        .T(ram_resp_t),
        .LOG_DEPTH(3),  // 8 entries
        .SYNC_STAGES(2)
    ) resp_cdc_fifo (
        .src_rst_ni(~rst),
        .src_clk_i(dram_clk),
        .src_data_i(resp_fifo_data_in),
        .src_valid_i(resp_fifo_valid_in),
        .src_ready_o(resp_fifo_ready_out),

        .dst_rst_ni(~rst),
        .dst_clk_i(clk),
        .dst_data_o(resp_fifo_data_out),
        .dst_valid_o(resp_fifo_valid_out),
        .dst_ready_i(resp_fifo_ready_in)
    );




    
    // ========================================================================
    // CPU Clock Domain - Request Generation
    // ========================================================================
    logic [1:0] write_beat_count;
    logic [255:0] write_data_accum;
    logic [31:0] write_addr_hold;
    logic write_in_progress;
    logic write_pending;
    logic [31:0] write_pending_addr;
    logic [255:0] write_pending_data;

    logic [31:0] resp_addr_internal;
    logic [255:0] resp_data_internal;
    logic [1:0] resp_beat_count;
    logic resp_active;

    assign dram_if.ready = write_in_progress || (req_fifo_ready_out && !write_pending);

    always_ff @(posedge clk) begin
        if (rst) begin
            write_beat_count <= 2'd0;
            write_data_accum <= 256'd0;
            write_addr_hold <= 32'd0;
            write_in_progress <= 1'b0;
            write_pending <= 1'b0;
            write_pending_addr <= 32'd0;
            write_pending_data <= 256'd0;
            req_fifo_valid_in <= 1'b0;
            req_fifo_data_in <= '0;
            resp_active <= 1'b0;
            resp_beat_count <= 2'd0;
            resp_addr_internal <= 32'd0;
            resp_data_internal <= 256'd0;
        end else begin
            req_fifo_valid_in <= 1'b0;

            // ====== Write Request Logic ======
            if (dram_if.write) begin
                if (!write_in_progress) begin
                    write_in_progress <= 1'b1;
                    write_beat_count <= 2'd0;
                    write_addr_hold <= dram_if.addr;
                    write_data_accum[63:0] <= dram_if.wdata;
                end else begin
                    write_beat_count <= write_beat_count + 2'd1;
                    case (write_beat_count)
                        2'd0: write_data_accum[127:64] <= dram_if.wdata;
                        2'd1: write_data_accum[191:128] <= dram_if.wdata;
                        2'd2: write_data_accum[255:192] <= dram_if.wdata;
                    endcase

                    if (write_beat_count == 2'd2) begin
                        write_in_progress <= 1'b0;
                        write_beat_count <= 2'd0;

                        if (req_fifo_ready_out) begin
                            req_fifo_valid_in <= 1'b1;
                            req_fifo_data_in.addr <= write_addr_hold;
                            req_fifo_data_in.we <= 1'b1;
                            req_fifo_data_in.wdata <= {dram_if.wdata, write_data_accum[191:0]};
                        end else begin
                            write_pending <= 1'b1;
                            write_pending_addr <= write_addr_hold;
                            write_pending_data <= {dram_if.wdata, write_data_accum[191:0]};
                        end
                    end
                end
            end else if (write_pending && req_fifo_ready_out) begin
                req_fifo_valid_in <= 1'b1;
                req_fifo_data_in.addr <= write_pending_addr;
                req_fifo_data_in.we <= 1'b1;
                req_fifo_data_in.wdata <= write_pending_data;
                write_pending <= 1'b0;
            end else if (dram_if.read && req_fifo_ready_out && !write_pending) begin
                req_fifo_valid_in <= 1'b1;
                req_fifo_data_in.addr <= dram_if.addr;
                req_fifo_data_in.we <= 1'b0;
                req_fifo_data_in.wdata <= '0;
            end

            // Check if new response available from CDC FIFO
            if (!resp_active && resp_fifo_valid_out) begin
                resp_addr_internal <= resp_fifo_data_out.addr;
                resp_data_internal <= resp_fifo_data_out.rdata;
                resp_active <= 1'b1;
                resp_beat_count <= 2'd0;
            end else if (resp_active) begin
                if (resp_beat_count == 2'd3) begin
                    if (resp_fifo_valid_out) begin
                        resp_addr_internal <= resp_fifo_data_out.addr;
                        resp_data_internal <= resp_fifo_data_out.rdata;
                        resp_beat_count <= 2'd0;
                    end else begin
                        resp_active <= 1'b0;
                        resp_beat_count <= 2'd0;
                    end
                end else begin
                    resp_beat_count <= resp_beat_count + 2'd1;
                end
            end
        end
    end

    // ========================================================================
    // CPU Clock Domain - Response Outputs
    // ========================================================================
    assign dram_if.rvalid = resp_active;
    assign dram_if.raddr = resp_addr_internal;

    always_comb begin
        case (resp_beat_count)
            2'd0: dram_if.rdata = resp_data_internal[63:0];
            2'd1: dram_if.rdata = resp_data_internal[127:64];
            2'd2: dram_if.rdata = resp_data_internal[191:128];
            2'd3: dram_if.rdata = resp_data_internal[255:192];
        endcase
    end

    assign resp_fifo_ready_in = !resp_active || (resp_beat_count == 2'd3);

    // ========================================================================
    // DRAM Clock Domain - DPI-C Interface
    // ========================================================================
    int req_success;
    int has_resp;
    int can_accept;
    int unsigned dram_resp_addr;
    bit [255:0] dram_resp_data;

    assign req_fifo_ready_in = (can_accept != 0);

    always_ff @(posedge dram_clk) begin
        if (rst) begin
            resp_fifo_valid_in <= 1'b0;
            resp_fifo_data_in <= '0;
            can_accept <= 0;
        end else begin
            resp_fifo_valid_in <= 1'b0;

            can_accept = ram_can_accept();

            if (req_fifo_valid_out && req_fifo_ready_in) begin
                req_success = ram_push_req(
                    req_fifo_data_out.addr,
                    req_fifo_data_out.we,
                    req_fifo_data_out.wdata
                );
                if (!req_success) begin
                    $display("Error: ram_push_req failed for addr=0x%h, we=%b",
                             req_fifo_data_out.addr, req_fifo_data_out.we);
                end
            end

            has_resp = ram_has_resp();
            if (has_resp && resp_fifo_ready_out) begin
                ram_get_resp(dram_resp_addr, dram_resp_data);
                resp_fifo_valid_in <= 1'b1;
                resp_fifo_data_in.addr <= dram_resp_addr;
                resp_fifo_data_in.rdata <= dram_resp_data;
            end else if (has_resp && !resp_fifo_ready_out) begin
                $display("Warning: Response FIFO full, response from DPI-C will be delayed");
            end
        end
    end

endmodule
