module inst_splitter(
    input [31:0] inst,

    output [4:0] ra1,
    output [4:0] ra2,
    output [6:0] opcode,
    output [4:0] rd,
    output [2:0] func3,
    output [6:0] func7
);
    assign ra1 = inst[19:15];
    assign ra2 = inst[24:20];
    assign opcode = inst[6:0];
    assign rd = inst[11:7];
    assign func3 = inst[14:12];
    assign func7 = inst[31:25];

endmodule