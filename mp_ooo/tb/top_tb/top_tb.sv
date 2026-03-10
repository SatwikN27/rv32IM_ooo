    
    dram_if dram(.clk(clk), .rst(rst));
    mon_itf #(.CHANNELS(`RVFI_CHANNELS)) mon_itf(.clk(clk), .rst(rst));
    monitor #(.CHANNELS(`RVFI_CHANNELS)) monitor(.mon_itf(mon_itf));

    cpu dut(
        .clk            (clk),
        .rst            (rst),

        .dram_addr  (dram.addr  ),
        .dram_read  (dram.read  ),
        .dram_write (dram.write ),
        .dram_wdata (dram.wdata ),
        .dram_ready (dram.ready ),
        .dram_raddr (dram.raddr ),
        .dram_rdata (dram.rdata ),
        .dram_rvalid(dram.rvalid)
    );

    memory_model memory_model(
        .clk(clk),
        .dram_clk(dram_clk),
        .rst(rst),

        .dram_if(dram.dram)
    );

    always @(posedge clk) begin
        if (mon_itf.halt) begin
            $finish;
        end
        if (mon_itf.error != 0 || dram.error != 0) begin
            $fatal;
        end
    end

    `include `RVFI_REFERENCE_FILE