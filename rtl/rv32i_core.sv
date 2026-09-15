`timescale 1ns / 1ps

module rv32i_core(
    input  logic clk,
    input  logic rst,
    input  logic stall,
    input  logic flush
    );
    
    logic [31:0] pc;
    logic [31:0] pc_next;
    logic [31:0] pc_plus_4;
    logic [31:0] instr;
    
    logic [31:0] pc_id;
    logic [31:0] pc_plus4_id;
    logic [31:0] instr_id;
    logic        valid_id;
    
    assign pc_plus_4 = pc + 32'd4;
    
    assign pc_next = pc_plus_4;
    
    assign stall = 1'b0;
    assign flush = 1'b0;
    
    always_ff @(posedge clk) begin
        if (rst) 
            pc <= 32'd0;
        else
            pc <= pc_next;
    end
    
    imem instruction_memory (
        .addr (pc),
        .rdata (instr)
    );
    
    always_ff @(posedge clk) begin
        if (rst) begin
            pc_id       <= 32'd0;
            pc_plus4_id <= 32'd0;
            instr_id    <= 32'd0;
            valid_id    <= 1'b0;
        end
        else if (flush) begin
            pc_id       <= 32'd0;
            pc_plus4_id <= 32'd0;
            instr_id    <= 32'd0;
            valid_id    <= 1'b0;
        end
        else if (!stall) begin
            pc_id       <= pc;
            pc_plus4_id <= pc_plus_4;
            instr_id    <= instr;
            valid_id    <= 1'b1;
        end
    end
    
    
    control_unit u_control_unit(
        
    );
    imm_gen immediate_generator (
        
    );
    regfile register_file (
    
    );
        
endmodule
