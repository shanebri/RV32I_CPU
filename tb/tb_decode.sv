`timescale 1ns / 1ps

module tb_decode;

    logic [31:0] instr;
    logic [6:0]  opcode;
    logic [2:0]  funct3;
    logic [6:0]  funct7;

    logic        reg_write;
    logic        mem_read;
    logic        mem_write;
    logic        alu_src_imm;
    logic        branch;
    logic        jump;
    logic        jalr;
    logic [1:0]  alu_a_sel;
    logic [1:0]  alu_mode;
    logic [2:0]  imm_sel;
    logic [1:0]  wb_sel;
    logic        uses_rs1;
    logic        uses_rs2;
    logic [31:0] imm;
    logic [3:0]  alu_op;

    integer errors;

    assign opcode = instr[6:0];
    assign funct3 = instr[14:12];
    assign funct7 = instr[31:25];

    control_unit u_control_unit (
        .opcode      (opcode),
        .reg_write   (reg_write),
        .mem_read    (mem_read),
        .mem_write   (mem_write),
        .alu_src_imm (alu_src_imm),
        .branch      (branch),
        .jump        (jump),
        .jalr        (jalr),
        .alu_a_sel   (alu_a_sel),
        .alu_mode    (alu_mode),
        .imm_sel     (imm_sel),
        .wb_sel      (wb_sel),
        .uses_rs1    (uses_rs1),
        .uses_rs2    (uses_rs2)
    );

    imm_gen u_imm_gen (
        .instr   (instr),
        .imm_sel (imm_sel),
        .imm     (imm)
    );

    alu_control u_alu_control (
        .opcode   (opcode),
        .funct3   (funct3),
        .funct7   (funct7),
        .alu_mode (alu_mode),
        .alu_op   (alu_op)
    );

    task automatic expect_bit(input string name, input logic actual, input logic expected);
        begin
            if (actual !== expected) begin
                $error("%s expected %0d got %0d", name, expected, actual);
                errors++;
            end
        end
    endtask

    task automatic expect_vec(input string name, input logic [31:0] actual, input logic [31:0] expected);
        begin
            if (actual !== expected) begin
                $error("%s expected %h got %h", name, expected, actual);
                errors++;
            end
        end
    endtask

    initial begin
        errors = 0;

        // ADD x3,x1,x2
        instr = 32'h002081B3; #1;
        expect_bit("ADD reg_write", reg_write, 1'b1);
        expect_bit("ADD uses_rs1", uses_rs1, 1'b1);
        expect_bit("ADD uses_rs2", uses_rs2, 1'b1);
        expect_vec("ADD alu_op", {28'd0, alu_op}, 32'd0);

        // SUB x3,x1,x2
        instr = 32'h402081B3; #1;
        expect_vec("SUB alu_op", {28'd0, alu_op}, 32'd1);

        // ADDI x5,x1,-7
        instr = 32'hFF908293; #1;
        expect_bit("ADDI reg_write", reg_write, 1'b1);
        expect_bit("ADDI alu_src_imm", alu_src_imm, 1'b1);
        expect_bit("ADDI uses_rs1", uses_rs1, 1'b1);
        expect_bit("ADDI uses_rs2", uses_rs2, 1'b0);
        expect_vec("ADDI imm", imm, 32'hFFFFFFF9);

        // LW x5,8(x1)
        instr = 32'h0080A283; #1;
        expect_bit("LW reg_write", reg_write, 1'b1);
        expect_bit("LW mem_read", mem_read, 1'b1);
        expect_bit("LW mem_write", mem_write, 1'b0);
        expect_vec("LW imm", imm, 32'd8);
        expect_vec("LW wb_sel", {30'd0, wb_sel}, 32'd1);

        // SW x5,12(x2)
        instr = 32'h00512623; #1;
        expect_bit("SW reg_write", reg_write, 1'b0);
        expect_bit("SW mem_write", mem_write, 1'b1);
        expect_bit("SW uses_rs1", uses_rs1, 1'b1);
        expect_bit("SW uses_rs2", uses_rs2, 1'b1);
        expect_vec("SW imm", imm, 32'd12);

        // BEQ x1,x2,-8
        instr = 32'hFE208CE3; #1;
        expect_bit("BEQ branch", branch, 1'b1);
        expect_bit("BEQ uses_rs1", uses_rs1, 1'b1);
        expect_bit("BEQ uses_rs2", uses_rs2, 1'b1);
        expect_vec("BEQ imm", imm, 32'hFFFFFFF8);

        // LUI x3,0x12345
        instr = 32'h123451B7; #1;
        expect_bit("LUI reg_write", reg_write, 1'b1);
        expect_vec("LUI imm", imm, 32'h12345000);
        expect_bit("LUI uses_rs1", uses_rs1, 1'b0);
        expect_bit("LUI uses_rs2", uses_rs2, 1'b0);

        // AUIPC x4,0x23456
        instr = 32'h23456217; #1;
        expect_bit("AUIPC reg_write", reg_write, 1'b1);
        expect_vec("AUIPC imm", imm, 32'h23456000);

        // JAL x1,+16
        instr = 32'h010000EF; #1;
        expect_bit("JAL jump", jump, 1'b1);
        expect_bit("JAL jalr", jalr, 1'b0);
        expect_bit("JAL reg_write", reg_write, 1'b1);
        expect_vec("JAL imm", imm, 32'd16);
        expect_vec("JAL wb_sel", {30'd0, wb_sel}, 32'd2);

        // JALR x1,4(x2)
        instr = 32'h004100E7; #1;
        expect_bit("JALR jump", jump, 1'b1);
        expect_bit("JALR jalr", jalr, 1'b1);
        expect_bit("JALR uses_rs1", uses_rs1, 1'b1);
        expect_vec("JALR imm", imm, 32'd4);

        if (errors == 0)
            $display("ALL DECODE TESTS PASSED");
        else
            $fatal(1, "DECODE TESTS FAILED: %0d error(s)", errors);

        $finish;
    end

endmodule
