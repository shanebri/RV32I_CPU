`timescale 1ns / 1ps

module dmem_mmio #(
    parameter WORDS = 1024
)(
    input  logic        clk,
    input  logic        mem_read,
    input  logic        mem_write,
    input  logic [31:0] addr,
    input  logic [31:0] wdata,
    output logic [31:0] rdata
);

    logic [31:0] mem [0:WORDS-1];

    always_ff @(posedge clk) begin
        if (mem_write)
            mem[addr[11:2]] <= wdata;
    end

    always_comb begin
        if (mem_read)
            rdata = mem[addr[11:2]];
        else
            rdata = 32'd0;
    end

endmodule