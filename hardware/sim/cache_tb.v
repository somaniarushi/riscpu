`timescale 1ns/1ns
`define CLK_PERIOD 8

module cache_tb();
    // Generate 125 Mhz clock
    reg clk = 0;
    always #(`CLK_PERIOD/2) clk = ~clk;

    reg reset = 0;
    reg [31:0] ra0;
    reg [31:0] ra1;
    reg [31:0] wa;
    reg [31:0] din;
    reg we = 0;

    reg [31:0] dout0;
    reg [31:0] dout1;
    reg hit0;
    reg hit1;

    // Instantiate a cache object
    bp_cache #(
        .AWIDTH(32),
        .DWIDTH(32),
        .LINES(128)
    ) DUT (
        // inputs
        .clk(clk),
        .reset(reset),
        .ra0(ra0),
        .ra1(ra1),
        .wa(wa),
        .din(din),
        .we(we),
        // outputs
        .dout0(dout0),
        .dout1(dout1),
        .hit0(hit0),
        .hit1(hit1)
    );

    initial begin
        // Call reset!
        reset = 1;
        repeat (10) @(posedge clk);
        reset = 0;

        // If we were to read from an address before ever writing
        // hit should be zero
        ra0 = 32'h00000000; // This should index into the zero'th element of the
        repeat (1) @(negedge clk);
        assert (hit0 == 0) else $display("incorrect hit check for ra0 %b", hit0);

        ra1 = 32'h00000000;
        repeat (1) @(negedge clk);
        assert (hit1 == 0) else $display("incorrect hit check for ra1 %b", hit1);

        $finish();

    end
endmodule
