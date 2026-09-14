`timescale 1ns / 1ps

module control_unit (
    input  logic [6:0] opcode,
    output logic       reg_write,
    output logic       vreg_write,
    output logic       mem_read,
    output logic       mem_write,
    output logic       mem_to_reg,
    output logic       alu_src_imm,
    output logic       branch,
    output logic       jump,
    output logic       jalr,
    output logic       alu_op,
    output logic       imm_sel,
    output logic [1:0] wb_sel,
    output logic       uses_rs1,
    output logic       uses_rs2
    );
        
    
    always_comb begin
        reg_write   = 1'b0;
        vreg_write  = 1'b0;
        mem_read    = 1'b0;
        mem_write   = 1'b0;
        mem_to_reg  = 1'b0;
        alu_src_imm = 1'b0;
        branch      = 1'b0;
        jump        = 1'b0;
        jalr        = 1'b0;
        alu_op      = 1'b0;
        imm_sel     = 1'b0;
        wb_sel      = 1'b0;
        uses_rs1    = 1'b0;
        uses_rs2    = 1'b0;
        
        unique case (opcode)
            7'b0110110: begin
                reg_write   = 1'b1;
                uses_rs1    = 1'b1;
                uses_rs2    = 1'b1;
            end
            7'b0010110: begin
                reg_write   = 1'b1;
                uses_rs1    = 1'b1;
            end    
        endcase
    end    
        
endmodule