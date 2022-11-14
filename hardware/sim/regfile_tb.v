`timescale 1ns/1ns

module regfile_tb();
    reg clk;
    parameter CPU_CLOCK_PERIOD = 10;
    parameter CPU_CLOCK_FREQ   = 1_000_000_000 / CPU_CLOCK_PERIOD;

    parameter DEPTH = 32;

    initial clk = 0;
    always #(CPU_CLOCK_PERIOD/2) clk = ~clk;

    reg we;
    reg [4:0] ra1, ra2, wa;
    reg [31:0] wd;
    wire [31:0] rd1, rd2;
    reg_file dut (
        .clk(clk),
        .we(we),
        .ra1(ra1),
        .ra2(ra2),
        .wa(wa),
        .wd(wd),
        .rd1(rd1),
        .rd2(rd2)
    );

    // Initialize register values
    initial begin
        ra1 = 0; ra2 = 0; wa = 0; wd = 0; we = 0;

        // Check initial reads
        for(integer i = 0; i < DEPTH; i += 1) begin
            for(integer j = 0; j < DEPTH; j += 1) begin
                ra1 = i;
                ra2 = j;
                repeat (1) @(negedge clk);
                assert(rd1 == 0) else $display("rd1 not initialized at %b", ra1);
                assert(rd2 == 0) else $display("rd2 not initialized at %b", ra2);
            end
        end

        // Check that writing to reg file is functional
        wa = 3; wd = 12; we = 1; ra1 = 3;
        repeat (1) @(negedge clk);
        assert(rd1 == 12) else $display("write to rd1 not functionl at %b %b", ra1, rd1);

        // Check that no writing occurs if we = 0
        we = 0; wd = 25;
        repeat (1) @(negedge clk);
        assert(rd1 == 12) else $display("value at register changed because writes disabled %d", ra1);

        // Check that rs2 reads correctly
        ra2 = 3;
        repeat (1) @(negedge clk)
        assert(rd2 == 12) else $display("value at rs2 not written properly %d %d", ra2, rd2);

        // Check that writing to x0 doesn't change value
        wa = 0; wd = 100; we = 1; ra1 = 0;
        repeat (1) @(negedge clk);
        assert(rd1 == 0) else $display("write to x0 should not overwrite value");

        $finish();
    end

endmodule