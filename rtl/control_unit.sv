`timescale 1ns / 1ps

module control_unit (
    input  logic [6:0] opcode,
    input  logic [3:0] alu_op,
    output logic       reg_write,
    output logic       mem_read,
    output logic       mem_write,
    output logic       alu_src_imm,
    output logic       branch,
    output logic       jump,
    output logic       jalr,
    output logic [1:0] alu_a_sel,
    output logic [1:0] alu_mode,
    output logic [2:0] imm_sel,
    output logic [1:0] wb_sel,
    output logic       uses_rs1,
    output logic       uses_rs2
    );
    
    localparam logic [2:0] IMM_I = 3'b000;
    localparam logic [2:0] IMM_S = 3'b001;
    localparam logic [2:0] IMM_B = 3'b010;
    localparam logic [2:0] IMM_U = 3'b011;
    localparam logic [2:0] IMM_J = 3'b100;
    
    localparam logic [1:0] WB_ALU = 2'b00;
    localparam logic [1:0] WB_MEM = 2'b01;
    localparam logic [1:0] WB_PC4 = 2'b10;
    
    localparam logic [1:0] ALU_A_RS1  = 2'b00;
    localparam logic [1:0] ALU_A_PC   = 2'b01;
    localparam logic [1:0] ALU_A_ZERO = 2'b10;    
    
    localparam logic [1:0] ALU_MODE_OP     = 2'b00;
    localparam logic [1:0] ALU_MODE_ADD    = 2'b01;
    localparam logic [1:0] ALU_MODE_BRANCH = 2'b10;
    localparam logic [1:0] ALU_MODE_PASS   = 2'b11;
    
    always_comb begin
       reg_write   = 1'b0;

       mem_read    = 1'b0;
       mem_write   = 1'b0;

       alu_src_imm = 1'b0;

       branch      = 1'b0;
       jump        = 1'b0;
       jalr        = 1'b0;

       alu_a_sel   = ALU_A_RS1;
       alu_mode    = ALU_MODE_OP;

       imm_sel     = IMM_I;
       wb_sel      = WB_ALU;

       uses_rs1    = 1'b0;
       uses_rs2    = 1'b0;
        
        unique case (opcode)
            7'b0110011: begin
                reg_write   = 1'b1;
                alu_src_imm = 1'b0;
                alu_a_sel   = ALU_A_RS1;
                alu_mode    = ALU_MODE_OP;
                wb_sel      = WB_ALU;
                uses_rs1    = 1'b1;
                uses_rs2    = 1'b1;
            end
            7'b0010011: begin
                reg_write   = 1'b1;
                alu_src_imm = 1'b1;
                alu_a_sel   = ALU_A_RS1;
                alu_mode    = ALU_MODE_OP;
                imm_sel     = IMM_I;
                wb_sel      = WB_ALU;
                uses_rs1    = 1'b1;
                uses_rs2    = 1'b0;
            end    
            7'b0000011: begin
                uses_rs1    = 1'b1;
                alu_src_imm = 1'b1;
                alu_a_sel   = ALU_A_RS1;
                alu_mode    = ALU_MODE_OP;
                imm_sel     = IMM_I;
                wb_sel      = WB_ALU;
                
            end
            7'b0100011: begin
                mem_write   = 1'b1;
                alu_src_imm = 1'b1;
                alu_a_sel   = ALU_A_RS1;
                alu_mode    = ALU_MODE_ADD;
                imm_sel     = IMM_S;
                uses_rs1    = 1'b1;
                uses_rs2    = 1'b1;
            end
            7'b1100011: begin
                branch      = 1'b1;
                alu_src_imm = 1'b1;
                alu_a_sel   = ALU_A_PC;
                alu_mode    = ALU_MODE_BRANCH;
                imm_sel     = IMM_B;
                uses_rs1    = 1'b1;
                uses_rs2    = 1'b1;
            end
            7'b1101111: begin
                reg_write   = 1'b1;
                jump        = 1'b1;
                alu_src_imm = 1'b1;
                alu_a_sel   = ALU_A_PC;
                alu_mode    = ALU_MODE_ADD;
                imm_sel     = IMM_J;
                wb_sel      = WB_PC4;
                uses_rs1    = 1'b0;
                uses_rs2    = 1'b0;
            end
            7'b1100111: begin
                reg_write   = 1'b1;
                jump        = 1'b1;
                jalr        = 1'b1;
                alu_src_imm = 1'b1;
                alu_a_sel   = ALU_A_RS1;
                alu_mode    = ALU_MODE_ADD;
                imm_sel     = IMM_I;
                wb_sel      = WB_PC4;
                uses_rs1    = 1'b1;
                uses_rs2    = 1'b0;    
            end
            7'b0110111: begin
                reg_write   = 1'b1;
                alu_src_imm = 1'b1;
                alu_a_sel   = ALU_A_ZERO;
                alu_mode    = ALU_MODE_ADD;
                imm_sel     = IMM_U;
                wb_sel      = WB_ALU;
                uses_rs1    = 1'b0;
                uses_rs2    = 1'b0;
            end
            7'b0010111: begin
                reg_write   = 1'b1;
                alu_src_imm = 1'b1;
                alu_a_sel   = ALU_A_PC;
                alu_mode    = ALU_MODE_ADD;
                imm_sel     = IMM_U;
                wb_sel      = WB_ALU;
                uses_rs1    = 1'b0;
                uses_rs2    = 1'b0;
            end
            default: begin
            end         
        endcase
    end    
        
endmodule