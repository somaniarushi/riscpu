module fetch_next_pc(
    input [1:0] pc_sel,
    input [31:0] pc,
    input [31:0] imm,
    input [31:0] alu,
    output [31:0] next_pc
);
    /*
    Fast lookup for PC Sel
    0 -> Jal Jump = PC + imm
    1 -> Branch = ALU
    2 -> Next = PC + 4
    */

    reg [31:0] next;
    always @(*) begin
        // Jump instruction: jal
        if (pc_sel == 0) begin
            next = pc + imm;
        // Branch instructions
        end else if (pc_sel == 1) begin
            next = alu;
        // Simple next instruction
        end else begin
            next = pc + 4;
        end
    end

    assign next_pc = next;
endmodule