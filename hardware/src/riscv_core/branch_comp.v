module branch_comp (
    input brun,
    input [31:0] rs1,
    input [31:0] rs2,
    output reg brlt,
    output reg breq
);
    always @(*) begin
        if (brun) begin
            brlt = (rs1 < rs2) ? 1 : 0;
            breq = (rs1 == rs2) ? 1 : 0;
        end else begin
            brlt = ($signed(rs1) < $signed(rs2)) ? 1 : 0;
            breq = ($signed(rs1) == $signed(rs2)) ? 1 : 0;
        end
    end
endmodule