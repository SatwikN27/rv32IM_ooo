task verify_alu(output bit passed);
    bit [31:0] a_rand;
    bit [31:0] b_rand;
    bit [31:0] exp_f;

    passed = 1'b1;

    // TODO: Modify this code to cover all coverpoints in coverage.sv.
    for (int i = 0; i <= 6; ++i) begin
        std::randomize(a_rand);
        // TODO: Randomize b_rand using std::randomize.

        // TODO: Call the sample_cg function with the right arguments.
        // This tells the covergroup about what stimulus you sent
        // to the DUT.

        // sample_cg(...);

        case (i)
            0: exp_f = a_rand & b_rand;
            1: exp_f = a_rand | b_rand;
            // TODO: Fill out the rest of the operations.
        endcase

        // TODO: Drive the operand and op to DUT
        // Make sure you use non-blocking assignment (<=)

        // a <= a_rand;
        // b <= ...
        // aluop <= ...
        // valid_i <= 1'b1;

        // TODO: Wait one cycle for DUT to get the signal, then deassert valid

        // @(posedge clk)
        // valid_i <= ...

        // TODO: Wait for the valid_o signal to come out of the ALU
        // and check the result with the expected value,
        // modify the function output
        // "passed" if needed to tell top_tb if the ALU failed

        // @(posedge clk iff ...);

    end

endtask : verify_alu