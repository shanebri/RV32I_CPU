`timescale 1ns / 1ps

module tb_dmem;

    logic        clk;
    logic        mem_read;
    logic        mem_write;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic [31:0] rdata;

    integer errors;

    dmem_mmio #(.WORDS(64)) dut (
        .clk       (clk),
        .mem_read  (mem_read),
        .mem_write (mem_write),
        .addr      (addr),
        .wdata     (wdata),
        .rdata     (rdata)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task automatic write_word(input logic [31:0] address, input logic [31:0] data);
        begin
            addr      = address;
            wdata     = data;
            mem_write = 1'b1;
            mem_read  = 1'b0;
            @(posedge clk);
            #1;
            mem_write = 1'b0;
        end
    endtask

    task automatic check_read(input logic [31:0] address, input logic [31:0] expected);
        begin
            addr     = address;
            mem_read = 1'b1;
            #1;
            if (rdata !== expected) begin
                $error("DMEM read failed at %h: expected=%h got=%h", address, expected, rdata);
                errors++;
            end
            mem_read = 1'b0;
            #1;
            if (rdata !== 32'd0) begin
                $error("DMEM read-disable failed: expected 0 got=%h", rdata);
                errors++;
            end
        end
    endtask

    initial begin
        errors    = 0;
        mem_read  = 1'b0;
        mem_write = 1'b0;
        addr      = 32'd0;
        wdata     = 32'd0;

        write_word(32'h00000000, 32'h11223344);
        write_word(32'h00000004, 32'hA5A5A5A5);
        write_word(32'h00000010, 32'hDEADBEEF);

        check_read(32'h00000000, 32'h11223344);
        check_read(32'h00000004, 32'hA5A5A5A5);
        check_read(32'h00000010, 32'hDEADBEEF);

        write_word(32'h00000004, 32'h12345678);
        check_read(32'h00000004, 32'h12345678);

        if (errors == 0)
            $display("ALL DMEM TESTS PASSED");
        else
            $fatal(1, "DMEM TESTS FAILED: %0d error(s)", errors);

        $finish;
    end

endmodule
