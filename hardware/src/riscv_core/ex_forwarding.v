module ex_forwarding (
    input [31:0] rs1,
    input [31:0] rs2,
    input [31:0] mem,
    input [31:0] alu,
    input [1:0] asel,
    input [1:0] bsel,
    output reg [31:0] rs1_in,
    output reg [31:0] rs2_in
);
endmodule