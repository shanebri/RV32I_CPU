`timescale 1ns / 1ps

module imem #(
    parameter WORDS = 1024,
    parameter FILE  = "program.hex"
    ) (
    input  logic [31:0] addr,
    output logic [31:0] rdata
    );
    
    logic [31:0] mem [0:WORDS-1];
    
    initial $readmemh(FILE, mem);
    
    assign rdata = mem[addr[11:2]];  
    
    // Async read from a program, is not going to to infer BRAM so I will have to refactor later
endmodule