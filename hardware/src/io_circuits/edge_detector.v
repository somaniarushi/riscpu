module edge_detector #(
    parameter WIDTH = 1
)(
    input clk,
    input [WIDTH-1:0] signal_in,
    output [WIDTH-1:0] edge_detect_pulse
);
    reg [WIDTH-1:0] intermediate;

    always @(posedge clk) begin
        intermediate <= signal_in;
    end

    assign edge_detect_pulse = signal_in & ~intermediate; // Did any bit change?
endmodule

