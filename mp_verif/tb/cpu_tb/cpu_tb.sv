
    mem_itf mem_itf(.*);
    mon_itf  mon_itf(.clk(clk), .rst(rst));
    

    // Pick one of the two options (only one of these should be uncommented at a time):
    // If using random_tb, set SPIKE_DPI to 0, else set it to 1.
    memory_model memory_model(.itf(mem_itf)); // For directed testing with PROG
    // random_tb random_tb(.itf(mem_itf)); // PROG needs to be still set, but not used.

    monitor  #(.SPIKE_DPI(1)) monitor(.mon_itf(mon_itf));


    cpu dut(
        .clk          (clk),
        .rst          (rst),
        .mem_addr     (mem_itf.addr),
        .mem_rmask    (mem_itf.rmask),
        .mem_wmask    (mem_itf.wmask),
        .mem_rdata    (mem_itf.rdata),
        .mem_wdata    (mem_itf.wdata),
        .mem_resp     (mem_itf.resp)
    );

    always @(posedge clk) begin
        if (mon_itf.halt) begin
            $finish;
        end
        if (mon_itf.error != 0) begin
            $fatal;
        end
    end

    `include `RVFI_REFERENCE_FILE
