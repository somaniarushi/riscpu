module ex_forwarding (
    input [31:0] rs1,
    input [31:0] rs2,
    input [31:0] wb_val,
    input [31:0] pc,
    input [31:0] imm,
    input [1:0] asel,
    input [1:0] bsel,
    output reg [31:0] rs1_in,
    output reg [31:0] rs2_in,
    output reg [31:0] rs1_br,
    output reg [31:0] rs2_br
);
    always @(*) begin
        rs1_br = asel[1] ? wb_val : rs1; // if asel first bit is high, forward wb_val, else keep rs1
        rs2_br = bsel[1] ? wb_val : rs2; // if bsel first bit is high, forward wb_val, else keep rs2
    end

    always @(*) begin
        rs1_in = asel[0] ? pc : (asel[1] ? wb_val : rs1); // if asel second bit is high, forward pc, else keep rs1_br
        rs2_in = bsel[0] ? imm : (asel[1] ? wb_val : rs1); // if bsel second bit is high, forward imm, else keep rs2_br
    end
endmodule