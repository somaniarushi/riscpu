module alu (
    input [31:0] rs1,
    input [31:0] rs2,
    input [31:0] alu_sel,
    output reg [31:0] out
);
    /*
        ADD = 0, SUB = 1, SLL = 2, SLT = 3
        SLTU = 4, XOR = 5, SRL = 6, SRA = 7, OR = 8,
        AND = 9
    */
endmodule