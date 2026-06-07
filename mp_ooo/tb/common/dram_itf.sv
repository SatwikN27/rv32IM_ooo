interface dram_if(
    input   bit             clk,
    input   bit             rst
);

    logic   [31:0]          addr;
    logic                   read;
    logic                   write;
    logic   [63:0]          wdata;
    logic                   ready;
    logic   [31:0]          raddr;
    logic   [63:0]          rdata;
    logic                   rvalid;

    bit                     error = 1'b0;

    modport cpu (
        input               clk,
        input               rst,
        output              addr,
        output              read,
        output              write,
        output              wdata,
        input               ready,
        input               raddr,
        input               rdata,
        input               rvalid
    );

    modport dram (
        input               clk,
        input               rst,
        input               addr,
        input               read,
        input               write,
        input               wdata,
        output              ready,
        output              rdata,
        output              raddr,
        output              rvalid,
        output              error
    );

endinterface
