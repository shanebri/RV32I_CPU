`timescale 1ns / 1ps

module regfile(
    input  logic         clk,
    input  logic         we,
    input  logic [4:0]   rs1,
    input  logic [4:0]   rs2,
    input  logic [4:0]   rd,
    input  logic [31:0]  wd,
    output logic [31:0]  rd1,
    output logic [31:0]  rd2
    );
    
    logic [31:0] regs [0:31];
    
    always_ff @(posedge clk) begin
        if (we && (rd != 5'd0)) 
            regs[rd] <= wd;
    end
    
    always_comb begin
        rd1 = (rs1 == 5'd0) ? 32'd0 : regs[rs1];
        rd2 = (rs2 == 5'd0) ? 32'd0 : regs[rs2];
        
        if (we && (rd != 0) && (rd == rs1))
            rd1 = wd;
        if (we && (rd != 0) && (rd == rs2))
            rd2 = wd;        
    end
    
        
endmodule
