`timescale 1ns / 1ps

module alu_control (
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,
    input  logic [1:0] alu_mode,
    output logic [3:0] alu_op
);

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

    localparam logic [1:0]
        ALU_MODE_OP     = 2'b00,
        ALU_MODE_ADD    = 2'b01,
        ALU_MODE_BRANCH = 2'b10,
        ALU_MODE_PASS   = 2'b11;

    always_comb begin

        alu_op = ALU_ADD;

        unique case (alu_mode)

            ALU_MODE_OP: begin
                unique case (funct3)

                    3'b000: begin
                        if ((opcode == 7'b0110011) && funct7[5])
                            alu_op = ALU_SUB;
                        else
                            alu_op = ALU_ADD;
                    end

                    3'b001:
                        alu_op = ALU_SLL;

                    3'b010:
                        alu_op = ALU_SLT;

                    3'b011:
                        alu_op = ALU_SLTU;

                    3'b100:
                        alu_op = ALU_XOR;

                    3'b101: begin
                        if (funct7[5])
                            alu_op = ALU_SRA;
                        else
                            alu_op = ALU_SRL;
                    end

                    3'b110:
                        alu_op = ALU_OR;

                    3'b111:
                        alu_op = ALU_AND;

                    default:
                        alu_op = ALU_ADD;

                endcase
            end

            ALU_MODE_ADD:
                alu_op = ALU_ADD;

            ALU_MODE_BRANCH:
                alu_op = ALU_ADD;

            default:
                alu_op = ALU_ADD;

        endcase
    end

endmodule
