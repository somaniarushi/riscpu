module fetch_next_pc #(
    parameter RESET_PC = 32'h4000_0000
)(
    input clk,
    input rst,
    input [2:0] pc_sel,
    input [31:0] pc,
    input [31:0] pc_fd,
    input [31:0] next_pc_in,
    input [31:0] alu,
    input br_taken,
    input br_pred_taken,
    input bp_enable,
    output [31:0] next_pc
);
    /*
    Fast lookup for PC Sel
    0 -> Jal Jump = PC + imm
    1 -> Branch = ALU
    2 -> Next = PC + 4
    */
    reg pred_cache;
    reg [31:0] pc_prev_cache;
    always @(posedge clk) begin
        pred_cache <= br_pred_taken;
        pc_prev_cache <= pc;
    end

    reg [31:0] next;
    always @(*) begin
        if (rst) begin
            next = RESET_PC;
        end else begin
            // Jump instruction: jal
            if (pc_sel == 0) begin
                next = alu;
            end
            // Branch instructions: result
            else if (pc_sel == 1) begin
                if (bp_enable) begin 
                    if (pred_cache) begin
                        next = (br_taken) ? pc + 4 : pc_prev_cache + 4;
                    end else begin
                        next = (br_taken) ? alu : pc + 4;
                    end
                end else begin 
                    next = (br_taken) ? alu : pc_fd + 4;
                end 
            end
            // Branch instruction: prediction
            else if (pc_sel == 3) begin
                if (bp_enable) begin
                    next = (br_pred_taken) ? next_pc_in : pc + 4;
                end else begin
                    next = pc + 4;
                end
            end
            else if (pc_sel == 4) begin
                next = next_pc_in;
            end
            // Simple next instruction
            else begin
                next = pc + 4;
            end
        end
    end

    assign next_pc = next;
endmodule