    
    //----------------------------------------------------------------------
    // Coverage
    //----------------------------------------------------------------------
    `include "coverage.sv"
    cg cg_inst = new;
    
    //----------------------------------------------------------------------
    // DUT instance.
    //----------------------------------------------------------------------
            logic   [2:0]   aluop;
            logic   [31:0]  a, b;
            logic   [31:0]  f;
            logic           valid_i, valid_o;

    alu dut (
        .clk(clk),
        .aluop(aluop),
        .a(a),
        .b(b),
        .valid_i(valid_i),
        .f(f),
        .valid_o(valid_o)
    );

    //----------------------------------------------------------------------
    // Verification helper functions/tasks.
    //----------------------------------------------------------------------
    bit PASSED;

    function sample_cg(bit [31:0] a, bit [31:0] b, bit [2:0] op);
        cg_inst.sample(a, b, op, b[4:0]);
    endfunction : sample_cg

    `include "verify.sv"

    //----------------------------------------------------------------------
    // Main process.
    //----------------------------------------------------------------------
    initial begin
        bit passed;
        repeat (2) @(posedge clk);

        verify_alu(passed);

        if (passed) begin
            $finish;
        end else begin
            $error("TB Error: Verification Failed");
            $fatal;
        end
    end

    //----------------------------------------------------------------------
    // Final coverage checking.
    //----------------------------------------------------------------------
    `include "final.sv"