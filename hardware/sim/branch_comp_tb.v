`timescale 1ns/1ns

module branch_comp_tb();
    reg clk;
    parameter CPU_CLOCK_PERIOD = 10;
    parameter CPU_CLOCK_FREQ   = 1_000_000_000 / CPU_CLOCK_PERIOD;

    parameter DEPTH = 32;
    initial clk = 0;
    always #(CPU_CLOCK_PERIOD/2) clk = ~clk;

    reg [31:0] rs1;
    reg [31:0] rs2;
    reg brun;
    reg brlt;
    reg breq;

    branch_comp dut (
        .brun(brun),
        .rs1(rs1),
        .rs2(rs2),
        .brlt(brlt),
        .breq(breq)
    );

    initial begin
        // Test BrLT

        rs1 = 31'h10;
        rs2 = 31'h12;

        brun = 0;
        repeat (1) @(negedge clk);
        assert(brlt == 1) else $display("Signed number brlt incorrect %b", brlt);

        brun = 1;
        repeat (1) @(negedge clk);
        assert(brlt == 1) else $display("Unsigned number brlt incorrect %b", brlt);

        rs1 = -10;
        rs2 = 10;
        brun = 0;
        repeat (1) @(negedge clk);
        assert(brlt == 1) else $display("Signed number brlt incorrect %b", brlt);

        brun = 1;
        repeat (1) @(negedge clk);
        assert(brlt == 0) else $display("Unsigned number brlt incorrect %b", brlt);

        // Test BrEq

        rs1 = 31'h10;
        rs2 = 31'h12;
        brun = 0;
        repeat (1) @(negedge clk)
        assert(breq == 0) else $display("Signed number breq incorrect %b", breq);

        brun = 1;
        repeat (1) @(negedge clk);
        assert(breq == 0) else $display("Unsigned number breq incorrect %b", breq);

        rs1 = -10;
        rs2 = -10;
        brun = 0;
        repeat (1) @(negedge clk);
        assert(breq == 1) else $display("Signed number breq incorrect %b", breq);

        brun = 1;
        repeat (1) @(negedge clk);
        assert(breq == 1) else $display("Unsigned number breq incorrect %b", breq);

        $finish();
    end

endmodule