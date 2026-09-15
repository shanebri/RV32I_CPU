`timescale 1ns / 1ps

module rv32i_core(
    input  logic clk,
    input  logic rst
    );

    // Hazard control
    logic        stall_ifid;
    logic        flush_ifid;
    logic        stall_pc;

    assign stall_ifid = 1'b0;
    assign flush_ifid = 1'b0;
    assign stall_pc   = 1'b0;


    // IF stage
    logic [31:0] pc;
    logic [31:0] pc_next;
    logic [31:0] pc_plus_4;
    logic [31:0] instr;

    assign pc_plus_4 = pc + 32'd4;
    assign pc_next   = pc_plus_4;

    assign stall = 1'b0;
    assign flush = 1'b0;


    // IF/ID pipeline register
    logic [31:0] pc_id;
    logic [31:0] pc_plus4_id;
    logic [31:0] instr_id;
    logic        valid_id;


    // ID instruction fields
    logic [6:0] opcode_id;
    logic [4:0] rd_id;
    logic [2:0] funct3_id;
    logic [4:0] rs1_id;
    logic [4:0] rs2_id;
    logic [6:0] funct7_id;

    assign opcode_id = instr_id[6:0];
    assign rd_id     = instr_id[11:7];
    assign funct3_id = instr_id[14:12];
    assign rs1_id    = instr_id[19:15];
    assign rs2_id    = instr_id[24:20];
    assign funct7_id = instr_id[31:25];


    // ID control signals
    logic        reg_write_id;
    logic        mem_read_id;
    logic        mem_write_id;
    logic        alu_src_imm_id;
    logic        branch_id;
    logic        jump_id;
    logic        jalr_id;
    logic [1:0]  alu_a_sel_id;
    logic [1:0]  alu_mode_id;
    logic [2:0]  imm_sel_id;
    logic [1:0]  wb_sel_id;
    logic        uses_rs1_id;
    logic        uses_rs2_id;


    // ID datapath signals
    logic [31:0] imm_id;
    logic [31:0] rs1_val_id;
    logic [31:0] rs2_val_id;
    logic [3:0]  alu_op_id;


    // ID/EX pipeline register
    logic [31:0] pc_ex;
    logic [31:0] pc_plus4_ex;
    logic [31:0] rs1_val_ex;
    logic [31:0] rs2_val_ex;
    logic [4:0]  rs1_ex;
    logic [4:0]  rs2_ex;
    logic [4:0]  rd_ex;
    logic [31:0] imm_ex;
    logic [2:0]  funct3_ex;
    logic [3:0]  alu_op_ex;
    logic        reg_write_ex;
    logic        mem_read_ex;
    logic        mem_write_ex;
    logic        alu_src_imm_ex;
    logic [1:0]  alu_a_sel_ex;
    logic        branch_ex;
    logic        jump_ex;
    logic        jalr_ex;
    logic [1:0]  wb_sel_ex;
    logic        valid_ex;
    logic        flush_idex;


    // Program counter
    always_ff @(posedge clk) begin
        if (rst)
            pc <= 32'd0;
        else
            pc <= pc_next;
    end


    // Instruction memory
    imem instruction_memory (
        .addr  (pc),
        .rdata (instr)
    );


    // IF/ID register
    always_ff @(posedge clk) begin
        if (rst) begin
            pc_id       <= 32'd0;
            pc_plus4_id <= 32'd0;
            instr_id    <= 32'd0;
            valid_id    <= 1'b0;
        end
        else if (flush_ifid) begin
            pc_id       <= 32'd0;
            pc_plus4_id <= 32'd0;
            instr_id    <= 32'd0;
            valid_id    <= 1'b0;
        end
        else if (!stall_ifid) begin
            pc_id       <= pc;
            pc_plus4_id <= pc_plus_4;
            instr_id    <= instr;
            valid_id    <= 1'b1;
        end
    end


    // Main control decoder
    control_unit u_control_unit (
        .opcode      (opcode_id),
        .reg_write   (reg_write_id),
        .mem_read    (mem_read_id),
        .mem_write   (mem_write_id),
        .alu_src_imm (alu_src_imm_id),
        .branch      (branch_id),
        .jump        (jump_id),
        .jalr        (jalr_id),
        .alu_a_sel   (alu_a_sel_id),
        .alu_mode    (alu_mode_id),
        .imm_sel     (imm_sel_id),
        .wb_sel      (wb_sel_id),
        .uses_rs1    (uses_rs1_id),
        .uses_rs2    (uses_rs2_id)
    );


    // Immediate generator
    imm_gen immediate_generator (
        .instr   (instr_id),
        .imm_sel (imm_sel_id),
        .imm     (imm_id)
    );


    // Register file
    regfile register_file (
        .clk (clk),
        .we  (wb_reg_write),
        .rd  (wb_rd),
        .wd  (wb_value),
        .rs1 (rs1_id),
        .rs2 (rs2_id),
        .rd1 (rs1_val_id),
        .rd2 (rs2_val_id)
    );


    // ALU operation decoder
    alu_control u_alu_control (
        .opcode   (opcode_id),
        .funct3   (funct3_id),
        .funct7   (funct7_id),
        .alu_mode (alu_mode_id),
        .alu_op   (alu_op_id)
    );


    // ID/EX register
    always_ff @(posedge clk) begin
        if (rst) begin
            pc_ex          <= 32'd0;
            pc_plus4_ex    <= 32'd0;

            rs1_val_ex     <= 32'd0;
            rs2_val_ex     <= 32'd0;

            rs1_ex         <= 5'd0;
            rs2_ex         <= 5'd0;
            rd_ex          <= 5'd0;

            imm_ex         <= 32'd0;

            funct3_ex      <= 3'd0;
            alu_op_ex      <= 4'd0;

            reg_write_ex   <= 1'b0;
            mem_read_ex    <= 1'b0;
            mem_write_ex   <= 1'b0;

            alu_src_imm_ex <= 1'b0;
            alu_a_sel_ex   <= 2'b00;

            branch_ex      <= 1'b0;
            jump_ex        <= 1'b0;
            jalr_ex        <= 1'b0;

            wb_sel_ex      <= 2'b00;
            valid_ex       <= 1'b0;
        end

        else if (flush_idex) begin
            pc_ex          <= 32'd0;
            pc_plus4_ex    <= 32'd0;

            rs1_val_ex     <= 32'd0;
            rs2_val_ex     <= 32'd0;

            rs1_ex         <= 5'd0;
            rs2_ex         <= 5'd0;
            rd_ex          <= 5'd0;

            imm_ex         <= 32'd0;

            funct3_ex      <= 3'd0;
            alu_op_ex      <= 4'd0;

            reg_write_ex   <= 1'b0;
            mem_read_ex    <= 1'b0;
            mem_write_ex   <= 1'b0;

            alu_src_imm_ex <= 1'b0;
            alu_a_sel_ex   <= 2'b00;

            branch_ex      <= 1'b0;
            jump_ex        <= 1'b0;
            jalr_ex        <= 1'b0;

            wb_sel_ex      <= 2'b00;
            valid_ex       <= 1'b0;
        end

        else begin
            pc_ex          <= pc_id;
            pc_plus4_ex    <= pc_plus4_id;

            rs1_val_ex     <= rs1_val_id;
            rs2_val_ex     <= rs2_val_id;

            rs1_ex         <= rs1_id;
            rs2_ex         <= rs2_id;
            rd_ex          <= rd_id;

            imm_ex         <= imm_id;

            funct3_ex      <= funct3_id;
            alu_op_ex      <= alu_op_id;

            reg_write_ex   <= reg_write_id;
            mem_read_ex    <= mem_read_id;
            mem_write_ex   <= mem_write_id;

            alu_src_imm_ex <= alu_src_imm_id;
            alu_a_sel_ex   <= alu_a_sel_id;

            branch_ex      <= branch_id;
            jump_ex        <= jump_id;
            jalr_ex        <= jalr_id;

            wb_sel_ex      <= wb_sel_id;
            valid_ex       <= valid_id;
        end
    end

endmodule