`timescale 1ns / 1ps

module tb_regfile;

    logic        clk;
    logic        we;
    logic [4:0]  rs1;
    logic [4:0]  rs2;
    logic [4:0]  rd;
    logic [31:0] wd;
    logic [31:0] rd1;
    logic [31:0] rd2;

    integer errors;

    regfile dut (
        .clk (clk),
        .we  (we),
        .rs1 (rs1),
        .rs2 (rs2),
        .rd  (rd),
        .wd  (wd),
        .rd1 (rd1),
        .rd2 (rd2)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task automatic write_reg(input logic [4:0] reg_num, input logic [31:0] value);
        begin
            rd = reg_num;
            wd = value;
            we = 1'b1;
            @(posedge clk);
            #1;
            we = 1'b0;
        end
    endtask

    task automatic check_read(
        input logic [4:0] in_rs1,
        input logic [4:0] in_rs2,
        input logic [31:0] exp1,
        input logic [31:0] exp2,
        input string name
    );
        begin
            rs1 = in_rs1;
            rs2 = in_rs2;
            #1;
            if ((rd1 !== exp1) || (rd2 !== exp2)) begin
                $error("%s failed: rd1 expected=%h got=%h rd2 expected=%h got=%h",
                       name, exp1, rd1, exp2, rd2);
                errors++;
            end
        end
    endtask

    initial begin
        errors = 0;
        we = 1'b0;
        rs1 = 5'd0;
        rs2 = 5'd0;
        rd = 5'd0;
        wd = 32'd0;

        check_read(5'd0, 5'd0, 32'd0, 32'd0, "x0 initial read");

        write_reg(5'd1, 32'h11111111);
        write_reg(5'd2, 32'h22222222);
        check_read(5'd1, 5'd2, 32'h11111111, 32'h22222222, "normal register reads");

        write_reg(5'd0, 32'hDEADBEEF);
        check_read(5'd0, 5'd1, 32'd0, 32'h11111111, "x0 remains zero");

        rs1 = 5'd3;
        rs2 = 5'd2;
        rd  = 5'd3;
        wd  = 32'hCAFEBABE;
        we  = 1'b1;
        #1;
        if (rd1 !== 32'hCAFEBABE) begin
            $error("write-through bypass failed: expected CAFEBABE got=%h", rd1);
            errors++;
        end
        @(posedge clk);
        #1;
        we = 1'b0;
        check_read(5'd3, 5'd2, 32'hCAFEBABE, 32'h22222222, "committed bypass value");

        if (errors == 0)
            $display("ALL REGFILE TESTS PASSED");
        else
            $fatal(1, "REGFILE TESTS FAILED: %0d error(s)", errors);

        $finish;
    end

endmodule
