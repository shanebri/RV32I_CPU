`timescale 1ns / 1ps

module top (
    input  logic       CLK100MHZ,
    input  logic       btn0,
    output logic [3:0] led
);

    logic [31:0] gpio_out;

    rv32i_core u_core (
        .clk      (CLK100MHZ),
        .rst      (btn0),
        .gpio_out (gpio_out)
    );

    assign led = gpio_out[3:0];

endmodule