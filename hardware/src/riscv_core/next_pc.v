module fetch_next_pc #(
    parameter RESET_PC = 32'h4000_0000
)(
    input clk,
    input rst,
    input [2:0] pc_sel,
    input [31:0] pc,
    input [31:0] pc_imm,
    input [31:0] rs1_imm,
    input [31:0] alu,
    input br_taken,
    input br_taken_fd,
    input br_pred_taken,
    input mispredict,
    output [31:0] next_pc
);
    /*
    Fast lookup for PC Sel
    0 -> Jal Jump = PC + imm
    1 -> Branch = ALU
    2 -> Next = PC + 4
    */
    reg [31:0] pc_prev;
    always @(posedge clk) pc_prev <= pc;

    reg [31:0] next;
    always @(*) begin
        if (rst) begin
            next = RESET_PC;
        end else begin
            // Jump instruction X stage
            if (pc_sel == 2) begin
                next = alu;
            end
            // Branch instructions: result
            else if (pc_sel == 1) begin
                if (mispredict) begin
                    next = (br_taken) ? alu : pc_prev + 4;
                end else begin
                    next = pc + 4;
                end
            end
            // Branch instruction: prediction
            else if (pc_sel == 3) begin
                next = (br_pred_taken) ? pc_imm : pc + 4;
            end
            // Jal Optimization
            else if (pc_sel == 4) begin
                next = pc_imm;
            end
            // Jalr Optimization
            else if (pc_sel == 5) begin
                next = rs1_imm;
            end
            else if (pc_sel == 6) begin 
                next = (br_taken_fd)? pc_imm: pc + 4;
            end 
            // Simple next instruction
            else begin
                next = pc + 4;
            end
        end
    end
    assign next_pc = next;
endmodule