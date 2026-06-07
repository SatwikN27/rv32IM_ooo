    
    logic   [2:0]   aluop;
    logic   [31:0]  a;
    logic   [31:0]  b;
    logic   [31:0]  f;

    alu dut(.*);

    initial begin
        a = 32'h800055AA;
        b = 32'h00000004;
        aluop = '0;

        repeat (100) @(posedge clk);
        $finish;
    end

    always @(posedge clk) begin
        aluop <= aluop + 3'd1;
    end