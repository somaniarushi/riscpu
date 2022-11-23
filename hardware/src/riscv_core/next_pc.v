module fetch_next_pc(
    input [1:0] pc_sel,
    input [31:0] pc,
    input [31:0] pc_fd,
    input [31:0] pc_x,
    input [31:0] imm,
    input [31:0] alu,
    input brlt,
    input breq,
    input [31:0] inst,
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
        // Jump instruction: jal
        if (pc_sel == 0) begin
            next = alu;
        end
        // Branch instructions
        else if (pc_sel == 1) begin
            // BEQ
            if (func3 == 3'b000) begin
                next = (breq) ? alu : pc_fd;
            end
            // BNE
            else if (func3 == 3'b001) begin
                next = (breq) ? pc_fd : alu;
            end
            // BLT
            else if (func3 == 3'b100) begin
                next = (brlt) ? alu : pc_fd;
            end
            // BGE
            else if (func3 == 3'b101) begin
                next = (brlt) ? pc_fd : alu;
            end
            // BLTU
            else if (func3 == 3'b110) begin
                next = (brlt) ? alu : pc_fd; // TODO: Control logic figures it out for us.
            end
            // BGEU
            else begin
                next = (brlt) ? pc_fd : alu;
            end
        end
        // Simple next instruction
        else begin
            next = pc + 4;
        end
    end

    assign next_pc = next;
endmodule