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
    // Selecting next PC
    reg [1:0] pc_sel;
    // Selecting inst from BIOS or IMEM
    reg inst_sel;
    // Selection whether to input a nop or not
    reg is_j_or_b;
    // Selecting whether to forward from WB to Decode
    reg mw2d_a, mw2d_b;
    // Selecting values for branch comparison
    reg brun;
    // Selecting values that input to the ALU
    reg [1:0] asel, bsel;
    // Selecting operation performed by the ALU
    reg [31:0] alu_sel;

    control_logic cl (
      // Inputs
      .inst_fd(inst_fd),
      .inst_x(inst_x),
      .inst_mw(inst_mw),
      .brlt(brlt),
      .breq(breq),
      // Outputs
      .pc_sel(pc_sel),
      .is_j_or_b(is_j_or_b),
      .wb2d_a(wb2d_a),
      .wb2d_b(wb2d_b),
      .brun(brun),
      .asel(asel),
      .bsel(bsel),
      .alu_sel(alu_sel)
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
          // What if instruction is not R-type but it just looks like it is?
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

        /**
        Test brUN.
        */
        inst_x = 32'h0041E263; // bltu x3 x4 4
        repeat (1) @(negedge clk);
        assert(brun == 1) else $display("inst wasn't recog'd as unsigned %b", brun);

        inst_x = 32'h0041F263; // bgeu x3 x4 4
        repeat (1) @(negedge clk);
        assert(brun == 1) else $display("inst wasn't recog'd as unsigned %b", brun);

        inst_x = 32'h00419A63; // bne x3 x4 20
        repeat (1) @(negedge clk);
        assert(brun == 0) else $display("inst was recog'd as signed %b", brun);

        /**
        Test A-Sel
        */
        // No forwarding, choose rs1
        inst_mw = 32'h00000013; // addi x0 x0 0
        inst_x = 32'h09928213; // addi x4 x5 153
        repeat (1) @(negedge clk);
        assert (asel == 'b00) else $display("asel wrong | output %d", asel);

        // No forwarding, choose rs1
        inst_x = 	32'h010301E7; // jalr x3 x6 16
        repeat (1) @(negedge clk);
        assert (asel == 'b00) else $display("asel wrong | output %d", asel);

        // No forwarding, choose PC
        inst_x = 32'h03266197; // auipc x3 12902
        repeat (1) @(negedge clk);
        assert (asel == 'b01) else $display("PC overwrite broken | output %d", asel);

        // No forwarding, choose PC
        inst_x = 32'h0A740063; // beq x8 x7 160
        repeat (1) @(negedge clk);
        assert (asel == 'b01) else $display("PC overwrite broken | output %d", asel);

        // No forwarding, choose PC
        inst_x = 32'h010001EF; // jal x3 16
        repeat (1) @(negedge clk);
        assert (asel == 'b01) else $display("PC overwrite broken | output %d", asel);

        // ALU to ALU forwarding, choose rs1
        inst_mw = 32'h4DF00193; // addi x3 x0 1247
        inst_x = 32'h00518293; // addi x5 x3 5
        repeat (1) @(negedge clk);
        assert (asel == 'b10) else $display("ALU forwarding broken | output %d", asel);

        // Mem to ALU forwarding, choose rs1
        inst_mw = 32'h00422183; // lw x3 4(x4)
        inst_x = 32'h00518293;	// addi x5 x3 5
        repeat (1) @(negedge clk);
        assert (asel == 'b10) else $display("Mem forwarding broken | output %d", asel);

        // No forwarding, choose PC
        inst_mw = 32'h4DF00193; // addi x3 x0 1247
        inst_x =  32'h010001EF; // jal x3 16
        repeat (1) @(negedge clk);
        assert(asel == 'b01) else $display("forwarding broken | output %d", asel);

        // Mem-Mem Conflict, accounts for PrevMemrs1
        inst_mw = 32'h00012083; // lw x1, 0(x2)
        inst_x =  32'h0030A023; // sw x3, 0(x1)
        repeat (1) @(negedge clk);
        assert(asel == 'b10) else $display("mem-mem forwarding broken | output %d", asel);

        /**
        Test BSel
        */
        inst_mw = 32'h00000033; // add x3 x5 x2
        inst_x = 32'h009400B3; // add x1 x8 x9
        repeat (1) @(negedge clk);
        assert(bsel == 'b00) else $display("bsel wrong | output %d", bsel);

        inst_x = 32'h05920193; // addi x3 x4 89
        repeat (1) @(negedge clk);
        assert (bsel == 'b01) else $display("imm selection broken | output %d", bsel);

        inst_x = 32'h00720863; // beq x4 x7 16
        repeat (1) @(negedge clk);
        assert (bsel == 'b01) else $display("imm selection broken | output %d", bsel);

        inst_x = 32'h0B740267; // jalr x4 x8 183
        repeat (1) @(negedge clk);
        assert (bsel == 'b01) else $display("imm selection broken | output %d", bsel);

        inst_x = 32'h0007B437; // lui x8 123
        repeat (1) @(negedge clk);
        assert (bsel == 'b01) else $display("imm selection broken | output %d", bsel);

        inst_x = 32'h00A62423; // sw x10 8(x12)
        repeat (1) @(negedge clk);
        assert (bsel == 'b01) else $display("imm selection broken | output %d", bsel);

        inst_mw = 32'h5A300293; // addi x5 x0 1443
        inst_x = 32'h00518133; // add x2 x3 x5
        repeat (1) @(negedge clk);
        assert(bsel == 'b10) else $display("forwarding selection works | output %d", bsel);

        // detect rs2 forwarding for MEM-MEM instructions, proves prevmemrs1 is not necessary
        inst_mw = 32'h00012083; // lw x1, 0(x2)
        inst_x =  32'h00112223; // sw x1, 4(x2)
        repeat (1) @(negedge clk);
        assert(bsel[1] == 'b1) else  $display("mem-mem forwarding | output %d", bsel);


        $finish();

    end
endmodule