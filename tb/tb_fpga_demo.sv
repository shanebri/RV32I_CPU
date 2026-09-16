`timescale 1ns / 1ps

// Execute the committed program.hex through the actual FPGA wrapper.
module tb_fpga_demo;
    logic clk = 0;
    logic rst = 1;
    logic [3:0] led;
    top dut (.CLK100MHZ(clk), .btn0(rst), .led(led));
    always #5 clk = ~clk;

    task automatic run_demo;
        repeat (100) @(negedge clk);
        if (led !== 4'b1010 || dut.gpio_out !== 32'd10)
            $fatal(1, "LED demo failed: GPIO=%h LEDs=%b", dut.gpio_out, led);
    endtask

    initial begin
        repeat (3) @(negedge clk);
        if (led !== 4'b0000) $fatal(1, "Reset did not clear LEDs");
        rst = 0;
        run_demo();
        rst = 1;
        repeat (3) @(negedge clk);
        if (led !== 4'b0000) $fatal(1, "Button reset did not clear LEDs");
        rst = 0;
        run_demo();
        $display("ALL FPGA DEMO TESTS PASSED");
        $finish;
    end
endmodule
