module synchronizer #(parameter WIDTH = 1) (
    input [WIDTH-1:0] async_signal,
    input clk,
    output [WIDTH-1:0] sync_signal
);
    reg [WIDTH-1:0] intermediate = 0;
    reg [WIDTH-1:0] sync_reg = 0;

    always @(posedge clk) begin
        intermediate <= async_signal;
        sync_reg <= intermediate;
    end
    assign sync_signal = sync_reg;

endmodule