    //----------------------------------------------------------------------
    // DUT instance.
    //----------------------------------------------------------------------

    logic ack;

    loop dut(
        .clk(clk),
        .rst(rst),
        .ack(ack)
    );

    //----------------------------------------------------------------------
    // Verification tasks/functions
    //----------------------------------------------------------------------
    task verify_loop();
        @(posedge clk);

        repeat (100) begin
            repeat (15) @(posedge clk);
            if (!ack) begin
                $error("TB Error: Verification Failed");
                $fatal;
            end
        end
    endtask : verify_loop

    //----------------------------------------------------------------------
    // Main process.
    //----------------------------------------------------------------------
    initial begin
        repeat (2) @(posedge clk);
        verify_loop();
        $finish;
    end

