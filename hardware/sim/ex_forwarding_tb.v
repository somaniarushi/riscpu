`timescale 1ns/1ns

module ex_forwarding_tb();
    reg clk;
    parameter CPU_CLOCK_PERIOD = 10;
    parameter CPU_CLOCK_FREQ   = 1_000_000_000 / CPU_CLOCK_PERIOD;

    parameter DEPTH = 32;
    initial clk = 0;
    always #(CPU_CLOCK_PERIOD/2) clk = ~clk;

    reg [31:0] rs1;
    reg [31:0] rs2;
    reg [31:0] wb_val;
    reg [31:0] pc;
    reg [31:0] imm;
    reg [1:0] asel;
    reg [1:0] bsel;
    reg [31:0] rs1_in;
    reg [31:0] rs2_in;
    reg [31:0] rs1_br;
    reg [31:0] rs2_br;

    ex_forwarding dut (
        .rs1(rs1),
        .rs2(rs2),
        .wb_val(wb_val),
        .pc(pc),
        .imm(imm),
        .asel(asel),
        .bsel(bsel),
        .rs1_in(rs1_in),
        .rs2_in(rs2_in),
        .rs1_br(rs1_br),
        .rs2_br(rs2_br)
    );

    initial begin
        rs1 = 10;
        rs2 = 15;
        wb_val = 111;
        pc = 44;
        imm = 1;

        // Test rs1/rs2, no forwarding
        asel = 'b00;
        bsel = 'b00;
        repeat (1) @(negedge clk);
        assert(rs1_in == 10) else $display("Rs1 forwarding incorrect, output %b", rs1_in);
        assert(rs2_in == 15) else $display("Rs2 forwarding incorrect, output %b", rs2_in);

        // Testing pc and imm selection
        asel = 'b01;
        bsel = 'b01;
        repeat (1) @(negedge clk);
        assert(rs1_in == 44) else $display("PC forwarding incorrect, output %b", rs1_in);
        assert(rs2_in == 1) else $display("imm forwarding incorrect, output %b", rs2_in);

        // Testing write back value forwarding
        asel = 'b10;
        bsel = 'b10;
        repeat (1) @(negedge clk);
        assert(rs1_in == 111) else $display("WB Val forwarding incorrect, output %b", rs1_in);
        assert(rs2_in == 111) else $display("WB Val forwarding incorrect, output %b", rs2_in);

        // Testing WB value forwarding AND PC/Imm selection
        asel = 'b11;
        bsel = 'b11;
        repeat (1) @(negedge clk);
        assert(rs1_in == 44) else $display("latch protection incorrect, output %b", rs1_in);
        assert(rs2_in == 1) else $display("latch protection incorrect, output %b", rs2_in);

        $finish();
    end
endmodule