module read_from_reg(
    input [31:0] inst,
    input wb2d_a,
    input wb2d_b,
    input [31:0] rd1,
    input [31:0] rd2,
    input [31:0] wb_val,
    output reg [4:0] ra1,
    output reg [4:0] ra2,
    output [31:0] rs1,
    output [31:0] rs2
);

    // RegFile read (asynchronous)
    always @(*) begin
      ra1 = inst[19:15];
      ra2 = inst[24:20];
    end

    // MW2D Forwarding
    assign rs1 = (ra1 == 0) ? 0 : ((wb2d_a) ? wb_val : rd1);
    assign rs2 = (ra2 == 0) ? 0 : ((wb2d_b) ? wb_val : rd2);

endmodule