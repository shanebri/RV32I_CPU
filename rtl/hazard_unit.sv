`timescale 1ns / 1ps

module hazard_unit(
    input  logic [4:0] rs1_id,
    input  logic [4:0] rs2_id,
    input  logic       uses_rs1_id,
    input  logic       uses_rs2_id,
    input  logic [4:0] rd_ex,
    input  logic       mem_read_ex,
    input  logic       redirect_ex,
    output logic       stall_ifid,
    output logic       stall_pc,
    output logic       flush_idex,
    output logic       flush_ifid
);

    logic load_use_hazard;

    always_comb begin
        stall_ifid = 1'b0;
        stall_pc   = 1'b0;
        flush_idex = 1'b0;
        flush_ifid = 1'b0;

        load_use_hazard = mem_read_ex && (rd_ex != 5'd0) && ((uses_rs1_id && (rd_ex == rs1_id)) || (uses_rs2_id && (rd_ex == rs2_id)));

        if (redirect_ex) begin
            flush_ifid = 1'b1;
            flush_idex = 1'b1;
        end
        else if (load_use_hazard) begin
            stall_ifid = 1'b1;
            stall_pc   = 1'b1;
            flush_idex = 1'b1;
        end
    end

endmodule