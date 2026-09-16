`timescale 1ns / 1ps

module tb_forwarding;

    logic [4:0] rs1_ex;
    logic [4:0] rs2_ex;
    logic [4:0] rd_mem;
    logic       reg_write_mem;
    logic [4:0] rd_wb;
    logic       reg_write_wb;
    logic [1:0] forward_a;
    logic [1:0] forward_b;

    integer errors;

    localparam logic [1:0]
        REG_FILE     = 2'b00,
        EXMEM_BYPASS = 2'b01,
        MEMWB_BYPASS = 2'b10;

    forwarding_unit dut (
        .rs1_ex        (rs1_ex),
        .rs2_ex        (rs2_ex),
        .rd_mem        (rd_mem),
        .reg_write_mem (reg_write_mem),
        .rd_wb         (rd_wb),
        .reg_write_wb  (reg_write_wb),
        .forward_a     (forward_a),
        .forward_b     (forward_b)
    );

    task automatic check(
        input logic [4:0] in_rs1,
        input logic [4:0] in_rs2,
        input logic [4:0] in_rd_mem,
        input logic       in_we_mem,
        input logic [4:0] in_rd_wb,
        input logic       in_we_wb,
        input logic [1:0] exp_a,
        input logic [1:0] exp_b,
        input string      name
    );
        begin
            rs1_ex        = in_rs1;
            rs2_ex        = in_rs2;
            rd_mem        = in_rd_mem;
            reg_write_mem = in_we_mem;
            rd_wb         = in_rd_wb;
            reg_write_wb  = in_we_wb;
            #1;

            if ((forward_a !== exp_a) || (forward_b !== exp_b)) begin
                $error("%s failed: A expected=%b got=%b, B expected=%b got=%b",
                       name, exp_a, forward_a, exp_b, forward_b);
                errors++;
            end
        end
    endtask

    initial begin
        errors = 0;

        check(5'd1, 5'd2, 5'd3, 1'b0, 5'd4, 1'b0,
              REG_FILE, REG_FILE, "no dependency");

        check(5'd5, 5'd2, 5'd5, 1'b1, 5'd0, 1'b0,
              EXMEM_BYPASS, REG_FILE, "EXMEM to A");

        check(5'd1, 5'd6, 5'd6, 1'b1, 5'd0, 1'b0,
              REG_FILE, EXMEM_BYPASS, "EXMEM to B");

        check(5'd7, 5'd2, 5'd0, 1'b0, 5'd7, 1'b1,
              MEMWB_BYPASS, REG_FILE, "MEMWB to A");

        check(5'd1, 5'd8, 5'd0, 1'b0, 5'd8, 1'b1,
              REG_FILE, MEMWB_BYPASS, "MEMWB to B");

        check(5'd9, 5'd9, 5'd9, 1'b1, 5'd0, 1'b0,
              EXMEM_BYPASS, EXMEM_BYPASS, "dual EXMEM forwarding");

        check(5'd10, 5'd11, 5'd10, 1'b1, 5'd11, 1'b1,
              EXMEM_BYPASS, MEMWB_BYPASS, "mixed forwarding");

        check(5'd12, 5'd0, 5'd12, 1'b1, 5'd12, 1'b1,
              EXMEM_BYPASS, REG_FILE, "EXMEM priority over MEMWB");

        check(5'd0, 5'd0, 5'd0, 1'b1, 5'd0, 1'b1,
              REG_FILE, REG_FILE, "x0 never forwards");

        if (errors == 0)
            $display("ALL FORWARDING TESTS PASSED");
        else
            $fatal(1, "FORWARDING TESTS FAILED: %0d error(s)", errors);

        $finish;
    end

endmodule
