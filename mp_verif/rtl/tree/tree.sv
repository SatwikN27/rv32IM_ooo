module tree(
    input   logic           clk,
    input   logic   [15:0]  a,
    output  logic           b
);

            logic   [15:0]  a_reg;
            logic   [7:0]   intermediate1;
            logic   [3:0]   intermediate2;
            logic   [1:0]   intermediate3;
            logic   [1:0]   intermediate3_reg;
            logic           intermediate4;

    always_ff @(posedge clk) begin
        a_reg <= a;
    end

    always_comb begin
        intermediate1 = a_reg[15:8] & a_reg[7:0];
        intermediate2 = intermediate1[7:4] ^ intermediate1[3:0];
        intermediate3 = intermediate2[3:2] | intermediate2[1:0];
    end

    always_ff @(posedge clk) begin
        intermediate3_reg <= intermediate3;
    end

    always_comb begin
        intermediate4 = intermediate3_reg[1] ^ intermediate3_reg[0];
    end

    always_ff @(posedge clk) begin
        b <= intermediate4;
    end

endmodule