module data_in_gen(
    input [31:0] in,
    input [3:0] mask,
    output reg [31:0] out
);
    always @(*) begin 
        if (mask == 4'b1100) begin
            out = in << 16;
        end else if (mask == 4'b0010) begin
            out = in << 8;
        end else if (mask == 4'b0100) begin
            out = in << 16;
        end else if (mask == 4'b1000) begin
            out = in << 24;
        end else begin
            out = in;
        end
    end 
endmodule