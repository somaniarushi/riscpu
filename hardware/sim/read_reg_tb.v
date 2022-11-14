`timescale 1ns/1ns

module read_reg_tb();
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
    reg_file rf (
        .clk(clk),
        .we(we),
        .ra1(ra1), .ra2(ra2), .wa(wa),
        .wd(wd),
        .rd1(rd1), .rd2(rd2)
    );

    reg [31:0] inst;
    reg wb2d_a, wb2d_b;
    reg [31:0] wb;

    reg [31:0] rs1, rs2;

    read_from_reg(
        .inst(inst),
        .wb2d_a(wb2d_a),
        .wb2d_b(wb2d_b),
        .rd1(rd1),
        .rd2(rd2),
        .wb_val(wb),
        .ra1(ra1),
        .ra2(ra2),
        .rs1(rs1),
        .rs2(rs2)
    );

    initial begin
        // Test: Simple rs1 rs2 passing

        // Initialize unused values
        wb2d_a = 0;
        wb2d_b = 0;
        wb = 0;

        // Put value into reg file
        we = 1; wa = 4; wd = 1000;
        repeat (1) @(negedge clk);
        wa = 5; wd = 700;
        repeat (1) @(negedge clk);
        we = 0;

        // Simple read from regfile
        inst = 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        inst[19:15] = 4; // setting ra1
        inst[24:20] = 5; // setting rs2
        repeat (1) @(negedge clk);

        // Tests the rs1 and rs2 values after the MUX selection
        assert(rs1 == 1000) else $display("Read was not correctly implemented for rs1, read %d instead", rs1);
        assert(rs2 == 700) else $display("Read was not correctly implemented for rs2, read %d instead", rs2);

        // Tests override of the wb2d-a
        wb2d_a = 1;
        wb = 400;
        repeat (1) @(negedge clk);
        assert(rs1 == 400) else $display("rs1 not overwritten, displays %d", rs1);
        wb2d_a = 0;

        // Tests override of the wb2d-b
        wb2d_b = 1;
        wb = 666;
        repeat (1) @(negedge clk);
        assert(rs2 == 666) else $display("rs2 not overwritten, displays %d", rs2);
        wb2d_b = 0;

        $finish();

    end

endmodule