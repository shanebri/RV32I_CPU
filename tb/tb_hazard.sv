`timescale 1ns / 1ps

module tb_hazard;

    logic [4:0] rs1_id;
    logic [4:0] rs2_id;
    logic       uses_rs1_id;
    logic       uses_rs2_id;
    logic [4:0] rd_ex;
    logic       mem_read_ex;
    logic       redirect_ex;
    logic       stall_ifid;
    logic       stall_pc;
    logic       flush_idex;
    logic       flush_ifid;

    integer errors;

    hazard_unit dut (
        .rs1_id      (rs1_id),
        .rs2_id      (rs2_id),
        .uses_rs1_id (uses_rs1_id),
        .uses_rs2_id (uses_rs2_id),
        .rd_ex       (rd_ex),
        .mem_read_ex (mem_read_ex),
        .redirect_ex (redirect_ex),
        .stall_ifid  (stall_ifid),
        .stall_pc    (stall_pc),
        .flush_idex  (flush_idex),
        .flush_ifid  (flush_ifid)
    );

    task automatic check(
        input logic [4:0] in_rs1,
        input logic [4:0] in_rs2,
        input logic       in_uses1,
        input logic       in_uses2,
        input logic [4:0] in_rd_ex,
        input logic       in_mem_read,
        input logic       in_redirect,
        input logic       exp_stall_ifid,
        input logic       exp_stall_pc,
        input logic       exp_flush_idex,
        input logic       exp_flush_ifid,
        input string      name
    );
        begin
            rs1_id      = in_rs1;
            rs2_id      = in_rs2;
            uses_rs1_id = in_uses1;
            uses_rs2_id = in_uses2;
            rd_ex       = in_rd_ex;
            mem_read_ex = in_mem_read;
            redirect_ex = in_redirect;
            #1;

            if ((stall_ifid !== exp_stall_ifid) ||
                (stall_pc   !== exp_stall_pc)   ||
                (flush_idex !== exp_flush_idex) ||
                (flush_ifid !== exp_flush_ifid)) begin
                $error("%s failed: stall_ifid=%b stall_pc=%b flush_idex=%b flush_ifid=%b",
                       name, stall_ifid, stall_pc, flush_idex, flush_ifid);
                errors++;
            end
        end
    endtask

    initial begin
        errors = 0;

        check(5'd1, 5'd2, 1'b1, 1'b1, 5'd3, 1'b0, 1'b0,
              1'b0, 1'b0, 1'b0, 1'b0, "no hazard");

        check(5'd5, 5'd2, 1'b1, 1'b1, 5'd5, 1'b1, 1'b0,
              1'b1, 1'b1, 1'b1, 1'b0, "load-use on rs1");

        check(5'd1, 5'd6, 1'b1, 1'b1, 5'd6, 1'b1, 1'b0,
              1'b1, 1'b1, 1'b1, 1'b0, "load-use on rs2");

        check(5'd1, 5'd6, 1'b1, 1'b0, 5'd6, 1'b1, 1'b0,
              1'b0, 1'b0, 1'b0, 1'b0, "unused rs2 must not stall");

        check(5'd5, 5'd2, 1'b1, 1'b1, 5'd0, 1'b1, 1'b0,
              1'b0, 1'b0, 1'b0, 1'b0, "x0 load destination ignored");

        check(5'd1, 5'd2, 1'b1, 1'b1, 5'd3, 1'b0, 1'b1,
              1'b0, 1'b0, 1'b1, 1'b1, "redirect flush");

        check(5'd5, 5'd2, 1'b1, 1'b1, 5'd5, 1'b1, 1'b1,
              1'b0, 1'b0, 1'b1, 1'b1, "redirect priority over load-use");

        if (errors == 0)
            $display("ALL HAZARD TESTS PASSED");
        else
            $fatal(1, "HAZARD TESTS FAILED: %0d error(s)", errors);

        $finish;
    end

endmodule
