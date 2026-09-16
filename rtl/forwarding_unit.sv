`timescale 1ns / 1ps

module forwarding_unit (
    input  logic [4:0] rs1_ex,
    input  logic [4:0] rs2_ex,
    input  logic [4:0] rd_mem,
    input  logic       reg_write_mem,
    input  logic [4:0] rd_wb,
    input  logic       reg_write_wb,
    output logic [1:0] forward_a,
    output logic [1:0] forward_b
);

    localparam logic [1:0]
        REG_FILE     = 2'b00,
        EXMEM_BYPASS = 2'b01,
        MEMWB_BYPASS = 2'b10;

    always_comb begin
        forward_a = REG_FILE;
        forward_b = REG_FILE;

        // Operand A
        if (reg_write_mem && (rd_mem != 5'd0) && (rd_mem == rs1_ex))
            forward_a = EXMEM_BYPASS;
        else if (reg_write_wb && (rd_wb != 5'd0) && (rd_wb == rs1_ex))
            forward_a = MEMWB_BYPASS;

        // Operand B
        if (reg_write_mem && (rd_mem != 5'd0) && (rd_mem == rs2_ex))
            forward_b = EXMEM_BYPASS;
        else if (reg_write_wb && (rd_wb != 5'd0) && (rd_wb == rs2_ex))
            forward_b = MEMWB_BYPASS;
    end

endmodule