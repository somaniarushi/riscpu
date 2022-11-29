module fetch_next_pc #(
    parameter RESET_PC = 32'h4000_0000
)(
    input rst,
    input [1:0] pc_sel,
    input [31:0] pc,
    input [31:0] pc_fd,
    input [31:0] pc_x,
    input [31:0] imm,
    input [31:0] alu,
    input [31:0] inst,
    input br_taken,
    output [31:0] next_pc
);
    /*
    Fast lookup for PC Sel
    0 -> Jal Jump = PC + imm
    1 -> Branch = ALU
    2 -> Next = PC + 4
    */

    wire [2:0] func3 = inst[14:12];
    reg [31:0] next;
    always @(*) begin
        if (rst) begin
            next = RESET_PC;
        end else begin
            // Jump instruction: jal
            if (pc_sel == 0) begin
                next = alu;
            end
            // Branch instructions
            else if (pc_sel == 1) begin
                next = (br_taken) ? alu : pc + 4;
            end
            // Simple next instruction
            else begin
                next = pc + 4;
            end
        end
    end

    assign next_pc = next;
endmodule