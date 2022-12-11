`timescale 1ns/1ns
`define CLK_PERIOD 8

module sat_updn_tb();
    // Generate 125 Mhz clock
    reg clk = 0;
    always #(`CLK_PERIOD/2) clk = ~clk;

    reg [1:0] in, out;
    reg br_taken;

    sat_updn (
        .in(in),
        .out(out),
        .up(br_taken),
        .dn(!br_taken)
    );

    initial begin
        in = 'b10;
        br_taken = 1;
        repeat (1) @(negedge clk);
        assert (out == 2'b10) else $display("State transition incorrect");

        br_taken = 0;
        repeat (1) @(negedge clk);
        assert (out == 2'b11) else $display("State transition incorrect");

        $finish();
    end
endmodule
