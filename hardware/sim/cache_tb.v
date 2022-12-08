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

        // Cache Addition 
        // Write address bits 0-6 is offset, bits 7-31 are tag
        wa = 32'h00000011;
        we = 'h1;
        din = 2'b11;
        repeat (1) @(negedge clk);

        we = 'h0;
        ra1 = 32'h00000011; // This should index into the element we just wrote to 
        repeat (1) @(negedge clk);
        assert(dout1[1:0] == 2'b11) else $display("ERROR: value written into cache incorrect, reads %b.", dout1[1:0]);
        assert(hit1 == 1) else $display("ERROR: incorrect hit check for ra1 %b", hit1);

        ra0 = 32'h00000011; // This should index into the element we just wrote to 
        repeat (1) @(negedge clk);
        assert(dout0[1:0] == 2'b11) else $display("ERROR: value written into cache incorrect, reads %b.", dout0[1:0]);
        assert(hit0 == 1) else $display("ERROR: incorrect hit check for ra0 %b", hit0);

        // Test cache miss 
        ra0 = 32'h00000012; 
        repeat (1) @(negedge clk);
        assert (hit0 == 0) else $display("ERROR: incorrect hit check for ra0 %b", hit0);

        // Test for read miss, read hit, write and cache eviction 
        wa = 32'h11000011;
        we = 1;
        din = 2'b10;
        repeat (1) @(negedge clk);
        
        // Cache eviction caused read miss
        we = 0;
        ra1 = 32'h00000011;
        repeat (1) @(negedge clk);
        // dout value should still be correct, even on cache miss
        assert(dout1[1:0] == 2'b10) else $display("ERROR: incorrect cache eviction for dout1 %b", dout1); 
        assert(hit1 == 0) else $display("ERROR: incorrect cache eviction hit for hit1 %b", hit1);

        // Testing simultaneous read hits to same wa
        ra0 = 32'h11000011;
        ra1 = 32'h11000011;
        repeat (1) @(negedge clk);
        assert(dout0[1:0] == 2'b10) else $display("ERROR: incorrect cache eviction for dout0 %b", dout0); 
        assert(hit0 == 1) else $display("ERROR: incorrect cache eviction hit for hit0 %b", hit0);
        assert(dout1[1:0] == 2'b10) else $display("ERROR: incorrect cache eviction for dout1 %b", dout1); 
        assert(hit1 == 1) else $display("ERROR: incorrect cache eviction hit for hit1 %b", hit1);


        // Testing simultaneous read hits to different wa
        wa = 32'h00000100;
        we = 1;
        din = 2'b11;
        repeat (1) @(negedge clk);
        we = 0;
        ra0 = 32'h00000100;
        ra1 = 32'h11000011;
        repeat (1) @(negedge clk);
        assert(dout0[1:0] == 2'b11) else $display("ERROR: incorrect cache eviction for dout0 %b", dout0); 
        assert(hit0 == 1) else $display("ERROR: incorrect cache eviction hit for hit0 %b", hit0);
        assert(dout1[1:0] == 2'b10) else $display("ERROR: incorrect cache eviction for dout1 %b", dout1); 
        assert(hit1 == 1) else $display("ERROR: incorrect cache eviction hit for hit1 %b", hit1);
        
        // Testing simultaneous read hit and read miss
        ra0 = 32'h00000100;
        ra1 = 32'h00000011;
        repeat (1) @(negedge clk);
        assert(dout0[1:0] == 2'b11) else $display("ERROR: incorrect simultaneous cache hit and miss for dout0 %b", dout0); 
        assert(hit0 == 1) else $display("ERROR: incorrect cache eviction hit for hit0 %b", hit0);
        assert(dout1[1:0] == 2'b10) else $display("ERROR: incorrect simultaneous cache hit and miss for dout1 %b", dout1); 
        assert(hit1 == 0) else $display("ERROR: incorrect cache eviction hit for hit1 %b", hit1);

        // Testing simultaneous read ra0 and write
        wa = 32'h11001111;
        we = 1;
        din = 2'b10;
        ra0 = 32'h11001111; 
        repeat (1) @(negedge clk);
        we = 0;
        assert(dout0[1:0] == 2'b10) else $display("ERROR: incorrect simultaneous read write for dout0 %b", dout0); 
        assert(hit0 == 1) else $display("ERROR: incorrect cache eviction hit for hit0 %b", hit0);

        // Testing simultaneous read ra1 and write
        wa = 32'h11011111;
        we = 1;
        din = 2'b11;
        ra1 = 32'h11011111; 
        repeat (1) @(negedge clk);
        we = 0;
        assert(dout1[1:0] == 2'b11) else $display("ERROR: incorrect simultaneous read write for dout1 %b", dout1); 
        assert(hit1 == 1) else $display("ERROR: incorrect cache eviction hit for hit1 %b", hit1);

        // Testing simultaneous read, cache eviction, and write
        we = 1;
        wa = 32'h11110011;
        din = 2'b00;
        ra0 = 32'h00000011;
        ra1 = 32'h11110011;
        repeat (1) @(negedge clk);
        we = 0;
        assert(dout0[1:0]== 2'b00) else $display("ERROR: incorrect simultaneous read, cache eviction and write for dout0 %b", dout0); 
        assert(dout1[1:0] == 2'b00) else $display("ERROR: incorrect simultaneous read, cache eviction and write for dout1 %b", dout1); 
        assert(hit0 == 0) else $display("ERROR: incorrect avengers for hit0 %b", hit0);
        assert(hit1 == 1) else $display("ERROR: incorrect avengers for hit1 %b", hit1);

        


        $finish();

    end
endmodule
