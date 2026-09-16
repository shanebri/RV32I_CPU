`timescale 1ns / 1ps

module tb_control_flow;

    logic clk;
    logic rst;

    integer errors;
    integer redirect_count;
    integer i;

    rv32i_core dut (
        .clk (clk),
        .rst (rst),
        .gpio_out ()
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    always @(posedge clk) begin
        if (!rst && dut.redirect_ex)
            redirect_count++;
    end

    task automatic check_reg(
        input integer reg_num,
        input logic [31:0] expected
    );
        logic [31:0] actual;
        begin
            actual = dut.register_file.regs[reg_num];
            if (actual !== expected) begin
                $error("x%0d expected=%h got=%h", reg_num, expected, actual);
                errors++;
            end
        end
    endtask

    initial begin
        errors         = 0;
        redirect_count = 0;
        rst             = 1'b1;

        #1;

        for (i = 0; i < 32; i = i + 1)
            dut.register_file.regs[i] = 32'd0;

        for (i = 0; i < 64; i = i + 1)
            dut.instruction_memory.mem[i] = 32'h00000013;

        // BEQ taken, BNE not taken
        dut.instruction_memory.mem[0]  = 32'h00500093; // addi x1,x0,5
        dut.instruction_memory.mem[1]  = 32'h00500113; // addi x2,x0,5
        dut.instruction_memory.mem[2]  = 32'h00208463; // beq x1,x2,+8
        dut.instruction_memory.mem[3]  = 32'h00100A13; // wrong path: x20=1
        dut.instruction_memory.mem[4]  = 32'h00100193; // x3=1
        dut.instruction_memory.mem[5]  = 32'h00209463; // bne x1,x2,+8, not taken
        dut.instruction_memory.mem[6]  = 32'h00200213; // x4=2

        // Signed and unsigned comparisons
        dut.instruction_memory.mem[7]  = 32'h00700113; // addi x2,x0,7
        dut.instruction_memory.mem[8]  = 32'h0020C463; // blt x1,x2,+8
        dut.instruction_memory.mem[9]  = 32'h00100A93; // wrong path: x21=1
        dut.instruction_memory.mem[10] = 32'h00115463; // bge x2,x1,+8
        dut.instruction_memory.mem[11] = 32'h00100B13; // wrong path: x22=1
        dut.instruction_memory.mem[12] = 32'h0020E463; // bltu x1,x2,+8
        dut.instruction_memory.mem[13] = 32'h00100B93; // wrong path: x23=1
        dut.instruction_memory.mem[14] = 32'h00117463; // bgeu x2,x1,+8
        dut.instruction_memory.mem[15] = 32'h00100C13; // wrong path: x24=1

        // Forwarded JALR target and link value
        dut.instruction_memory.mem[16] = 32'h05000293; // addi x5,x0,80
        dut.instruction_memory.mem[17] = 32'h00028367; // jalr x6,0(x5)
        dut.instruction_memory.mem[18] = 32'h00100C93; // wrong path: x25=1
        dut.instruction_memory.mem[19] = 32'h00100D13; // wrong path: x26=1
        dut.instruction_memory.mem[20] = 32'h04D00393; // target: x7=77

        // Prove signed and unsigned branches differ for -1
        dut.instruction_memory.mem[21] = 32'hFFF00413; // addi x8,x0,-1
        dut.instruction_memory.mem[22] = 32'h00100493; // addi x9,x0,1
        dut.instruction_memory.mem[23] = 32'h00944463; // blt x8,x9,+8, taken
        dut.instruction_memory.mem[24] = 32'h00100D93; // wrong path: x27=1
        dut.instruction_memory.mem[25] = 32'h00946463; // bltu x8,x9,+8, not taken
        dut.instruction_memory.mem[26] = 32'h03700513; // x10=55
        dut.instruction_memory.mem[27] = 32'h00947463; // bgeu x8,x9,+8, taken
        dut.instruction_memory.mem[28] = 32'h00100E13; // wrong path: x28=1
        dut.instruction_memory.mem[29] = 32'h04200593; // x11=66

        repeat (3) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;

        repeat (90) @(posedge clk);
        #1;

        check_reg(1,  32'd5);
        check_reg(2,  32'd7);
        check_reg(3,  32'd1);
        check_reg(4,  32'd2);
        check_reg(6,  32'h00000048);
        check_reg(7,  32'd77);
        check_reg(8,  32'hFFFFFFFF);
        check_reg(9,  32'd1);
        check_reg(10, 32'd55);
        check_reg(11, 32'd66);

        check_reg(20, 32'd0);
        check_reg(21, 32'd0);
        check_reg(22, 32'd0);
        check_reg(23, 32'd0);
        check_reg(24, 32'd0);
        check_reg(25, 32'd0);
        check_reg(26, 32'd0);
        check_reg(27, 32'd0);
        check_reg(28, 32'd0);

        if (redirect_count != 8) begin
            $error("expected 8 redirects, observed %0d", redirect_count);
            errors++;
        end

        if (errors == 0)
            $display("ALL CONTROL FLOW TESTS PASSED");
        else
            $fatal(1, "CONTROL FLOW TESTS FAILED: %0d error(s)", errors);

        $finish;
    end

endmodule
