`timescale 1ns / 1ps

module tb_alu;

    logic [31:0] a;
    logic [31:0] b;
    logic [3:0]  alu_op;
    logic [31:0] y;
    logic        zero;

    integer errors;

    localparam logic [3:0]
        ALU_ADD  = 4'd0,
        ALU_SUB  = 4'd1,
        ALU_AND  = 4'd2,
        ALU_OR   = 4'd3,
        ALU_XOR  = 4'd4,
        ALU_SLT  = 4'd5,
        ALU_SLTU = 4'd6,
        ALU_SLL  = 4'd7,
        ALU_SRL  = 4'd8,
        ALU_SRA  = 4'd9;

    alu dut (
        .a      (a),
        .b      (b),
        .alu_op (alu_op),
        .y      (y),
        .zero   (zero)
    );

    task automatic check_alu(
        input logic [3:0]  op,
        input logic [31:0] lhs,
        input logic [31:0] rhs,
        input logic [31:0] expected
    );
        begin
            alu_op = op;
            a      = lhs;
            b      = rhs;
            #1;

            if (y !== expected) begin
                $error("ALU failed: op=%0d a=%h b=%h expected=%h got=%h",
                       op, lhs, rhs, expected, y);
                errors++;
            end

            if (zero !== (expected == 32'd0)) begin
                $error("Zero flag failed: op=%0d expected zero=%0d got=%0d",
                       op, (expected == 32'd0), zero);
                errors++;
            end
        end
    endtask

    initial begin
        errors = 0;
        a      = 32'd0;
        b      = 32'd0;
        alu_op = ALU_ADD;

        check_alu(ALU_ADD,  32'd20,       32'd22, 32'd42);
        check_alu(ALU_ADD,  32'hFFFFFFFF, 32'd1,  32'd0);
        check_alu(ALU_SUB,  32'd20,       32'd7,  32'd13);
        check_alu(ALU_SUB,  32'd5,        32'd5,  32'd0);
        check_alu(ALU_AND,  32'hF0F0AA55, 32'h0FF00F0F, 32'h00F00A05);
        check_alu(ALU_OR,   32'hF000000F, 32'h0F0000F0, 32'hFF0000FF);
        check_alu(ALU_XOR,  32'hAAAAAAAA, 32'h55555555, 32'hFFFFFFFF);
        check_alu(ALU_SLT,  32'hFFFFFFFF, 32'd1,  32'd1);
        check_alu(ALU_SLT,  32'd7,        32'd3,  32'd0);
        check_alu(ALU_SLTU, 32'hFFFFFFFF, 32'd1,  32'd0);
        check_alu(ALU_SLTU, 32'd1,        32'hFFFFFFFF, 32'd1);
        check_alu(ALU_SLL,  32'd1,        32'd5,  32'd32);
        check_alu(ALU_SRL,  32'h80000000, 32'd4,  32'h08000000);
        check_alu(ALU_SRA,  32'h80000000, 32'd4,  32'hF8000000);

        if (errors == 0)
            $display("ALL ALU TESTS PASSED");
        else
            $fatal(1, "ALU TESTS FAILED: %0d error(s)", errors);

        $finish;
    end

endmodule
