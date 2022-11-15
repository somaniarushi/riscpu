`timescale 1ns/1ns
`include "../src/riscv_core/opcode.vh"

module control_logic_tb();
    reg clk;
    parameter CPU_CLOCK_PERIOD = 10;
    parameter CPU_CLOCK_FREQ   = 1_000_000_000 / CPU_CLOCK_PERIOD;

    parameter DEPTH = 32;
    initial clk = 0;
    always #(CPU_CLOCK_PERIOD/2) clk = ~clk;

    reg [31:0] inst_fd, inst_x, inst_mw;
    reg [1:0] pc_sel;
    reg is_j_or_b, wb2d_a, wb2d_b;

    control_logic cl (
      .inst_fd(inst_fd),
      .inst_x(inst_x),
      .inst_mw(inst_mw),
      .pc_sel(pc_sel),
      .is_j_or_b(is_j_or_b),
      .wb2d_a(wb2d_a),
      .wb2d_b(wb2d_b)
    );

    initial begin
        /**
          TEST PC SEL
        */
        inst_fd = 32'h00500113; // addi x2 x0 4
        inst_x = 32'h00508213; // addi x3 x1 5
        repeat (1) @(negedge clk);
        assert(pc_sel == 2) else $display("Should prompt next PCSEL = 2, instead %d", pc_sel);

        inst_fd = 32'h0040026F; // jal x4 4
        repeat (1) @(negedge clk);
        assert(pc_sel == 0) else $display("Should prompt next PCSEL = 1, instead %d", pc_sel);

        inst_fd = 32'h00500113; // addi x2 x0 4
        inst_x = 32'h00428267; // jalr x4 x5 4
        repeat (1) @(negedge clk);
        assert(pc_sel == 1) else $display("Should prompt next PCSEL = 0, instead %d", pc_sel);

          // TODO: Test PC Sel = 1 for branching

        /**
          Test isJorB
        */
        inst_x = 32'h00428267; // jalr x4 x5 4
        repeat (1) @(negedge clk);
        assert(is_j_or_b == 1) else $display("Should recog jump instruction, but %d", is_j_or_b);

        inst_x = 32'h00500113; // addi x2 x0 4
        repeat (1) @(negedge clk);
        assert(is_j_or_b == 0) else $display("Should not recog, but %d", is_j_or_b);

        inst_x = 32'h00620263;  // beq x4, x6, 4
        repeat (1) @(negedge clk);
        assert(is_j_or_b == 1) else $display("Should recog branch instruction, but %d", is_j_or_b);


        /**
        Test WB2Ds
        */
        inst_mw = 32'h00110193; // addi x3 x2 1
        inst_fd = 32'h00018313; // addi x6 x3 0
        repeat (1) @(negedge clk);
        assert(wb2d_a == 1) else $display("rd -> rs1 forwarding did not work");
        assert(wb2d_b == 0) else $display("rd -> rs2 forwarding should not be happening");
          // TODO: What if instruction is not R-type but it just looks like it is?
          // Accidental forwarding

        inst_mw = 32'h00110193; // addi x3 x2 1
        inst_fd = 32'h00350333; // add x6 x10 x3
        repeat (1) @(negedge clk);
        assert(wb2d_b == 1) else $display("rd -> rs2 forwarding does not work");
        assert(wb2d_a == 0) else $display("rd -> rs1 forwarding should not be working");

        inst_mw = 32'h00110193; // addi x3 x2 1
        inst_fd = 32'h00318333; // add x6 x3 x3
        repeat (1) @(negedge clk);
        assert(wb2d_a == 1) else $display("rd -> rs1 forwarding did not work");
        assert(wb2d_b == 1) else $display("rd -> rs2 forwarding does not work");

        $finish();

    end
endmodule