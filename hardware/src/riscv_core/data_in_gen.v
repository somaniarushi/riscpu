module data_in_gen(
    input [31:0] in,
    input [3:0] mask,
    output reg [31:0] out
);
    always @(*) begin
        case (mask)
            4'b1100: out = in << 16;
            4'b0010: out = in << 8;
            4'b0100: out = in << 16;
            4'b1000: out = in << 24;
            default: out = in;
        endcase
    end
endmodule