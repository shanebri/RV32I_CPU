`timescale 1ns / 1ps

module dmem_mmio #(
    parameter WORDS = 1024
)(
    input  logic        clk,
    input  logic        rst,
    input  logic        mem_read,
    input  logic        mem_write,
    input  logic [31:0] addr,
    input  logic [31:0] wdata,
    output logic [31:0] rdata,
    output logic [31:0] gpio_out
);

    localparam logic [31:0] GPIO_ADDR = 32'h1000_0000;

    logic [31:0] mem [0:WORDS-1];

    always_ff @(posedge clk) begin
        if (rst) begin
            gpio_out <= 32'd0;
        end
        else if (mem_write) begin
            if (addr == GPIO_ADDR)
                gpio_out <= wdata;
            else
                mem[addr[11:2]] <= wdata;
        end
    end

    always_comb begin
        if (mem_read) begin
            if (addr == GPIO_ADDR)
                rdata = gpio_out;
            else
                rdata = mem[addr[11:2]];
        end
        else begin
            rdata = 32'd0;
        end
    end

endmodule