`timescale 1ns/1ns

module imm_generator_tb();
    reg clk;
    parameter CPU_CLOCK_PERIOD = 10;
    parameter CPU_CLOCK_FREQ   = 1_000_000_000 / CPU_CLOCK_PERIOD;

    parameter DEPTH = 32;
    initial clk = 0;
    always #(CPU_CLOCK_PERIOD/2) clk = ~clk;

    reg [31:0] inst;
    reg [31:0] imm;
    immediate_generator (
      .inst(inst),
      .imm(imm)
    );

    initial begin
        // Test I-Types
        inst = 32'h42618313; // addi x6 x3 1062
        repeat (1) @(negedge clk);
        assert (imm == 'd1062) else $display("immediate value incorrect, %d", imm);

        inst = 32'h01022283; // lw x5 16(x4)
        repeat (1) @(negedge clk);
        assert (imm == 'd16) else $display("immediate value incorrect, %d", imm);

        inst = 32'h00428267; // jalr x4 x5 4
        repeat (1) @(negedge clk);
        assert(imm == 'd4) else $display("immediate value incorrect, %d", imm);

        // Test S-Types
        inst = 32'h0072AC23; // sw x7 24(x5)
        repeat (1) @(negedge clk);
        assert(imm == 'd24) else $display("immediate value incorrect, %d", imm);

        // Test B-Types
        inst = 32'h00428463; // beq x5 x4 8
        repeat (1) @(negedge clk);
            // FIXME: Is this incorrect?
        assert (imm == 'd8) else $display("immediate value incorrect, %d", imm);

        // Test U-Types
        inst = 32'h1E59E117; // auipc x2 124318
        repeat (1) @(negedge clk);
            // Checking that upper 20 bits == imm
        assert (imm[31:12] == 'd124318) else $display("immediate value incorrect, %b", imm[31:12]);

        inst = 32'h07BF0337; // lui x6 31728
        repeat (1) @(negedge clk);
            // Checking that upper 20 bits == imm
        assert (imm[31:12] == 'd31728) else $display("immediate value incorrect, %b", imm[31:12]);

        // Test J Types
        inst = 32'h3BF6A26F; // jal x4 437182
        repeat (1) @(negedge clk);
        assert (imm == 'd437182) else $display("immediate value incorrect, %b", imm);

        $finish();

    end

endmodule