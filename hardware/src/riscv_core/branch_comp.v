module branch_comp (
    input brun,
    input [31:0] rs1,
    input [31:0] rs2,
    output reg brlt,
    output reg breq
);
    wire signed [31:0] rs1_s = rs1;
    wire signed [31:0] rs2_s = rs2;
    always @(*) begin
        if (brun) begin
            brlt = (rs1 < rs2) ? 1 : 0;
            breq = (rs1 == rs2) ? 1 : 0;
        end else begin
            brlt = (rs1_s < rs2_s) ? 1 : 0;
            breq = (rs1_s == rs2_s) ? 1 : 0;
        end
    end
endmodule