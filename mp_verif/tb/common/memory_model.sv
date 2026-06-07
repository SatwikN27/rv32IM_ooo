module memory_model #(
    parameter DELAY = 3
)(
    mem_itf.mem itf
);

    string memfile;
    initial begin
        $value$plusargs("PROGRAM_HEX=%s", memfile);
    end

    logic [31:0] internal_memory_array [logic [31:2]];

    enum int {
        MEMORY_STATE_IDLE,
        MEMORY_STATE_READ,
        MEMORY_STATE_WRITE
    } state;

    int delay_counter;

    always_ff @(posedge itf.clk) begin
        if (itf.rst) begin
            internal_memory_array.delete();
            $readmemh(memfile, internal_memory_array);
            $display("using memory file %s", memfile);
            state <= MEMORY_STATE_IDLE;
            delay_counter <= '0;
            itf.resp <= 1'b0;
            itf.rdata <= 'x;
        end else begin
            itf.resp <= 1'b0;
            itf.rdata <= 'x;
            unique case (state)
            MEMORY_STATE_IDLE: begin
                if (|itf.rmask) begin
                    state <= MEMORY_STATE_READ;
                    delay_counter <= DELAY;
                end
                if (|itf.wmask) begin
                    state <= MEMORY_STATE_WRITE;
                    delay_counter <= DELAY;
                end
            end
            MEMORY_STATE_READ: begin
                if (delay_counter == 2) begin
                    automatic logic [31:0] rdata_xmask;
                    itf.resp <= 1'b1;
                    for (int i = 0; i < 4; i++) begin
                        if (itf.rmask[i]) begin
                            rdata_xmask[i*8 +: 8] = '0;
                        end else begin
                            rdata_xmask[i*8 +: 8] = 'x;
                        end
                    end
                    itf.rdata <= internal_memory_array[itf.addr[31:2]] ^ rdata_xmask;
                end
                if (delay_counter == 1) begin
                    state <= MEMORY_STATE_IDLE;
                end
                delay_counter <= delay_counter - 1;
            end
            MEMORY_STATE_WRITE: begin
                if (delay_counter == 2) begin
                    itf.resp <= 1'b1;
                end
                if (delay_counter == 1) begin
                    for (int i = 0; i < 4; i++) begin
                        if (itf.wmask[i]) begin
                            internal_memory_array[itf.addr[31:2]][i*8 +: 8] = itf.wdata[i*8 +: 8];
                        end
                    end
                    state <= MEMORY_STATE_IDLE;
                end
                delay_counter <= delay_counter - 1;
            end
            endcase
        end
    end

    logic [31:0] cached_addr;
    logic [3:0] cached_mask;

    always_ff @(posedge itf.clk) begin
        if (|itf.rmask) begin
            cached_addr <= itf.addr;
            cached_mask <= itf.rmask;
        end
        if (|itf.wmask) begin
            cached_addr <= itf.addr;
            cached_mask <= itf.wmask;
        end
    end

    always @(posedge itf.clk iff !itf.rst) begin
        if ($isunknown(itf.rmask) || $isunknown(itf.wmask)) begin
            $error("Memory Error: mask containes 'x");
            itf.error <= 1'b1;
        end
        if ((|itf.rmask) && (|itf.wmask)) begin
            $error("Memory Error: simultaneous memory read and write");
            itf.error <= 1'b1;
        end
        if ((|itf.rmask) || (|itf.wmask)) begin
            if ($isunknown(itf.addr)) begin
                $error("Memory Error: address contained 'x");
                itf.error <= 1'b1;
            end
            if (itf.addr[1:0] != 2'b00) begin
                $error("Memory Error: address is not 32-bit aligned");
                itf.error <= 1'b1;
            end
        end

        case (state)
        MEMORY_STATE_READ: begin
            if (itf.addr != cached_addr) begin
                $error("Memory Error: address changed");
                itf.error <= 1'b1;
            end
            if (itf.rmask != cached_mask) begin
                $error("Memory Error: mask changed");
                itf.error <= 1'b1;
            end
        end
        MEMORY_STATE_WRITE: begin
            if (itf.addr != cached_addr) begin
                $error("Memory Error: address changed");
                itf.error <= 1'b1;
            end
            if (itf.wmask != cached_mask) begin
                $error("Memory Error: mask changed");
                itf.error <= 1'b1;
            end
        end
        endcase
    end

endmodule