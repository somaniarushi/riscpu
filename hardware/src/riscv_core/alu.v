module alu (
    input [31:0] rs1,
    input [31:0] rs2,
    input [3:0] alu_sel,
    output reg [31:0] out
);
    /*
        ADD = 0, SUB = 1, SLL = 2, SLT = 3
        SLTU = 4, XOR = 5, SRL = 6, SRA = 7, OR = 8,
        AND = 9
    */
    // Shift left logical and shift right logical can only shift
    // A maximum of 2^5 = 32 times (AKA, 32 values). Thus,
    // we only consider the lowermost 5 bits.
    wire [4:0] rs2_res = rs2[4:0];
    always @(*) begin
        case (alu_sel)
            'd0: out = rs1 + rs2;
            'd1: out = rs1 - rs2;
            'd2: out = rs1 << rs2_res;
            'd3: out = ($signed(rs1) < $signed(rs2)) ? 1 : 0;
            'd4: out = (rs1 < rs2) ? 1 : 0;
            'd5: out = rs1 ^ rs2;
            'd6: out = rs1 >> rs2_res;
            'd7: out = $signed(rs1) >>> rs2;
            'd8: out = rs1 | rs2;
            'd9: out = rs1 & rs2;
            default: out = rs1 + rs2;
        endcase
    end
endmodule