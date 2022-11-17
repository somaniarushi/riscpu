module ex_forwarding (
    input [31:0] rs1,
    input [31:0] rs2,
    input [31:0] wb_val,
    input [31:0] pc,
    input [31:0] imm,
    input [1:0] asel,
    input [1:0] bsel,
    output reg [31:0] rs1_in,
    output reg [31:0] rs2_in
);

    always @(*) begin
        if(asel == 0) begin
            rs1_in = rs1;
        end else if(asel == 1) begin
            rs1_in = pc;
        end else if(asel == 2) begin
            rs1_in = wb_val;
        end else begin
            rs1_in = rs1; // Should not reach
        end

        if (bsel == 0) begin
            rs2_in = rs2;
        end else if (bsel == 1) begin
            rs2_in = imm;
        end else if (bsel == 2) begin
            rs2_in = wb_val;
        end else begin
            rs2_in = rs2; // Should not reach
        end
    end
endmodule