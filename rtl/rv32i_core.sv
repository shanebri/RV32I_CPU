`timescale 1ns / 1ps

module rv32i_core(
    input  logic clk,
    input  logic rst
    );

    // Hazard control
    logic        stall_ifid;
    logic        flush_ifid;
    logic        stall_pc;


    // IF stage
    logic [31:0] pc;
    logic [31:0] pc_next;
    logic [31:0] pc_plus_4;
    logic [31:0] instr;

    assign pc_plus_4 = pc + 32'd4;


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
    
    // Writeback
    logic [31:0] wb_value;
    
    localparam logic [1:0]
        WB_ALU = 2'b00,
        WB_MEM = 2'b01,
        WB_PC4 = 2'b10;
    
    // ALU Signals
    logic [31:0] a_ex;
    logic [31:0] b_ex;
    logic [31:0] y_ex;
    logic        zero_ex;
    
    logic [31:0] branch_target_ex;
    logic [31:0] jalr_target_ex;
    logic [31:0] redirect_target_ex;
    logic        redirect_ex;
    
    assign branch_target_ex = pc_ex + imm_ex;
    assign jalr_target_ex   = (rs1_forwarded_ex + imm_ex) & 32'hFFFF_FFFE;   
    assign redirect_ex = (branch_ex && branch_taken_ex) || jump_ex;
    assign redirect_target_ex = jalr_ex ? jalr_target_ex : branch_target_ex;
    
    // EX/MEM Pipeline Register
    logic [31:0] alu_result_mem;
    logic [31:0] store_data_mem;
    logic [31:0] pc_plus4_mem;
    logic [4:0]  rd_mem;  
    logic        reg_write_mem;
    logic        mem_read_mem;
    logic        mem_write_mem;
    logic [1:0]  wb_sel_mem;
    logic        valid_mem;
    
    // Forwarding
    logic [1:0]  forward_a;
    logic [1:0]  forward_b;
    logic [31:0] rs1_forwarded_ex;
    logic [31:0] rs2_forwarded_ex;
    logic [31:0] mem_forward_value;
    
    logic [31:0] mem_read_data;
    
    // MEM/WB pipeline register
    logic [31:0] alu_result_wb;
    logic [31:0] mem_data_wb;
    logic [31:0] pc_plus4_wb;    
    logic [4:0]  rd_wb;
    logic        reg_write_wb;
    logic [1:0]  wb_sel_wb;
    logic        valid_wb;


    hazard_unit u_hazard_unit (
        .rs1_id        (rs1_id),
        .rs2_id        (rs2_id),
        .uses_rs1_id   (uses_rs1_id),
        .uses_rs2_id   (uses_rs2_id),
        .rd_ex         (rd_ex),
        .mem_read_ex   (mem_read_ex && valid_ex),
        .redirect_ex   (redirect_ex),
        .stall_ifid    (stall_ifid),
        .stall_pc      (stall_pc),
        .flush_idex    (flush_idex),
        .flush_ifid    (flush_ifid)
    );
    
    assign pc_next = redirect_ex ? redirect_target_ex : pc_plus_4;

    always_ff @(posedge clk) begin
        if (rst)
            pc <= 32'd0;
        else if (redirect_ex || !stall_pc)
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
        .we  (reg_write_wb && valid_wb),
        .rd  (rd_wb),
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
    
    alu u_alu (
        .a      (a_ex),
        .b      (b_ex),
        .alu_op (alu_op_ex),
        .y      (y_ex),
        .zero   (zero_ex)
    );
    
    always_comb begin
        unique case (alu_a_sel_ex)
            2'b00: a_ex = rs1_forwarded_ex;
            2'b01: a_ex = pc_ex;
            2'b10: a_ex = 32'd0;
            default: a_ex = 32'd0;
        endcase
    end
    
    assign b_ex = alu_src_imm_ex ? imm_ex : rs2_forwarded_ex;
    
    logic branch_taken_ex;
    
    always_comb begin
        branch_taken_ex = 1'b0;
    
        if (branch_ex) begin
            unique case (funct3_ex)
                3'b000: branch_taken_ex = (rs1_forwarded_ex == rs2_forwarded_ex);
                3'b001: branch_taken_ex = (rs1_forwarded_ex != rs2_forwarded_ex);
                3'b100: branch_taken_ex = ($signed(rs1_forwarded_ex) <  $signed(rs2_forwarded_ex));
                3'b101: branch_taken_ex = ($signed(rs1_forwarded_ex) >= $signed(rs2_forwarded_ex));
                3'b110: branch_taken_ex = (rs1_forwarded_ex <  rs2_forwarded_ex);
                3'b111: branch_taken_ex = (rs1_forwarded_ex >= rs2_forwarded_ex);
                default: branch_taken_ex = 1'b0;
            endcase
        end
    end
    
    forwarding_unit u_forwarding_unit (
        .rs1_ex        (rs1_ex),
        .rs2_ex        (rs2_ex),  
        .rd_mem        (rd_mem),
        .reg_write_mem (reg_write_mem && valid_mem),  
        .rd_wb         (rd_wb),
        .reg_write_wb  (reg_write_wb && valid_wb), 
        .forward_a     (forward_a),
        .forward_b     (forward_b)
    );
    
    
    always_comb begin
        unique case (wb_sel_mem)
            WB_ALU:  mem_forward_value = alu_result_mem;
            WB_PC4:  mem_forward_value = pc_plus4_mem;
            default: mem_forward_value = alu_result_mem;
        endcase
    end
    
    always_comb begin
        unique case (forward_a)
            2'b00:   rs1_forwarded_ex = rs1_val_ex;
            2'b01:   rs1_forwarded_ex = mem_forward_value;
            2'b10:   rs1_forwarded_ex = wb_value;
            default: rs1_forwarded_ex = rs1_val_ex;
        endcase
    
        unique case (forward_b)
            2'b00:   rs2_forwarded_ex = rs2_val_ex;
            2'b01:   rs2_forwarded_ex = mem_forward_value;
            2'b10:   rs2_forwarded_ex = wb_value;
            default: rs2_forwarded_ex = rs2_val_ex;
        endcase
    end
    
    // EX/MEM Pipeline Register
    always_ff @(posedge clk) begin
        if (rst) begin
            alu_result_mem <= 32'd0;
            store_data_mem <= 32'd0;
            pc_plus4_mem   <= 32'd0;
            rd_mem         <= 5'd0;
    
            reg_write_mem  <= 1'b0;
            mem_read_mem   <= 1'b0;
            mem_write_mem  <= 1'b0;
            wb_sel_mem     <= 2'b00;
            valid_mem      <= 1'b0;
        end
        else begin
            alu_result_mem <= y_ex;
            store_data_mem <= rs2_forwarded_ex;
            pc_plus4_mem   <= pc_plus4_ex;
            rd_mem         <= rd_ex;
    
            reg_write_mem  <= reg_write_ex;
            mem_read_mem   <= mem_read_ex;
            mem_write_mem  <= mem_write_ex;
            wb_sel_mem     <= wb_sel_ex;
            valid_mem      <= valid_ex;
        end
    end
    
    dmem_mmio data_memory (
        .clk       (clk),
        .mem_read  (mem_read_mem),
        .mem_write (mem_write_mem),
        .addr      (alu_result_mem),
        .wdata     (store_data_mem),
        .rdata     (mem_read_data)
    );
    
    
    // MEM/WB pipeline register
    always_ff @(posedge clk) begin
        if (rst) begin
            alu_result_wb <= 32'd0;
            mem_data_wb   <= 32'd0;
            pc_plus4_wb   <= 32'd0;
    
            rd_wb         <= 5'd0;
            reg_write_wb  <= 1'b0;
            wb_sel_wb     <= 2'b00;
    
            valid_wb      <= 1'b0;
        end
        else begin
            alu_result_wb <= alu_result_mem;
            mem_data_wb   <= mem_read_data;
            pc_plus4_wb   <= pc_plus4_mem;
    
            rd_wb         <= rd_mem;
            reg_write_wb  <= reg_write_mem;
            wb_sel_wb     <= wb_sel_mem;
    
            valid_wb      <= valid_mem;
        end
    end
    
    always_comb begin
        unique case (wb_sel_wb)
            WB_ALU:  wb_value = alu_result_wb;
            WB_MEM:  wb_value = mem_data_wb;
            WB_PC4:  wb_value = pc_plus4_wb;
            default: wb_value = 32'd0;
        endcase
    end
        

endmodule