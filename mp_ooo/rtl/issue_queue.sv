module alu_issue_queue (
    input   logic               clk,
    input   logic               rst,

    input   logic               valid,
    input   logic   [63:0]      order,
    
    input   logic   [5:0]       prd,
    input   logic   [5:0]       ps1,
    input   logic   [5:0]       ps2,
    input   logic   []
); 

endmodule: alu_issue_queue