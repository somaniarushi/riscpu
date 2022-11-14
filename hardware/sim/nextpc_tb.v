`timescale 1ns/1ns

module nextpc_tb();
    reg clk;
    parameter CPU_CLOCK_PERIOD = 10;
    parameter CPU_CLOCK_FREQ   = 1_000_000_000 / CPU_CLOCK_PERIOD;

    parameter DEPTH = 32;
    initial clk = 0;
    always #(CPU_CLOCK_PERIOD/2) clk = ~clk;

    reg [1:0] pc_sel;
    reg [31:0] pc;
    reg [31:0] imm;
    reg [31:0] alu;
    reg [31:0] next_pc;

    fetch_next_pc dut (
        .pc(pc),
        .imm(imm),
        .alu(alu),
        .pc_sel(pc_sel),
        .next_pc(next_pc)
    );

    initial begin
        // Test simple next instruction
        pc_sel = 2;
        pc = 32'h10;
        imm = 32'h10;
        alu = 32'h25;
        repeat (1) @(negedge clk);
        // PC = PC + 4
        assert(next_pc == 32'h14) else $display("incorrectly selected next instruction %h", next_pc);

        // Test ALU next instruction
        pc_sel = 1;
        repeat(1) @(negedge clk);
        assert(next_pc == 32'h25) else $display("incorrectly selected next instruction %h", next_pc);

        // Test Jump instruction
        pc_sel = 0;
        repeat(1) @(negedge clk);
        assert(next_pc == 32'h20) else $display("incorrectly selected next instruction %h", next_pc);


        $finish();
    end
endmodule