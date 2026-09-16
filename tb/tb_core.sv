`timescale 1ns / 1ps

module tb_core;

    logic clk;
    logic rst;

    integer errors;
    integer stall_count;
    integer redirect_count;
    integer i;

    rv32i_core dut (
        .clk (clk),
        .rst (rst)
    );


    // 100 MHz clock
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end


    // Count pipeline events
    always @(posedge clk) begin
        if (!rst) begin
            if (dut.stall_pc)
                stall_count++;

            if (dut.redirect_ex)
                redirect_count++;
        end
    end


    // Check register value
    task automatic check_reg(
        input integer reg_num,
        input logic [31:0] expected
    );
        logic [31:0] actual;

        begin
            actual = dut.register_file.regs[reg_num];

            if (actual !== expected) begin
                $error(
                    "x%0d FAILED: expected 0x%08h, got 0x%08h",
                    reg_num,
                    expected,
                    actual
                );
                errors++;
            end
            else begin
                $display(
                    "x%0d PASS: 0x%08h",
                    reg_num,
                    actual
                );
            end
        end
    endtask


    // Check that a wrong-path write did not occur
    task automatic check_reg_not(
        input integer reg_num,
        input logic [31:0] forbidden
    );
        logic [31:0] actual;

        begin
            actual = dut.register_file.regs[reg_num];

            if (actual === forbidden) begin
                $error(
                    "x%0d FAILED: wrong-path value 0x%08h was committed",
                    reg_num,
                    forbidden
                );
                errors++;
            end
            else begin
                $display(
                    "x%0d PASS: wrong-path value was not committed",
                    reg_num
                );
            end
        end
    endtask


    initial begin
        errors         = 0;
        stall_count    = 0;
        redirect_count = 0;

        rst = 1'b1;

        // Allow IMEM's own initial block to finish first
        #1;

        // Fill unused instruction memory with NOPs
        for (i = 0; i < 64; i = i + 1)
            dut.instruction_memory.mem[i] = 32'h00000013;


        // --------------------------------------------------------
        // Test program
        // --------------------------------------------------------

        // 0x00: addi x1, x0, 5
        dut.instruction_memory.mem[0] = 32'h00500093;

        // 0x04: addi x2, x0, 7
        dut.instruction_memory.mem[1] = 32'h00700113;

        // 0x08: add x3, x1, x2
        // Tests simultaneous MEM/WB + EX/MEM forwarding
        dut.instruction_memory.mem[2] = 32'h002081B3;

        // 0x0C: sub x4, x3, x1
        // Tests immediate EX/MEM forwarding
        dut.instruction_memory.mem[3] = 32'h40118233;

        // 0x10: addi x5, x4, 3
        // x5 = 10
        dut.instruction_memory.mem[4] = 32'h00320293;

        // 0x14: sw x5, 0(x0)
        // Tests forwarded store data
        dut.instruction_memory.mem[5] = 32'h00502023;

        // 0x18: lw x6, 0(x0)
        // x6 = 10
        dut.instruction_memory.mem[6] = 32'h00002303;

        // 0x1C: add x7, x6, x1
        // Immediate load-use hazard: should stall one cycle
        dut.instruction_memory.mem[7] = 32'h001303B3;

        // 0x20: beq x7, x7, +8
        // Always taken; also tests branch operand forwarding
        dut.instruction_memory.mem[8] = 32'h00738463;

        // 0x24: addi x11, x0, 99
        // WRONG PATH: must be flushed
        dut.instruction_memory.mem[9] = 32'h06300593;

        // 0x28: addi x8, x0, 42
        dut.instruction_memory.mem[10] = 32'h02A00413;

        // 0x2C: jal x9, +8
        // x9 should receive PC + 4 = 0x30
        dut.instruction_memory.mem[11] = 32'h008004EF;

        // 0x30: addi x12, x0, 111
        // WRONG PATH: must be flushed
        dut.instruction_memory.mem[12] = 32'h06F00613;

        // 0x34: addi x10, x0, 77
        dut.instruction_memory.mem[13] = 32'h04D00513;


        // Hold reset for several clocks
        repeat (3) @(posedge clk);

        @(negedge clk);
        rst = 1'b0;


        // Run long enough for program + pipeline drain
        repeat (40) @(posedge clk);

        #1;


        // --------------------------------------------------------
        // Register checks
        // --------------------------------------------------------

        $display("");
        $display("========================================");
        $display("REGISTER CHECKS");
        $display("========================================");

        check_reg(1,  32'd5);
        check_reg(2,  32'd7);
        check_reg(3,  32'd12);
        check_reg(4,  32'd7);
        check_reg(5,  32'd10);
        check_reg(6,  32'd10);
        check_reg(7,  32'd15);
        check_reg(8,  32'd42);

        // JAL at 0x2C should write 0x30 into x9
        check_reg(9,  32'h00000030);

        check_reg(10, 32'd77);


        // --------------------------------------------------------
        // Flush checks
        // --------------------------------------------------------

        $display("");
        $display("========================================");
        $display("CONTROL HAZARD CHECKS");
        $display("========================================");

        check_reg_not(11, 32'd99);
        check_reg_not(12, 32'd111);


        // --------------------------------------------------------
        // Hazard checks
        // --------------------------------------------------------

        $display("");
        $display("========================================");
        $display("HAZARD CHECKS");
        $display("========================================");

        if (stall_count != 1) begin
            $error(
                "Load-use stall FAILED: expected 1 stall, observed %0d",
                stall_count
            );
            errors++;
        end
        else begin
            $display(
                "Load-use stall PASS: exactly 1 stall observed"
            );
        end


        if (redirect_count != 2) begin
            $error(
                "Redirect count FAILED: expected 2, observed %0d",
                redirect_count
            );
            errors++;
        end
        else begin
            $display(
                "Control redirects PASS: branch + JAL observed"
            );
        end


        // --------------------------------------------------------
        // Final result
        // --------------------------------------------------------

        $display("");
        $display("========================================");

        if (errors == 0) begin
            $display("ALL CPU TESTS PASSED");
        end
        else begin
            $display("CPU TEST FAILED: %0d error(s)", errors);
        end

        $display("========================================");
        $display("");

        $finish;
    end


endmodule