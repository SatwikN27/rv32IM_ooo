    
    //----------------------------------------------------------------------
    // DUT instance.
    //----------------------------------------------------------------------

    logic   [15:0]  a;
    logic           b;

    tree dut(
        .clk(clk),
        .a(a),
        .b(b)
    );

    //----------------------------------------------------------------------
    // Verification tasks/functions
    //----------------------------------------------------------------------
    task verify_tree();
        bit [15:0] a0;
        bit [7:0]  a1;
        bit [3:0]  a2;
        bit [1:0]  a3;
        bit        expected_b;

        @(posedge clk);

        for (int i = 0; i <= 2**16; i++) begin
            a0 = 16'(i);
            a1 = a0[15:8] & a0[7:0];
            a2 = a1[7:4] ^ a1[3:0];
            a3 = a2[3:2] | a2[1:0];
            expected_b = a3[1] ^ a3[0];

            a <= a0;
            repeat (4) @(posedge clk);

            if (b !== expected_b) begin
                $error("Expected b value of %x, got %x", expected_b, b);
                $error("TB Error: Verification Failed");
                $fatal;
            end
        end

    endtask : verify_tree

    //----------------------------------------------------------------------
    // Main process.
    //----------------------------------------------------------------------
    initial begin
        repeat (2) @(posedge clk);
        verify_tree();
        $finish;
    end

