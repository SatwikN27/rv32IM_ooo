module cpu
(
    input   logic               clk,
    input   logic               rst,

    output  logic   [31:0]      dram_addr,
    output  logic               dram_read,
    output  logic               dram_write,
    output  logic   [63:0]      dram_wdata,
    input   logic               dram_ready,

    input   logic   [31:0]      dram_raddr,
    input   logic   [63:0]      dram_rdata,
    input   logic               dram_rvalid

);   
    
endmodule : cpu