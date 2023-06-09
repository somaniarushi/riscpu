module immediate_generator (
    input [31:0] inst,
    output [31:0] imm
);
    reg [31:0] imm_reg;
    wire [6:0] opc;
    assign opc = inst[6:0];
    wire [2:0] func3;
    assign func3 = inst[14:12];

    always @(*) begin
        // Instruction = I-Type
        if (opc == 7'h03 || opc == 7'h13 || opc == 7'h67) begin
            // SHAMT instructions
            if (opc == 7'h13 && (func3 == 3'b001 || func3 == 3'b101)) begin
                imm_reg[4:0] = inst[24:20];
                imm_reg[31:5] = 'd0;
            end
            else begin
                imm_reg[11:0] = inst[31:20];
                imm_reg[31:12] = inst[31]? 'hfffff: 'd0;
            end
        end
        // Instruction = CSR
        else if (opc == 7'h73) begin
            imm_reg[4:0] = inst[19:15];
            imm_reg[31:5] = 'd0; // No sign extension needed.
        end
        // Instruction = S-Type
        else if (opc == 7'h23) begin
            imm_reg[4:0] = inst[11:7];
            imm_reg[11:5] = inst[31:25];
            imm_reg[31:12] = inst[31] ? 'hffffff : 'h0;
        end
        // Instruction = B-Type
        else if (opc == 7'h63) begin
            imm_reg[0] = 0;
            imm_reg[4:1] = inst[11:8];
            imm_reg[10:5] = inst[30:25];
            imm_reg[11] = inst[7];
            imm_reg[12] = inst[31];
            imm_reg[31:13] = (inst[31]) ? 'hffffff : 'd0;
        end
        // Instruction = U-Type
        else if (opc == 7'h17 || opc == 7'h37) begin
            imm_reg[31:12] = inst[31:12];
            imm_reg[11:0] = 'd0;
        end
        // Instruction = J-Type
        else if (opc == 7'h6F) begin
            imm_reg[0] = 0;
            imm_reg[10:1] = inst[30:21];
            imm_reg[11] = inst[20];
            imm_reg[19:12] = inst[19:12];
            imm_reg[20] = inst[31];
            imm_reg[31:21] = (inst[31]) ? 'hfffff : 'h0;
        end
        // Instruction = R-Type
        else begin
            imm_reg = 0; // Immediate doesn't get used at all in R-Type insts.
        end
    end

    assign imm = $signed(imm_reg);

endmodule

// Calculations based on https://inst.eecs.berkeley.edu/~cs61c/fa17/img/riscvcard.pdf